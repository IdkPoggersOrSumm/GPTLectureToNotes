//
//  SettingsMenuVisit.swift
//  LectureToNotes
//
//  Created by Jacob Rodriguez on 4/10/25.
//

//
//  SettingsMenuView.swift
//  LectureToNotes
//
//  Created by Jacob Rodriguez on 4/10/25.
//
import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct HamburgerMenu: View {
    @Binding var showSettingsMenu: Bool
    @State private var selectedSetting: String? = "General"
    @State private var showAPIKeyInput = false
    @State private var showPromptSelection = false
    @State private var showNotesView = false // Add this state
    @State private var showYouTubeInput = false
    @State private var youtubeLink: String = ""
    @State private var showPDFImporter = false
    @State private var transcriptionStartTime: Date? = nil
    @State private var transcriptionDuration: TimeInterval = 0
    @State private var timer: Timer? = nil
    

    
    let settingsOptions = [
        "Import Audio",
        "Storage",
        "API Key",


    ]
    
     struct PromptSelectionView: View {
            @Environment(\.presentationMode) var presentationMode
            @State private var selectedPrompt: PromptOption = OpenAIClient.shared.currentPrompt
            
            var body: some View {
                VStack(alignment: .leading) {
                    Text("Select Prompt Style")
                        .font(.headline)
                        .padding()
                    
                    List(PromptPresets.all) { prompt in
                        HStack {
                            Text(prompt.name)
                                .font(.system(size: 14))
                            Spacer()
                            if prompt.id == selectedPrompt.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPrompt = prompt
                            OpenAIClient.shared.setPrompt(prompt)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .listStyle(.plain)
                    
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .frame(width: 300, height: 400)
                .onAppear {
                    selectedPrompt = OpenAIClient.shared.currentPrompt
                }
            }
        }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 8)
            .background(Color(red: 18/255, green: 18/255, blue: 18/255))
            
            Divider()
            
            // Scrollable content with actions
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Audio Quality
 
                    SettingsRow(title: "Import Audio", isSelected: selectedSetting == "Audio Quality") {
                        startTranscriptionTimer()
                        AudioRecorder.shared.importAudioFile()
                        
                    }
                    .icon("square.and.arrow.down")
                    .font(.system(size: 18))
                
                    SettingsRow(title: "Import YouTube Audio", isSelected: false) {
                        showYouTubeInput.toggle()
                    }
                    .icon("play.rectangle")
                    .font(.system(size: 18))
                    .sheet(isPresented: $showYouTubeInput) {
                        VStack {
                            Text("Enter YouTube Link")
                                .font(.headline)
                                .padding(.top)
                            
                            TextField("https://youtube.com/...", text: $youtubeLink)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()

                            HStack {
                                Button("Cancel") {
                                    showYouTubeInput = false
                                }
                                .padding()

                                Spacer()

                                Button("Import") {
                                    startTranscriptionTimer()
                                    AudioRecorder.shared.importYouTubeAudio(from: youtubeLink)
                                    showYouTubeInput = false
                                }
                                .padding()
                                .disabled(youtubeLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                            .padding([.horizontal, .bottom])
                        }
                        .frame(width: 400, height: 180)
                        .padding()
                    }

                    SettingsRow(title: "Import PDF", isSelected: false) {
                        showPDFImporter.toggle()
                    }
                    .icon("doc.text")
                    .font(.system(size: 18))
                    .fileImporter(
                        isPresented: $showPDFImporter,
                        allowedContentTypes: [.pdf, .plainText, .rtf, .json],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            if let pdfURL = urls.first {
                                startTranscriptionTimer()
                                PDFImport.generateNotes(from: pdfURL) { notes in
                                    DispatchQueue.main.async {
                                        stopTranscriptionTimer()
                                        if let notes = notes {
                                            // Handle the notes (e.g. show in a view or save)
                                            print("Generated Notes: \(notes)")
                                        } else {
                                            print("Failed to generate notes from PDF.")
                                        }
                                    }
                                }
                            }
                        case .failure(let error):
                            print("Failed to import PDF: \(error.localizedDescription)")
                        }
                    }
               
                    // Example: In your SettingsView
                    SettingsRow(title: "OpenAI API Key", isSelected: false) {
                        // Present the API key input view (e.g., as a sheet or navigation link)
                        showAPIKeyInput.toggle()
                        
                    }
                    .icon("apple.intelligence")
                    .font(.system(size: 18))
           
                    // Storage
                    SettingsRow(title: "Storage", isSelected: selectedSetting == "Storage") {
                        selectedSetting = "Storage"
                        AudioRecorder.shared.openStorageDirectory()
                    }
                    .icon("folder")
                    .font(.system(size: 18))
                    

                    .sheet(isPresented: $showAPIKeyInput) {
                        APIKeyInputView()
                    }
                    
                    SettingsRow(title: "Clear Storage", isSelected: false) {
                        AudioRecorder.shared.clearStorageDirectory()
                    }
                    .icon("trash")
                    .font(.system(size: 18))
                    
                    SettingsRow(title: "OpenAI Prompt", isSelected: false) {
                        showPromptSelection.toggle()
                        
                    }
                    .icon("text.bubble")
                    .font(.system(size: 18))
                  
                    .sheet(isPresented: $showPromptSelection) {
                        PromptSelectionView()
                    }
                    
                    SettingsRow(title: "Open Quizlet", isSelected: false) {
                        if let url = URL(string: "https://quizlet.com/create-set") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .icon("safari") // Optional icon
                    .font(.system(size: 18))
                    
              

                           
                }
                .background(Color(red: 18/255, green: 18/255, blue: 18/255))
                
                
            }
            .background(Color(red: 18/255, green: 18/255, blue: 18/255))
            
            if let startTime = transcriptionStartTime {
                HStack {
                    Text("⏱️ Transcribing: \(formattedDuration(transcriptionDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(Color(red: 18/255, green: 18/255, blue: 18/255))
            }
        
                
            
            Divider()
                .padding(.bottom, 8)
                .background(Color(red: 18/255, green: 18/255, blue: 18/255))
            
        // MARK: - Version Editor
            
            // Footer
            HStack {
                Spacer()
                Text("v2.2.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            .background(Color(red: 18/255, green: 18/255, blue: 18/255))
        }
        .background(Color(red: 18/255, green: 18/255, blue: 18/255))
        .frame(maxHeight: .infinity)
        .onAppear {
            NotificationCenter.default.addObserver(forName: Notification.Name("StopTranscriptionTimer"), object: nil, queue: .main) { _ in
                stopTranscriptionTimer()
            }
            
        }
        
    }
// MARK: - Action Handlers

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startTranscriptionTimer() {
        transcriptionStartTime = Date()
        transcriptionDuration = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let start = transcriptionStartTime {
                transcriptionDuration = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopTranscriptionTimer() {
        timer?.invalidate()
        timer = nil
        // Do not reset transcriptionStartTime to preserve display
    }
    
    private func handleAudioQualityTap() {
        print("Audio Quality settings tapped")
        // Add your audio quality settings logic here
        // Example: show audio quality options
    }
    
    private func handleMicrophoneTap() {
        print("Microphone settings tapped")
        // Add microphone selection logic here
    }
    
    private func handleStorageTap() {
        print("Storage settings tapped")
        // Add storage management logic here
    }
    
    private func handleTranscriptionTap() {
        print("Transcription settings tapped")
        // Add transcription options logic here
    }
    
    private func handleAppearanceTap() {
        print("Appearance settings tapped")
        // Add theme/color scheme logic here
    }
    
    private func handleKeyboardShortcutsTap() {
        print("Keyboard Shortcuts tapped")
        // Add keyboard shortcuts configuration
    }
    
    private func handleAboutTap() {
        print("About tapped")
        // Show about dialog or version info
    }
}

struct SettingsRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var iconName: String?
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Icon view (if provided)
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .frame(width: 20)
                }
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .background(isSelected ? Color.clear : Color(red: 18/255, green: 18/255, blue: 18/255))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.clear : Color(red: 18/255, green: 18/255, blue: 18/255))
        
    }
            //  .background(audioRecorder.isRecording ? Color.clear : Color(red: 0/255, green: 0/255, blue: 0/255))
    

    
    func icon(_ systemName: String) -> SettingsRow {
        var view = self
        view.iconName = systemName
        return view
    }
}
