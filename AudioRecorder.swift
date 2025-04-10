import AVFoundation
import Combine
import AppKit


extension Notification.Name {
    static let startWaveform = Notification.Name("startWaveform")
    static let stopWaveform = Notification.Name("stopWaveform")
}


class AudioRecorder: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    @Published var audioFileURL: URL?
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var formattedNotes: String? = "Waiting for transcription..."
    @Published var isTranscribing = false
    @Published var isGeneratingNotes = false
    @Published var transcribedNotes: String? = "Transcription in progress..."
    @Published var consoleOutput: String = ""
    @Published var audioPower: Double = 0.0 // 🔥 Stores real-time audio level
    
    
    


    static let shared = AudioRecorder() // Singleton instance

    override init() {
        super.init()
        requestMicrophoneAccess()
    }
    
    private func logToConsole(_ message: String) {
        DispatchQueue.main.async {
            self.consoleOutput = message  // Overwrite with the latest message
            print(self.consoleOutput)     // Also print to Xcode console
        }
    }
    
    func redoTranscription() {
            // Logic to redo the transcription
        }

    func startRecording() {
        Logger.shared.log("🎤 Starting new recording...")

        // Reset state for new session
        DispatchQueue.main.async {
            self.formattedNotes = "Waiting for transcription..."
            self.transcribedNotes = nil
            self.isGeneratingNotes = false
            self.isTranscribing = false
        }

        // Create custom directory in Downloads if it doesn't exist
        let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let customDir = downloadsDir.appendingPathComponent("LectureToNotesCache")
        
        do {
            try FileManager.default.createDirectory(at: customDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Logger.shared.log("❌ Failed to create directory: \(error.localizedDescription)")
        }
        
        // Create unique filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let audioFilename = customDir.appendingPathComponent("lecture_\(timestamp).m4a")
        
        Logger.shared.log("📁 Saving recording to: \(audioFilename.path)")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            audioRecorder?.isMeteringEnabled = true // ✅ Enable metering to track volume
            audioRecorder?.record()
            
            // Start monitoring audio levels
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                guard let recorder = self.audioRecorder, recorder.isRecording else {
                    timer.invalidate() // Stop timer if recording stops
                    return
                }
                
                recorder.updateMeters()
                let power = pow(10, recorder.averagePower(forChannel: 0) / 20) // Convert to linear scale

                // Boost amplitude by a factor of 2 (or change this to whatever suits your needs)
                let boostedPower = power * 100.0 // Boost the power level by a factor (e.g., 2.0)
                
                DispatchQueue.main.async {
                    self.audioPower = Double(min(boostedPower, 50.0)) // Ensure power value doesn't exceed 1.0
                }
                
                recorder.updateMeters()
                DispatchQueue.main.async {
                    self.audioPower = Double(power) // ✅ Convert Float to Double
                }
            }

            DispatchQueue.main.async {
                self.audioFileURL = audioFilename
                self.isRecording = true
                self.isPaused = false
                DispatchQueue.main.async{
                    Logger.shared.log("✅ Recording started successfully.")
                }
                
                NotificationCenter.default.post(name: .startWaveform, object: nil)
            }
        } catch {
            Logger.shared.log("❌ Failed to start recording: \(error.localizedDescription)")
        }
    }

    func pauseRecording() {
        Logger.shared.log("⏸ Attempting to pause recording...")
        guard let recorder = audioRecorder, recorder.isRecording else {
            Logger.shared.log("⚠️ Cannot pause: No active recording.")
            return
        }
        recorder.pause()
        DispatchQueue.main.async {
            self.isPaused = true
            Logger.shared.log("✅ Recording paused.")
        }
    }

    func resumeRecording() {
        Logger.shared.log("▶️ Attempting to resume recording...")
        guard let recorder = audioRecorder, !recorder.isRecording else {
            Logger.shared.log("⚠️ Cannot resume: No paused recording.")
            return
        }
        recorder.record() // ✅ Actually resume recording
        DispatchQueue.main.async {
            self.isPaused = false
            self.isRecording = true
            Logger.shared.log("✅ Recording resumed.")
        }
    }

    func stopRecording() {
        Logger.shared.log("🛑 Attempting to stop recording...")
        guard let recorder = audioRecorder else {
            Logger.shared.log("⚠️ Cannot stop: No active recording.")
            return
        }
        recorder.stop()
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.isPaused = false
            self.audioRecorder = nil
            Logger.shared.log("✅ Recording stopped.")
            NotificationCenter.default.post(name: .stopWaveform, object: nil)
            self.audioPower = 0.0 // 🔥 Reset power level when recording stops


            if let fileURL = self.audioFileURL {
                Logger.shared.log("📁 Recorded file available at: \(fileURL.path)")
                if !self.isTranscribing { // Prevent duplicate calls
                    self.isTranscribing = true
                    self.transcribeRecording(audioFile: fileURL)
                }
            } else {
                Logger.shared.log("❌ No valid audio file URL after stopping recording.")
            }
        }
    }

    private func requestMicrophoneAccess() {
        Logger.shared.log("🔊 Requesting microphone access...")
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                if granted {
                    Logger.shared.log("✅ Microphone access granted.")
                } else {
                    Logger.shared.log("❌ Microphone access denied.")
                }
            }
        }
    }

    func transcribeRecording(audioFile: URL) {
        Logger.shared.log("📝 Sending file to WhisperAI for transcription: \(audioFile.path)")
        
        guard !self.isGeneratingNotes else {
            Logger.shared.log("⚠️ Notes are already being generated. Skipping duplicate request.")
            return
        }
        
        self.isGeneratingNotes = true

        WhisperAI.shared.transcribeAudio(audioURL: audioFile) { transcription in
            DispatchQueue.main.async {
                if let transcription = transcription {
                    Logger.shared.log("✅ Transcription completed. Preparing to generate study notes...")
                    self.transcribedNotes = transcription
                    
                    // Get the parent directory of the audio file
                    let audioDirectory = audioFile.deletingLastPathComponent()
                    let baseFilename = audioFile.deletingPathExtension().lastPathComponent
                    
                    // Save transcript to same directory as audio
                    let transcriptFile = audioDirectory.appendingPathComponent("\(baseFilename)_transcript.txt")
                    do {
                        try transcription.write(to: transcriptFile, atomically: true, encoding: .utf8)
                        Logger.shared.log("📄 Transcript saved to: \(transcriptFile.path)")
                        print("Transcript saved at: \(transcriptFile.path)")
                    } catch {
                        Logger.shared.log("❌ Failed to save transcript: \(error.localizedDescription)")
                    }

                    OpenAIClient.shared.generateStudyNotes(from: audioFile) { notes, tokens, cost in
                        DispatchQueue.main.async {
                            Logger.shared.log("✅ Notes successfully generated.")
                            self.formattedNotes = notes
                            self.isGeneratingNotes = false
                            self.isTranscribing = false
                            
                            // Save notes to same directory (no optional binding needed)
                            let notesFile = audioDirectory.appendingPathComponent("\(baseFilename)_notes.txt")
                            do {
                                try notes.write(to: notesFile, atomically: true, encoding: .utf8)
                                Logger.shared.log("📝 Notes saved to: \(notesFile.path)")
                                print("Notes saved at: \(notesFile.path)")
                            } catch {
                                Logger.shared.log("❌ Failed to save notes: \(error.localizedDescription)")
                            }
                        }
                    }
                } else {
                    Logger.shared.log("❌ Transcription failed.")
                    self.transcribedNotes = "Transcription failed."
                    self.formattedNotes = "Transcription failed."
                    self.isGeneratingNotes = false
                    self.isTranscribing = false
                }
            }
        }
    }
    
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            Logger.shared.log("✅ Recording saved at: \(recorder.url.path)")
            transcribeRecording(audioFile: recorder.url)
        } else {
            Logger.shared.log("❌ Recording failed.")
            DispatchQueue.main.async {
                self.isRecording = false
                self.isPaused = false
            }
        }
    }
}
