# LectureToNotes
App that takes live lecture audio, turns it into transcription, and then further into notes

## DISCLAIMER
97% of this app was generated from AI, this became more of more of a project with me seeing how much I could play with AI, while also making a semi-useful app
## Quick Start

**LectureToNotes** is now more portable! The app features:
- 🔍 **Auto-detection** of Python, FFmpeg, and yt-dlp from your system
- ⚙️ **Settings UI** to manually configure tool paths if auto-detection fails
- 🔧 **Architecture detection** that optimizes for Apple Silicon or Intel
- 📊 **Diagnostics view** to troubleshoot issues
- 🧩 **Pluggable transcription engines** (Whisper, Faster-Whisper, MLX-Whisper)

## Requirements & Installation

### 1. System Dependencies

The app relies on a few system packages and Python libraries. Below are the installation instructions:

#### Homebrew (package manager)

Install:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Uninstall:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```

#### Python 3.11

Install:
```bash
brew install python@3.11
```

Uninstall:
```bash
brew uninstall python@3.11
```

#### FFmpeg (required for audio encoding/decoding)

Install:
```bash
brew install ffmpeg
```

Uninstall:
```bash
brew uninstall ffmpeg
```

#### yt-dlp (optional: for importing audio from YouTube links)

Install:
```bash
brew install yt-dlp
```

Uninstall:
```bash
brew uninstall yt-dlp
```

### 2. Python Dependencies

Install using the provided `requirements.txt`:

```bash
python3.11 -m pip install -r requirements.txt
```

Or install manually:
```bash
python3.11 -m pip install --upgrade pip
python3.11 -m pip install openai-whisper faster-whisper torch pydub
```

**Optional** (Apple Silicon only, for optimized transcription):
```bash
python3.11 -m pip install mlx-whisper mlx
```

### 3. macOS App

If using the macOS app UI:
- The app references `SiriWaveView` for the waveform visualization
- Xcode automatically fetches Swift Package Manager dependencies when you open the project
- System frameworks (AVFoundation, PDFKit, AppKit) are provided by macOS

## Portability Features

### Auto-Detection
On app launch, LectureToNotes automatically:
1. Detects your system architecture (Apple Silicon or Intel)
2. Searches for Python 3.11, FFmpeg, and yt-dlp
3. Caches the discovered paths in `~/Library/Application Support/LectureToNotes/config.json`
4. Falls back to manual detection if paths need to be updated

### Manual Configuration
If auto-detection fails:

1. **Open Settings** (⚙️ icon in the app)
2. Go to the **Tools** tab
3. Click the folder icon next to each tool
4. Select the executable manually
5. Or use **Auto-Detect All** to retry system detection

### Diagnostics
To troubleshoot issues:

1. **Open Diagnostics** from the Help menu
2. Review:
   - System architecture (Apple Silicon vs Intel)
   - Detected Python and FFmpeg paths
   - Python package versions
   - Recommended transcription engine

You can also:
- **Copy Diagnostics** to debug messages to your clipboard
- **Export Diagnostics** to a file for bug reports

### Transcription Engines

The app supports multiple transcription backends:

- **MLX-Whisper** (Apple Silicon only, recommended)
  - Optimized for Apple Silicon Macs
  - Fastest performance
  - Lowest power consumption

- **Faster-Whisper** (Intel & Apple Silicon)
  - Faster inference than classic Whisper
  - Good balance of speed and quality

- **OpenAI Whisper** (Intel & Apple Silicon)
  - Classic Whisper implementation
  - Highest quality transcription

**Configure in Settings** → **Engine** tab:
- The app automatically recommends the best engine for your system
- You can manually select a different engine if installed

## Configuration

### Storage Locations

By default, cached files are stored at:
- **Model Cache**: `~/Library/Caches/LectureToNotes/models`
- **General Cache**: `~/Library/Caches/LectureToNotes`
- **Config**: `~/Library/Application Support/LectureToNotes`

You can customize these in **Settings** → **Directories** tab.

### OpenAI Model Selection

Configure which OpenAI model to use for note generation in **Settings** → **Engine** tab:
- GPT-4o Mini (default, fastest & cheapest)
- GPT-4
- GPT-4o

## Troubleshooting

### Python Not Found

**Error**: "Python 3.11 not found"

**Solution**:
1. Install: `brew install python@3.11`
2. Open **Settings** → **Tools**
3. Click the folder icon for Python
4. Select the python3.11 executable
5. Or use **Auto-Detect All** button

### FFmpeg Not Found

**Error**: "FFmpeg not found" or "audio encoding failed"

**Solution**:
1. Install: `brew install ffmpeg`
2. Use **Settings** → **Auto-Detect All** to refresh

### Transcription Packages Missing

**Error**: "whisper module not found"

**Solution**:
```bash
python3.11 -m pip install openai-whisper faster-whisper torch pydub
```

Or for Apple Silicon optimization:
```bash
python3.11 -m pip install mlx-whisper mlx
```

### Intel Mac Users

If you have an Intel Mac:
1. Classic Whisper and Faster-Whisper work best
2. MLX-Whisper is **not** available
3. The app will auto-detect and recommend Faster-Whisper

### Apple Silicon Users

If you have an Apple Silicon Mac:
1. **Recommended**: Use MLX-Whisper for best performance
2. Install: `python3.11 -m pip install mlx-whisper mlx`
3. Configure in **Settings** → **Engine**
4. Enjoy 3-5x faster transcription!

### Running on Rosetta

If you're running the app under Rosetta translation (Intel app on Apple Silicon):
1. The **Diagnostics** view will show "Rosetta Translation"
2. Performance will be slower than native
3. Consider installing the native Apple Silicon version of Xcode and building natively

## Advanced Configuration

### Direct Config File

For advanced users, you can edit the config directly:

```bash
nano ~/Library/Application\ Support/LectureToNotes/config.json
```

Example:
```json
{
  "pythonPath": "/opt/homebrew/opt/python@3.11/bin/python3.11",
  "ffmpegPath": "/opt/homebrew/bin/ffmpeg",
  "ytdlpPath": "/opt/homebrew/bin/yt-dlp",
  "openaiModel": "gpt-4o-mini",
  "preferredTranscriptionEngine": "mlx-whisper",
  "enableAutoTunePathDetection": true
}
```

### Environment Variables

For shell integration, you can:
```bash
# Set Python path for all processes
export PYTHON_311_PATH="/opt/homebrew/opt/python@3.11/bin/python3.11"

# Or add to your shell profile (~/.zshrc or ~/.bash_profile)
export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"
```

## Contributing

Found a portability issue? Please:
1. Open **Diagnostics** and export the report
2. Include the diagnostics in your bug report
3. Mention your macOS version and architecture

## Support

If you encounter issues:
1. Check the **Diagnostics** view for system information
2. Review the **Troubleshooting** section above
3. Export diagnostics for detailed debugging

---

**Note**: This app requires an OpenAI API key for note generation. Set this in **Settings** → **API Key**.
