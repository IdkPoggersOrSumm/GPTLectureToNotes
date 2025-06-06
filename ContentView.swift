import SwiftUI
import AppKit
import SiriWaveView

// MARK: - WhatsNew Feature Modal Support
struct WhatsNewItem: Identifiable {
    var id = UUID()
    var icon: String
    var title: String
    var subtitle: String
}

struct WhatsNewView: View {
    var items: [WhatsNewItem]
    var onContinue: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 30) {
                Text("Welcome to Applesauce")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 25) {
                    ForEach(items) { item in
                        WhatsNewItemView(item: item)
                    }
                }

                Spacer()

                Button(action: {
                    onContinue()
                })
                {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 40)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(30)
            .background(Color(red: 28/255, green: 28/255, blue: 28/255))
            .cornerRadius(20)
            .shadow(radius: 10)
            .frame(
                width: geometry.size.width * 0.8,
                height: geometry.size.height * 0.8,
                alignment: .center
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

struct WhatsNewItemView: View {
    var item: WhatsNewItem

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: item.icon)
                .foregroundColor(.blue)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                if item.subtitle.contains("Paste this in Terminal:") {
                    CopyButton(text: item.subtitle.components(separatedBy: "Paste this in Terminal:\n").last ?? item.subtitle)
                }
                if item.subtitle.contains("--model") {
                    CopyButton(text: item.subtitle.components(separatedBy: "Command: ").last ?? item.subtitle)
                }
                if item.subtitle.contains("pip3") {
                    CopyButton(text: item.subtitle.components(separatedBy: "Command: ").last ?? item.subtitle)
                }
            }
        }
    }
}

struct CopyButton: View {
    var text: String

    var body: some View {
        Button(action: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }) {
            Image(systemName: "doc.on.doc")
                .foregroundColor(.gray)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
}

extension String {
    func asMarkdownAttributed() -> AttributedString {
        do {
            let attributedString = try AttributedString(
                markdown: self,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )
            return attributedString
        } catch {
            print("❌ Error parsing Markdown: \(error)")
            return AttributedString(self)
        }
    }
}
// MARK: - Regular ContentView
struct ContentView: View {
    @ObservedObject var audioRecorder = AudioRecorder.shared
    @State private var isHovering = false
    @State private var amplitude: Double = 0.5
    @State private var frequency: Double = 1.0
    @State private var power: Double = 1.0
    @State var vm = ViewModel()
    @State private var showSettingsMenu = false

    // MARK: - First Launch "What's New" State
    @State private var showInitialIntro = true
    @State private var showWhatsNew = false
    @State private var whispermodeldownload = false
    
    
    
    // MARK: - Rest of Regular ContentView
    var body: some View {
        ZStack {
            // Onboarding: Initial Intro
            if showInitialIntro {
                WhatsNewView(items: [
                    WhatsNewItem(icon: "sparkles", title: "Welcome to Applesauce", subtitle: "I've made this app specifically so that we don't have to pay attention to every little class detail in order to pass"),
                    WhatsNewItem(icon: "waveform", title: "How it Works", subtitle: "In short, this app will have you record your lecture audio (or insert audio/text via Youtube Link or file upload) and then automatically transcribe it into a readable format, and THEN send it to OpenAI to be turned into notes"),
                    WhatsNewItem(icon: "doc.text", title: "Before we Proceed", subtitle: "Your going to have to manually download some software, but don't worry, it's not too hard! Please make sure you have AT LEAST 12GB of storage free (You absolutely will not need to use all of this storage, but its just incase) I've added the steps to download each dependancy in the following slide!")
                ]) {
                    withAnimation {
                        showInitialIntro = false
                        showWhatsNew = true
                    }
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
            // Onboarding: Installation Instructions
            else if showWhatsNew {
                WhatsNewView(items: [
                    WhatsNewItem(icon: "terminal.fill",
                                 title: "Install Homebrew",
                                 subtitle: "Paste this in Terminal:\n/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""),
                    WhatsNewItem(icon: "terminal.fill",
                                 title: "Install Python 3.11 + pip",
                                 subtitle: "Paste this in Terminal:\nbrew install python@3.11"),
                    WhatsNewItem(icon: "terminal.fill",
                                 title: "Add Python 3.11 to PATH",
                                 subtitle: "Paste this in Terminal:\necho 'export PATH=\"/opt/homebrew/opt/python@3.11/bin:$PATH\"' >> ~/.zshrc && source ~/.zshrc"),
                    WhatsNewItem(icon: "terminal.fill",
                                 title: "Install Required Python Packages",
                                 subtitle: "Paste this in Terminal:\n/opt/homebrew/opt/python@3.11/bin/python3.11 -m pip install openai-whisper torch"),
                    WhatsNewItem(icon: "terminal.fill",
                                 title: "Install pydub",
                                 subtitle: "Paste this in Terminal:\n/opt/homebrew/opt/python@3.11/bin/python3.11 -m pip install pydub"),
                    WhatsNewItem(icon: "terminal.fill",
                                 title: "Install FFmpeg",
                                 subtitle: "Paste this in Terminal:\nbrew install ffmpeg"),
                    WhatsNewItem(icon: "terminal.fill",
                                 title: "Install yt-dlp",
                                 subtitle: "Paste this in Terminal:\nbrew install yt-dlp")
                ]) {
                    withAnimation {
                        showWhatsNew = false
                        whispermodeldownload = true
                    }
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
            else if whispermodeldownload {
                WhatsNewView(items: [
                    WhatsNewItem(icon: "apple.intelligence",
                                 title: "Download Whisper",
                                 subtitle: "pip3 install --break-system-packages git+https://github.com/openai/whisper.git"),

                ]) {
                    withAnimation {
                        whispermodeldownload = false
                    }
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
            // Main Content
            else {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Settings Menu (left panel)
                        if showSettingsMenu {
                            HamburgerMenu(showSettingsMenu: $showSettingsMenu)
                                .frame(width: 200)
                                .transition(.move(edge: .leading))
                        }

                        // Main Content Area
                        VStack(spacing: 5) {
                            // Top controls with settings button
                            HStack() {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showSettingsMenu.toggle()
                                    }
                                }) {
                                    Image(systemName: showSettingsMenu ? "sidebar.left" : "line.3.horizontal")
                                        .padding(8)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())

                                Spacer()
                            }
                            .padding(.horizontal)
                            .offset(y: 3)
                            .offset(x:-15)
    // MARK: - Recording Controls
                            // Recording Controls
                            HStack(spacing: 20) {
                                Button(action: {
                                    audioRecorder.startRecording()
                                    let vm = ViewModel()
                                    vm.state = .recording
                                }) {

                                    Text("Start")
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(audioRecorder.isRecording ? Color.clear : Color(red: 161/255, green: 101/255, blue: 239/255))
                                        .foregroundColor(.white)
                                        .cornerRadius(100)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(audioRecorder.isRecording)

                                Button(action: {
                                    if audioRecorder.isPaused {
                                        audioRecorder.resumeRecording()
                                    } else {
                                        audioRecorder.pauseRecording()
                                    }
                                }) {
                                    Text(audioRecorder.isPaused ? "Resume" : "Pause")
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(audioRecorder.isPaused ? Color.green : (audioRecorder.isRecording ? Color(red: 3/255, green: 218/255, blue: 197/255) : Color.clear))
                                        .foregroundColor(.white)
                                        .cornerRadius(100)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(!audioRecorder.isRecording && !audioRecorder.isPaused)

                                Button(action: {
                                    audioRecorder.stopRecording()
                                    let vm = ViewModel()
                                    vm.state = .idle
                                }) {
                                    Text("Stop")
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(audioRecorder.isRecording || audioRecorder.isPaused ? Color(red: 161/255, green: 101/255, blue: 239/255) : Color.clear)
                                        .foregroundColor(.white)
                                        .cornerRadius(100)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(!audioRecorder.isRecording && !audioRecorder.isPaused)
                            }
                            .padding(.horizontal)

                            Spacer()

    // MARK: - Lecture Notes Section

                            // Lecture Notes Section
                            Text("Lecture Notes")
                                .font(.headline)
                                .padding(.top)

                            ScrollView {
                                ZStack(alignment: .topTrailing) {
                                    Text(audioRecorder.formattedNotes?.isEmpty == false ?
                                         audioRecorder.formattedNotes!.asMarkdownAttributed() : "Processing notes...")
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(red: 18/255, green: 18/255, blue: 18/255))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                    .id(audioRecorder.formattedNotes)
                                    .onReceive(audioRecorder.$formattedNotes) { _ in
                                        print("📜 UI updated with new notes")
                                        NotificationCenter.default.post(name: Notification.Name("TranscriptionDidFinish"), object: nil)
                                    }

                                    if !(audioRecorder.formattedNotes?.isEmpty ?? true) {
                                        Button(action: {
                                            guard let notes = audioRecorder.formattedNotes, !notes.isEmpty else {
                                                print("⚠️ No notes to copy.")
                                                return
                                            }

                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(notes, forType: .string)
                                            print("✅ Notes copied to clipboard!")
                                        }) {
                                            Image(nsImage: NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Copy")!)
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                                .padding(6)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .opacity(isHovering ? 1.0 : 0.0)
                                        .background(audioRecorder.isRecording ? Color.clear : Color(red: 18/255, green: 18/255, blue: 18/255))
                                        .cornerRadius(5)
                                        .padding(.trailing, 25)
                                        .padding(.top, 5)
                                    }
                                }
                                .onHover { hovering in
                                    withAnimation {
                                        isHovering = hovering
                                    }
                                }
                            }

                            // Waveform Display
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack {
                                    SiriWaveView(power: $power)
                                        .frame(height: 250)
                                        .opacity(audioRecorder.isRecording ? 1.0 : 0.0)
                                        .onReceive(audioRecorder.$audioPower) { newPower in
                                            power = newPower
                                        }
                                        .scaleEffect(y: 1, anchor: .top)
                                        .offset(y: 50)
                                        .padding(.top)
                                }
                            }
                            .frame(maxHeight: 250)

                            // Console Output
                            HStack {
                                Text("\(Logger.shared.consoleOutput)")
                                    .padding()
                                    .frame(maxWidth: .infinity, minHeight: 5, maxHeight: 15, alignment: .center)
                                    .background(audioRecorder.isRecording ? Color.clear : Color(red: 0/255, green: 0/255, blue: 0/255))
                                    .cornerRadius(5)
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .onAppear {
                    NotificationCenter.default.addObserver(forName: Notification.Name("TranscriptionDidFinish"), object: nil, queue: .main) { _ in
                        NotificationCenter.default.post(name: Notification.Name("StopTranscriptionTimer"), object: nil)
                    }
                }
                .background(audioRecorder.isRecording ? Color.black : Color(red: 0/255, green: 0/255, blue: 0/255))
            }
        }
    }
}
#Preview {
    ContentView()
}
