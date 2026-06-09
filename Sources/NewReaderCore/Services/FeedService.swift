import Foundation
import FeedKit
import SwiftData

/// Limits feed download size to prevent OOM from malicious servers.
final class LimitedDataDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    let maxBytes: Int = 10 * 1024 * 1024
    var accumulatedData = Data()
    var error: Error?

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        accumulatedData.append(data)
        if accumulatedData.count > maxBytes {
            error = FeedServiceError.networkError
            dataTask.cancel()
        }
    }
}

/// Errors that can occur during feed operations
public enum FeedServiceError: LocalizedError {
    case invalidURL
    case parseFailed
    case networkError
    case alreadySubscribed

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 Feed 地址"
        case .parseFailed: return "解析失败，Feed 格式不正确"
        case .networkError: return "网络错误，请稍后重试"
        case .alreadySubscribed: return "已订阅此 Feed"
        }
    }
}

@MainActor
public final class FeedService {
    private let session: URLSession
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        self.modelContext = modelContext
    }

    /// Discover and subscribe to a feed from a URL (handles both direct feed URLs and site URLs)
    public func subscribe(urlString: String) async throws -> Feed {
        guard let url = URLValidator.validate(urlString) else {
            throw FeedServiceError.invalidURL
        }

        // Check for duplicate
        let descriptor = FetchDescriptor<Feed>(predicate: #Predicate { $0.url == url.absoluteString })
        if (try? modelContext.fetch(descriptor).first) != nil {
            throw FeedServiceError.alreadySubscribed
        }

        let parsedFeed = try await fetchAndParse(url: url)
        let feed = Feed(
            title: parsedFeed.title ?? url.host ?? "Untitled",
            url: url.absoluteString,
            feedDescription: parsedFeed.description ?? "",
            siteURL: parsedFeed.link
        )
        feed.imageURL = parsedFeed.imageURL
        feed.lastFetched = Date()

        modelContext.insert(feed)

        // Import articles with sanitized content
        for item in parsedFeed.items {
            let article = Article(
                title: item.title ?? "Untitled",
                url: item.link ?? url.absoluteString,
                contentHTML: HTMLSanitizer.sanitize(item.content ?? item.description ?? ""),
                author: item.author,
                publishedDate: item.publishedDate
            )
            article.feed = feed
            modelContext.insert(article)
        }

        try? modelContext.save()
        return feed
    }

    /// Refresh all articles for a given feed
    public func refresh(feed: Feed) async throws -> [Article] {
        guard let url = URLValidator.validate(feed.url) else {
            throw FeedServiceError.invalidURL
        }

        let parsedFeed = try await fetchAndParse(url: url)
        feed.lastFetched = Date()

        var newArticles: [Article] = []
        let existingURLs = Set(feed.allArticles.map { $0.url })

        for item in parsedFeed.items {
            let articleURL = item.link ?? url.absoluteString
            guard !existingURLs.contains(articleURL) else { continue }

            let article = Article(
                title: item.title ?? "Untitled",
                url: articleURL,
                contentHTML: HTMLSanitizer.sanitize(item.content ?? item.description ?? ""),
                author: item.author,
                publishedDate: item.publishedDate
            )
            article.feed = feed
            modelContext.insert(article)
            newArticles.append(article)
        }

        try? modelContext.save()
        return newArticles
    }

    /// Refresh all subscribed feeds (sequential to avoid data race warnings)
    public func refreshAll(feeds: [Feed]) async {
        for feed in feeds {
            _ = try? await refresh(feed: feed)
        }
    }

    // MARK: - Private

    private func fetchAndParse(url: URL) async throws -> ParsedFeed {
        let delegate = LimitedDataDelegate()
        let (data, _) = try await session.data(from: url, delegate: delegate)
        if let error = delegate.error { throw error }
        let parser = FeedParser(data: data)
        let result = parser.parse()

        switch result {
        case .success(let feed):
            return ParsedFeed(from: feed)
        case .failure:
            throw FeedServiceError.parseFailed
        }
    }
}

/// Simplified feed model from FeedKit parsing result
public struct ParsedFeed {
    let title: String?
    let description: String?
    let link: String?
    let imageURL: String?
    let items: [ParsedItem]

    public init(from feed: FeedKit.Feed) {
        switch feed {
        case .atom(let atom):
            self.title = atom.title
            self.description = atom.subtitle?.value
            self.link = atom.links?.first?.attributes?.href
            self.imageURL = atom.icon
            self.items = atom.entries?.compactMap { ParsedItem(from: $0) } ?? []
        case .rss(let rss):
            self.title = rss.title
            self.description = rss.description
            self.link = rss.link
            self.imageURL = rss.image?.url
            self.items = rss.items?.compactMap { ParsedItem(from: $0) } ?? []
        case .json(let json):
            self.title = json.title
            self.description = json.description
            self.link = json.homePageURL
            self.imageURL = json.icon
            self.items = json.items?.compactMap { ParsedItem(from: $0) } ?? []
        }
    }
}

public struct ParsedItem {
    let title: String?
    let link: String?
    let content: String?
    let description: String?
    let author: String?
    let publishedDate: Date?

    public init(from entry: AtomFeedEntry) {
        self.title = entry.title
        self.link = entry.links?.first?.attributes?.href
        self.content = entry.content?.value
        self.description = entry.summary?.value
        self.author = entry.authors?.first?.name
        self.publishedDate = entry.published
    }

    public init(from item: RSSFeedItem) {
        self.title = item.title
        self.link = item.link
        self.content = item.content?.contentEncoded
        self.description = item.description
        self.author = item.author
        self.publishedDate = item.pubDate
    }

    public init(from item: JSONFeedItem) {
        self.title = item.title
        self.link = item.url
        self.content = item.contentHtml ?? item.contentText
        self.description = item.summary
        self.author = item.author?.name
        self.publishedDate = item.datePublished
    }
}
