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

struct HamburgerMenu: View {
    @Binding var showSettingsMenu: Bool
    @State private var selectedSetting: String? = "General"
    @State private var showAPIKeyInput = false
    @State private var showPromptSelection = false
    
    let settingsOptions = [
        "Import Audio",
        "Storage",
        "API Key",
        "OpenAI Prompt",

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
            
            Divider()
            
            // Scrollable content with actions
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Audio Quality
 
                    SettingsRow(title: "Import Audio", isSelected: selectedSetting == "Audio Quality") {
                       
                        AudioRecorder.shared.importAudioFile()
                        
                    }
                    .icon("square.and.arrow.down")
                    .font(.system(size: 18))
                
               
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
                }
            }
            
            Spacer()
            
            Divider()
                .padding(.bottom, 8)
            
        // MARK: Version Editor
            
            // Footer
            HStack {
                Spacer()
                Text("v1.3.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(
            Color(NSColor.controlBackgroundColor)
                .edgesIgnoringSafeArea(.all)
        )
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Action Handlers
    
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
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
    
    

    
    func icon(_ systemName: String) -> SettingsRow {
        var view = self
        view.iconName = systemName
        return view
    }
}
