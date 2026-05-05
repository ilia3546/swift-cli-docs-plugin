import Foundation

/// Header decoded first to validate the serialization version of `--experimental-dump-help`.
public struct ToolInfoHeader: Codable, Sendable {
    public let serializationVersion: Int
}

/// Local Codable mirror of swift-argument-parser's `ArgumentParserToolInfo.ToolInfoV0`.
///
/// We can't depend on the upstream module because it's not exposed as an SPM product,
/// so we re-declare the schema here. Field names match the JSON keys produced by
/// `--experimental-dump-help` so decoding is straightforward.
public struct ToolInfoV0: Codable, Sendable {
    public var serializationVersion: Int
    public var command: CommandInfoV0

    public init(serializationVersion: Int = 0, command: CommandInfoV0) {
        self.serializationVersion = serializationVersion
        self.command = command
    }
}

public struct CommandInfoV0: Codable, Sendable {
    public var commandName: String
    public var abstract: String?
    public var discussion: String?
    public var aliases: [String]?
    public var defaultSubcommand: String?
    public var superCommands: [String]?
    public var shouldDisplay: Bool
    public var subcommands: [CommandInfoV0]?
    public var arguments: [ArgumentInfoV0]?

    public init(
        commandName: String,
        abstract: String? = nil,
        discussion: String? = nil,
        aliases: [String]? = nil,
        defaultSubcommand: String? = nil,
        superCommands: [String]? = nil,
        shouldDisplay: Bool = true,
        subcommands: [CommandInfoV0]? = nil,
        arguments: [ArgumentInfoV0]? = nil
    ) {
        self.commandName = commandName
        self.abstract = abstract
        self.discussion = discussion
        self.aliases = aliases
        self.defaultSubcommand = defaultSubcommand
        self.superCommands = superCommands
        self.shouldDisplay = shouldDisplay
        self.subcommands = subcommands
        self.arguments = arguments
    }

    private enum CodingKeys: String, CodingKey {
        case commandName, abstract, discussion, aliases, defaultSubcommand,
             superCommands, shouldDisplay, subcommands, arguments
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.commandName = try c.decode(String.self, forKey: .commandName)
        self.abstract = try c.decodeIfPresent(String.self, forKey: .abstract)
        self.discussion = try c.decodeIfPresent(String.self, forKey: .discussion)
        self.aliases = try c.decodeIfPresent([String].self, forKey: .aliases)
        self.defaultSubcommand = try c.decodeIfPresent(String.self, forKey: .defaultSubcommand)
        self.superCommands = try c.decodeIfPresent([String].self, forKey: .superCommands)
        self.shouldDisplay = try c.decodeIfPresent(Bool.self, forKey: .shouldDisplay) ?? true
        self.subcommands = try c.decodeIfPresent([CommandInfoV0].self, forKey: .subcommands)
        self.arguments = try c.decodeIfPresent([ArgumentInfoV0].self, forKey: .arguments)
    }
}

public struct ArgumentInfoV0: Codable, Sendable {
    public enum KindV0: String, Codable, Sendable {
        case positional
        case option
        case flag
    }

    public struct NameInfoV0: Codable, Sendable {
        public enum KindV0: String, Codable, Sendable {
            case long
            case short
            case longWithSingleDash
        }

        public var kind: KindV0
        public var name: String

        public init(kind: KindV0, name: String) {
            self.kind = kind
            self.name = name
        }
    }

    public var kind: KindV0
    public var shouldDisplay: Bool
    public var sectionTitle: String?
    public var isOptional: Bool
    public var isRepeating: Bool
    public var parsingStrategy: String?
    public var names: [NameInfoV0]?
    public var preferredName: NameInfoV0?
    public var valueName: String?
    public var defaultValue: String?
    public var allValueStrings: [String]?
    public var allValueDescriptions: [String: String]?
    public var completionKind: String?
    public var abstract: String?
    public var discussion: String?

    public init(
        kind: KindV0,
        shouldDisplay: Bool = true,
        sectionTitle: String? = nil,
        isOptional: Bool = true,
        isRepeating: Bool = false,
        parsingStrategy: String? = nil,
        names: [NameInfoV0]? = nil,
        preferredName: NameInfoV0? = nil,
        valueName: String? = nil,
        defaultValue: String? = nil,
        allValueStrings: [String]? = nil,
        allValueDescriptions: [String: String]? = nil,
        completionKind: String? = nil,
        abstract: String? = nil,
        discussion: String? = nil
    ) {
        self.kind = kind
        self.shouldDisplay = shouldDisplay
        self.sectionTitle = sectionTitle
        self.isOptional = isOptional
        self.isRepeating = isRepeating
        self.parsingStrategy = parsingStrategy
        self.names = names
        self.preferredName = preferredName
        self.valueName = valueName
        self.defaultValue = defaultValue
        self.allValueStrings = allValueStrings
        self.allValueDescriptions = allValueDescriptions
        self.completionKind = completionKind
        self.abstract = abstract
        self.discussion = discussion
    }

    private enum CodingKeys: String, CodingKey {
        case kind, shouldDisplay, sectionTitle, isOptional, isRepeating, parsingStrategy,
             names, preferredName, valueName, defaultValue, allValueStrings,
             allValueDescriptions, completionKind, abstract, discussion
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.kind = try c.decode(KindV0.self, forKey: .kind)
        self.shouldDisplay = try c.decodeIfPresent(Bool.self, forKey: .shouldDisplay) ?? true
        self.sectionTitle = try c.decodeIfPresent(String.self, forKey: .sectionTitle)
        self.isOptional = try c.decodeIfPresent(Bool.self, forKey: .isOptional) ?? true
        self.isRepeating = try c.decodeIfPresent(Bool.self, forKey: .isRepeating) ?? false
        self.parsingStrategy = try c.decodeIfPresent(String.self, forKey: .parsingStrategy)
        self.names = try c.decodeIfPresent([NameInfoV0].self, forKey: .names)
        self.preferredName = try c.decodeIfPresent(NameInfoV0.self, forKey: .preferredName)
        self.valueName = try c.decodeIfPresent(String.self, forKey: .valueName)
        self.defaultValue = try c.decodeIfPresent(String.self, forKey: .defaultValue)
        self.allValueStrings = try c.decodeIfPresent([String].self, forKey: .allValueStrings)
        self.allValueDescriptions = try c.decodeIfPresent([String: String].self, forKey: .allValueDescriptions)
        self.completionKind = try c.decodeIfPresent(String.self, forKey: .completionKind)
        self.abstract = try c.decodeIfPresent(String.self, forKey: .abstract)
        self.discussion = try c.decodeIfPresent(String.self, forKey: .discussion)
    }
}
