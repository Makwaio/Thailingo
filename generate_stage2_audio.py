#!/usr/bin/env python3
"""Generate missing audio files for Stage 2 lessons (23-37) using gTTS."""

import json
import os
import sys
from pathlib import Path
from gtts import gTTS

# Force UTF-8 stdout on Windows so Thai text prints without crash
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

LESSONS_DIR = Path("assets/lessons")
AUDIO_DIR = Path("assets/audio")
LESSON_RANGE = range(23, 38)

created = 0
already_existed = 0
missing_thai = []
missing_audio_field = []
lesson_status = {}

total_words = 0

for lesson_id in LESSON_RANGE:
    json_path = LESSONS_DIR / f"lesson_{lesson_id}.json"
    if not json_path.exists():
        lesson_status[lesson_id] = f"❌ JSON missing: {json_path}"
        continue

    with open(json_path, encoding="utf-8") as f:
        data = json.load(f)

    words = data.get("words", [])
    lesson_ok = True

    for idx, word in enumerate(words, start=1):
        total_words += 1
        word_id = word.get("id", f"word{idx}")
        thai = word.get("thai", "").strip()
        audio = word.get("audio", "").strip()

        if not audio:
            missing_audio_field.append(f"L{lesson_id} #{idx} id={word_id}")
            lesson_ok = False
            continue

        if not thai:
            missing_thai.append(f"L{lesson_id} {audio}")
            lesson_ok = False
            continue

        audio_path = AUDIO_DIR / audio
        if audio_path.exists():
            already_existed += 1
            print(f"  ✓ exists  {audio}")
            continue

        # Generate with gTTS
        try:
            tts = gTTS(text=thai, lang="th", slow=False)
            tts.save(str(audio_path))
            created += 1
            print(f"  [{created:3d}] generated  {audio}  —  {thai}")
        except Exception as e:
            print(f"  ✗ FAILED   {audio}  —  {e}")
            lesson_ok = False

    lesson_status[lesson_id] = "✅" if lesson_ok else "❌"

# ── Summary ─────────────────────────────────────────────────────────────────
print()
print("═" * 56)
print("AUDIT RESULTS  (lessons 23-37)")
print("═" * 56)
for lesson_id in LESSON_RANGE:
    status = lesson_status.get(lesson_id, "❌ not found")
    json_path = LESSONS_DIR / f"lesson_{lesson_id}.json"
    if json_path.exists():
        with open(json_path, encoding="utf-8") as f:
            d = json.load(f)
        title = d.get("title", "")
    else:
        title = "MISSING"
    print(f"  {status}  L{lesson_id:02d}  {title}")

print()
print(f"  Total words checked   : {total_words}")
print(f"  Audio files generated : {created}")
print(f"  Already existed       : {already_existed}")
print(f"  Words using fallback  : {created}  (online TTS will cover these on device)")

if missing_thai:
    print(f"\n  Missing 'thai' field  : {len(missing_thai)}")
    for m in missing_thai:
        print(f"    {m}")
else:
    print(f"  Missing 'thai' field  : 0")

if missing_audio_field:
    print(f"\n  Missing 'audio' field : {len(missing_audio_field)}")
    for m in missing_audio_field:
        print(f"    {m}")
else:
    print(f"  Missing 'audio' field : 0")

print("═" * 56)
