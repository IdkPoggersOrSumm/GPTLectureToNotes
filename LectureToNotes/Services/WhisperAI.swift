import Foundation
import Combine

class WhisperAI {
    static let shared = WhisperAI()
    @Published var consoleOutput: String = ""  // Bindable for UI updates
    @Published var progressPercent: Double = 0.0

    private init() {}

    func transcribeAudio(audioURL: URL, completion: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            Logger.shared.log("🎤 Starting transcription process for file: \(audioURL.path)")
        }

        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            DispatchQueue.main.async {
                Logger.shared.log("❌ Error: Audio file does not exist at path: \(audioURL.path)")
                completion(nil)
            }
            return
        }

        guard let scriptPath = Bundle.main.path(forResource: "Transcript", ofType: "py") else {
            DispatchQueue.main.async {
                Logger.shared.log("❌ Error: Could not find Transcript.py in the bundle.")
                completion(nil)
            }
            return
        }

        DispatchQueue.main.async {
            Logger.shared.log("🐍 Running Whisper transcription script at path: \(scriptPath)")
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            guard let pythonURL = PythonLocator.resolvePython311() else {
                DispatchQueue.main.async {
                    Logger.shared.log("❌ Python 3.11 not found. Install with: brew install python@3.11")
                    completion(nil)
                }
                return
            }

            process.executableURL = pythonURL
            process.environment = PythonLocator.subprocessEnvironment()
            process.arguments = [scriptPath, audioURL.path]

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()

                DispatchQueue.main.async {
                    Logger.shared.log("⏳ Whisper transcription process started...")
                }

                var fullOutput = ""
                var lineBuffer = ""
                var lastProgressLineLength = 0

                outputPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    guard data.count > 0,
                          let chunk = String(data: data, encoding: .utf8) else { return }

                    DispatchQueue.main.async {
                        fullOutput += chunk
                        lineBuffer += chunk

                        // Process only complete lines to avoid broken segment logs
                        while let range = lineBuffer.range(of: "\n") {
                            let line = String(lineBuffer[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                            lineBuffer.removeSubrange(..<range.upperBound)

                            if !line.isEmpty {

                                // Detect structured progress messages from Python
                                if line.hasPrefix("[PROGRESS]") {
                                    let valueString = line.replacingOccurrences(of: "[PROGRESS]", with: "")
                                        .trimmingCharacters(in: .whitespaces)

                                    if let percent = Double(valueString) {
                                        self.progressPercent = percent

                                        // Build a simple 30-char console progress bar
                                        let totalBlocks = 30
                                        let filledBlocks = Int((percent / 100.0) * Double(totalBlocks))
                                        let bar = String(repeating: "█", count: filledBlocks) +
                                                  String(repeating: "░", count: totalBlocks - filledBlocks)

                                        let progressLine = "📊 [\(bar)] \(Int(percent))%"

                                        // Replace last progress line instead of appending endlessly
                                        if lastProgressLineLength > 0 {
                                            self.consoleOutput.removeLast(lastProgressLineLength)
                                        }

                                        self.consoleOutput += progressLine
                                        lastProgressLineLength = progressLine.count
                                    }

                                } else {
                                    Logger.shared.log("📝 \(line)")
                                    self.consoleOutput += line + "\n"
                                }
                            }
                        }
                    }
                }

                // Stream stderr incrementally (helps debugging Metal / model issues)
                errorPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if data.count > 0, let chunk = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            // Clean up the chunk and log it
                            let cleanedChunk = chunk.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
                            
                            // Log error codes and important messages
                            if cleanedChunk.contains("ERROR CODE") || cleanedChunk.contains("❌") || cleanedChunk.contains("🚀") {
                                Logger.shared.log("⚠️ \(cleanedChunk)")
                            } else if let percentRange = cleanedChunk.range(of: "[0-9]+%\\|[^\\d]*", options: .regularExpression) {
                                // Extract percentage and progress bar (e.g., "74%|███████▍")
                                let progressInfo = String(cleanedChunk[percentRange]).trimmingCharacters(in: .whitespaces)
                                if !progressInfo.isEmpty {
                                    Logger.shared.log("⚠️ Whisper Progress: \(progressInfo)")
                                }
                            }
                        }
                    }
                }

                process.terminationHandler = { _ in
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil

                    DispatchQueue.main.async {
                        Logger.shared.log("✅ Transcription completed successfully.")
                        completion(fullOutput)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    Logger.shared.log("❌ Whisper transcription failed: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
    }
}
