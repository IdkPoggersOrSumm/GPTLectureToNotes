import sys
import os

# Ensure Homebrew's site-packages are available
sys.path.append("/opt/homebrew/lib/python3.11/site-packages")
sys.path.append("/usr/local/lib/python3.11/site-packages")

# Patch pydub detection before importing it
os.environ["PATH"] += os.pathsep + "/opt/homebrew/bin"
import pydub
pydub.utils.get_encoder_name = lambda: "ffmpeg"

from pydub import AudioSegment
AudioSegment.converter = "/opt/homebrew/bin/ffmpeg"

import whisper
import shutil
import os

def split_audio(audio_path, chunk_length_ms=600000):  # 10 minutes
    audio = AudioSegment.from_file(audio_path)
    chunks = [audio[i:i+chunk_length_ms] for i in range(0, len(audio), chunk_length_ms)]
    chunk_paths = []
    for idx, chunk in enumerate(chunks):
        chunk_path = f"/tmp/chunk_{idx}.mp3"
        chunk.export(chunk_path, format="mp3")
        chunk_paths.append(chunk_path)
    return chunk_paths

def transcribe_audio(audio_path):
    if not shutil.which("/opt/homebrew/bin/ffmpeg"):
        print(f"❌ Error: FFmpeg not found at /opt/homebrew/bin/ffmpeg. Please install it using 'brew install ffmpeg'")
        sys.exit(1)

    model = whisper.load_model("small")  # Use a smaller model to reduce lag
    chunk_paths = split_audio(audio_path)

    print("🔊 Started Whisper transcription process.", flush=True)
    total_chunks = len(chunk_paths)

    for idx, path in enumerate(chunk_paths, start=1):
        result = model.transcribe(path, fp16=False)  # Disable fp16 for better compatibility
        print(result["text"])
        print(f"✅ Transcribed chunk {idx} of {total_chunks}", flush=True)
        os.remove(path)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("❌ Error: No audio file provided.")
        sys.exit(1)

    audio_file = sys.argv[1]
    try:
        transcribe_audio(audio_file)
    except Exception as e:
        print(f"❌ Exception occurred: {e}", file=sys.stderr)
        sys.exit(1)
