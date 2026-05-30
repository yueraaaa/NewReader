import Foundation

/// Lightweight HTML sanitizer for feed content.
/// Strips dangerous elements and attributes before rendering.
public enum HTMLSanitizer {

    /// Remove scripts, event handlers, and other potentially dangerous constructs from HTML.
    /// This is not a full HTML parser — it uses regex-based heuristics suitable for RSS feed content.
    public static func sanitize(_ html: String) -> String {
        var cleaned = html

        // Remove <script>...</script>
        cleaned = cleaned.replacingOccurrences(
            of: "<script[^>]*>[\\s\\S]*?</script>",
            with: "",
            options: .regularExpression
        )

        // Remove on* event handler attributes
        cleaned = cleaned.replacingOccurrences(
            of: "\\son\\w+\\s*=\\s*\"[^\"]*\"",
            with: "",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: "\\son\\w+\\s*=\\s*'[^']*'",
            with: "",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: "\\son\\w+\\s*=\\s*[^\\s>]+",
            with: "",
            options: .regularExpression
        )

        // Remove javascript: URLs from href/src attributes
        cleaned = cleaned.replacingOccurrences(
            of: "(?i)href\\s*=\\s*\"javascript:[^\"]*\"",
            with: "href=\"#\"",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: "(?i)src\\s*=\\s*\"javascript:[^\"]*\"",
            with: "src=\"\"",
            options: .regularExpression
        )

        // Remove <iframe> elements (tracking, malicious embeds)
        cleaned = cleaned.replacingOccurrences(
            of: "<iframe[^>]*>[\\s\\S]*?</iframe>",
            with: "",
            options: .regularExpression
        )

        // Remove <object> and <embed> elements
        cleaned = cleaned.replacingOccurrences(
            of: "<(object|embed)[^>]*>[\\s\\S]*?</(object|embed)>",
            with: "",
            options: .regularExpression
        )

        // Remove <form> elements (phishing risk)
        cleaned = cleaned.replacingOccurrences(
            of: "<form[^>]*>[\\s\\S]*?</form>",
            with: "",
            options: .regularExpression
        )

        return cleaned
    }
}
