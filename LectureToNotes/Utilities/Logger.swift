//
//  Logger.swift
//  LectureToNotes
//
//  Created by Jacob Rodriguez on 3/30/25.
//

import Foundation
import Foundation
import Combine

class Logger: ObservableObject {  // Conforming to ObservableObject
    static let shared = Logger()
    
    @Published var consoleOutput: String = ""  // Bindable for UI updates
    private init() {}

    func log(_ message: String) {
        DispatchQueue.main.async {
            self.consoleOutput += message + "\n"
            
            // Keep only the last 2 lines
            let lines = self.consoleOutput.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            let lastTwoLines = lines.suffix(2).joined(separator: "\n")
            self.consoleOutput = lastTwoLines
            
            self.objectWillChange.send()
            print(message)
        }
    }
}
