import Foundation
import Stencil

public enum MarkdownFilters {
    /// Register the small set of filters our themes need.
    /// Currently: only `mdEscape` for defensive escaping of arbitrary `theme.variables`
    /// values. Everything else is pre-computed in `ContextBuilder`.
    public static func register(in ext: Extension) {
        ext.registerFilter("mdEscape") { value -> Any? in
            guard let s = value as? String else { return value }
            return MarkdownEscape.inline(s)
        }
        ext.registerFilter("mdAnchor") { value -> Any? in
            guard let s = value as? String else { return value }
            return MarkdownEscape.anchor(s)
        }
    }
}
