import ArgumentParser

@main
struct Demo: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "demo",
        abstract: "A demo CLI to showcase swift-cli-docs-plugin.",
        discussion: """
        This tool exists only so you can run `swift package generate-docs` and see
        what kind of Markdown the plugin produces for a small Argument Parser CLI.
        """,
        subcommands: [Build.self, Test.self]
    )
}

struct Build: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build the demo project."
    )

    @Flag(name: .long, help: "Build in release configuration.")
    var release: Bool = false

    @Option(name: [.short, .long], help: "Build target name.")
    var target: String?

    @Argument(help: "Path to the project root.")
    var path: String

    func run() throws {
        print("build \(path) release=\(release) target=\(target ?? "<auto>")")
    }
}

struct Test: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Run the test suite."
    )

    @Option(name: .long, help: "Filter tests by name.")
    var filter: String?

    @Flag(name: .long, help: "Show verbose output.")
    var verbose: Bool = false

    func run() throws {
        print("test filter=\(filter ?? "*") verbose=\(verbose)")
    }
}
