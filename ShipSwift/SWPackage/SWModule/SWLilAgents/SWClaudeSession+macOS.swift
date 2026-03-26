// SWClaudeSession+macOS.swift
// Claude Code CLI process management, NDJSON stream parsing, and environment resolution.

import Foundation

final class SWClaudeSession {
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var outputBuffer = ""

    private(set) var isBusy = false {
        didSet {
            if oldValue != isBusy {
                onBusyChanged?(isBusy)
            }
        }
    }

    var onOutput: ((String) -> Void)?
    var onToolUse: ((String, String) -> Void)?
    var onBusyChanged: ((Bool) -> Void)?

    private var messageHistory: [(role: String, content: String)] = []

    private static var activeSessions: [SWClaudeSession] = []

    // MARK: - Lifecycle

    func start() {
        guard let claudePath = resolveClaudePath() else {
            onOutput?("[error] Could not find Claude CLI. Install it with: npm install -g @anthropic-ai/claude-code\n")
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: claudePath)
        process.arguments = [
            "-p",
            "--output-format", "stream-json",
            "--input-format", "stream-json",
            "--verbose"
        ]

        // Inherit a full shell environment so Claude can find tools
        process.environment = resolveShellEnvironment()

        let input = Pipe()
        let output = Pipe()

        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        self.process = process
        self.inputPipe = input
        self.outputPipe = output

        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
            self?.handleRawOutput(str)
        }

        do {
            try process.run()
            SWClaudeSession.activeSessions.append(self)
        } catch {
            onOutput?("[error] Failed to start Claude: \(error.localizedDescription)\n")
        }
    }

    func send(message: String) {
        guard let pipe = inputPipe else { return }

        messageHistory.append((role: "user", content: message))
        isBusy = true

        let payload: [String: Any] = [
            "type": "user",
            "message": [
                "role": "user",
                "content": message
            ]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload),
           var json = String(data: data, encoding: .utf8) {
            json += "\n"
            pipe.fileHandleForWriting.write(json.data(using: .utf8)!)
        }
    }

    func terminate() {
        process?.terminate()
        SWClaudeSession.activeSessions.removeAll { $0 === self }
    }

    static func killAllSessions() {
        activeSessions.forEach { $0.process?.terminate() }
        activeSessions.removeAll()
    }

    // MARK: - NDJSON Parsing

    private func handleRawOutput(_ raw: String) {
        outputBuffer += raw

        while let newlineIndex = outputBuffer.firstIndex(of: "\n") {
            let line = String(outputBuffer[outputBuffer.startIndex..<newlineIndex])
            outputBuffer = String(outputBuffer[outputBuffer.index(after: newlineIndex)...])

            guard !line.isEmpty else { continue }
            parseLine(line)
        }
    }

    private func parseLine(_ line: String) {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "system":
            // Session initialized
            break

        case "assistant":
            if let message = json["message"] as? [String: Any],
               let content = message["content"] as? [[String: Any]] {
                for block in content {
                    guard let blockType = block["type"] as? String else { continue }

                    if blockType == "text", let text = block["text"] as? String {
                        DispatchQueue.main.async { [weak self] in
                            self?.onOutput?(text)
                        }
                    } else if blockType == "tool_use" {
                        let toolName = block["name"] as? String ?? "tool"
                        let input = block["input"] as? [String: Any] ?? [:]
                        let inputStr: String
                        if let command = input["command"] as? String {
                            inputStr = command
                        } else if let content = input["content"] as? String {
                            inputStr = content
                        } else {
                            inputStr = String(describing: input)
                        }
                        DispatchQueue.main.async { [weak self] in
                            self?.onToolUse?(toolName, inputStr)
                        }
                    }
                }
            }

        case "user":
            // Tool results
            if let message = json["message"] as? [String: Any],
               let content = message["content"] as? [[String: Any]] {
                for block in content {
                    if let blockType = block["type"] as? String, blockType == "tool_result",
                       let resultContent = block["content"] as? String {
                        DispatchQueue.main.async { [weak self] in
                            self?.onToolUse?("result", resultContent)
                        }
                    }
                }
            }

        case "result":
            isBusy = false
            if let resultText = json["result"] as? String {
                messageHistory.append((role: "assistant", content: resultText))
            }

        default:
            break
        }
    }

    // MARK: - Environment Resolution

    private func resolveClaudePath() -> String? {
        // First try the shell environment PATH
        let env = resolveShellEnvironment()
        if let path = env["PATH"] {
            let dirs = path.split(separator: ":").map(String.init)
            for dir in dirs {
                let candidate = (dir as NSString).appendingPathComponent("claude")
                if FileManager.default.isExecutableFile(atPath: candidate) {
                    return candidate
                }
            }
        }

        // Fallback to known locations
        let knownPaths = [
            NSHomeDirectory() + "/.local/bin/claude",
            NSHomeDirectory() + "/.claude/local/bin/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude"
        ]

        for path in knownPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        return nil
    }

    private func resolveShellEnvironment() -> [String: String] {
        // Spawn a login shell to capture the full user environment
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: shell)
        proc.arguments = ["-l", "-i", "-c", "env"]

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        proc.standardInput = FileHandle.nullDevice

        do {
            try proc.run()
            proc.waitUntilExit()
        } catch {
            return ProcessInfo.processInfo.environment
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return ProcessInfo.processInfo.environment
        }

        var env = ProcessInfo.processInfo.environment
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                env[String(parts[0])] = String(parts[1])
            }
        }

        return env
    }
}
