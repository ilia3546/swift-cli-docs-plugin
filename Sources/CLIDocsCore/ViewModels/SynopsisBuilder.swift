import Foundation

/// Builds the `Usage:` synopsis line for a command.
public enum SynopsisBuilder {
    /// Compose a usage line like `mycli build [--release] [--target <name>] <path>...`.
    /// The leading invocation token is the full command path so users can copy/paste.
    /// When `hasSubcommands` is true, append `<subcommand>` to mirror the convention
    /// used by ArgumentParser's own `--help` output.
    public static func build(
        commandPath: [String],
        arguments: [ArgumentInfoV0]?,
        hasSubcommands: Bool = false,
        includeHelpFlag: Bool = false
    ) -> String {
        var parts: [String] = commandPath
        let visible = (arguments ?? [])
            .filter { $0.shouldDisplay }
            .filter { includeHelpFlag || !isHelpFlag($0) }

        let nonPositional = visible.filter { $0.kind != .positional }
        let positional = visible.filter { $0.kind == .positional }

        for arg in nonPositional {
            parts.append(synopsisFragment(for: arg))
        }
        for arg in positional {
            parts.append(synopsisFragment(for: arg))
        }
        if hasSubcommands {
            parts.append("<subcommand>")
        }
        return parts.joined(separator: " ")
    }

    private static func isHelpFlag(_ arg: ArgumentInfoV0) -> Bool {
        guard arg.kind == .flag else { return false }
        let names = (arg.names ?? []).map(\.name)
        return names.contains("help") || names.contains("h")
    }

    private static func synopsisFragment(for arg: ArgumentInfoV0) -> String {
        switch arg.kind {
        case .positional:
            let value = arg.valueName ?? "value"
            let core = arg.isRepeating ? "<\(value)>..." : "<\(value)>"
            return arg.isOptional ? "[\(core)]" : core
        case .option:
            let name = bestSynopsisName(arg)
            let value = arg.valueName ?? "value"
            let trailing = arg.isRepeating ? " <\(value)>..." : " <\(value)>"
            let core = "\(name)\(trailing)"
            return arg.isOptional ? "[\(core)]" : core
        case .flag:
            let name = bestSynopsisName(arg)
            return arg.isOptional ? "[\(name)]" : name
        }
    }

    /// For the synopsis we prefer the shortest preferred name to keep the line compact.
    private static func bestSynopsisName(_ arg: ArgumentInfoV0) -> String {
        if let preferred = arg.preferredName {
            return DefaultsFormatter.formatted(name: preferred)
        }
        if let first = arg.names?.first {
            return DefaultsFormatter.formatted(name: first)
        }
        return arg.valueName ?? "value"
    }
}
