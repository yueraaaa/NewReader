import Foundation

/// Extracts full article text from web pages (simplified Mercury/Readability-style)
public final class ReadabilityService: @unchecked Sendable {
    private let session: URLSession

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    /// Attempt to extract clean article text from a URL
    public func extractArticle(from url: String) async throws -> String {
        guard let articleURL = URLValidator.validate(url) else {
            throw ReadabilityError.invalidURL
        }

        let (data, _) = try await session.data(from: articleURL)
        guard let html = String(data: data, encoding: .utf8) else {
            throw ReadabilityError.invalidContent
        }

        // Sanitize before extraction
        let sanitized = HTMLSanitizer.sanitize(html)
        return try extractContent(from: sanitized, baseURL: articleURL)
    }

    /// Extract meaningful text content from raw HTML using heuristics
    public func extractContent(from html: String, baseURL: URL?) throws -> String {
        // Remove scripts and styles
        let cleaned = html
            .replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>",
                                  with: "", options: .regularExpression)
            .replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>",
                                  with: "", options: .regularExpression)
            .replacingOccurrences(of: "<nav[^>]*>[\\s\\S]*?</nav>",
                                  with: "", options: .regularExpression)
            .replacingOccurrences(of: "<header[^>]*>[\\s\\S]*?</header>",
                                  with: "", options: .regularExpression)
            .replacingOccurrences(of: "<footer[^>]*>[\\s\\S]*?</footer>",
                                  with: "", options: .regularExpression)

        // Try to find article content in common containers
        let articlePatterns = [
            "<article[^>]*>([\\s\\S]*?)</article>",
            "<div[^>]*class=\"[^\"]*article[^\"]*\"[^>]*>([\\s\\S]*?)</div>",
            "<div[^>]*class=\"[^\"]*post[^\"]*\"[^>]*>([\\s\\S]*?)</div>",
            "<div[^>]*class=\"[^\"]*content[^\"]*\"[^>]*>([\\s\\S]*?)</div>",
            "<main[^>]*>([\\s\\S]*?)</main>"
        ]

        var extractedHTML = cleaned
        for pattern in articlePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
               let range = Range(match.range(at: 1), in: cleaned) {
                extractedHTML = String(cleaned[range])
                break
            }
        }

        // Convert to plain text
        guard let data = extractedHTML.data(using: .utf8) else {
            throw ReadabilityError.invalidContent
        }

        let plainText = try NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
        ).string

        // Clean up whitespace
        let lines = plainText.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return lines.joined(separator: "\n\n")
    }
}

public enum ReadabilityError: LocalizedError {
    case invalidURL
    case invalidContent

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的文章链接"
        case .invalidContent: return "无法解析文章内容"
        }
    }
}
