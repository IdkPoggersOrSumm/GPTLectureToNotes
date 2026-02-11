# LectureToNotes
App that takes live lecture audio, turns it into transcription, and then further into notes

## Requirements & Installation

The app relies on a few system packages and Python libraries for transcription and media handling. Below are the tools you should install and the exact commands to install and uninstall them on macOS (Intel / Apple Silicon). Run these in a terminal.

- Homebrew (package manager)

Install:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Uninstall:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```

- Python 3.11 (via Homebrew)

Install:
```bash
brew install python@3.11
# Add to PATH (example for zsh):
echo 'export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Uninstall:
```bash
brew uninstall python@3.11
```

- FFmpeg (required by pydub/whisper for encoding/decoding)

Install:
```bash
brew install ffmpeg
```

Uninstall:
```bash
brew uninstall ffmpeg
```

- yt-dlp (optional: import audio from YouTube links)

Install:
```bash
brew install yt-dlp
```

Uninstall:
```bash
brew uninstall yt-dlp
```
Note: The app runs yt-dlp via the system shell and relies on your shell PATH to find it.

- Python packages used by the transcription script (`Transcript.py`)

Install (recommended to use the brewed Python executable):
```bash
/opt/homebrew/opt/python@3.11/bin/python3.11 -m pip install --upgrade pip
/opt/homebrew/opt/python@3.11/bin/python3.11 -m pip install --break-system-packages git+https://github.com/openai/whisper.git torch pydub
```

Notes:
- Some environments require `--break-system-packages` on macOS for newer Python/pip; remove it if your pip is configured normally.
- The `whisper` package may be installed directly from the upstream repository (shown above) or via `openai-whisper` if available for your environment.
- The app runs transcription using Python 3.11 (it tries common Homebrew paths and `command -v python3.11`).

Uninstall Python packages:
```bash
/opt/homebrew/opt/python@3.11/bin/python3.11 -m pip uninstall -y whisper openai-whisper torch pydub
```

---

If you use the macOS app UI, the app also references the Swift package `SiriWaveView` for the waveform; Xcode will fetch any Swift Package Manager dependencies when you open the project. System frameworks used (AVFoundation, PDFKit, AppKit) are provided by macOS and do not need separate installation.

If you'd like, I can add a small troubleshooting checklist (common install issues and fixes) or generate a shell script that runs the install commands for you.
