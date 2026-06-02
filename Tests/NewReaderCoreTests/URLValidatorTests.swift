import XCTest
@testable import NewReaderCore

final class URLValidatorTests: XCTestCase {
    // MARK: - Happy path

    func testAcceptsHttps() {
        XCTAssertNotNil(URLValidator.validate("https://example.com/feed"))
    }

    func testAcceptsHttp() {
        XCTAssertNotNil(URLValidator.validate("http://example.com/feed"))
    }

    func testTrimsSurroundingWhitespace() {
        XCTAssertNotNil(URLValidator.validate("   https://example.com   "))
    }

    // MARK: - Scheme allowlist

    func testRejectsFileScheme() {
        XCTAssertNil(URLValidator.validate("file:///etc/passwd"))
    }

    func testRejectsJavascriptScheme() {
        XCTAssertNil(URLValidator.validate("javascript:alert(1)"))
    }

    func testRejectsDataScheme() {
        XCTAssertNil(URLValidator.validate("data:text/html,<script>alert(1)</script>"))
    }

    func testRejectsMissingScheme() {
        XCTAssertNil(URLValidator.validate("example.com/feed"))
    }

    // MARK: - Private IPv4 ranges (SSRF blocklist)

    func testRejectsLoopback() {
        XCTAssertNil(URLValidator.validate("http://127.0.0.1/feed"))
        XCTAssertNil(URLValidator.validate("http://127.255.255.255/feed"))
    }

    func testRejectsRfc1918_10() {
        XCTAssertNil(URLValidator.validate("http://10.0.0.1/feed"))
        XCTAssertNil(URLValidator.validate("http://10.255.255.255/feed"))
    }

    func testRejectsRfc1918_172() {
        XCTAssertNil(URLValidator.validate("http://172.16.0.1/feed"))
        XCTAssertNil(URLValidator.validate("http://172.31.255.255/feed"))
    }

    func testRejectsRfc1918_192() {
        XCTAssertNil(URLValidator.validate("http://192.168.1.1/feed"))
        XCTAssertNil(URLValidator.validate("http://192.168.0.0/feed"))
    }

    func testRejectsLinkLocal() {
        XCTAssertNil(URLValidator.validate("http://169.254.169.254/latest/meta-data/"))
    }

    func testRejectsMulticast() {
        XCTAssertNil(URLValidator.validate("http://224.0.0.1/feed"))
    }

    func testAllowsPublicIPv4() {
        XCTAssertNotNil(URLValidator.validate("http://8.8.8.8/feed"))
        XCTAssertNotNil(URLValidator.validate("http://1.1.1.1/feed"))
    }

    // MARK: - Hostname allowlist

    func testRejectsLocalhost() {
        XCTAssertNil(URLValidator.validate("http://localhost/feed"))
        XCTAssertNil(URLValidator.validate("http://localhost.localdomain/feed"))
    }

    func testRejectsIPv6Loopback() {
        XCTAssertNil(URLValidator.validate("http://[::1]/feed"))
    }

    func testRejectsIPv6LinkLocal() {
        XCTAssertNil(URLValidator.validate("http://[fe80::1]/feed"))
    }

    // MARK: - Plausibility (OPML import) is a softer check

    func testPlausibleURLStillRejectsEvil() {
        XCTAssertFalse(URLValidator.isPlausibleURL("file:///etc/passwd"))
        XCTAssertFalse(URLValidator.isPlausibleURL("javascript:alert(1)"))
        XCTAssertTrue(URLValidator.isPlausibleURL("https://example.com/feed"))
    }
    // MARK: - IPv6 private ranges (added after review)

    func testRejectsIPv6ULA() {
        XCTAssertNil(URLValidator.validate("http://[fd00::1]/feed"))
        XCTAssertNil(URLValidator.validate("http://[fc00::1]/feed"))
    }

    func testRejectsIPv4MappedIPv6() {
        XCTAssertNil(URLValidator.validate("http://[::ffff:127.0.0.1]/feed"))
        XCTAssertNil(URLValidator.validate("http://[::ffff:192.168.1.1]/feed"))
    }

    func testAllowsIPv4MappedPublicIPv6() {
        XCTAssertNotNil(URLValidator.validate("http://[::ffff:8.8.8.8]/feed"))
    }

    func testRejectsNAT64Prefix() {
        XCTAssertNil(URLValidator.validate("http://[64:ff9b::1]/feed"))
    }

    // MARK: - Integer-encoded IPv4 (SSRF)

    func testRejectsDecimalEncodedLoopback() {
        XCTAssertNil(URLValidator.validate("http://2130706433/feed"))
    }

    func testRejectsHexEncodedLoopback() {
        XCTAssertNil(URLValidator.validate("http://0x7f000001/feed"))
    }

    func testAllowsDecimalEncodedPublicIP() {
        XCTAssertNotNil(URLValidator.validate("http://134744072/feed")) // 8.8.8.8
    }

    // MARK: - IPv6 bracketed hosts

    func testRejectsBracketedIPv6Loopback() {
        XCTAssertNil(URLValidator.validate("http://[::1]/feed"))
    }

}
