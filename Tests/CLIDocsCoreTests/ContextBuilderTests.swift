import XCTest
@testable import CLIDocsCore

final class ContextBuilderTests: XCTestCase {
    func testSimpleToolBuildsExpectedCommandView() throws {
        let tool = try loadFixture("simple-tool")
        let cfg = DocsConfig()
        let builder = ContextBuilder(
            config: cfg,
            linkResolver: RelativeFileLinkResolver(filenameTemplate: cfg.output.filename, rootName: tool.command.commandName)
        )
        let views = builder.buildAllCommandViews(from: tool)
        XCTAssertEqual(views.count, 1)
        let v = views[0]
        XCTAssertEqual(v.name, "demo")
        XCTAssertEqual(v.fullPath, "demo")
        XCTAssertEqual(v.headingPrefix, "#")
        XCTAssertTrue(v.synopsis.contains("[--verbose <level>]"))
        XCTAssertTrue(v.synopsis.contains("[--release]"))
        XCTAssertTrue(v.synopsis.contains("<path>..."))
        XCTAssertEqual(v.argumentSections.count, 3)
        let optionsSection = v.argumentSections.first { $0.title == "Options" }
        XCTAssertNotNil(optionsSection)
        XCTAssertEqual(optionsSection?.arguments.first?.defaultDisplay, "1")
        XCTAssertEqual(optionsSection?.arguments.first?.valueRangeText, "one of: 0, 1, 2")
    }

    func testNestedToolHidesNonDisplayedSubcommands() throws {
        let tool = try loadFixture("nested-tool")
        let cfg = DocsConfig()
        let builder = ContextBuilder(
            config: cfg,
            linkResolver: AnchorLinkResolver()
        )
        let views = builder.buildAllCommandViews(from: tool)
        let names = views.map(\.fullPath)
        XCTAssertEqual(names, ["demo", "demo build"])
        XCTAssertFalse(names.contains("demo internal-debug"))
    }

    func testIncludeExcludeFilters() throws {
        let tool = try loadFixture("nested-tool")
        var cfg = DocsConfig()
        cfg.exclude = ["demo build"]
        let builder = ContextBuilder(config: cfg, linkResolver: AnchorLinkResolver())
        let views = builder.buildAllCommandViews(from: tool)
        XCTAssertEqual(views.map(\.fullPath), ["demo"])
    }

    func testOverrideAbstractWins() throws {
        let tool = try loadFixture("simple-tool")
        var cfg = DocsConfig()
        cfg.overrides["demo"] = CommandOverride(abstract: "Custom!", examples: [.init(title: "Hello", code: "demo /tmp")])
        let builder = ContextBuilder(config: cfg, linkResolver: AnchorLinkResolver())
        let views = builder.buildAllCommandViews(from: tool)
        XCTAssertEqual(views.first?.abstract, "Custom!")
        XCTAssertEqual(views.first?.examples.first?.title, "Hello")
        XCTAssertEqual(views.first?.examples.first?.codeFenced, "```bash\ndemo /tmp\n```")
    }

    private func loadFixture(_ name: String) throws -> ToolInfoV0 {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            XCTFail("Fixture \(name).json not found")
            throw NSError(domain: "test", code: -1)
        }
        let data = try Data(contentsOf: url)
        return try DumpHelpRunner().decode(data)
    }
}
