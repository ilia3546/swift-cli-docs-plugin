import Foundation
import ArgumentParserToolInfo

/// Builds the `Usage:` synopsis line for a command.
public enum SynopsisBuilder {
    /// Compose a usage line like `mycli build [--release] [--target <name>] <path>...`.
    /// The leading invocation token is the full command path so users can copy/paste.
    public static func build(commandPath: [String], arguments: [ArgumentInfoV0]?) -> String {
        var parts: [String] = commandPath
        let visible = (arguments ?? []).filter { $0.shouldDisplay }

        let nonPositional = visible.filter { $0.kind != .positional }
        let positional = visible.filter { $0.kind == .positional }

        for arg in nonPositional {
            parts.append(synopsisFragment(for: arg))
        }
        for arg in positional {
            parts.append(synopsisFragment(for: arg))
        }
        return parts.joined(separator: " ")
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
            let trailing = arg.isRepeating ? " <\(value)> ..." : " <\(value)>"
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
