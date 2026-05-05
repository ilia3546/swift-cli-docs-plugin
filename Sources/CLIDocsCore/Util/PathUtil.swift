import Foundation

public enum PathUtil {
    /// Glob-style match supporting `*` (any chars except spaces) and `?`.
    /// Matches against the full command path like `"mycli build"`.
    public static func matches(pattern: String, value: String) -> Bool {
        if pattern == "*" { return true }
        return regex(for: pattern).map { $0.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) != nil } ?? (pattern == value)
    }

    private static func regex(for pattern: String) -> NSRegularExpression? {
        var rx = "^"
        for ch in pattern {
            switch ch {
            case "*":
                rx += ".*"
            case "?":
                rx += "."
            case ".", "+", "(", ")", "[", "]", "{", "}", "^", "$", "|", "\\":
                rx += "\\\(ch)"
            default:
                rx.append(ch)
            }
        }
        rx += "$"
        return try? NSRegularExpression(pattern: rx, options: [])
    }
}
