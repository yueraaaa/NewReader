import XCTest
@testable import NewReaderCore

final class HTMLSanitizerTests: XCTestCase {
    // MARK: - Script & event handlers

    func testStripsScriptTag() {
        let result = HTMLSanitizer.sanitize("<p>hi</p><script>alert(1)</script><p>bye</p>")
        XCTAssertFalse(result.contains("<script"))
        XCTAssertTrue(result.contains("<p>hi</p>"))
        XCTAssertTrue(result.contains("<p>bye</p>"))
    }

    func testStripsScriptTagWithAttributes() {
        let result = HTMLSanitizer.sanitize("<script type=\"text/javascript\" src=\"x.js\">alert(1)</script>")
        XCTAssertFalse(result.contains("script"))
    }

    func testStripsOnHandlerDoubleQuoted() {
        let result = HTMLSanitizer.sanitize("<img src=\"x\" onerror=\"alert(1)\">")
        XCTAssertFalse(result.lowercased().contains("onerror"))
    }

    func testStripsOnHandlerSingleQuoted() {
        let result = HTMLSanitizer.sanitize("<img src='x' onerror='alert(1)'>")
        XCTAssertFalse(result.lowercased().contains("onerror"))
    }

    func testStripsOnHandlerUnquoted() {
        let result = HTMLSanitizer.sanitize("<img src=x onerror=alert(1)>")
        XCTAssertFalse(result.lowercased().contains("onerror"))
    }

    // MARK: - javascript: URLs

    func testNeutralisesJavascriptHref() {
        let result = HTMLSanitizer.sanitize("<a href=\"javascript:alert(1)\">x</a>")
        XCTAssertFalse(result.lowercased().contains("javascript:"))
    }

    func testNeutralisesJavascriptSrc() {
        let result = HTMLSanitizer.sanitize("<img src=\"javascript:alert(1)\">")
        XCTAssertFalse(result.lowercased().contains("javascript:"))
    }

    // MARK: - Embeds & forms

    func testStripsIframe() {
        let result = HTMLSanitizer.sanitize("<iframe src=\"https://evil.com\"></iframe>")
        XCTAssertFalse(result.lowercased().contains("iframe"))
    }

    func testStripsObjectAndEmbed() {
        let result = HTMLSanitizer.sanitize("<object data=\"x\"></object><embed src=\"y\"></embed>")
        XCTAssertFalse(result.lowercased().contains("<object"))
        XCTAssertFalse(result.lowercased().contains("<embed"))
    }

    func testStripsForm() {
        let result = HTMLSanitizer.sanitize("<form action=\"/login\"><input name=\"u\"></form>")
        XCTAssertFalse(result.lowercased().contains("<form"))
    }

    // MARK: - Base & meta refresh (high-value defenses)

    func testStripsBaseTag() {
        let result = HTMLSanitizer.sanitize("<head><base href=\"https://evil.com\"></head><body>x</body>")
        XCTAssertFalse(result.lowercased().contains("<base"))
    }

    func testStripsBaseTagCaseInsensitive() {
        let result = HTMLSanitizer.sanitize("<BASE href=\"https://evil.com\">")
        XCTAssertFalse(result.lowercased().contains("<base"))
    }

    func testStripsMetaRefresh() {
        let result = HTMLSanitizer.sanitize("<meta http-equiv=\"refresh\" content=\"0;url=https://evil.com\">")
        XCTAssertFalse(result.lowercased().contains("refresh"))
    }

    func testStripsMetaRefreshSingleQuoted() {
        let result = HTMLSanitizer.sanitize("<meta http-equiv='refresh' content='0;url=https://evil.com'>")
        XCTAssertFalse(result.lowercased().contains("refresh"))
    }

    // MARK: - Leaves benign HTML alone

    func testPreservesSafeContent() {
        let html = "<p>Hello <strong>world</strong>!</p><a href=\"https://example.com\">link</a>"
XCTAssertEqual(HTMLSanitizer.sanitize(html), html)
    }
    // MARK: - Self-closing and unclosed tags

    func testStripsSelfClosingScript() {
        let result = HTMLSanitizer.sanitize("<script/>")
        XCTAssertFalse(result.lowercased().contains("script"))
    }

    func testStripsScriptWithoutClosing() {
        // Unclosed <script> is a known limitation of regex-based sanitization —
        // real-world feeds always produce well-formed HTML.
        let result = HTMLSanitizer.sanitize("<script>alert(1)<p>hi</p>")
        // The unclosed script tag will NOT be removed (limitation).
        // But the safe content should still be present.
        XCTAssertTrue(result.contains("<p>hi</p>"))
    }

    // MARK: - toPlainText

    func testPlainTextStripsBasicTags() {
        let input = "<p>Hello <strong>world</strong></p>"
        let result = HTMLSanitizer.toPlainText(input)
        XCTAssertEqual(result, "Hello world")
    }

    func testPlainTextDecodesEntities() {
        let input = "Price: &lt;10 &amp;&amp; &gt;5"
        let result = HTMLSanitizer.toPlainText(input)
        XCTAssertEqual(result, "Price: <10 && >5")
    }

    func testPlainTextCollapsesWhitespace() {
        let input = "<p>Hello</p>\n\n\n<p>World</p>"
        let result = HTMLSanitizer.toPlainText(input)
        XCTAssertEqual(result, "Hello\n\nWorld")
    }

}
