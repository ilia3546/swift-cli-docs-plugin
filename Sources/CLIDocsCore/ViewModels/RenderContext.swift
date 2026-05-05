import Foundation

/// Top-level context root passed to every Stencil template.
///
/// All fields are pre-computed strings, booleans, or arrays of view-models — never
/// raw `ToolInfoV0` types. This keeps templates logic-less and gives us a stable
/// public API for custom themes.
public struct RenderContext: Sendable, Equatable {
    public var meta: MetaView
    public var theme: ThemeView
    public var command: CommandView?
    public var commands: [CommandView]
    public var index: IndexView?

    public init(
        meta: MetaView,
        theme: ThemeView,
        command: CommandView? = nil,
        commands: [CommandView] = [],
        index: IndexView? = nil
    ) {
        self.meta = meta
        self.theme = theme
        self.command = command
        self.commands = commands
        self.index = index
    }

    /// Convert to a Stencil-compatible dictionary tree.
    public func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "meta": meta.asDictionary(),
            "theme": theme.asDictionary(),
            "commands": commands.map { $0.asDictionary() },
        ]
        if let command { dict["command"] = command.asDictionary() }
        if let index { dict["index"] = index.asDictionary() }
        return dict
    }
}

public struct MetaView: Sendable, Equatable {
    public var title: String
    public var description: String?
    public var version: String?
    public var repository: String?

    public init(
        title: String,
        description: String? = nil,
        version: String? = nil,
        repository: String? = nil
    ) {
        self.title = title
        self.description = description
        self.version = version
        self.repository = repository
    }

    public func asDictionary() -> [String: Any] {
        var d: [String: Any] = ["title": title]
        if let description { d["description"] = description }
        if let version { d["version"] = version }
        if let repository { d["repository"] = repository }
        return d
    }
}

public struct ThemeView: Sendable, Equatable {
    public var name: String
    public var headingDepth: Int
    public var toc: Bool
    public var showAliases: Bool
    public var codeFence: String
    public var emoji: Bool
    public var variables: [String: String]

    public init(
        name: String,
        headingDepth: Int,
        toc: Bool,
        showAliases: Bool,
        codeFence: String,
        emoji: Bool,
        variables: [String: String]
    ) {
        self.name = name
        self.headingDepth = headingDepth
        self.toc = toc
        self.showAliases = showAliases
        self.codeFence = codeFence
        self.emoji = emoji
        self.variables = variables
    }

    public func asDictionary() -> [String: Any] {
        [
            "name": name,
            "headingDepth": headingDepth,
            "toc": toc,
            "showAliases": showAliases,
            "codeFence": codeFence,
            "emoji": emoji,
            "variables": variables,
        ]
    }
}
