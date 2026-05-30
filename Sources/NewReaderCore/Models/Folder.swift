import Foundation
import SwiftData

@Model
public final class Folder {
    public var id: UUID = UUID()
    public var name: String = ""
    public var sortOrder: Int = 0

    @Relationship(deleteRule: .nullify)
    public var feeds: [Feed]

    public init(name: String) {
        self.name = name
        self.feeds = []
    }
}
