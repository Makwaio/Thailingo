"""
Generate TTS audio for Thailingo lessons 38-43.
Reads each lesson JSON, generates Thai audio with gTTS, saves to assets/audio/.
Skips files that already exist.

Usage:
    pip install gtts
    python scripts/generate_audio_38_43.py
"""

import json
import os
import sys
import time
from pathlib import Path

# Windows console defaults to cp1252 which can't encode Thai; force UTF-8
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

try:
    from gtts import gTTS
except ImportError:
    print("ERROR: gtts not installed. Run: pip install gtts")
    raise

LESSONS_DIR = Path("assets/lessons")
AUDIO_DIR = Path("assets/audio")
LESSON_IDS = range(38, 44)  # 38 through 43

AUDIO_DIR.mkdir(parents=True, exist_ok=True)


def generate_for_lesson(lesson_id: int) -> tuple[int, int]:
    """Returns (generated, skipped) counts."""
    lesson_file = LESSONS_DIR / f"lesson_{lesson_id}.json"
    if not lesson_file.exists():
        print(f"  [WARN] {lesson_file} not found, skipping")
        return 0, 0

    with open(lesson_file, encoding="utf-8") as f:
        lesson = json.load(f)

    title = lesson.get("title", f"Lesson {lesson_id}")
    words = lesson.get("words", [])
    generated = 0
    skipped = 0

    print(f"\nLesson {lesson_id}: {title} ({len(words)} words)")

    for word in words:
        audio_file = word.get("audio", "")
        thai_text = word.get("thai", "")
        if not audio_file or not thai_text:
            continue

        output_path = AUDIO_DIR / audio_file
        if output_path.exists():
            print(f"  SKIP  {audio_file}")
            skipped += 1
            continue

        try:
            tts = gTTS(text=thai_text, lang="th", slow=False)
            tts.save(str(output_path))
            print(f"  GEN   {audio_file}  ({thai_text})")
            generated += 1
            time.sleep(0.3)  # be polite to Google TTS
        except Exception as e:
            print(f"  ERROR {audio_file}: {e}")

    return generated, skipped


def main():
    total_generated = 0
    total_skipped = 0

    print("=" * 50)
    print("Thailingo Audio Generator — Lessons 38-43")
    print("=" * 50)

    for lesson_id in LESSON_IDS:
        gen, skip = generate_for_lesson(lesson_id)
        total_generated += gen
        total_skipped += skip

    print("\n" + "=" * 50)
    print(f"Done!  Generated: {total_generated}  Skipped: {total_skipped}")
    print("=" * 50)


if __name__ == "__main__":
    main()
