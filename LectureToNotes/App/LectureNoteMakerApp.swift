import SwiftUI
import Combine

@main
struct LectureNoteMakerApp: App {
    @StateObject var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .commands {
            ContentViewMenuCommands(disableIntroSlides: {
                appState.showInitialIntro = false
                appState.showWhatsNew = false
                appState.whispermodeldownload = false
            })
        }
    }
}   
