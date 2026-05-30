import Foundation
import SwiftData

@Model
public final class Feed {
    public var id: UUID = UUID()
    public var title: String = ""
    public var feedDescription: String = ""
    public var url: String = ""
    public var siteURL: String?
    public var imageURL: String?
    public var lastFetched: Date?
    public var addedDate: Date = Date()

    @Relationship(deleteRule: .cascade)
    public var articles: [Article]

    public var folder: Folder?

    public init(title: String, url: String, feedDescription: String = "", siteURL: String? = nil) {
        self.title = title
        self.url = url
        self.feedDescription = feedDescription
        self.siteURL = siteURL
        self.articles = []
    }

    /// Sorted unread articles, newest first
    public var unreadArticles: [Article] {
        articles.filter { !$0.isRead }
            .sorted { ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast) }
    }
}
