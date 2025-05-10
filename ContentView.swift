import SwiftUI
import AppKit
import SiriWaveView

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

struct ContentView: View {
    @ObservedObject var audioRecorder = AudioRecorder.shared
    @State private var isHovering = false
    @State private var amplitude: Double = 0.5
    @State private var frequency: Double = 1.0
    @State private var power: Double = 1.0
    @State var vm = ViewModel()
    @State private var showSettingsMenu = false
    
    var body: some View {
  
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
#Preview {
    ContentView()
}
