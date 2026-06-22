#!/usr/bin/env python3
"""
Generate Thai audio files for Thailingo app using gTTS.
Run: pip install gtts  then  python scripts/generate_audio.py
"""

import os
import json
import time
from pathlib import Path

try:
    from gtts import gTTS
except ImportError:
    print("ERROR: gTTS not installed. Run: pip install gtts")
    raise

ASSETS_DIR = Path(__file__).parent.parent / "assets"
LESSONS_DIR = ASSETS_DIR / "lessons"
AUDIO_DIR = ASSETS_DIR / "audio"
AUDIO_DIR.mkdir(parents=True, exist_ok=True)

LESSON_FILES = [
    # Lessons 11-22 (Stage 1 expansion)
    "lesson_11.json", "lesson_12.json", "lesson_13.json", "lesson_14.json",
    "lesson_15.json", "lesson_16.json", "lesson_17.json", "lesson_18.json",
    "lesson_19.json", "lesson_20.json", "lesson_21.json", "lesson_22.json",
    # Stage 2 lessons 23-37
    "lesson_23.json", "lesson_24.json", "lesson_25.json", "lesson_26.json",
    "lesson_27.json", "lesson_28.json", "lesson_29.json", "lesson_30.json",
    "lesson_31.json", "lesson_32.json", "lesson_33.json", "lesson_34.json",
    "lesson_35.json", "lesson_36.json", "lesson_37.json",
    # Stage 0 alphabet lessons
    "lesson_A1.json", "lesson_A2.json", "lesson_A3.json",
    "lesson_A4.json", "lesson_A5.json",
]

def generate_audio(thai_text: str, out_path: Path, delay: float = 0.5):
    """Generate a single Thai audio file using gTTS."""
    if out_path.exists():
        print(f"  [SKIP] {out_path.name} already exists")
        return
    try:
        tts = gTTS(text=thai_text, lang="th", slow=False)
        tts.save(str(out_path))
        print(f"  [OK]   {out_path.name}  ({thai_text})")
        time.sleep(delay)  # avoid rate limiting
    except Exception as e:
        print(f"  [ERR]  {out_path.name}: {e}")

def process_lesson(filename: str):
    lesson_path = LESSONS_DIR / filename
    if not lesson_path.exists():
        print(f"[WARN] Missing lesson file: {filename}")
        return

    with open(lesson_path, encoding="utf-8") as f:
        data = json.load(f)

    words = data.get("words", [])
    print(f"\n=== {filename} ({data.get('title', '')}) — {len(words)} words ===")

    for word in words:
        thai = word.get("thai", "")
        audio = word.get("audio", "")
        if not thai or not audio:
            continue
        out_path = AUDIO_DIR / audio
        generate_audio(thai, out_path)

def main():
    print("Thailingo Audio Generator")
    print(f"Output directory: {AUDIO_DIR}")
    print("=" * 50)

    for filename in LESSON_FILES:
        process_lesson(filename)

    print("\n✓ Done!")
    existing = len(list(AUDIO_DIR.glob("*.mp3")))
    print(f"  Total audio files: {existing}")

if __name__ == "__main__":
    main()
