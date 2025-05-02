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
    
    let settingsOptions = [
        "Import Audio",
        "Storage",
        "API Key",

    ]
    
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
                  
                    
                }
            }
            
            Spacer()
            
            Divider()
                .padding(.bottom, 8)
            
        // MARK: Version Editor
            
            // Footer
            HStack {
                Spacer()
                Text("v1.2.0")
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
