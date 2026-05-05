import Foundation
import ArgumentParserToolInfo

public enum DocsGeneratorError: Error, CustomStringConvertible {
    case writeFailed(URL, underlying: Error)

    public var description: String {
        switch self {
        case .writeFailed(let url, let err):
            return "Could not write file at \(url.path): \(err)"
        }
    }
}

/// Top-level orchestrator. Glues `ContextBuilder` → templates → disk together.
public struct DocsGenerator {
    public let config: DocsConfig

    public init(config: DocsConfig) {
        self.config = config
    }

    /// Render the given tool to in-memory files. Pure function — no disk I/O.
    /// Useful for tests and for callers that want to inspect the output.
    public func renderFiles(from tool: ToolInfoV0) throws -> [GeneratedFile] {
        let resolver = ThemeResolver()
        let searchPaths = try resolver.resolveSearchPaths(
            themeName: config.theme.name,
            userThemePath: config.theme.path
        )
        let engine = StencilEngine(searchPaths: searchPaths)

        let rootName = tool.command.commandName
        let linkResolver: LinkResolver = {
            switch config.output.layout {
            case .singleFile:
                return AnchorLinkResolver()
            case .multiFile:
                return RelativeFileLinkResolver(
                    filenameTemplate: config.output.filename,
                    rootName: rootName
                )
            }
        }()
        let builder = ContextBuilder(config: config, linkResolver: linkResolver)
        let commands = builder.buildAllCommandViews(from: tool)
        let index = builder.buildIndexView(from: tool)
        let meta = builder.buildMeta(from: tool)
        let theme = builder.buildTheme()

        switch config.output.layout {
        case .singleFile:
            let layout = SingleFileLayout(engine: engine, config: config)
            return try layout.render(meta: meta, theme: theme, commands: commands, index: index, rootName: rootName)
        case .multiFile:
            let layout = MultiFileLayout(engine: engine, config: config)
            return try layout.render(meta: meta, theme: theme, commands: commands, index: index, rootName: rootName)
        }
    }

    /// Render and write to disk under the given package directory.
    /// `packageRoot` is treated as the base for resolving `output.directory`.
    @discardableResult
    public func generate(from tool: ToolInfoV0, packageRoot: URL) throws -> [URL] {
        let files = try renderFiles(from: tool)
        let outputDir = packageRoot.appendingPathComponent(config.output.directory, isDirectory: true)
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        var writtenURLs: [URL] = []
        for file in files {
            let target = outputDir.appendingPathComponent(file.relativePath)
            let parent = target.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            do {
                try file.contents.write(to: target, atomically: true, encoding: .utf8)
            } catch {
                throw DocsGeneratorError.writeFailed(target, underlying: error)
            }
            writtenURLs.append(target)
        }
        return writtenURLs
    }
}
