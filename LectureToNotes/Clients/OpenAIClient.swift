//
//  OpenAIClient.swift
//  LectureNoteMaker
//
//  Created by Jacob Rodriguez on 3/24/25.
//

import Foundation
import os
// Standard pricing struct for OpenAI models
struct OpenAIModelPricing {
    // GPT-5-nano pricing
    static let gpt5NanoInput: Double = 0.00000005      // $0.05 / 1M
    static let gpt5NanoOutput: Double = 0.00000040     // $0.40 / 1M
    
    // GPT-4.1-nano pricing
    static let gpt4_1_nanoInput: Double = 0.00000010   // $0.10 / 1M
    static let gpt4_1_nanoOutput: Double = 0.00000040  // $0.40 / 1M
    
    static let whisper: Double = 0.0000004
}

class OpenAIClient {
    static let shared = OpenAIClient()
    
    // Key for UserDefaults storage
    private let userAPIKeyKey = "userOpenAIAPIKey"
    
    //Tracks selected prompt
    var currentPrompt: PromptOption = PromptPresets.all[0]
    
    // Allows the changing of prompts
    func setPrompt(_ prompt: PromptOption) {
        self.currentPrompt = prompt
        Logger.shared.log("📝 Changed prompt to: \(prompt.name)")
    }
    
    // Get the active API key (priority: UserDefaults -> Secrets.plist)
    func getAPIKey() -> String? {
        // Check UserDefaults first
        if let userKey = UserDefaults.standard.string(forKey: userAPIKeyKey) {
            return userKey
        }
        // Fallback to Secrets.plist
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let plistKey = dict["OpenAI_API_Key"] as? String else {
            return nil
        }
        return plistKey
    }
    
    // Save a user-provided key to UserDefaults
    func saveUserAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: userAPIKeyKey)
        Logger.shared.log("🔑 Saved user-provided OpenAI API key.")
    }
    
    // Delete the user-provided key (reverts to Secrets.plist)
    func clearUserAPIKey() {
        UserDefaults.standard.removeObject(forKey: userAPIKeyKey)
        Logger.shared.log("🗑 Deleted user-provided OpenAI API key.")
    }
    
    
    func sendMessageToChatGPT(message: String, completion: @escaping (String?, Int, Double) -> Void) {
        guard let apiKey = self.getAPIKey() else {
            Logger.shared.log("❌ Error: OpenAI API Key not found.")
            completion("Error: API Key not found", 0, 0.0)
            return
        }
    }
    
    func transcribeAudio(from audioURL: URL, completion: @escaping (String?) -> Void) {
        let process = Process()
        guard let pythonURL = PythonLocator.resolvePython311() else {
            Logger.shared.log("❌ Python 3.11 not found. Install with: brew install python@3.11")
            completion(nil)
            return
        }

        process.executableURL = pythonURL
        process.environment = PythonLocator.subprocessEnvironment()

        guard let scriptPath = Bundle.main.path(forResource: "Transcript", ofType: "py") else {
            Logger.shared.log("❌ Transcript.py not found in bundle.")
            completion(nil)
            return
        }

        let scriptExists = FileManager.default.fileExists(atPath: scriptPath)
        let audioFileExists = FileManager.default.fileExists(atPath: audioURL.path)

        Logger.shared.log("📍 Transcript.py path: \(scriptPath) (exists: \(scriptExists))")
        Logger.shared.log("🎧 Audio file path: \(audioURL.path) (exists: \(audioFileExists))")

        process.arguments = [scriptPath, audioURL.path]
        Logger.shared.log("🚀 Running command: \(pythonURL.path) \(process.arguments?.joined(separator: " ") ?? "")")

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        var transcript = ""
        let handle = outputPipe.fileHandleForReading

        // Buffer for partial lines
        var lineBuffer = Data()

        // Use a DispatchGroup to signal completion
        let group = DispatchGroup()
        group.enter()

        process.terminationHandler = { _ in
            // Signal that process is done
            group.leave()
        }

        handle.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if data.isEmpty {
                // EOF
                return
            }
            // Append to buffer
            lineBuffer.append(data)
            // Split into lines
            while let range = lineBuffer.range(of: Data([UInt8(10)])) { // 10 is \n
                let lineData = lineBuffer.subdata(in: 0..<range.lowerBound)
                lineBuffer.removeSubrange(0...range.lowerBound)
                if let line = String(data: lineData, encoding: .utf8) {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.hasPrefix("[PROGRESS]") {
                        // Format: [PROGRESS] 67
                        let comps = trimmed.components(separatedBy: " ")
                        if comps.count > 1, let percent = Int(comps[1]) {
                            Logger.shared.log("⏳ Transcription progress: \(percent)%")
                        } else {
                            Logger.shared.log("⏳ Transcription progress: \(trimmed)")
                        }
                    } else if !trimmed.isEmpty {
                        Logger.shared.log("📝 \(trimmed)")
                        transcript += trimmed + "\n"
                    }
                }
            }
        }

        do {
            try process.run()
        } catch {
            Logger.shared.log("❌ Whisper transcription failed: \(error.localizedDescription)")
            completion(nil)
            return
        }

        // Wait for process to finish
        DispatchQueue.global(qos: .utility).async {
            group.wait()
            handle.readabilityHandler = nil
            // Capture any remaining data in buffer
            if !lineBuffer.isEmpty, let lastLine = String(data: lineBuffer, encoding: .utf8) {
                let trimmed = lastLine.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("[PROGRESS]") {
                    let comps = trimmed.components(separatedBy: " ")
                    if comps.count > 1, let percent = Int(comps[1]) {
                        Logger.shared.log("⏳ Transcription progress: \(percent)%")
                    } else {
                        Logger.shared.log("⏳ Transcription progress: \(trimmed)")
                    }
                } else if !trimmed.isEmpty {
                    Logger.shared.log("📝 \(trimmed)")
                    transcript += trimmed + "\n"
                }
            }
            Logger.shared.log("⚙️ Process terminated with status: \(process.terminationStatus)")
            let result = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            completion(result.isEmpty ? nil : result)
        }
    }
    
    func generateStudyNotes(from text: String, completion: @escaping (String, Int, Double) -> Void) {
        guard let apiKey = self.getAPIKey() else {
            Logger.shared.log("❌ Error: OpenAI API Key not found.")
            completion("Error: API Key not found", 0, 0.0)
            return
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        let prompt = self.currentPrompt.prompt + text

        let requestData: [String: Any] = [
            "model": "gpt-4.1-nano",
            "messages": [
                ["role": "system", "content": "Your role is to take transcripts from Lecutres and then transform them into studayble notes"],
                ["role": "user", "content": prompt ]
            ],
            "temperature": 0.3
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let jsonData = try? JSONSerialization.data(withJSONObject: requestData) {
            request.httpBody = jsonData
        } else {
            Logger.shared.log("❌ Error: Failed to encode JSON request.")
            completion("Error: Failed to encode request", 0, 0.0)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Enhanced error handling
            if let error = error {
                Logger.shared.log("❌ Error: \(error.localizedDescription)")
                completion("Error: \(error.localizedDescription)", 0, 0.0)
                return
            }

            guard let data = data else {
                Logger.shared.log("❌ Error: No data received.")
                completion("Error: No data received", 0, 0.0)
                return
            }

            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                if !(200...299).contains(httpResponse.statusCode) {
                    Logger.shared.log("❌ OpenAI API returned HTTP \(httpResponse.statusCode)")
                    var serverMessage = "HTTP \(httpResponse.statusCode)"
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let errorInfo = json["error"] as? [String: Any],
                       let message = errorInfo["message"] as? String {
                        serverMessage += ": \(message)"
                    }
                    completion("OpenAI API error: \(serverMessage)", 0, 0.0)
                    return
                }
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Check for OpenAI error in JSON
                    if let errorInfo = jsonResponse["error"] as? [String: Any],
                       let message = errorInfo["message"] as? String {
                        Logger.shared.log("❌ OpenAI error: \(message)")
                        completion("OpenAI error: \(message)", 0, 0.0)
                        return
                    }

                    // Extract content as before
                    if let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String,
                       let usage = jsonResponse["usage"] as? [String: Any],
                       let promptTokens = usage["prompt_tokens"] as? Int,
                       let completionTokens = usage["completion_tokens"] as? Int {

                        let inputCost = Double(promptTokens) * OpenAIModelPricing.gpt4_1_nanoInput
                        let outputCost = Double(completionTokens) * OpenAIModelPricing.gpt4_1_nanoOutput
                        let estimatedCost = inputCost + outputCost
                        let totalTokens = promptTokens + completionTokens

                        Logger.shared.log("✅ AI Response (Study Notes) generated successfully.")

                        completion(content, totalTokens, estimatedCost)
                    } else {
                        Logger.shared.log("❌ Error: Malformed OpenAI response, could not extract content or usage")
                        completion("Error: Malformed OpenAI response", 0, 0.0)
                    }
                } else {
                    Logger.shared.log("❌ Error: OpenAI response is not valid JSON")
                    completion("Error: OpenAI response is not valid JSON", 0, 0.0)
                }
            } catch {
                Logger.shared.log("❌ Error: Failed to parse JSON: \(error.localizedDescription)")
                completion("Error: Failed to parse JSON: \(error.localizedDescription)", 0, 0.0)
            }
        }
        task.resume()
    }
    
    // Estimate token count and cost from input text
    func estimateTokenCount(for text: String) -> Int {
        return text.count / 4 // Rough estimate: 1 token ≈ 4 characters
    }

    func estimateCost(for text: String) -> (tokens: Int, cost: Double) {
        let tokenCount = estimateTokenCount(for: text)
        let cost = Double(tokenCount) * OpenAIModelPricing.gpt4_1_nanoInput
        return (tokenCount, cost)
    }
}
