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
            of: "<script\\b[^>]*>[\\s\\S]*?</script>",
            with: "",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: "<script\\b[^>]*/>",
            with: "",
            options: [.regularExpression, .caseInsensitive]
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

        // Remove <base> elements — they would override the WKWebView baseURL
        // and turn every relative link into a phishing redirect.
        cleaned = cleaned.replacingOccurrences(
            of: "<base[^>]*>",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )

        // Strip CSS url() references to prevent tracking pixels via
        // background-image / @import etc.
        cleaned = cleaned.replacingOccurrences(
            of: #"url\s*\("#,
            with: "url(data:,",
            options: [.regularExpression, .caseInsensitive]
        )

        // Remove <meta http-equiv="refresh"> — automatic redirect that works
        // even with JavaScript disabled.
        cleaned = cleaned.replacingOccurrences(
            of: "<meta[^>]*http-equiv\\s*=\\s*[\"']?refresh[\"']?[^>]*>",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )

        return cleaned
    }

    /// Strip all HTML tags and decode a handful of common entities,
    /// yielding plain text suitable for AI prompts and TTS.
    ///
    /// This is intentionally a pure regex/lookup approach — it does not
    /// instantiate `NSAttributedString` (which would fetch remote images,
    /// CSS, and fonts, leaking the user's IP and stalling for tens of
    /// seconds while resources time out).
    public static func toPlainText(_ html: String) -> String {
        var text = html

        // Remove <script> and <style> blocks entirely (including contents).
        text = text.replacingOccurrences(
            of: "<(script|style)\\b[\\s\\S]*?</\\1>",
            with: " ",
            options: [.regularExpression, .caseInsensitive]
        )

        // Remove all other HTML tags.
        text = text.replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )

        // Decode the most common named/numeric entities.
        let entities: [(String, String)] = [
            ("&nbsp;", " "), ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&apos;", "'"), ("&#39;", "'"),
            ("&hellip;", "..."), ("&mdash;", "-"), ("&ndash;", "-"),
            ("&rsquo;", "'"), ("&lsquo;", "'"), ("&rdquo;", "\""),
            ("&ldquo;", "\""), ("&middot;", ".")
        ]
        for (entity, replacement) in entities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }
        // Numeric entities: &#1234; and &#x1F4A9;
        text = text.replacingOccurrences(
            of: "&#([0-9]+);",
            with: " ",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: "&#x([0-9a-fA-F]+);",
            with: " ",
            options: .regularExpression
        )

        // Collapse runs of whitespace into single spaces, then normalize
        // line breaks so paragraph boundaries survive.
        text = text.replacingOccurrences(
            of: "[ \\t\\xa0]+",
            with: " ",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: "[ \\t]*\\n[ \\t]*",
            with: "\n",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: "\\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
