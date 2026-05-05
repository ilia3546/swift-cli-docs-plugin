import Foundation

public struct GeneratedFile: Sendable, Equatable {
    public var relativePath: String
    public var contents: String

    public init(relativePath: String, contents: String) {
        self.relativePath = relativePath
        self.contents = contents
    }
}

public struct MultiFileLayout {
    public let engine: StencilEngine
    public let config: DocsConfig

    public init(engine: StencilEngine, config: DocsConfig) {
        self.engine = engine
        self.config = config
    }

    public func render(meta: MetaView, theme: ThemeView, commands: [CommandView], index: IndexView, rootName: String) throws -> [GeneratedFile] {
        var files: [GeneratedFile] = []

        for command in commands {
            let context = RenderContext(meta: meta, theme: theme, command: command).asDictionary()
            let body = try engine.render(template: "command.stencil", context: context)
            let path = FilenameRenderer.render(
                template: config.output.filename,
                fullPath: command.fullPath.split(separator: " ").map(String.init),
                rootName: rootName
            )
            files.append(GeneratedFile(relativePath: path, contents: body))
        }

        let indexContext = RenderContext(meta: meta, theme: theme, commands: commands, index: index).asDictionary()
        let indexBody = try engine.render(template: "index.stencil", context: indexContext)
        files.append(GeneratedFile(relativePath: config.output.index, contents: indexBody))

        return files
    }
}
