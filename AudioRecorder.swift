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
    @Published var audioPower: Double = 0.0
    private var powerUpdateTimer: Timer?
    private var lastPower: Float = 0.0
    
    static let shared = AudioRecorder()

    override init() {
        super.init()
        requestMicrophoneAccess()
    }
    
    func openStorageDirectory() {
        let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let customDir = downloadsDir.appendingPathComponent("LectureToNotesCache")
        
        if FileManager.default.fileExists(atPath: customDir.path) {
            NSWorkspace.shared.open(customDir)
            Logger.shared.log("📂 Opened storage directory: \(customDir.path)")
        } else {
            do {
                try FileManager.default.createDirectory(at: customDir, withIntermediateDirectories: true, attributes: nil)
                NSWorkspace.shared.open(customDir)
                Logger.shared.log("📂 Created and opened storage directory: \(customDir.path)")
            } catch {
                Logger.shared.log("❌ Failed to create directory: \(error.localizedDescription)")
            }
        }
    }
    
    func importAudioFile() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select an Audio File"
        openPanel.allowedContentTypes = [.audio]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false

        openPanel.begin { response in
            if response == .OK, let selectedFileURL = openPanel.url {
                DispatchQueue.main.async {
                    self.audioFileURL = selectedFileURL
                    self.isTranscribing = true
                    Logger.shared.log("🎵 Selected audio file: \(selectedFileURL.lastPathComponent)")
                    self.transcribeRecording(audioFile: selectedFileURL)
                }
            } else {
                Logger.shared.log("⚠️ File selection canceled or failed.")
            }
        }
    }
    
    private func logToConsole(_ message: String) {
        DispatchQueue.main.async {
            self.consoleOutput = message
            print(self.consoleOutput)
        }
    }
    
    func redoTranscription() {
        // Logic to redo the transcription
    }

    func startRecording() {
        Logger.shared.log("🎤 Starting new recording...")
        
        DispatchQueue.main.async {
            self.formattedNotes = "Waiting for transcription..."
            self.transcribedNotes = nil
            self.isGeneratingNotes = false
            self.isTranscribing = false
        }

        let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let customDir = downloadsDir.appendingPathComponent("LectureToNotesCache")
        
        do {
            try FileManager.default.createDirectory(at: customDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Logger.shared.log("❌ Failed to create directory: \(error.localizedDescription)")
        }
        
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
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            // Reset power state
            lastPower = 0.0
            audioPower = 0.0
            
            // Create and schedule timer on main run loop
            powerUpdateTimer?.invalidate()
            powerUpdateTimer = Timer.scheduledTimer(
                withTimeInterval: 0.05, // Faster updates for smoother visualization
                repeats: true
            ) { [weak self] _ in
                guard let self = self else { return }
                
                self.audioRecorder?.updateMeters()
                let dB = self.audioRecorder?.averagePower(forChannel: 0) ?? -80.0
                
                // Convert dB to linear scale (0-1) with better sens itivity
                let linearPower = pow(10, (dB + 5) / 20) // More responsive to low volume // Adjust +60 to control sensitivity
                
                // Apply smoothing and scaling
                let smoothedPower = (self.lastPower * 0.7) + (linearPower * 0.3)
                let scaledPower = min(smoothedPower * 7, 1.0) // Taller waveform // Scale up for better visibility
                
                DispatchQueue.main.async {
                    self.audioPower = Double(scaledPower)
                }
                
                self.lastPower = smoothedPower
            }
            
            // Add timer to main run loop
            RunLoop.main.add(powerUpdateTimer!, forMode: .common)
            
            DispatchQueue.main.async {
                self.audioFileURL = audioFilename
                self.isRecording = true
                self.isPaused = false
                Logger.shared.log("✅ Recording started successfully.")
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
        recorder.record()
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
        
        powerUpdateTimer?.invalidate()
        powerUpdateTimer = nil
        recorder.stop()

        DispatchQueue.main.async {
            self.isRecording = false
            self.isPaused = false
            self.audioRecorder = nil
            self.audioPower = 0.0
            Logger.shared.log("✅ Recording stopped.")
            NotificationCenter.default.post(name: .stopWaveform, object: nil)
        }

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
            if let fileURL = self.audioFileURL {
                self.transcribeRecording(audioFile: fileURL)
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
    
    func clearStorageDirectory() {
        let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let customDir = downloadsDir.appendingPathComponent("LectureToNotesCache")
        
        do {
            let fileManager = FileManager.default
            let fileURLs = try fileManager.contentsOfDirectory(at: customDir, includingPropertiesForKeys: nil, options: [])
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            Logger.shared.log("🧹 Cleared all files in storage directory.")
            }
            Logger.shared.log("🧹 Cleared all files in storage directory.")
        } catch {
            Logger.shared.log("❌ Failed to clear storage: \(error.localizedDescription)")
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
                    
                    let audioDirectory = audioFile.deletingLastPathComponent()
                    let baseFilename = audioFile.deletingPathExtension().lastPathComponent
                    let transcriptFile = audioDirectory.appendingPathComponent("\(baseFilename)_transcript.txt")
                    
                    do {
                        try transcription.write(to: transcriptFile, atomically: true, encoding: .utf8)
                        Logger.shared.log("📄 Transcript saved to: \(transcriptFile.path)")
                    } catch {
                        Logger.shared.log("❌ Failed to save transcript: \(error.localizedDescription)")
                    }

                    OpenAIClient.shared.generateStudyNotes(from: audioFile) { notes, tokens, cost in
                        DispatchQueue.main.async {
                            Logger.shared.log("✅ Notes successfully generated.")
                            self.formattedNotes = notes
                            self.isGeneratingNotes = false
                            self.isTranscribing = false
                            
                            let notesFile = audioDirectory.appendingPathComponent("\(baseFilename)_notes.txt")
                            do {
                                try notes.write(to: notesFile, atomically: true, encoding: .utf8)
                                Logger.shared.log("📝 Notes saved to: \(notesFile.path)")
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
