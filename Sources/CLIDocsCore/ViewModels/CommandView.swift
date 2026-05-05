import Foundation

/// Pre-computed view of a single command, ready to be rendered by a template.
public struct CommandView: Sendable, Equatable {
    public var name: String
    public var fullPath: String
    public var anchor: String
    public var headingPrefix: String
    public var abstract: String
    public var abstractEscaped: String
    public var discussion: String
    public var discussionEscaped: String
    public var aliases: [String]
    public var hasAliases: Bool
    public var synopsis: String
    public var argumentSections: [ArgumentSectionView]
    public var hasArguments: Bool
    public var subcommands: [SubcommandLinkView]
    public var hasSubcommands: Bool
    public var examples: [ExampleView]
    public var hasExamples: Bool
    public var customSections: [String: String]
    public var sectionOrder: [String]
    public var isHidden: Bool

    public init(
        name: String,
        fullPath: String,
        anchor: String,
        headingPrefix: String,
        abstract: String,
        abstractEscaped: String,
        discussion: String,
        discussionEscaped: String,
        aliases: [String],
        synopsis: String,
        argumentSections: [ArgumentSectionView],
        subcommands: [SubcommandLinkView],
        examples: [ExampleView],
        customSections: [String: String],
        sectionOrder: [String],
        isHidden: Bool
    ) {
        self.name = name
        self.fullPath = fullPath
        self.anchor = anchor
        self.headingPrefix = headingPrefix
        self.abstract = abstract
        self.abstractEscaped = abstractEscaped
        self.discussion = discussion
        self.discussionEscaped = discussionEscaped
        self.aliases = aliases
        self.hasAliases = !aliases.isEmpty
        self.synopsis = synopsis
        self.argumentSections = argumentSections
        self.hasArguments = !argumentSections.isEmpty
        self.subcommands = subcommands
        self.hasSubcommands = !subcommands.isEmpty
        self.examples = examples
        self.hasExamples = !examples.isEmpty
        self.customSections = customSections
        self.sectionOrder = sectionOrder
        self.isHidden = isHidden
    }

    public func asDictionary() -> [String: Any] {
        [
            "name": name,
            "fullPath": fullPath,
            "anchor": anchor,
            "headingPrefix": headingPrefix,
            "abstract": abstract,
            "abstractEscaped": abstractEscaped,
            "discussion": discussion,
            "discussionEscaped": discussionEscaped,
            "aliases": aliases,
            "hasAliases": hasAliases,
            "synopsis": synopsis,
            "argumentSections": argumentSections.map { $0.asDictionary() },
            "hasArguments": hasArguments,
            "subcommands": subcommands.map { $0.asDictionary() },
            "hasSubcommands": hasSubcommands,
            "examples": examples.map { $0.asDictionary() },
            "hasExamples": hasExamples,
            "customSections": customSections,
            "sectionOrder": sectionOrder,
            "isHidden": isHidden,
        ]
    }
}

public struct ArgumentSectionView: Sendable, Equatable {
    public enum Kind: String, Sendable, Equatable {
        case positional, option, flag, mixed
    }

    public var title: String
    public var kind: Kind
    public var arguments: [ArgumentView]

    public init(title: String, kind: Kind, arguments: [ArgumentView]) {
        self.title = title
        self.kind = kind
        self.arguments = arguments
    }

    public func asDictionary() -> [String: Any] {
        [
            "title": title,
            "kind": kind.rawValue,
            "arguments": arguments.map { $0.asDictionary() },
        ]
    }
}

public struct SubcommandLinkView: Sendable, Equatable {
    public var name: String
    public var fullPath: String
    public var abstract: String
    public var abstractEscaped: String
    public var link: String

    public init(name: String, fullPath: String, abstract: String, abstractEscaped: String, link: String) {
        self.name = name
        self.fullPath = fullPath
        self.abstract = abstract
        self.abstractEscaped = abstractEscaped
        self.link = link
    }

    public func asDictionary() -> [String: Any] {
        [
            "name": name,
            "fullPath": fullPath,
            "abstract": abstract,
            "abstractEscaped": abstractEscaped,
            "link": link,
        ]
    }
}

public struct ExampleView: Sendable, Equatable {
    public var title: String
    public var titleEscaped: String
    public var code: String
    public var codeFenced: String

    public init(title: String, titleEscaped: String, code: String, codeFenced: String) {
        self.title = title
        self.titleEscaped = titleEscaped
        self.code = code
        self.codeFenced = codeFenced
    }

    public func asDictionary() -> [String: Any] {
        [
            "title": title,
            "titleEscaped": titleEscaped,
            "code": code,
            "codeFenced": codeFenced,
        ]
    }
}

public struct IndexView: Sendable, Equatable {
    public var nodes: [IndexNodeView]

    public init(nodes: [IndexNodeView]) {
        self.nodes = nodes
    }

    public func asDictionary() -> [String: Any] {
        ["nodes": nodes.map { $0.asDictionary() }]
    }
}

public struct IndexNodeView: Sendable, Equatable {
    public var name: String
    public var fullPath: String
    public var abstract: String
    public var abstractEscaped: String
    public var link: String
    public var depth: Int
    public var indent: String

    public init(
        name: String,
        fullPath: String,
        abstract: String,
        abstractEscaped: String,
        link: String,
        depth: Int
    ) {
        self.name = name
        self.fullPath = fullPath
        self.abstract = abstract
        self.abstractEscaped = abstractEscaped
        self.link = link
        self.depth = depth
        self.indent = String(repeating: "  ", count: max(0, depth))
    }

    public func asDictionary() -> [String: Any] {
        [
            "name": name,
            "fullPath": fullPath,
            "abstract": abstract,
            "abstractEscaped": abstractEscaped,
            "link": link,
            "depth": depth,
            "indent": indent,
        ]
    }
}
