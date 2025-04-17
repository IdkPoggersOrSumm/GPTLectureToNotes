//
//  APIKeyUpdater.swift
//  LectureToNotes
//
//  Created by Jacob Rodriguez on 4/16/25.
//

import SwiftUI

struct APIKeyInputView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var apiKeyInput = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // This invisible rectangle will capture taps outside the content
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                }
            
            VStack(alignment: .leading, spacing: 20) {
                Text("OpenAI API Key Configuration")
                    .font(.title2)
                    .padding(.bottom, 10)
                
                Text("Enter your OpenAI API key. This will override any key in Secrets.plist.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                SecureField("sk-...", text: $apiKeyInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical)
                
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    Spacer()
                    
                    Button("Save") {
                        saveAPIKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKeyInput.isEmpty)
                }
            }
            .padding()
            .frame(minWidth: 400, minHeight: 200)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(10)
            .shadow(radius: 5)
            // This prevents taps inside the content from dismissing
            .onTapGesture {}
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("API Key"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                  })
        }
        .onAppear {
            if let currentKey = OpenAIClient.shared.getAPIKey() {
                apiKeyInput = currentKey
            }
        }
    }
    
    private func saveAPIKey() {
        guard !apiKeyInput.isEmpty else {
            alertMessage = "Please enter a valid API key."
            showAlert = true
            return
        }
        
        OpenAIClient.shared.saveUserAPIKey(apiKeyInput)
        alertMessage = "API key saved successfully!"
        showAlert = true
    }
}
