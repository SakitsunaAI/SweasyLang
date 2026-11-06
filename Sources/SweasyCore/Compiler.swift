import Foundation

/// Coordinates transpilation, execution, and binary compilation of Sweasy source code.
public final class Compiler {
    public init() {}

    /// Transpiles Sweasy source code to Swift source code
    public func transpile(source: String) throws -> String {
        let parser = Parser()
        let program = try parser.parse(source: source)
        let transpiler = Transpiler()
        return transpiler.transpile(program)
    }

    /// Runs a Sweasy source string directly using the Swift interpreter/JIT
    @discardableResult
    public func run(source: String, arguments: [String] = []) throws -> Int32 {
        let swiftCode = try transpile(source: source)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("sweasy_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let tempFile = tempDir.appendingPathComponent("main.swift")
        try swiftCode.write(to: tempFile, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", tempFile.path] + arguments
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            throw SweasyError("Failed to execute Swift runner: \(error.localizedDescription)")
        }
    }

    /// Compiles Sweasy source code into a standalone native binary using swiftc
    public func build(source: String, outputPath: String) throws {
        let swiftCode = try transpile(source: source)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("sweasy_build_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let tempFile = tempDir.appendingPathComponent("main.swift")
        try swiftCode.write(to: tempFile, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swiftc", "-O", tempFile.path, "-o", outputPath]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errString = String(data: errData, encoding: .utf8) ?? "Unknown swiftc compiler error"
                throw SweasyError("Compilation failed:\n\(errString)")
            }
        } catch let err as SweasyError {
            throw err
        } catch {
            throw SweasyError("Failed to invoke swiftc compiler: \(error.localizedDescription)")
        }
    }
}

