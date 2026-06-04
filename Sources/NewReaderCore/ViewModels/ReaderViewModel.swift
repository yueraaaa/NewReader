import Foundation
import SwiftData
import Combine

/// Central ViewModel shared across macOS and iOS
@MainActor
public final class ReaderViewModel: ObservableObject {
    // MARK: - Published state
    @Published public var feeds: [Feed] = []
    @Published public var folders: [Folder] = []
    @Published public var selectedFeed: Feed?
    @Published public var selectedArticle: Article?
    @Published public var articles: [Article] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var searchQuery: String = ""
    @Published public var isRefreshing: Bool = false
    @Published public var showSubscribe: Bool = false

    // Services
    public let aiService = AIService()
    public let ttsService = TTSService()
    public let readabilityService = ReadabilityService()
    public let cacheService = CacheService()
    public let notificationService = NotificationService.shared

    public let modelContext: ModelContext
    public let syncMonitor: SyncMonitor
    @Published public var appTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(appTheme.rawValue, forKey: "newreader_theme")
        }
    }
    private var feedService: FeedService { FeedService(modelContext: modelContext) }
    private var opmlService: OPMLService { OPMLService(modelContext: modelContext) }

    /// Articles filtered by search query if active
    public var filteredArticles: [Article] {
        guard !searchQuery.isEmpty else { return articles }
        let query = searchQuery.localizedLowercase
        return articles.filter {
            $0.title.localizedLowercase.contains(query) ||
            ($0.author?.localizedLowercase.contains(query) ?? false) ||
            $0.summary.localizedLowercase.contains(query)
        }
    }

    public init(modelContext: ModelContext, iCloudContainerID: String? = nil) {
        self.modelContext = modelContext
        self.appTheme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "newreader_theme") ?? "system") ?? .system
        self.syncMonitor = SyncMonitor(configuredContainerID: iCloudContainerID)
        loadData()
    }

    // MARK: - Data loading

    public func loadData() {
        invalidateCache()
        let feedDescriptor = FetchDescriptor<Feed>(sortBy: [SortDescriptor(\.addedDate)])
        let folderDescriptor = FetchDescriptor<Folder>(sortBy: [SortDescriptor(\.sortOrder)])
        if let f = try? modelContext.fetch(feedDescriptor) { feeds = f }
        if let d = try? modelContext.fetch(folderDescriptor) { folders = d }
    }

    public func selectFeed(_ feed: Feed?) {
        selectedFeed = feed
        selectedArticle = nil
        articles = sortedArticles(from: feed?.allArticles ?? allFlatArticles)
    }

    public func selectAllArticles() {
        selectedFeed = nil
        selectedArticle = nil
        articles = sortedArticles(from: allFlatArticles)
    }

    public func selectUnread() {
        selectedFeed = nil
        selectedArticle = nil
        articles = sortedArticles(from: allFlatArticles.filter { !$0.isRead })
    }

    public func selectStarred() {
        selectedFeed = nil
        selectedArticle = nil
        articles = sortedArticles(from: allFlatArticles.filter { $0.isStarred })
    }

    private var _cachedAllArticles: [Article] = []
    private var _articlesCacheInvalid = true

    private func invalidateCache() { _articlesCacheInvalid = true }

    private var allFlatArticles: [Article] {
        if _articlesCacheInvalid {
            _cachedAllArticles = feeds.flatMap { $0.allArticles }
            _articlesCacheInvalid = false
        }
        return _cachedAllArticles
    }

    private func sortedArticles(from articles: [Article]) -> [Article] {
        articles.sorted { ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast) }
    }

    // MARK: - Feed operations

    public func subscribe(url: String, folder: Folder? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let feed = try await feedService.subscribe(urlString: url)
            feed.folder = folder
            try? modelContext.save()
            feeds.append(feed)
            feeds.sort { $0.addedDate < $1.addedDate }
            await autoSummarizeNewArticles(feed.allArticles)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func refreshFeed(_ feed: Feed) async {
        do {
            let newArticles = try await feedService.refresh(feed: feed)
            if !newArticles.isEmpty {
                notifyNewArticles(newArticles, feed: feed)
                cacheNewArticles(newArticles)
                if selectedFeed?.id == feed.id {
                    articles = sortedArticles(from: feed.allArticles)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func refreshAll() async {
        isRefreshing = true
        defer { isRefreshing = false }
        var allNew: [(Article, Feed)] = []
        for feed in feeds {
            if let newArticles = try? await feedService.refresh(feed: feed) {
                for article in newArticles { allNew.append((article, feed)) }
            }
        }
        if !allNew.isEmpty {
            let notifications = allNew.map { ($0.0.title, $0.1.title) }
            notificationService.notifyNewArticles(notifications)
            for (article, _) in allNew { cacheNewArticle(article) }
        }
        loadData()
        if let feed = selectedFeed { selectFeed(feed) }
        else { selectAllArticles() }
    }

    /// Recently deleted feeds with undo window (5s).
    @Published public var lastDeletedFeed: Feed?
    private var undoTask: Task<Void, Never>?

    public func deleteFeed(_ feed: Feed) {
        let snapshot = feed
        modelContext.delete(feed)
        try? modelContext.save()
        feeds.removeAll { $0.id == feed.id }
        if selectedFeed?.id == feed.id { selectAllArticles() }
        lastDeletedFeed = snapshot
        undoTask?.cancel()
        undoTask = Task {
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled { lastDeletedFeed = nil }
        }
    }

    public func undoDeleteFeed() {
        guard let feed = lastDeletedFeed else { return }
        modelContext.insert(feed)
        try? modelContext.save()
        feeds.append(feed)
        feeds.sort { $0.addedDate < $1.addedDate }
        lastDeletedFeed = nil
        undoTask?.cancel()
    }

    // MARK: - Article operations

    public func toggleRead(_ article: Article) {
        article.isRead.toggle()
        try? modelContext.save()
    }

    public func toggleStarred(_ article: Article) {
        article.isStarred.toggle()
        try? modelContext.save()
    }

    public func markAllAsRead(in feed: Feed) {
        feed.allArticles.forEach { $0.isRead = true }
        try? modelContext.save()
    }

    /// Batch mark all visible articles as read
    public func markAllVisibleAsRead() {
        articles.filter { !$0.isRead }.forEach { $0.isRead = true }
        try? modelContext.save()
    }

    // MARK: - AI

    public func summarize(_ article: Article) async -> String {
        if let cached = article.aiSummary { return cached }
        do {
            let summary = try await aiService.summarize(html: article.contentHTML, title: article.title)
            article.aiSummary = summary
            try? modelContext.save()
            return summary
        } catch {
            errorMessage = error.localizedDescription
            return ""
        }
    }

    /// Batch summarize multiple unread articles
    public func summarizeAllUnread() async {
        isLoading = true
        defer { isLoading = false }
        for article in articles where article.aiSummary == nil {
            _ = try? await aiService.summarize(html: article.contentHTML, title: article.title)
        }
        try? modelContext.save()
    }

    public func translate(_ article: Article, to language: TranslationLanguage) async -> String {
        if let cached = getTranslation(for: article, language: language.rawValue) { return cached }
        do {
            let text = try await aiService.translate(html: article.contentHTML, to: language)
            setTranslation(for: article, language: language.rawValue, text: text)
            try? modelContext.save()
            return text
        } catch {
            errorMessage = error.localizedDescription
            return ""
        }
    }

    public func getTranslation(for article: Article, language: String) -> String? {
        guard let json = article.translationJSON,
              let data = json.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return nil }
        return dict[language]
    }

    public func setTranslation(for article: Article, language: String, text: String) {
        var dict: [String: String] = [:]
        if let json = article.translationJSON,
           let data = json.data(using: .utf8),
           let existing = try? JSONDecoder().decode([String: String].self, from: data) {
            dict = existing
        }
        dict[language] = text
        if let data = try? JSONEncoder().encode(dict) {
            article.translationJSON = String(data: data, encoding: .utf8)
        }
    }

    // MARK: - Readability (full-text extraction)

    public func extractFullText(_ article: Article) async -> String {
        do {
            let html = try await readabilityService.extractArticle(from: article.url)
            article.contentHTML = html
            try? modelContext.save()
            cacheArticle(article)
            return html
        } catch {
            errorMessage = error.localizedDescription
            return article.contentHTML
        }
    }

    // MARK: - Offline caching

    public func cacheArticle(_ article: Article) {
        cacheService.cacheArticle(id: article.id, html: article.contentHTML, title: article.title)
    }

    public func loadCachedArticle(_ article: Article) -> String? {
        cacheService.loadCachedArticle(id: article.id)
    }

    public func isArticleCached(_ article: Article) -> Bool {
        cacheService.isCached(id: article.id)
    }

    public func clearCache() {
        cacheService.clearAllCache()
    }

    public func cacheSizeFormatted() -> String {
        let bytes = cacheService.cacheSize()
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }

    // MARK: - OPML

    public func exportOPML() -> URL? {
        opmlService.exportOPML(feeds: feeds, folders: folders)
    }

    public func importOPML(from url: URL) async -> Int {
        isLoading = true
        defer { isLoading = false }
        let count = await opmlService.importOPML(from: url)
        loadData()
        selectAllArticles()
        return count
    }

    // MARK: - Background refresh

    public func backgroundRefresh() async {
        await refreshAll()
    }

    // MARK: - Folder

    public func createFolder(name: String) {
        let folder = Folder(name: name)
        modelContext.insert(folder)
        try? modelContext.save()
        folders.append(folder)
    }

    public func renameFeed(_ feed: Feed, to newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        feed.title = trimmed
        try? modelContext.save()
    }

    public func renameFolder(_ folder: Folder, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        folder.name = trimmed
        try? modelContext.save()
    }

    public func deleteFolder(_ folder: Folder) {
        // Unlink all feeds from this folder
        for feed in folder.allFeeds {
            feed.folder = nil
        }
        modelContext.delete(folder)
        try? modelContext.save()
        folders.removeAll { $0.id == folder.id }
    }

    public func moveFeed(_ feed: Feed, to folder: Folder?) {
        feed.folder = folder
        try? modelContext.save()
    }

    // MARK: - Private

    private func notifyNewArticles(_ articles: [Article], feed: Feed) {
        let items = articles.map { ($0.title, feed.title) }
        notificationService.notifyNewArticles(items)
    }

    private func cacheNewArticles(_ articles: [Article]) {
        for article in articles {
            cacheService.cacheArticle(id: article.id, html: article.contentHTML, title: article.title)
        }
    }

    private func cacheNewArticle(_ article: Article) {
        cacheService.cacheArticle(id: article.id, html: article.contentHTML, title: article.title)
    }

    private func autoSummarizeNewArticles(_ articles: [Article]) async {
        for article in articles.prefix(5) where article.aiSummary == nil {
            if let summary = try? await aiService.summarize(html: article.contentHTML, title: article.title) {
                article.aiSummary = summary
            }
        }
        try? modelContext.save()
    }
}
