//
//  DownloadResources.swift
//  LectureToNotes
//
//  Created by Jacob Rodriguez on 6/5/25.
//


import Foundation
import AppKit

func checkAndInstallDependencies() {
    let dependencies = [
        ("Homebrew", "brew --version", ""),
        ("Python", "python3 --version", "brew install python"),
        ("Pip", "pip3 --version", "curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py"),
        ("FFmpeg", "ffmpeg -version", "brew install ffmpeg")
    ]

    for (name, checkCmd, installCmd) in dependencies {
        if runShellCommand(checkCmd) {
            print("✅ \(name) is already installed.")
        } else {
            print("⬇️ Installing \(name)...")
            if name == "Homebrew" {
                let appleScript = """
tell application "Terminal"
    activate
    do script ""
    delay 0.5
    tell application "System Events"
        keystroke "/bin/bash -c 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh'"
    end tell
end tell
"""
                print("🔧 Opening Terminal and pre-filling Homebrew install command...")
                let scriptCommand = "osascript -e '\(appleScript)'"
                if runShellCommand(scriptCommand) {
                    print("✅ Terminal opened and command pre-filled. Press Enter to run installer.")
                } else {
                    print("❌ Failed to open Terminal and pre-fill command.")
                }
            } else {
                if runShellCommand(installCmd) {
                    print("✅ \(name) installation successful.")
                } else {
                    print("❌ Failed to install \(name).")
                }
            }
        }
    }
}

@discardableResult
private func runShellCommand(_ command: String) -> Bool {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.standardInput = nil
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    do {
        try task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print("📤 Command Output for '\(command)':\n\(output)")
        }
        return task.terminationStatus == 0
    } catch {
        print("❌ Error running command: \(command)\n\(error)")
        return false
    }
}
