import Foundation

class WhisperAI {
    static let shared = WhisperAI()
    @Published var consoleOutput: String = ""  // Bindable for UI updates
    
    private init() {}

    func transcribeAudio(audioURL: URL, completion: @escaping (String?) -> Void) {
        // Log that the transcription is starting
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

        // Log that we are about to run the transcription script
        DispatchQueue.main.async {
            Logger.shared.log("🐍 Running Whisper transcription script at path: \(scriptPath)")
        }

        // Perform the transcription process on a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
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
                process.waitUntilExit()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                if let errorOutput = String(data: errorData, encoding: .utf8), !errorOutput.isEmpty {
                    DispatchQueue.main.async {
                        Logger.shared.log("⚠️ Whisper Error Output: \(errorOutput)")
                    }
                }

                if let output = String(data: outputData, encoding: .utf8), !output.isEmpty {
                    DispatchQueue.main.async {
                        Logger.shared.log("✅ Transcription completed, sending to OpenAI...")
                    }
                    DispatchQueue.main.async {
                        // Handle result and UI updates
                        OpenAIClient.shared.generateStudyNotes(from: audioURL) { notes, tokens, cost in
                            DispatchQueue.main.async {
                                Logger.shared.log("✅ Notes successfully generated.")
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        Logger.shared.log("❌ Whisper output was empty or nil.")
                        completion(nil)
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
