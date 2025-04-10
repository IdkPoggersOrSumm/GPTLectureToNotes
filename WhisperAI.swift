import Foundation

class WhisperAI {
    static let shared = WhisperAI()
    @Published var consoleOutput: String = ""  // Bindable for UI updates
    
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

                if let output = String(data: outputData, encoding: .utf8) {
                    DispatchQueue.main.async {
                        Logger.shared.log("✅ Transcription completed successfully.")
                        completion(output) // THIS WAS MISSING - NOW RETURNS THE TRANSCRIPTION
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
