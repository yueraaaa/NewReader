import XCTest
@testable import NewReaderCore

final class AIServiceTests: XCTestCase {
    func testStripsSingleThinkingBlock() {
        let input = "<think>reasoning here</think>Final answer"
        XCTAssertEqual(AIService.stripThinking(input), "Final answer")
    }

    func testStripsMultipleThinkingBlocks() {
        let input = "<think>first</think>middle<think>second</think>end"
        XCTAssertEqual(AIService.stripThinking(input), "middleend")
    }

    func testLeavesTextWithoutThinkingAlone() {
        let input = "Just a normal response"
        XCTAssertEqual(AIService.stripThinking(input), "Just a normal response")
    }

    func testTrimsWhitespace() {
        let input = "  \n <think>hidden</think>visible  \n"
        XCTAssertEqual(AIService.stripThinking(input), "visible")
    }

    func testHandlesUnclosedThinkBlock() {
        // No </think> — output should be left untouched (don't eat real content).
        let input = "<think>still thinking... no closing"
        XCTAssertEqual(AIService.stripThinking(input), input)
    }

    func testPreservesContentWithThinkTextInMiddle() {
        let input = "before <think>hidden</think> <think>also hidden</think> after"
        XCTAssertEqual(AIService.stripThinking(input), "before   after")
    }
}
