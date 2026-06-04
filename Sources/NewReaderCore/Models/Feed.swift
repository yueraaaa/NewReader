import Foundation
import SwiftData

@Model
public final class Feed {
    public var id: UUID = UUID()
    public var title: String = ""
    public var feedDescription: String = ""
    public var url: String = ""
    public var siteURL: String?
    /// Non-nil when the last refresh failed. Cleared on successful refresh.
    public var lastError: String?
    public var imageURL: String?
    public var lastFetched: Date?
    public var addedDate: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Article.feed)
    public var articles: [Article]?

    /// CloudKit-safe accessor. Use this instead of `articles` directly.
    public var allArticles: [Article] { articles ?? [] }

    public var folder: Folder?

    public init(title: String, url: String, feedDescription: String = "", siteURL: String? = nil) {
        self.title = title
        self.url = url
        self.feedDescription = feedDescription
        self.siteURL = siteURL
    }

    /// Sorted unread articles, newest first
    public var unreadArticles: [Article] {
        (articles ?? []).filter { !$0.isRead }
            .sorted { ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast) }
    }
}
