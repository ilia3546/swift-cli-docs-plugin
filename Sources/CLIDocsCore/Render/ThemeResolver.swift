import Foundation

public enum ThemeResolverError: Error, CustomStringConvertible {
    case unknownBuiltinTheme(String)
    case userThemeNotFound(URL)
    case bundleResourcesMissing
    case templateMissing(name: String, locations: [URL])

    public var description: String {
        switch self {
        case .unknownBuiltinTheme(let name):
            return "Unknown built-in theme '\(name)'. Known: default, minimal, github."
        case .userThemeNotFound(let url):
            return "User theme directory not found at \(url.path)."
        case .bundleResourcesMissing:
            return "Could not locate bundled theme resources. Was the package built with the proper resources declaration?"
        case .templateMissing(let name, let locations):
            let paths = locations.map { $0.path }.joined(separator: ", ")
            return "Stencil template '\(name)' not found in: \(paths)"
        }
    }
}

/// Locates the directories that hold the chosen theme's `.stencil` files.
/// Returns an ordered list of search roots: user theme first (if any), then the
/// built-in theme so that user themes can omit partials and fall back.
public struct ThemeResolver {
    public static let knownBuiltinThemes: Set<String> = ["default", "minimal", "github"]

    public init() {}

    public func resolveSearchPaths(themeName: String, userThemePath: String?) throws -> [URL] {
        var paths: [URL] = []

        if let userPath = userThemePath {
            let url = URL(fileURLWithPath: userPath, isDirectory: true)
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
                throw ThemeResolverError.userThemeNotFound(url)
            }
            paths.append(url)
        }

        guard Self.knownBuiltinThemes.contains(themeName) else {
            throw ThemeResolverError.unknownBuiltinTheme(themeName)
        }

        let bundleThemes = try locateBundledThemesRoot()
        paths.append(bundleThemes.appendingPathComponent(themeName, isDirectory: true))

        // Always fall back to "default" so themes that extend default can find shared partials.
        if themeName != "default" {
            paths.append(bundleThemes.appendingPathComponent("default", isDirectory: true))
        }

        return paths
    }

    private func locateBundledThemesRoot() throws -> URL {
        // .copy("Resources/Themes") puts a "Themes" directory at the bundle root.
        if let url = Bundle.module.url(forResource: "Themes", withExtension: nil) {
            return url
        }
        // Fallback: derive from bundleURL when running in test bundles where
        // url(forResource:) sometimes returns nil for directories.
        let derived = Bundle.module.bundleURL.appendingPathComponent("Themes", isDirectory: true)
        if FileManager.default.fileExists(atPath: derived.path) { return derived }
        throw ThemeResolverError.bundleResourcesMissing
    }
}
