import XCTest
@testable import CLIDocsCore

final class DocsGeneratorTests: XCTestCase {
    func testMultiFileLayoutProducesCommandFilesAndIndex() throws {
        let tool = try loadFixture("nested-tool")
        var cfg = DocsConfig()
        cfg.theme.name = "default"
        cfg.output.layout = .multiFile

        let generator = DocsGenerator(config: cfg)
        let files = try generator.renderFiles(from: tool)

        let paths = files.map(\.relativePath).sorted()
        XCTAssertTrue(paths.contains("INDEX.md"))
        XCTAssertTrue(paths.contains("demo.md"))
        XCTAssertTrue(paths.contains("demo-build.md"))
        XCTAssertFalse(paths.contains("demo-internal-debug.md"))

        let demoBuild = files.first { $0.relativePath == "demo-build.md" }
        XCTAssertNotNil(demoBuild)
        XCTAssertTrue(demoBuild!.contents.contains("# demo build"))
        XCTAssertTrue(demoBuild!.contents.contains("Build the project."))
        XCTAssertTrue(demoBuild!.contents.contains("--release"))
    }

    func testSingleFileLayoutProducesOneFile() throws {
        let tool = try loadFixture("simple-tool")
        var cfg = DocsConfig()
        cfg.theme.name = "default"
        cfg.output.layout = .singleFile
        let generator = DocsGenerator(config: cfg)
        let files = try generator.renderFiles(from: tool)
        XCTAssertEqual(files.count, 1)
        XCTAssertEqual(files[0].relativePath, "demo.md")
        XCTAssertTrue(files[0].contents.contains("# Demo") || files[0].contents.contains("# demo"))
        XCTAssertTrue(files[0].contents.contains("Verbosity level."))
    }

    func testMinimalThemeRendersAsLists() throws {
        let tool = try loadFixture("simple-tool")
        var cfg = DocsConfig()
        cfg.theme.name = "minimal"
        cfg.output.layout = .multiFile
        let generator = DocsGenerator(config: cfg)
        let files = try generator.renderFiles(from: tool)
        let demoFile = files.first { $0.relativePath == "demo.md" }
        XCTAssertNotNil(demoFile)
        // Minimal theme uses list bullets, not table pipes inside arguments section.
        XCTAssertTrue(demoFile!.contents.contains("- `--verbose <level>`"))
        XCTAssertFalse(demoFile!.contents.contains("| Name | Default | Description |"))
    }

    func testGithubThemeRendersDetailsBlocks() throws {
        let tool = try loadFixture("simple-tool")
        var cfg = DocsConfig()
        cfg.theme.name = "github"
        cfg.output.layout = .multiFile
        let generator = DocsGenerator(config: cfg)
        let files = try generator.renderFiles(from: tool)
        let demoFile = files.first { $0.relativePath == "demo.md" }
        XCTAssertNotNil(demoFile)
        XCTAssertTrue(demoFile!.contents.contains("<details>"))
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
