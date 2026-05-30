import Foundation
import SwiftData

@Model
public final class Article {
    public var id: UUID = UUID()
    public var title: String = ""
    public var author: String?
    public var url: String = ""
    public var contentHTML: String = ""
    public var summary: String = ""
    public var publishedDate: Date?
    public var fetchedDate: Date = Date()
    public var isRead: Bool = false
    public var isStarred: Bool = false

    /// Cached AI summary, nil if not yet generated
    public var aiSummary: String?
    /// Cached translation (keyed by target language code, e.g. "zh")
    public var translationJSON: String?

    public var feed: Feed?

    public init(title: String, url: String, contentHTML: String, author: String? = nil, publishedDate: Date? = nil) {
        self.title = title
        self.url = url
        self.contentHTML = contentHTML
        self.author = author
        self.publishedDate = publishedDate
    }
}
