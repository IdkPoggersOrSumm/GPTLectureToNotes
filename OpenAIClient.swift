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
    static let gpt4_1_nano: Double = 0.000002
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
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3") // Ensure correct Python version

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
        Logger.shared.log("🚀 Running command: /usr/bin/python3 \(process.arguments?.joined(separator: " ") ?? "")")

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
            process.waitUntilExit()
            Logger.shared.log("⚙️ Process terminated with status: \(process.terminationStatus)")
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                Logger.shared.log("🔍 Whisper Output: \(output)")
                completion(output.trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                Logger.shared.log("❌ Whisper output was nil.")
                completion(nil)
            }
        } catch {
            Logger.shared.log("❌ Whisper transcription failed: \(error.localizedDescription)")
            completion(nil)
        }
    }

    func generateStudyNotes(from audioURL: URL, completion: @escaping (String, Int, Double) -> Void) {
        
        transcribeAudio(from: audioURL) { transcription in
            guard let transcription = transcription, !transcription.isEmpty else {
                DispatchQueue.main.async {
                    AudioRecorder.shared.formattedNotes = "Error: Failed to transcribe audio"
                }
                completion("Error: Failed to transcribe audio", 0, 0.0)
                return
            }

            guard let apiKey = self.getAPIKey() else {
                Logger.shared.log("❌ Error: OpenAI API Key not found.")
                DispatchQueue.main.async {
                    AudioRecorder.shared.formattedNotes = "Error: API Key not found"
                }
                completion("Error: API Key not found", 0, 0.0)
                return
            }

            let url = URL(string: "https://api.openai.com/v1/chat/completions")!
            
            let prompt = self.currentPrompt.prompt + transcription
            
            let requestData: [String: Any] = [
                "model": "gpt-4.1-nano",
                "messages": [
                    ["role": "system", "content": "Your role is to take transcripts from Lecutres and then transform them into studayble notes"],
                    ["role": "user", "content": prompt ]
                ],
                "temperature": 0.7
            ]

            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
                Logger.shared.log("❌ Error: Failed to encode JSON request.")
                DispatchQueue.main.async {
                    AudioRecorder.shared.formattedNotes = "Error: Failed to encode request"
                }
                completion("Error: Failed to encode request", 0, 0.0)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    Logger.shared.log("❌ Error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        AudioRecorder.shared.formattedNotes = "Error: \(error.localizedDescription)"
                    }
                    completion("Error: \(error.localizedDescription)", 0, 0.0)
                    return
                }

                guard let data = data else {
                    Logger.shared.log("❌ Error: No data received.")
                    DispatchQueue.main.async {
                        AudioRecorder.shared.formattedNotes = "Error: No data received"
                    }
                    completion("Error: No data received", 0, 0.0)
                    return
                }

                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String,
                       let usage = jsonResponse["usage"] as? [String: Any],
                       let totalTokens = usage["total_tokens"] as? Int {

                        let costPerToken = 0.0000004 // Adjust based on actual pricing
                        let estimatedCost = Double(totalTokens) * costPerToken

                        Logger.shared.log("✅ AI Response (Study Notes): \(content)")
                        Logger.shared.log(" Tokens Used: \(totalTokens)")
                        Logger.shared.log("Estimated Cost: $\(String(format: "%.4f", estimatedCost))")

                        DispatchQueue.main.async {
                            AudioRecorder.shared.formattedNotes = content // Update the UI
                            completion(content, totalTokens, estimatedCost)
                        }

                        completion(content, totalTokens, estimatedCost)
                    } else {
                        Logger.shared.log("❌ Error: Failed to parse OpenAI response.")
                        DispatchQueue.main.async {
                            AudioRecorder.shared.formattedNotes = "Error: Failed to parse response"
                        }
                        completion("Error: Failed to parse response", 0, 0.0)
                    }
                } catch {
                    Logger.shared.log("❌ Error: Failed to parse JSON: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        AudioRecorder.shared.formattedNotes = "Error: Failed to parse JSON"
                    }
                    completion("Error: Failed to parse JSON", 0, 0.0)
                }
            }

            task.resume()
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
            "temperature": 0.7
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

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String,
                   let usage = jsonResponse["usage"] as? [String: Any],
                   let totalTokens = usage["total_tokens"] as? Int {

                    let costPerToken = 0.000002 // Adjust based on actual pricing
                    let estimatedCost = Double(totalTokens) * costPerToken

                    Logger.shared.log("✅ AI Response (Study Notes): \(content)")
                    Logger.shared.log(" Tokens Used: \(totalTokens)")
                    Logger.shared.log("Estimated Cost: $\(String(format: "%.4f", estimatedCost))")

                    completion(content, totalTokens, estimatedCost)
                } else {
                    Logger.shared.log("❌ Error: Failed to parse OpenAI response.")
                    completion("Error: Failed to parse response", 0, 0.0)
                }
            } catch {
                Logger.shared.log("❌ Error: Failed to parse JSON: \(error.localizedDescription)")
                completion("Error: Failed to parse JSON", 0, 0.0)
            }
        }

        task.resume()
    }
}

    // Estimate token count and cost from input text
    func estimateTokenCount(for text: String) -> Int {
        return text.count / 4 // Rough estimate: 1 token ≈ 4 characters
    }

    func estimateCost(for text: String, costPerToken: Double = OpenAIModelPricing.gpt4_1_nano) -> (tokens: Int, cost: Double) {
        let tokenCount = estimateTokenCount(for: text)
        let cost = Double(tokenCount) * costPerToken
        return (tokenCount, cost)
    }
