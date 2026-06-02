import Foundation
import SwiftData

/// Handles OPML import and export for feed subscriptions
@MainActor
public final class OPMLService {
    private let modelContext: ModelContext
    private var feedService: FeedService { FeedService(modelContext: modelContext) }

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Export all feeds to an OPML file
    public func exportOPML(feeds: [Feed], folders: [Folder]) -> URL? {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
          <head>
            <title>NewReader Subscriptions</title>
            <dateCreated>\(ISO8601DateFormatter().string(from: Date()))</dateCreated>
          </head>
          <body>

        """

        for folder in folders where !folder.feeds.isEmpty {
            xml += "    <outline text=\"\(escapeXML(folder.name))\" title=\"\(escapeXML(folder.name))\">\n"
            for feed in folder.feeds {
                xml += outlineXML(for: feed, indent: "      ")
            }
            xml += "    </outline>\n"
        }

        let folderFeedIDs = Set(folders.flatMap { $0.feeds.map { $0.id } })
        for feed in feeds where !folderFeedIDs.contains(feed.id) {
            xml += outlineXML(for: feed, indent: "    ")
        }

        xml += """
          </body>
        </opml>
        """

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("NewReader_\(Date().ISO8601Format().prefix(10)).opml")
        try? xml.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// Import feeds from an OPML file, returns count of newly added feeds
    /// Max OPML file size: 5 MB
    private static let maxOPMLSize: Int64 = 5 * 1024 * 1024

    public func importOPML(from url: URL) async -> Int {
        // Reject oversized files to prevent memory exhaustion
        let fileSize: Int64
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            fileSize = size
        } else {
            return 0
        }
        guard fileSize <= OPMLService.maxOPMLSize else { return 0 }
        guard let data = try? Data(contentsOf: url),
              let xml = String(data: data, encoding: .utf8) else { return 0 }

        let outlines = Self.parseOutlines(from: xml)
        var count = 0

        for (_, feedURL) in outlines {
            guard !feedURL.isEmpty,
                  URLValidator.isPlausibleURL(feedURL) else { continue }
            do {
                _ = try await feedService.subscribe(urlString: feedURL)
                count += 1
            } catch {
                continue
            }
        }

        return count
    }

    // MARK: - Private

    private func outlineXML(for feed: Feed, indent: String) -> String {
        """
        \(indent)<outline text="\(escapeXML(feed.title))" \
        title="\(escapeXML(feed.title))" type="rss" \
        xmlUrl="\(escapeXML(feed.url))" \
        htmlUrl="\(escapeXML(feed.siteURL ?? feed.url))"/>\n
        """
    }

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    /// Parse `<outline>` entries out of an OPML blob. Exposed as `internal`
    /// for unit testing; the public surface is `importOPML(from:)`.
    nonisolated static func parseOutlines(from xml: String) -> [(title: String, url: String)] {
        var results: [(String, String)] = []
        let urlPattern = #"xmlUrl="([^"]+)""#
        let titlePattern = #"text="([^"]+)""#

        guard let urlRegex = try? NSRegularExpression(pattern: urlPattern),
              let titleRegex = try? NSRegularExpression(pattern: titlePattern)
        else { return results }

        let range = NSRange(xml.startIndex..., in: xml)
        let matches = urlRegex.matches(in: xml, range: range)

        // Pre-scan all title matches so we can find the title regardless
        // of whether `text=` appears before or after `xmlUrl=`.
        let titleMatches = titleRegex.matches(in: xml, range: range)
        let titles: [(pos: Int, text: String)] = titleMatches.compactMap { m in
            guard let r = Range(m.range(at: 1), in: xml) else { return nil }
            return (m.range.location, String(xml[r]))
        }

        for match in matches {
            guard let urlRange = Range(match.range(at: 1), in: xml) else { continue }
            let url = String(xml[urlRange])
            let position = match.range.location
            let lineStart = xml.index(xml.startIndex, offsetBy: position)
            let linePrefix = String(xml[..<lineStart]).components(separatedBy: "\n").last ?? ""

            // Try the title that appears on the *same line* as the url,
            // which could be before or after xmlUrl.
            var title = "Untitled"
            var bestDist = Int.max
            for (tp, tt) in titles {
                // Estimate line bounds: search backwards from position for '<'
                let lineBoundary: Int = {
                    var p = position
                    while p > 0 {
                        let idx = xml.index(xml.startIndex, offsetBy: p - 1)
                        if xml[idx] == "<" { break }
                        p -= 1
                    }
                    return p
                }()
                if tp >= lineBoundary && tp < position + url.count + 30 {
                    let dist = abs(tp - position)
                    if dist < bestDist { bestDist = dist; title = tt }
                }
            }

            // Fallback to pre-scan on the same line
            if title == "Untitled" {
                if let titleMatch = titleRegex.firstMatch(in: linePrefix, range: NSRange(linePrefix.startIndex..., in: linePrefix)),
                   let titleRange = Range(titleMatch.range(at: 1), in: linePrefix) {
                    title = String(linePrefix[titleRange])
                }
            }

            results.append((title, url))
        }

        return results
    }
}
