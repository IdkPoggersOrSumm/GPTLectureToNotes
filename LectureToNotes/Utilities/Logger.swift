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
            self.consoleOutput = message // Update the console output
            self.objectWillChange.send() // Notify SwiftUI to update the view
            print(message) // Also print to Xcode console
        }
    }
}
