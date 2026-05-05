import XCTest
@testable import CLIDocsCore

final class MarkdownEscapeTests: XCTestCase {
    func testInlineEscapesPipesAndStars() {
        XCTAssertEqual(MarkdownEscape.inline("a|b*c"), "a\\|b\\*c")
    }

    func testTableCellReplacesNewlines() {
        XCTAssertEqual(MarkdownEscape.tableCell("a\nb|c"), "a b\\|c")
    }

    func testAnchorSlug() {
        XCTAssertEqual(MarkdownEscape.anchor("MyCLI build release"), "mycli-build-release")
        XCTAssertEqual(MarkdownEscape.anchor("a/b.c d"), "a-b-c-d")
        XCTAssertEqual(MarkdownEscape.anchor("---hello---"), "hello")
    }
}
