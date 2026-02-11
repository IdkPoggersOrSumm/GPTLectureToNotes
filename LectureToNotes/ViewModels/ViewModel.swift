//
//  ViewModel.swift
//  LectureToNotes
//
//  Created by Jacob Rodriguez on 3/30/25.
//

import Foundation
import AVFoundation
import Observation


@Observable
class ViewModel: NSObject {
    
    
    var state = WaveFormView.idle{
        didSet { print(state)}
    }
    var isIdle: Bool {
        if case .idle = state{
            return true
        }
        return false
    }
    var audiopower = 0.0

    
    
    
    
    
    
    enum WaveFormView { //File That I didnt wanna create
        case idle
        case recording
    }
}
