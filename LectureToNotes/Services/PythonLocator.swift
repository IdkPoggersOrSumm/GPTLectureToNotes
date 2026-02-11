import Foundation

enum PythonLocator {
    private static let preferredShellPath = "/bin/zsh"
    private static let preferredBinPaths = "/opt/homebrew/bin:/opt/homebrew/opt/python@3.11/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

    private static let preferredPython311Paths = [
        "/opt/homebrew/opt/python@3.11/bin/python3.11",
        "/usr/local/opt/python@3.11/bin/python3.11",
        "/opt/homebrew/bin/python3.11",
        "/usr/local/bin/python3.11"
    ]

    static func resolvePython311() -> URL? {
        for path in preferredPython311Paths where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        if let shellPath = resolveWithShell(command: "command -v python3.11"),
           FileManager.default.isExecutableFile(atPath: shellPath) {
            return URL(fileURLWithPath: shellPath)
        }

        return nil
    }

    static func subprocessEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        if let existing = env["PATH"], !existing.isEmpty {
            env["PATH"] = preferredBinPaths + ":" + existing
        } else {
            env["PATH"] = preferredBinPaths
        }
        return env
    }

    private static func resolveWithShell(command: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: preferredShellPath)
        task.arguments = ["-lc", command]
        task.environment = subprocessEnvironment()

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let value = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (value?.isEmpty == false) ? value : nil
        } catch {
            return nil
        }
    }
}

