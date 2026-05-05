import Foundation
import ArgumentParser
import CLIDocsCore

@main
struct SwiftCLIDocs: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swift-cli-docs",
        abstract: "Generate Markdown documentation for a Swift Argument Parser CLI tool.",
        discussion: """
        This is the helper invoked by the SwiftCLIDocsPlugin SPM command plugin.
        It can also be used standalone — point `--executable` at any tool that
        implements `--experimental-dump-help`.
        """
    )

    @Option(name: .long, help: "Path to the built executable to introspect.")
    var executable: String?

    @Option(name: .long, help: "Path to a pre-recorded --experimental-dump-help JSON. Useful for tests.")
    var jsonInput: String?

    @Option(name: .long, help: "Name of the executable target inside the package (used for messaging).")
    var target: String?

    @Option(name: .long, help: "Path to the YAML config. Defaults to .swift-cli-docs.yml in --package-root.")
    var config: String?

    @Option(name: .long, help: "Override output directory.")
    var output: String?

    @Option(name: .long, help: "Override layout: multi-file or single-file.")
    var layout: String?

    @Option(name: .long, help: "Override theme: default, minimal, github.")
    var theme: String?

    @Option(name: .long, help: "Override path to a user theme directory.")
    var themePath: String?

    @Option(name: .long, help: "Package root directory. Used for resolving config and output paths.")
    var packageRoot: String = "."

    func run() throws {
        let packageRootURL = URL(fileURLWithPath: packageRoot, isDirectory: true)

        let loader = ConfigLoader()
        var loaded: DocsConfig
        if let configPath = config {
            loaded = try loader.load(from: URL(fileURLWithPath: configPath))
        } else if let url = loader.locateConfig(in: packageRootURL) {
            loaded = try loader.load(from: url)
        } else {
            loaded = DocsConfig.default
        }

        let overrides = CLIOverrides(
            target: target,
            outputDirectory: output,
            layout: layout.flatMap(OutputConfig.Layout.init(rawValue:)),
            themeName: theme,
            themePath: themePath
        )
        let cfg = loader.merge(base: loaded, with: overrides)

        let toolInfo = try loadToolInfo()
        let generator = DocsGenerator(config: cfg)
        let written = try generator.generate(from: toolInfo, packageRoot: packageRootURL)

        FileHandle.standardError.write(Data("Wrote \(written.count) file(s) to \(cfg.output.directory).\n".utf8))
    }

    private func loadToolInfo() throws -> ToolInfoV0 {
        let runner = DumpHelpRunner()
        if let json = jsonInput {
            let data = try Data(contentsOf: URL(fileURLWithPath: json))
            return try runner.decode(data)
        }
        guard let exe = executable else {
            throw ValidationError("Either --executable or --json-input must be provided.")
        }
        return try runner.run(executable: URL(fileURLWithPath: exe))
    }
}
