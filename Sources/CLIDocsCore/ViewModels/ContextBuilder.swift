import Foundation
import ArgumentParserToolInfo

/// Strategy for turning a command's full path into a markdown link target.
/// Multi-file: relative file path. Single-file: anchor fragment.
public protocol LinkResolver: Sendable {
    func link(for fullPath: [String]) -> String
}

public struct AnchorLinkResolver: LinkResolver, Sendable {
    public init() {}
    public func link(for fullPath: [String]) -> String {
        "#" + MarkdownEscape.anchor(fullPath.joined(separator: " "))
    }
}

public struct RelativeFileLinkResolver: LinkResolver, Sendable {
    public let filenameTemplate: String
    public let rootName: String

    public init(filenameTemplate: String, rootName: String) {
        self.filenameTemplate = filenameTemplate
        self.rootName = rootName
    }

    public func link(for fullPath: [String]) -> String {
        FilenameRenderer.render(template: filenameTemplate, fullPath: fullPath, rootName: rootName)
    }
}

public enum FilenameRenderer {
    public static func render(template: String, fullPath: [String], rootName: String) -> String {
        var commandSlug = MarkdownEscape.anchor(fullPath.joined(separator: " "))
        if commandSlug.isEmpty { commandSlug = MarkdownEscape.anchor(rootName) }
        let parentSlug: String = fullPath.count > 1
            ? MarkdownEscape.anchor(fullPath.dropLast().joined(separator: " "))
            : ""
        return template
            .replacingOccurrences(of: "{command}", with: commandSlug)
            .replacingOccurrences(of: "{parent}", with: parentSlug)
    }
}

public struct ContextBuilder {
    public let config: DocsConfig
    public let linkResolver: LinkResolver

    public init(config: DocsConfig, linkResolver: LinkResolver) {
        self.config = config
        self.linkResolver = linkResolver
    }

    /// Flatten the command tree and produce one `CommandView` per visible command.
    public func buildAllCommandViews(from tool: ToolInfoV0) -> [CommandView] {
        var out: [CommandView] = []
        walk(command: tool.command, path: [], rootName: tool.command.commandName) { fullPath, info, depth in
            if let view = self.makeCommandView(info: info, fullPath: fullPath, depth: depth) {
                out.append(view)
            }
        }
        return out
    }

    /// Heading prefix that respects the configured layout. In multi-file, every
    /// page starts at `theme.headingDepth`. In single-file, subcommands nest
    /// deeper so they appear as proper sub-sections.
    private func headingPrefix(forDepth depth: Int) -> String {
        let level: Int = {
            switch config.output.layout {
            case .multiFile: return max(1, config.theme.headingDepth)
            case .singleFile: return max(1, config.theme.headingDepth) + depth
            }
        }()
        let clamped = min(level, 6)
        return String(repeating: "#", count: clamped)
    }

    public func buildIndexView(from tool: ToolInfoV0) -> IndexView {
        var nodes: [IndexNodeView] = []
        walk(command: tool.command, path: [], rootName: tool.command.commandName) { fullPath, info, depth in
            guard self.shouldInclude(fullPath: fullPath, info: info) else { return }
            let abstract = self.resolveAbstract(info: info, fullPath: fullPath)
            nodes.append(
                IndexNodeView(
                    name: info.commandName,
                    fullPath: fullPath.joined(separator: " "),
                    abstract: abstract,
                    abstractEscaped: MarkdownEscape.inline(abstract),
                    link: self.linkResolver.link(for: fullPath),
                    depth: depth
                )
            )
        }
        return IndexView(nodes: nodes)
    }

    public func buildMeta(from tool: ToolInfoV0) -> MetaView {
        let title = config.metadata.title ?? tool.command.commandName
        return MetaView(
            title: title,
            description: config.metadata.description ?? tool.command.abstract,
            version: config.metadata.version,
            repository: config.metadata.repository
        )
    }

    public func buildTheme() -> ThemeView {
        ThemeView(
            name: config.theme.name,
            headingDepth: config.theme.headingDepth,
            toc: config.theme.toc,
            showAliases: config.theme.showAliases,
            codeFence: config.theme.codeFence,
            emoji: config.theme.emoji,
            variables: config.theme.variables
        )
    }

    // MARK: - Internals

    private func walk(
        command: CommandInfoV0,
        path: [String],
        rootName: String,
        visit: ([String], CommandInfoV0, Int) -> Void
    ) {
        let fullPath = path.isEmpty ? [command.commandName] : path + [command.commandName]
        let depth = fullPath.count - 1
        visit(fullPath, command, depth)
        for sub in command.subcommands ?? [] {
            walk(command: sub, path: fullPath, rootName: rootName, visit: visit)
        }
    }

    private func makeCommandView(info: CommandInfoV0, fullPath: [String], depth: Int) -> CommandView? {
        guard shouldInclude(fullPath: fullPath, info: info) else { return nil }

        let pathKey = fullPath.joined(separator: " ")
        let override = config.overrides[pathKey]

        let abstract = resolveAbstract(info: info, fullPath: fullPath)
        let discussion = override?.discussion ?? info.discussion ?? ""

        let aliases = config.theme.showAliases ? (info.aliases ?? []) : []

        let synopsis = SynopsisBuilder.build(commandPath: fullPath, arguments: info.arguments)

        let argumentSections = makeArgumentSections(info: info)
        let subcommands = makeSubcommandLinks(info: info, parentPath: fullPath)
        let examples = makeExamples(info: info, override: override)
        let customSections = resolveCustomSections()

        let prefix = headingPrefix(forDepth: depth)

        return CommandView(
            name: info.commandName,
            fullPath: pathKey,
            anchor: MarkdownEscape.anchor(pathKey),
            headingPrefix: prefix,
            abstract: abstract,
            abstractEscaped: MarkdownEscape.inline(abstract),
            discussion: discussion,
            discussionEscaped: MarkdownEscape.inline(discussion),
            aliases: aliases,
            synopsis: synopsis,
            argumentSections: argumentSections,
            subcommands: subcommands,
            examples: examples,
            customSections: customSections,
            sectionOrder: config.sections.order,
            isHidden: !info.shouldDisplay
        )
    }

    private func resolveAbstract(info: CommandInfoV0, fullPath: [String]) -> String {
        let pathKey = fullPath.joined(separator: " ")
        if let override = config.overrides[pathKey]?.abstract { return override }
        return info.abstract ?? ""
    }

    private func makeArgumentSections(info: CommandInfoV0) -> [ArgumentSectionView] {
        let allArgs = (info.arguments ?? []).filter { config.theme.showHidden || $0.shouldDisplay }
        guard !allArgs.isEmpty else { return [] }

        // Group by sectionTitle when set, else by kind.
        var bySection: [String: [ArgumentInfoV0]] = [:]
        var sectionOrder: [String] = []
        for arg in allArgs {
            let key = arg.sectionTitle ?? defaultSectionTitle(for: arg.kind)
            if bySection[key] == nil {
                bySection[key] = []
                sectionOrder.append(key)
            }
            bySection[key]?.append(arg)
        }

        return sectionOrder.map { title in
            let bucket = bySection[title] ?? []
            return ArgumentSectionView(
                title: title,
                kind: detectKind(of: bucket),
                arguments: bucket.map(makeArgumentView(_:))
            )
        }
    }

    private func defaultSectionTitle(for kind: ArgumentInfoV0.KindV0) -> String {
        switch kind {
        case .positional: return "Arguments"
        case .option: return "Options"
        case .flag: return "Flags"
        }
    }

    private func detectKind(of args: [ArgumentInfoV0]) -> ArgumentSectionView.Kind {
        guard let first = args.first else { return .mixed }
        if args.allSatisfy({ $0.kind == first.kind }) {
            switch first.kind {
            case .positional: return .positional
            case .option: return .option
            case .flag: return .flag
            }
        }
        return .mixed
    }

    private func makeArgumentView(_ arg: ArgumentInfoV0) -> ArgumentView {
        let kind: ArgumentView.Kind = {
            switch arg.kind {
            case .positional: return .positional
            case .option: return .option
            case .flag: return .flag
            }
        }()

        let abstract = arg.abstract ?? ""
        let discussion = arg.discussion ?? ""
        let combinedDescription: String = {
            if !abstract.isEmpty && !discussion.isEmpty { return "\(abstract)\n\n\(discussion)" }
            return abstract.isEmpty ? discussion : abstract
        }()

        let displayName = DefaultsFormatter.displayName(for: arg)
        let primaryName = DefaultsFormatter.primaryName(for: arg)
        let defaultDisplay = DefaultsFormatter.format(arg.defaultValue)
        let valueRange = DefaultsFormatter.valueRangeText(allValueStrings: arg.allValueStrings)
        let isRequired = !arg.isOptional && !DefaultsFormatter.hasDefault(arg.defaultValue)

        return ArgumentView(
            kind: kind,
            displayName: displayName,
            primaryName: primaryName,
            anchor: MarkdownEscape.anchor(primaryName),
            description: combinedDescription,
            descriptionEscaped: MarkdownEscape.tableCell(combinedDescription),
            defaultDisplay: defaultDisplay,
            hasDefault: DefaultsFormatter.hasDefault(arg.defaultValue),
            isRequired: isRequired,
            isRepeating: arg.isRepeating,
            valueRangeText: valueRange
        )
    }

    private func makeSubcommandLinks(info: CommandInfoV0, parentPath: [String]) -> [SubcommandLinkView] {
        let subs = info.subcommands ?? []
        return subs.compactMap { sub in
            let fullPath = parentPath + [sub.commandName]
            guard shouldInclude(fullPath: fullPath, info: sub) else { return nil }
            let abstract = resolveAbstract(info: sub, fullPath: fullPath)
            return SubcommandLinkView(
                name: sub.commandName,
                fullPath: fullPath.joined(separator: " "),
                abstract: abstract,
                abstractEscaped: MarkdownEscape.inline(abstract),
                link: linkResolver.link(for: fullPath)
            )
        }
    }

    private func makeExamples(info: CommandInfoV0, override: CommandOverride?) -> [ExampleView] {
        let raws = override?.examples ?? []
        return raws.map { ex in
            let fence = config.theme.codeFence
            let codeFenced = "```\(fence)\n\(ex.code)\n```"
            return ExampleView(
                title: ex.title,
                titleEscaped: MarkdownEscape.inline(ex.title),
                code: ex.code,
                codeFenced: codeFenced
            )
        }
    }

    private func resolveCustomSections() -> [String: String] {
        var out: [String: String] = [:]
        for (name, path) in config.sections.custom {
            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                out[name] = content
            }
        }
        return out
    }

    private func shouldInclude(fullPath: [String], info: CommandInfoV0) -> Bool {
        if !config.theme.showHidden && !info.shouldDisplay { return false }
        let pathKey = fullPath.joined(separator: " ")
        let inIncluded = config.include.contains { PathUtil.matches(pattern: $0, value: pathKey) }
        if !inIncluded { return false }
        let inExcluded = config.exclude.contains { PathUtil.matches(pattern: $0, value: pathKey) }
        return !inExcluded
    }
}
