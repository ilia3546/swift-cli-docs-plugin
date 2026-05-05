import Foundation
import PackagePlugin

@main
struct SwiftCLIDocsPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        try run(
            packageDirectory: context.package.directory.string,
            executableTargets: context.package.targets.compactMap { $0 as? SwiftSourceModuleTarget }
                .filter { $0.kind == .executable }
                .map { $0.name },
            tool: try context.tool(named: "swift-cli-docs"),
            arguments: arguments,
            buildExecutable: { name in
                let result = try self.packageManager.build(
                    .product(name),
                    parameters: .init(configuration: .release, logging: .concise)
                )
                guard result.succeeded else {
                    Diagnostics.error("Failed to build executable '\(name)':\n\(result.logText)")
                    throw PluginError.buildFailed(name)
                }
                guard let artifact = result.builtArtifacts.first(where: { $0.kind == .executable && $0.path.lastComponent == name })
                    ?? result.builtArtifacts.first(where: { $0.kind == .executable })
                else {
                    throw PluginError.builtArtifactNotFound(name)
                }
                return artifact.path.string
            }
        )
    }

    /// Pure logic that's also reusable from XcodeCommandPlugin.
    func run(
        packageDirectory: String,
        executableTargets: [String],
        tool: PluginContext.Tool,
        arguments: [String],
        buildExecutable: (String) throws -> String
    ) throws {
        var extractor = ArgumentExtractor(arguments)
        let target = extractor.extractOption(named: "target").last
        let configPath = extractor.extractOption(named: "config").last
        let output = extractor.extractOption(named: "output").last
        let layout = extractor.extractOption(named: "layout").last
        let theme = extractor.extractOption(named: "theme").last
        let themePath = extractor.extractOption(named: "theme-path").last

        let resolvedTarget: String
        if let target {
            guard executableTargets.contains(target) else {
                throw PluginError.unknownTarget(target, available: executableTargets)
            }
            resolvedTarget = target
        } else if executableTargets.count == 1, let only = executableTargets.first {
            resolvedTarget = only
        } else if executableTargets.isEmpty {
            throw PluginError.noExecutableTargets
        } else {
            throw PluginError.targetRequired(available: executableTargets)
        }

        let executablePath = try buildExecutable(resolvedTarget)

        var helperArgs: [String] = [
            "--package-root", packageDirectory,
            "--target", resolvedTarget,
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
        let executableTargets = context.xcodeProject.targets.compactMap { target -> String? in
            // In Xcode contexts there's no direct target.kind == .executable check.
            // We rely on the user to pass --target explicitly.
            return target.displayName
        }

        try run(
            packageDirectory: context.xcodeProject.directory.string,
            executableTargets: executableTargets,
            tool: try context.tool(named: "swift-cli-docs"),
            arguments: arguments,
            buildExecutable: { name in
                Diagnostics.error("Building executable artifacts from Xcode contexts is not supported. Pass --executable <path> after building the target manually.")
                throw PluginError.buildFailed(name)
            }
        )
    }
}
#endif
