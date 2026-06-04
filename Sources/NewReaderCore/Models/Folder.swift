import Foundation
import SwiftData

@Model
public final class Folder {
    public var id: UUID = UUID()
    public var name: String = ""
    public var sortOrder: Int = 0

    @Relationship(deleteRule: .nullify, inverse: \Feed.folder)
    public var feeds: [Feed]?

    public var allFeeds: [Feed] { feeds ?? [] }

    public init(name: String) {
        self.name = name
    }
}
