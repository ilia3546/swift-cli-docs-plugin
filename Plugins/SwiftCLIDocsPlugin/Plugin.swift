import Foundation
import PackagePlugin

struct ExecutableEntry {
    var productName: String
    var targetName: String
}

@main
struct SwiftCLIDocsPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let executables: [ExecutableEntry] = context.package.products.compactMap { product in
            guard let exe = product as? ExecutableProduct else { return nil }
            return ExecutableEntry(productName: exe.name, targetName: exe.mainTarget.name)
        }

        try run(
            packageDirectory: context.package.directory.string,
            executables: executables,
            tool: try context.tool(named: "swift-cli-docs"),
            arguments: arguments,
            buildExecutable: { entry in
                let result = try self.packageManager.build(
                    .product(entry.productName),
                    parameters: .init(configuration: .release, logging: .concise)
                )
                guard result.succeeded else {
                    Diagnostics.error("Failed to build executable '\(entry.productName)':\n\(result.logText)")
                    throw PluginError.buildFailed(entry.productName)
                }
                guard let artifact = result.builtArtifacts.first(where: { $0.kind == .executable && $0.path.lastComponent == entry.productName })
                    ?? result.builtArtifacts.first(where: { $0.kind == .executable })
                else {
                    throw PluginError.builtArtifactNotFound(entry.productName)
                }
                return artifact.path.string
            }
        )
    }

    /// Pure logic that's also reusable from XcodeCommandPlugin.
    func run(
        packageDirectory: String,
        executables: [ExecutableEntry],
        tool: PluginContext.Tool,
        arguments: [String],
        buildExecutable: (ExecutableEntry) throws -> String
    ) throws {
        var extractor = ArgumentExtractor(arguments)
        let target = extractor.extractOption(named: "target").last
        let configPath = extractor.extractOption(named: "config").last
        let output = extractor.extractOption(named: "output").last
        let layout = extractor.extractOption(named: "layout").last
        let theme = extractor.extractOption(named: "theme").last
        let themePath = extractor.extractOption(named: "theme-path").last

        let availableNames = executables.map(\.targetName)

        let resolved: ExecutableEntry
        if let target {
            // Match against target name first, then fall back to product name so users
            // can pass either. This matters when the executable product is renamed in
            // Package.swift (e.g. target "DemoCLI" exposed as product "demo").
            guard let entry = executables.first(where: { $0.targetName == target })
                ?? executables.first(where: { $0.productName == target })
            else {
                throw PluginError.unknownTarget(target, available: availableNames)
            }
            resolved = entry
        } else if executables.count == 1, let only = executables.first {
            resolved = only
        } else if executables.isEmpty {
            throw PluginError.noExecutableTargets
        } else {
            throw PluginError.targetRequired(available: availableNames)
        }

        let executablePath = try buildExecutable(resolved)

        var helperArgs: [String] = [
            "--package-root", packageDirectory,
            "--target", resolved.targetName,
            "--executable", executablePath,
        ]
        if let configPath { helperArgs += ["--config", configPath] }
        if let output { helperArgs += ["--output", output] }
        if let layout { helperArgs += ["--layout", layout] }
        if let theme { helperArgs += ["--theme", theme] }
        if let themePath { helperArgs += ["--theme-path", themePath] }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool.path.string)
        process.arguments = helperArgs
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw PluginError.helperFailed(status: process.terminationStatus)
        }
    }
}

enum PluginError: Error, CustomStringConvertible {
    case noExecutableTargets
    case targetRequired(available: [String])
    case unknownTarget(String, available: [String])
    case buildFailed(String)
    case builtArtifactNotFound(String)
    case helperFailed(status: Int32)

    var description: String {
        switch self {
        case .noExecutableTargets:
            return "This package has no executable targets. swift-cli-docs needs an executable target that uses Swift Argument Parser."
        case .targetRequired(let avail):
            return "Multiple executable targets present. Pick one with `--target`. Available: \(avail.joined(separator: ", "))."
        case .unknownTarget(let name, let avail):
            return "Unknown target '\(name)'. Available executable targets: \(avail.joined(separator: ", "))."
        case .buildFailed(let name):
            return "Building target '\(name)' failed."
        case .builtArtifactNotFound(let name):
            return "Could not find a built executable artifact for '\(name)' in the build result."
        case .helperFailed(let status):
            return "swift-cli-docs helper exited with status \(status)."
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftCLIDocsPlugin: XcodeCommandPlugin {
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        let executables = context.xcodeProject.targets.map { target in
            // In Xcode contexts there's no direct target.kind == .executable check
            // and no separate product/target distinction, so reuse the display name.
            ExecutableEntry(productName: target.displayName, targetName: target.displayName)
        }

        try run(
            packageDirectory: context.xcodeProject.directory.string,
            executables: executables,
            tool: try context.tool(named: "swift-cli-docs"),
            arguments: arguments,
            buildExecutable: { entry in
                Diagnostics.error("Building executable artifacts from Xcode contexts is not supported. Pass --executable <path> after building the target manually.")
                throw PluginError.buildFailed(entry.productName)
            }
        )
    }
}
#endif
