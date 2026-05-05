import Foundation

public struct SingleFileLayout {
    public let engine: StencilEngine
    public let config: DocsConfig

    public init(engine: StencilEngine, config: DocsConfig) {
        self.engine = engine
        self.config = config
    }

    public func render(meta: MetaView, theme: ThemeView, commands: [CommandView], index: IndexView, rootName: String) throws -> [GeneratedFile] {
        let context = RenderContext(meta: meta, theme: theme, commands: commands, index: index).asDictionary()
        let body = try engine.render(template: "single.stencil", context: context)
        let filename = "\(rootName).md"
        return [GeneratedFile(relativePath: filename, contents: MarkdownEscape.tidy(body))]
    }
}
