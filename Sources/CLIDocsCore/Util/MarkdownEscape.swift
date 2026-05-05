import Foundation

private extension String {
    func trimmingTrailingWhitespace() -> String {
        var end = self.endIndex
        while end > self.startIndex {
            let prev = self.index(before: end)
            if self[prev].isWhitespace { end = prev } else { break }
        }
        return String(self[self.startIndex..<end])
    }
}

public enum MarkdownEscape {
    /// Escape characters that have meaning in Markdown when embedding arbitrary text
    /// inside paragraphs or table cells. Limited to characters that actually trigger
    /// inline parsing — emphasis, code, links, autolinks, and table separators.
    /// Notably does NOT escape `-`, `.`, `(`, `)`, `#`, `+`, `!` because those only
    /// have block-level meaning at the start of a line (and our callers always embed
    /// text mid-line).
    public static func inline(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count)
        for ch in s {
            switch ch {
            case "\\", "`", "*", "_", "[", "]", "|", "<", ">":
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

    /// Collapse runs of blank lines (3+ consecutive newlines) to a single blank
    /// line, and ensure the document ends with exactly one trailing newline.
    /// The Stencil templates emit blank lines around `{% if %}` blocks; without
    /// this pass the output has 2-4 blank lines between sections and trailing
    /// whitespace at EOF.
    public static func tidy(_ s: String) -> String {
        // Normalize CRLF/CR to LF first so the collapse logic is line-based.
        let normalized = s.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false)
        var out: [String] = []
        out.reserveCapacity(lines.count)
        var blankRun = 0
        for line in lines {
            let trimmed = String(line).trimmingTrailingWhitespace()
            if trimmed.isEmpty {
                blankRun += 1
                if blankRun <= 1 { out.append("") }
            } else {
                blankRun = 0
                out.append(trimmed)
            }
        }
        // Trim leading/trailing blank lines, then re-add a single newline at EOF.
        while out.first?.isEmpty == true { out.removeFirst() }
        while out.last?.isEmpty == true { out.removeLast() }
        return out.joined(separator: "\n") + "\n"
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
