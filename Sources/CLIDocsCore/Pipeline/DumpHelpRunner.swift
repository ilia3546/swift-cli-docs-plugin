import Foundation

public enum DumpHelpRunnerError: Error, CustomStringConvertible {
    case executableNotFound(URL)
    case launchFailed(URL, underlying: Error)
    case nonZeroExit(URL, status: Int32, stderr: String)
    case noOutput(URL)
    case unsupportedSerializationVersion(Int)
    case decoding(underlying: Error, raw: String)

    public var description: String {
        switch self {
        case .executableNotFound(let url):
            return "Executable not found at \(url.path)."
        case .launchFailed(let url, let err):
            return "Failed to launch \(url.path): \(err)"
        case .nonZeroExit(let url, let status, let stderr):
            return "\(url.lastPathComponent) exited with status \(status). stderr:\n\(stderr)"
        case .noOutput(let url):
            return "\(url.lastPathComponent) produced no --experimental-dump-help output."
        case .unsupportedSerializationVersion(let v):
            return "Unsupported ToolInfo serialization version: \(v). Expected 0."
        case .decoding(let err, let raw):
            return "Failed to decode --experimental-dump-help JSON: \(err)\nFirst 200 chars: \(String(raw.prefix(200)))"
        }
    }
}

/// Runs an executable with `--experimental-dump-help` and decodes the result into `ToolInfoV0`.
public struct DumpHelpRunner {
    public init() {}

    public func run(executable: URL) throws -> ToolInfoV0 {
        guard FileManager.default.isExecutableFile(atPath: executable.path) else {
            throw DumpHelpRunnerError.executableNotFound(executable)
        }

        let process = Process()
        process.executableURL = executable
        process.arguments = ["--experimental-dump-help"]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            throw DumpHelpRunnerError.launchFailed(executable, underlying: error)
        }

        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errString = String(data: errData, encoding: .utf8) ?? ""
            throw DumpHelpRunnerError.nonZeroExit(
                executable,
                status: process.terminationStatus,
                stderr: errString
            )
        }

        guard !outData.isEmpty else { throw DumpHelpRunnerError.noOutput(executable) }
        return try decode(outData)
    }

    public func decode(_ data: Data) throws -> ToolInfoV0 {
        let decoder = JSONDecoder()
        do {
            let header = try decoder.decode(ToolInfoHeader.self, from: data)
            guard header.serializationVersion == 0 else {
                throw DumpHelpRunnerError.unsupportedSerializationVersion(header.serializationVersion)
            }
        } catch let err as DumpHelpRunnerError {
            throw err
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw DumpHelpRunnerError.decoding(underlying: error, raw: raw)
        }

        do {
            return try decoder.decode(ToolInfoV0.self, from: data)
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw DumpHelpRunnerError.decoding(underlying: error, raw: raw)
        }
    }
}
