import sys
import os
os.environ["HF_HUB_DISABLE_SYMLINKS_WARNING"] = "1"
# Remove HF_HUB_OFFLINE to allow model downloading when cache is cleared
if "HF_HUB_OFFLINE" in os.environ:
    del os.environ["HF_HUB_OFFLINE"]
import traceback

# 1. Standardize the environment
HOMEBREW_SITE = "/opt/homebrew/lib/python3.11/site-packages"
if HOMEBREW_SITE not in sys.path:
    sys.path.append(HOMEBREW_SITE)

os.environ["PATH"] += os.pathsep + "/opt/homebrew/bin"

def transcribe_with_mlx(audio_path):
    if not os.path.exists(audio_path):
        print(f"❌ MLX ERROR CODE 101: Audio file does not exist at path: {audio_path}", file=sys.stderr, flush=True)
        return False
    try:
        import mlx_whisper
        
        # Force a local cache directory to avoid Sandbox permission issues
        os.environ["HF_HOME"] = os.path.expanduser("~/Downloads/LectureToNotesCache/hf_cache")
        os.makedirs(os.environ["HF_HOME"], exist_ok=True)

        print("🚀 Using MLX (M4 Pro GPU Acceleration)...", file=sys.stderr, flush=True)
        
        # Use a model that is already downloaded or allow it to download
        result = mlx_whisper.transcribe(
            audio_path,
            path_or_hf_repo="mlx-community/whisper-small-mlx-8bit",
            language="en",
            verbose=False  # Suppress streaming text and progress bars
        )
        
        if result and 'text' in result:
            transcript_text = result['text'].strip()
            if transcript_text:
                print(f"[TRANSCRIPT_START]", flush=True)
                print(transcript_text, flush=True)
                print(f"[TRANSCRIPT_END]", flush=True)
                return True
            else:
                print("❌ MLX ERROR CODE 104: Transcription returned empty text.", file=sys.stderr, flush=True)
                return False
        else:
            print("❌ MLX ERROR CODE 105: No text in result.", file=sys.stderr, flush=True)
            return False
    except ImportError as e:
        print("❌ MLX ERROR CODE 102: mlx_whisper not installed in this environment.", file=sys.stderr, flush=True)
        print(f"DETAILS: {e}", file=sys.stderr, flush=True)
        traceback.print_exc(file=sys.stderr)
        return False
    except RuntimeError as e:
        print("❌ MLX ERROR CODE 103: Runtime failure inside MLX (model load, ffmpeg, or GPU issue).", file=sys.stderr, flush=True)
        print(f"DETAILS: {e}", file=sys.stderr, flush=True)
        traceback.print_exc(file=sys.stderr)
        return False
    except Exception as e:
        print("❌ MLX ERROR CODE 199: Unexpected MLX failure.", file=sys.stderr, flush=True)
        print(f"DETAILS: {e}", file=sys.stderr, flush=True)
        traceback.print_exc(file=sys.stderr)
        return False

def transcribe_with_faster_whisper(audio_path):
    if not os.path.exists(audio_path):
        print(f"❌ FW ERROR CODE 201: Audio file does not exist at path: {audio_path}", file=sys.stderr, flush=True)
        return False
    try:
        from faster_whisper import WhisperModel
        print("🏃 Falling back to Faster-Whisper (CPU)...", file=sys.stderr, flush=True)
        
        model = WhisperModel("small.en", device="cpu", compute_type="int8")
        segments, info = model.transcribe(audio_path, language="en", vad_filter=True)

        print("[TRANSCRIPT_START]", flush=True)
        for segment in segments:
            print(segment.text, end="", flush=True)
        print("\n[TRANSCRIPT_END]", flush=True)
        return True
    except ImportError as e:
        print("❌ FW ERROR CODE 202: faster-whisper not installed.", file=sys.stderr, flush=True)
        print(f"DETAILS: {e}", file=sys.stderr, flush=True)
        traceback.print_exc(file=sys.stderr)
        return False
    except Exception as e:
        print("❌ FW ERROR CODE 299: Unexpected Faster-Whisper failure.", file=sys.stderr, flush=True)
        print(f"DETAILS: {e}", file=sys.stderr, flush=True)
        traceback.print_exc(file=sys.stderr)
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("❌ Error: No audio file provided.", file=sys.stderr, flush=True)
        sys.exit(1)

    audio_file = sys.argv[1]
    # Try the high-performance M4 Pro path first
    if not transcribe_with_mlx(audio_file):
        print("⚠️ MLX path failed. Attempting CPU fallback...", file=sys.stderr, flush=True)
        if not transcribe_with_faster_whisper(audio_file):
            print("❌ ERROR CODE 900: All transcription paths failed.", file=sys.stderr, flush=True)
            sys.exit(2)
