//
//  ConsoleOutput.swift
//  LectureToNotes
//
//  Created by Jacob Rodriguez on 3/28/25.
//

import Foundation
import Combine

class ConsoleOutput: ObservableObject {
    static let shared = ConsoleOutput()
    
    @Published var consoleText: String = ""
    
    private var pipe = Pipe()
    
    init() {
        startCapturing()
    }
    
    private func startCapturing() {
        // Redirect stdout and stderr to our Pipe poggy
        let outputPipe = Pipe()
        dup2(outputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(outputPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        // Continuously read the output
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            let data = fileHandle.availableData
            if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                DispatchQueue.main.async {
                    self?.consoleText += text
                }
            }
        }
    }
}
