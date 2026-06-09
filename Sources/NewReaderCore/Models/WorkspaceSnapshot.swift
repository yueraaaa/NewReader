import Foundation
import SwiftData

/// Cached workspace analysis result: keyword graph + AI summary of reading patterns.
@Model
public final class WorkspaceSnapshot {
    public var id: UUID = UUID()
    public var createdAt: Date = Date()
    /// JSON array of keyword strings, e.g. ["AI","隐私","Apple"]
    public var keywordsJSON: String = ""
    /// JSON array of relation objects: [{"source":"K1","target":"K2","weight":1.0}]
    public var relationsJSON: String = ""
    /// One-paragraph AI-generated summary of reading interests
    public var summaryText: String = ""
    /// Number of articles this analysis was based on
    public var articleCount: Int = 0
    /// True while generation is in progress (not persisted)
    @Transient
    public var isGenerating: Bool = false

    public init(keywordsJSON: String = "",
                relationsJSON: String = "",
                summaryText: String = "",
                articleCount: Int = 0,
                createdAt: Date = Date()) {
        self.keywordsJSON = keywordsJSON
        self.relationsJSON = relationsJSON
        self.summaryText = summaryText
        self.articleCount = articleCount
        self.createdAt = createdAt
    }

    // MARK: - Decoded accessors

    public var keywords: [String] {
        decodeJSON(keywordsJSON) ?? []
    }

    public var relations: [KeywordRelation] {
        decodeJSON(relationsJSON) ?? []
    }

    private func decodeJSON<T: Decodable>(_ raw: String) -> T? {
        guard let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

/// A single edge in the keyword relationship graph.
public struct KeywordRelation: Codable, Identifiable {
    public var id: String { "\(source)→\(target)" }
    public var source: String
    public var target: String
    public var weight: Double

    public init(source: String, target: String, weight: Double = 1.0) {
        self.source = source
        self.target = target
        self.weight = weight
    }
}
