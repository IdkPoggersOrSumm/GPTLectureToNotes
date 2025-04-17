import sys
import whisper
import shutil
import os

# Explicitly set the ffmpeg path
os.environ["PATH"] += os.pathsep + "/opt/homebrew/bin"

def transcribe_audio(audio_path):
    if not shutil.which("/opt/homebrew/bin/ffmpeg"):
        print(f"❌ Error: FFmpeg not found at {FFMPEG_PATH}. Please install it using 'brew install ffmpeg'")
        sys.exit(1)

    model = whisper.load_model("medium")  # Use a smaller model to reduce lag
    result = model.transcribe(audio_path, fp16=False)  # Disable fp16 for better compatibility
    print(result["text"])

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("❌ Error: No audio file provided.")
        sys.exit(1)

    audio_file = sys.argv[1]
    transcribe_audio(audio_file)
