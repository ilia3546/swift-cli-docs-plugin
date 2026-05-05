import XCTest
@testable import CLIDocsCore

final class ConfigTests: XCTestCase {
    func testDefaultValues() {
        let cfg = DocsConfig()
        XCTAssertEqual(cfg.output.directory, "docs")
        XCTAssertEqual(cfg.output.layout, .multiFile)
        XCTAssertEqual(cfg.output.filename, "{command}.md")
        XCTAssertEqual(cfg.output.index, "INDEX.md")
        XCTAssertEqual(cfg.theme.name, "default")
        XCTAssertEqual(cfg.theme.headingDepth, 1)
        XCTAssertEqual(cfg.theme.codeFence, "bash")
        XCTAssertTrue(cfg.theme.toc)
        XCTAssertFalse(cfg.theme.showHidden)
        XCTAssertEqual(cfg.include, ["*"])
        XCTAssertTrue(cfg.exclude.isEmpty)
    }

    func testYAMLRoundtrip() throws {
        let yaml = """
        target: MyCLI
        output:
          directory: docs/cli
          layout: single-file
          filename: "{command}.md"
        metadata:
          title: "Demo"
          description: "Hello"
        theme:
          name: github
          headingDepth: 2
          toc: false
          codeFence: shell
          variables:
            accent: "🚀"
        sections:
          order: [overview, usage, options]
          custom:
            footer: footer.md
        include: ["mycli build*"]
        exclude: ["mycli internal-*"]
        overrides:
          "mycli build":
            abstract: "Custom abstract"
            examples:
              - title: "Basic"
                code: "mycli build --release"
        """
        let url = makeTempYAML(yaml)
        defer { try? FileManager.default.removeItem(at: url) }

        let cfg = try ConfigLoader().load(from: url)
        XCTAssertEqual(cfg.target, "MyCLI")
        XCTAssertEqual(cfg.output.directory, "docs/cli")
        XCTAssertEqual(cfg.output.layout, .singleFile)
        XCTAssertEqual(cfg.metadata.title, "Demo")
        XCTAssertEqual(cfg.theme.name, "github")
        XCTAssertEqual(cfg.theme.headingDepth, 2)
        XCTAssertFalse(cfg.theme.toc)
        XCTAssertEqual(cfg.theme.codeFence, "shell")
        XCTAssertEqual(cfg.theme.variables["accent"], "🚀")
        XCTAssertEqual(cfg.include, ["mycli build*"])
        XCTAssertEqual(cfg.exclude, ["mycli internal-*"])
        XCTAssertEqual(cfg.overrides["mycli build"]?.abstract, "Custom abstract")
        XCTAssertEqual(cfg.overrides["mycli build"]?.examples.first?.code, "mycli build --release")
    }

    func testEmptyYAMLUsesDefaults() throws {
        let url = makeTempYAML("{}\n")
        defer { try? FileManager.default.removeItem(at: url) }
        let cfg = try ConfigLoader().load(from: url)
        XCTAssertEqual(cfg, DocsConfig.default)
    }

    func testCLIOverridesWin() {
        var base = DocsConfig()
        base.theme.name = "default"
        base.output.directory = "docs"
        let merged = ConfigLoader().merge(
            base: base,
            with: CLIOverrides(target: "X", outputDirectory: "out", layout: .singleFile, themeName: "github", themePath: nil)
        )
        XCTAssertEqual(merged.target, "X")
        XCTAssertEqual(merged.output.directory, "out")
        XCTAssertEqual(merged.output.layout, .singleFile)
        XCTAssertEqual(merged.theme.name, "github")
    }

    private func makeTempYAML(_ contents: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".yml")
        try! contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
