import Foundation
import Yams

public enum ConfigLoaderError: Error, CustomStringConvertible {
    case fileNotFound(URL)
    case unreadable(URL, underlying: Error)
    case decoding(URL, underlying: Error)

    public var description: String {
        switch self {
        case .fileNotFound(let url):
            return "Config file not found at \(url.path)."
        case .unreadable(let url, let err):
            return "Could not read config at \(url.path): \(err)"
        case .decoding(let url, let err):
            return "Could not decode YAML at \(url.path): \(err)"
        }
    }
}

public struct ConfigLoader {
    public static let defaultFilenames = [
        ".swift-cli-docs.yml",
        ".swift-cli-docs.yaml",
        "swift-cli-docs.yml",
        "swift-cli-docs.yaml",
    ]

    public init() {}

    /// Locate a config file by searching the given directory for the default filenames.
    /// Returns nil if no file is present (caller can fall back to defaults).
    public func locateConfig(in directory: URL) -> URL? {
        for name in Self.defaultFilenames {
            let candidate = directory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }

    public func load(from url: URL) throws -> DocsConfig {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ConfigLoaderError.unreadable(url, underlying: error)
        }
        guard let yaml = String(data: data, encoding: .utf8) else {
            throw ConfigLoaderError.unreadable(
                url,
                underlying: NSError(domain: "ConfigLoader", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Not valid UTF-8"])
            )
        }
        do {
            return try YAMLDecoder().decode(DocsConfig.self, from: yaml)
        } catch {
            throw ConfigLoaderError.decoding(url, underlying: error)
        }
    }

    /// Apply CLI overrides on top of a parsed config. CLI flags always win.
    public func merge(base: DocsConfig, with overrides: CLIOverrides) -> DocsConfig {
        var cfg = base
        if let v = overrides.target { cfg.target = v }
        if let v = overrides.outputDirectory { cfg.output.directory = v }
        if let v = overrides.layout { cfg.output.layout = v }
        if let v = overrides.themeName { cfg.theme.name = v }
        if let v = overrides.themePath { cfg.theme.path = v }
        return cfg
    }
}

/// CLI flag values that can override the YAML config.
public struct CLIOverrides: Sendable {
    public var target: String?
    public var outputDirectory: String?
    public var layout: OutputConfig.Layout?
    public var themeName: String?
    public var themePath: String?

    public init(
        target: String? = nil,
        outputDirectory: String? = nil,
        layout: OutputConfig.Layout? = nil,
        themeName: String? = nil,
        themePath: String? = nil
    ) {
        self.target = target
        self.outputDirectory = outputDirectory
        self.layout = layout
        self.themeName = themeName
        self.themePath = themePath
    }
}
