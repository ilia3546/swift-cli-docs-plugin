import Foundation

public enum DefaultsFormatter {
    public static let placeholder = "—"

    /// Format an `ArgumentInfoV0.defaultValue` for display in the docs.
    /// Returns `placeholder` if there is no default to show.
    public static func format(_ value: String?) -> String {
        guard let v = value, !v.isEmpty else { return placeholder }
        return v
    }

    /// True if the given default-value string represents a real default we should show.
    public static func hasDefault(_ value: String?) -> Bool {
        guard let v = value else { return false }
        return !v.isEmpty
    }

    /// "one of: a, b, c" or "" if there is no list of allowed values.
    public static func valueRangeText(allValueStrings: [String]?) -> String {
        guard let values = allValueStrings, !values.isEmpty else { return "" }
        return "one of: " + values.joined(separator: ", ")
    }

    /// Best display name for an argument:
    /// - positional → `<valueName>` or `<positional>`
    /// - option/flag → "-s, --long [<value>]"
    public static func displayName(for argument: ArgumentInfoV0) -> String {
        switch argument.kind {
        case .positional:
            let value = argument.valueName ?? "value"
            return argument.isRepeating ? "<\(value)> ..." : "<\(value)>"
        case .option:
            let names = formattedNames(argument)
            let value = argument.valueName ?? "value"
            let suffix = argument.isRepeating ? " <\(value)> ..." : " <\(value)>"
            return names + suffix
        case .flag:
            return formattedNames(argument)
        }
    }

    /// "-s, --long" — joined `NameInfoV0` array with the proper dash prefix.
    public static func formattedNames(_ argument: ArgumentInfoV0) -> String {
        guard let names = argument.names, !names.isEmpty else {
            return argument.valueName.map { "<\($0)>" } ?? "<value>"
        }
        return names.map { Self.formatted(name: $0) }.joined(separator: ", ")
    }

    public static func formatted(name: ArgumentInfoV0.NameInfoV0) -> String {
        switch name.kind {
        case .long:
            return "--\(name.name)"
        case .short:
            return "-\(name.name)"
        case .longWithSingleDash:
            return "-\(name.name)"
        }
    }

    /// Pick a stable primary name to use in anchors and synopses.
    public static func primaryName(for argument: ArgumentInfoV0) -> String {
        if let preferred = argument.preferredName {
            return preferred.name
        }
        if let first = argument.names?.first {
            return first.name
        }
        return argument.valueName ?? "argument"
    }
}
