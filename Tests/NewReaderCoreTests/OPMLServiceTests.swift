import XCTest
@testable import NewReaderCore

final class OPMLServiceTests: XCTestCase {
    func testParsesSimpleOutline() {
        let xml = """
        <opml><body>
          <outline text="Hacker News" title="Hacker News" type="rss" xmlUrl="https://hnrss.org/frontpage" htmlUrl="https://news.ycombinator.com"/>
        </body></opml>
        """
        let outlines = OPMLService.parseOutlines(from: xml)
        XCTAssertEqual(outlines.count, 1)
        XCTAssertEqual(outlines[0].url, "https://hnrss.org/frontpage")
        XCTAssertEqual(outlines[0].title, "Hacker News")
    }

    func testParsesMultipleOutlines() {
        let xml = """
        <opml><body>
          <outline text="A" xmlUrl="https://a.example/feed"/>
          <outline text="B" xmlUrl="https://b.example/feed"/>
          <outline text="C" xmlUrl="https://c.example/feed"/>
        </body></opml>
        """
        let outlines = OPMLService.parseOutlines(from: xml)
        XCTAssertEqual(outlines.count, 3)
        XCTAssertEqual(outlines.map(\.url), [
            "https://a.example/feed",
            "https://b.example/feed",
            "https://c.example/feed"
        ])
    }

    func testFallsBackToUntitledWhenTextMissing() {
        let xml = """
        <opml><body>
          <outline type="rss" xmlUrl="https://no-title.example/feed"/>
        </body></opml>
        """
        let outlines = OPMLService.parseOutlines(from: xml)
        XCTAssertEqual(outlines.count, 1)
        XCTAssertEqual(outlines[0].title, "Untitled")
    }

    func testIgnoresOutlinesWithoutXmlUrl() {
        let xml = """
        <opml><body>
          <outline text="folder" title="folder"/>
          <outline text="Real" xmlUrl="https://real.example/feed"/>
        </body></opml>
        """
        let outlines = OPMLService.parseOutlines(from: xml)
        XCTAssertEqual(outlines.count, 1)
        XCTAssertEqual(outlines[0].url, "https://real.example/feed")
    }

    func testHandlesEmptyBody() {
        let xml = "<opml><body></body></opml>"
        XCTAssertTrue(OPMLService.parseOutlines(from: xml).isEmpty)
    }
    func testParsesTitleAfterXmlUrl() {
        let xml = """
        <opml><body>
          <outline xmlUrl="https://a.example/feed" text="After URL"/>
        </body></opml>
        """
        let outlines = OPMLService.parseOutlines(from: xml)
        XCTAssertEqual(outlines.count, 1)
        XCTAssertEqual(outlines[0].title, "After URL")
    }

    func testParsesMultipleOutlinesMixedOrder() {
        let xml = """
        <opml><body>
          <outline text="First" xmlUrl="https://a.example/feed"/>
          <outline xmlUrl="https://b.example/feed" text="Second"/>
        </body></opml>
        """
        let outlines = OPMLService.parseOutlines(from: xml)
        XCTAssertEqual(outlines.count, 2)
        XCTAssertEqual(outlines[0].title, "First")
        XCTAssertEqual(outlines[1].title, "Second")
    }

}
