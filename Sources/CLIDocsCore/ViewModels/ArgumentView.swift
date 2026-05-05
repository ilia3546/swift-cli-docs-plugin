import Foundation

/// Pre-computed view of a single argument (positional, option, or flag).
public struct ArgumentView: Sendable, Equatable {
    public enum Kind: String, Sendable, Equatable {
        case positional, option, flag
    }

    public var kind: Kind
    public var displayName: String
    public var primaryName: String
    public var anchor: String
    public var description: String
    public var descriptionEscaped: String
    public var defaultDisplay: String
    public var hasDefault: Bool
    public var isRequired: Bool
    public var isRepeating: Bool
    public var valueRangeText: String
    public var hasValueRange: Bool

    public init(
        kind: Kind,
        displayName: String,
        primaryName: String,
        anchor: String,
        description: String,
        descriptionEscaped: String,
        defaultDisplay: String,
        hasDefault: Bool,
        isRequired: Bool,
        isRepeating: Bool,
        valueRangeText: String
    ) {
        self.kind = kind
        self.displayName = displayName
        self.primaryName = primaryName
        self.anchor = anchor
        self.description = description
        self.descriptionEscaped = descriptionEscaped
        self.defaultDisplay = defaultDisplay
        self.hasDefault = hasDefault
        self.isRequired = isRequired
        self.isRepeating = isRepeating
        self.valueRangeText = valueRangeText
        self.hasValueRange = !valueRangeText.isEmpty
    }

    public func asDictionary() -> [String: Any] {
        [
            "kind": kind.rawValue,
            "displayName": displayName,
            "primaryName": primaryName,
            "anchor": anchor,
            "description": description,
            "descriptionEscaped": descriptionEscaped,
            "defaultDisplay": defaultDisplay,
            "hasDefault": hasDefault,
            "isRequired": isRequired,
            "isRepeating": isRepeating,
            "valueRangeText": valueRangeText,
            "hasValueRange": hasValueRange,
        ]
    }
}
