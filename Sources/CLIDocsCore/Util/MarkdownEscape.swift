import Foundation

public enum MarkdownEscape {
    /// Escape characters that have meaning in Markdown when embedding arbitrary text
    /// inside paragraphs or table cells. Conservative: covers `|`, `*`, `_`, `<`, `` ` ``, `[`, `]`.
    public static func inline(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count)
        for ch in s {
            switch ch {
            case "\\", "`", "*", "_", "{", "}", "[", "]", "(", ")", "#", "+", "-", "!", "|", "<", ">":
                out.append("\\")
                out.append(ch)
            default:
                out.append(ch)
            }
        }
        return out
    }

    /// Escape just the table-breaking characters (newlines, pipes). Useful when the surrounding
    /// markdown is already a code-fence or pre-formatted block.
    public static func tableCell(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count)
        for ch in s {
            switch ch {
            case "|":
                out.append("\\|")
            case "\n", "\r":
                out.append(" ")
            default:
                out.append(ch)
            }
        }
        return out
    }

    /// Convert arbitrary command path or name to a stable lowercase anchor slug
    /// safe for use in Markdown intra-document links and as filenames.
    public static func anchor(_ s: String) -> String {
        let lowered = s.lowercased()
        var out = ""
        out.reserveCapacity(lowered.count)
        var lastWasDash = false
        for ch in lowered {
            if ch.isLetter || ch.isNumber {
                out.append(ch)
                lastWasDash = false
            } else if ch == "-" || ch == "_" {
                out.append(ch)
                lastWasDash = (ch == "-")
            } else if ch.isWhitespace || ch == "/" || ch == "." {
                if !lastWasDash {
                    out.append("-")
                    lastWasDash = true
                }
            }
        }
        // Trim leading/trailing dashes
        while out.first == "-" { out.removeFirst() }
        while out.last == "-" { out.removeLast() }
        return out
    }
}
