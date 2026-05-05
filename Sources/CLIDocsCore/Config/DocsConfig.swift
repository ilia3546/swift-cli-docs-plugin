import Foundation

public struct DocsConfig: Codable, Equatable, Sendable {
    public var target: String?
    public var output: OutputConfig
    public var metadata: MetadataConfig
    public var theme: ThemeConfig
    public var sections: SectionsConfig
    public var include: [String]
    public var exclude: [String]
    public var overrides: [String: CommandOverride]

    public init(
        target: String? = nil,
        output: OutputConfig = .init(),
        metadata: MetadataConfig = .init(),
        theme: ThemeConfig = .init(),
        sections: SectionsConfig = .init(),
        include: [String] = ["*"],
        exclude: [String] = [],
        overrides: [String: CommandOverride] = [:]
    ) {
        self.target = target
        self.output = output
        self.metadata = metadata
        self.theme = theme
        self.sections = sections
        self.include = include
        self.exclude = exclude
        self.overrides = overrides
    }

    public static let `default` = DocsConfig()

    private enum CodingKeys: String, CodingKey {
        case target, output, metadata, theme, sections, include, exclude, overrides
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.target = try c.decodeIfPresent(String.self, forKey: .target)
        self.output = try c.decodeIfPresent(OutputConfig.self, forKey: .output) ?? .init()
        self.metadata = try c.decodeIfPresent(MetadataConfig.self, forKey: .metadata) ?? .init()
        self.theme = try c.decodeIfPresent(ThemeConfig.self, forKey: .theme) ?? .init()
        self.sections = try c.decodeIfPresent(SectionsConfig.self, forKey: .sections) ?? .init()
        self.include = try c.decodeIfPresent([String].self, forKey: .include) ?? ["*"]
        self.exclude = try c.decodeIfPresent([String].self, forKey: .exclude) ?? []
        self.overrides = try c.decodeIfPresent([String: CommandOverride].self, forKey: .overrides) ?? [:]
    }
}

public struct OutputConfig: Codable, Equatable, Sendable {
    public enum Layout: String, Codable, Sendable {
        case multiFile = "multi-file"
        case singleFile = "single-file"
    }

    public var directory: String
    public var layout: Layout
    public var filename: String
    public var index: String

    public init(
        directory: String = "docs",
        layout: Layout = .multiFile,
        filename: String = "{command}.md",
        index: String = "INDEX.md"
    ) {
        self.directory = directory
        self.layout = layout
        self.filename = filename
        self.index = index
    }

    private enum CodingKeys: String, CodingKey {
        case directory, layout, filename, index
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.directory = try c.decodeIfPresent(String.self, forKey: .directory) ?? "docs"
        self.layout = try c.decodeIfPresent(Layout.self, forKey: .layout) ?? .multiFile
        self.filename = try c.decodeIfPresent(String.self, forKey: .filename) ?? "{command}.md"
        self.index = try c.decodeIfPresent(String.self, forKey: .index) ?? "INDEX.md"
    }
}

public struct MetadataConfig: Codable, Equatable, Sendable {
    public var title: String?
    public var description: String?
    public var version: String?
    public var repository: String?

    public init(
        title: String? = nil,
        description: String? = nil,
        version: String? = nil,
        repository: String? = nil
    ) {
        self.title = title
        self.description = description
        self.version = version
        self.repository = repository
    }
}

public struct ThemeConfig: Codable, Equatable, Sendable {
    public var name: String
    public var path: String?
    public var headingDepth: Int
    public var toc: Bool
    public var showAliases: Bool
    public var showHidden: Bool
    public var codeFence: String
    public var emoji: Bool
    public var variables: [String: String]

    public init(
        name: String = "default",
        path: String? = nil,
        headingDepth: Int = 1,
        toc: Bool = true,
        showAliases: Bool = true,
        showHidden: Bool = false,
        codeFence: String = "bash",
        emoji: Bool = false,
        variables: [String: String] = [:]
    ) {
        self.name = name
        self.path = path
        self.headingDepth = headingDepth
        self.toc = toc
        self.showAliases = showAliases
        self.showHidden = showHidden
        self.codeFence = codeFence
        self.emoji = emoji
        self.variables = variables
    }

    private enum CodingKeys: String, CodingKey {
        case name, path, headingDepth, toc, showAliases, showHidden, codeFence, emoji, variables
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try c.decodeIfPresent(String.self, forKey: .name) ?? "default"
        self.path = try c.decodeIfPresent(String.self, forKey: .path)
        self.headingDepth = try c.decodeIfPresent(Int.self, forKey: .headingDepth) ?? 1
        self.toc = try c.decodeIfPresent(Bool.self, forKey: .toc) ?? true
        self.showAliases = try c.decodeIfPresent(Bool.self, forKey: .showAliases) ?? true
        self.showHidden = try c.decodeIfPresent(Bool.self, forKey: .showHidden) ?? false
        self.codeFence = try c.decodeIfPresent(String.self, forKey: .codeFence) ?? "bash"
        self.emoji = try c.decodeIfPresent(Bool.self, forKey: .emoji) ?? false
        self.variables = try c.decodeIfPresent([String: String].self, forKey: .variables) ?? [:]
    }
}

public struct SectionsConfig: Codable, Equatable, Sendable {
    public static let defaultOrder = [
        "overview", "usage", "arguments", "options", "flags",
        "subcommands", "examples", "footer",
    ]

    public var order: [String]
    public var custom: [String: String]

    public init(order: [String] = SectionsConfig.defaultOrder, custom: [String: String] = [:]) {
        self.order = order
        self.custom = custom
    }

    private enum CodingKeys: String, CodingKey { case order, custom }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.order = try c.decodeIfPresent([String].self, forKey: .order) ?? SectionsConfig.defaultOrder
        self.custom = try c.decodeIfPresent([String: String].self, forKey: .custom) ?? [:]
    }
}

public struct CommandOverride: Codable, Equatable, Sendable {
    public var abstract: String?
    public var discussion: String?
    public var examples: [ExampleOverride]

    public init(abstract: String? = nil, discussion: String? = nil, examples: [ExampleOverride] = []) {
        self.abstract = abstract
        self.discussion = discussion
        self.examples = examples
    }

    private enum CodingKeys: String, CodingKey { case abstract, discussion, examples }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.abstract = try c.decodeIfPresent(String.self, forKey: .abstract)
        self.discussion = try c.decodeIfPresent(String.self, forKey: .discussion)
        self.examples = try c.decodeIfPresent([ExampleOverride].self, forKey: .examples) ?? []
    }
}

public struct ExampleOverride: Codable, Equatable, Sendable {
    public var title: String
    public var code: String

    public init(title: String, code: String) {
        self.title = title
        self.code = code
    }
}
