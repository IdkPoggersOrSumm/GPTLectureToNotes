import SwiftUI

@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("✅ App UI loaded successfully.") //test
                }
        }
    }
}
