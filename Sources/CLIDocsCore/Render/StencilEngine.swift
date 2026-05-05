import Foundation
import Stencil
import PathKit

public enum StencilEngineError: Error, CustomStringConvertible {
    case rendering(template: String, underlying: Error)

    public var description: String {
        switch self {
        case .rendering(let name, let err):
            return "Failed to render Stencil template '\(name)': \(err)"
        }
    }
}

/// Thin wrapper around Stencil that wires up a multi-root file-system loader and
/// our small set of Markdown filters. Templates are resolved in the order returned
/// by `ThemeResolver`, so user themes can override individual files while still
/// inheriting partials from the default theme.
public final class StencilEngine {
    private let environment: Environment

    public init(searchPaths: [URL]) {
        let paths = searchPaths.map { Path($0.path) }
        let loader = FileSystemLoader(paths: paths)
        let ext = Extension()
        MarkdownFilters.register(in: ext)
        self.environment = Environment(loader: loader, extensions: [ext])
    }

    public func render(template: String, context: [String: Any]) throws -> String {
        do {
            return try environment.renderTemplate(name: template, context: context)
        } catch {
            throw StencilEngineError.rendering(template: template, underlying: error)
        }
    }
}
