"""
Upload all Thailingo content to Firestore.

Uploads:
  - All assets/lessons/lesson_*.json → collection "lessons"
  - v1.0.5 patch note → collection "patch_notes"

Usage:
    pip install firebase-admin
    python scripts/upload_all_content.py [--dry-run] [--key path/to/key.json]

Service account key search order:
    1. --key argument (if provided)
    2. scripts/service-account.json
    3. scripts/thailingo-service-account.json
    4. scripts/firebase-service-account.json
    5. ~/Downloads/thailingo-5d117-firebase-adminsdk-fbsvc-3b3d8279cd.json
"""

import argparse
import glob
import json
import os
import sys
from datetime import datetime, timezone

import sys
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("ERROR: firebase-admin not installed. Run: pip install firebase-admin")
    sys.exit(1)

# ── Service account key discovery ────────────────────────────────────────

KEY_SEARCH_PATHS = [
    "scripts/service-account.json",
    "scripts/thailingo-service-account.json",
    "scripts/firebase-service-account.json",
    os.path.expanduser(
        "~/Downloads/thailingo-5d117-firebase-adminsdk-fbsvc-3b3d8279cd.json"
    ),
]

parser = argparse.ArgumentParser(description="Upload all Thailingo content to Firestore")
parser.add_argument("--key", default=None, help="Path to service account JSON")
parser.add_argument(
    "--dry-run", action="store_true", help="Print what would be uploaded without writing"
)
parser.add_argument(
    "--lessons-only", action="store_true", help="Upload only lessons"
)
parser.add_argument(
    "--patch-only", action="store_true", help="Upload only patch notes"
)
args = parser.parse_args()

key_path = args.key
if key_path is None:
    for candidate in KEY_SEARCH_PATHS:
        if os.path.exists(candidate):
            key_path = candidate
            break

if key_path is None or not os.path.exists(key_path):
    print("ERROR: Service account key not found.")
    print("Searched:")
    for p in KEY_SEARCH_PATHS:
        print(f"  {p}")
    print("\nDownload from: Firebase Console → Project Settings → Service Accounts")
    print("Or pass the path with: --key path/to/key.json")
    sys.exit(1)

print(f"Using service account: {key_path}")
cred = credentials.Certificate(key_path)
firebase_admin.initialize_app(cred)
db = firestore.client()

prefix = "DRY RUN — " if args.dry_run else ""
total_uploaded = 0
total_skipped = 0

# ── Upload lessons ────────────────────────────────────────────────────────

if not args.patch_only:
    lesson_files = sorted(glob.glob("assets/lessons/lesson_[0-9]*.json"))

    if not lesson_files:
        print("WARNING: No lesson JSON files found in assets/lessons/")
    else:
        print(f"\n{'='*50}")
        print(f"LESSONS  ({len(lesson_files)} files)")
        print(f"{'='*50}")

        for filepath in lesson_files:
            with open(filepath, "r", encoding="utf-8") as f:
                data = json.load(f)

            lesson_id = data.get("id")
            if lesson_id is None:
                print(f"  SKIP  {filepath}: missing 'id' field")
                total_skipped += 1
                continue

            doc_id = f"lesson_{str(lesson_id).zfill(2)}"
            data["lastUpdated"] = datetime.now(timezone.utc).isoformat()

            word_count = len(data.get("words", []))
            print(
                f"  {prefix}UP    {doc_id}: {data.get('title', '?')} "
                f"({word_count} words, stage {data.get('stage', '?')})"
            )

            if not args.dry_run:
                db.collection("lessons").document(doc_id).set(data)

            total_uploaded += 1

# ── Upload patch notes ────────────────────────────────────────────────────

PATCH_NOTES = [
    {
        "version": "1.0.0",
        "title": "Initial Release 🎉",
        "date": datetime(2026, 1, 1, tzinfo=timezone.utc),
        "type": "major",
        "notes": [
            "Thailingo launches with 22 Stage 1 lessons",
            "7 game types: Multiple Choice, Match Pairs, Listen & Choose, Speed Tap, "
            "Sentence Builder, Conversation Mode, Typing Challenge",
            "Thai flag themed UI with mascot character",
            "XP system, streaks, and 3-star ratings per lesson",
            "Review queue for words you got wrong",
            "Guide book with tones, alphabet and survival phrases",
            "Google Sign In and Firestore leaderboard",
            "Shorebird OTA updates",
        ],
    },
    {
        "version": "1.0.1",
        "title": "Fixes & Polish",
        "date": datetime(2026, 2, 1, tzinfo=timezone.utc),
        "type": "patch",
        "notes": [
            "Fixed conversation mode audio playing wrong sounds",
            "Added in-app bug reporting — tap 🐛 in any lesson",
            "Weekly XP rank banner on home screen",
            "Star system rework — easier to earn stars, based on play count",
            "Match Pairs now scores each pair individually",
            "Typing Challenge now accepts common spelling variations",
            "Typing Challenge hints — tap 💡 if you're stuck",
            "What's New screen — see what changed in each update",
        ],
    },
    {
        "version": "1.0.2",
        "title": "Muay Thai Mascot Update 🥊",
        "date": datetime(2026, 3, 1, tzinfo=timezone.utc),
        "type": "minor",
        "notes": [
            "Mascot redesigned as a Muay Thai fighter with mongkol headband and hand wraps",
            "Mascot repositioned to the right of the header for better readability on small screens",
            "Speech bubble moved to the left of the mascot",
            "Various bug fixes and UI polish",
        ],
    },
    {
        "version": "1.0.3",
        "title": "Real Bangkok Thai Content 🏙️",
        "date": datetime(2026, 4, 1, tzinfo=timezone.utc),
        "type": "minor",
        "notes": [
            "6 new lessons added from real Bangkok daily life",
            "Daily life sentences (going to kitchen, bathroom and more)",
            "Going out and making plans phrases",
            "Street ordering and shopping (kao man gai, som tam and more)",
            "Goodbyes and conversation endings",
            "Numbers 11 to 1,000,000",
            "Bangkok slang and useful fillers",
            "7 new conversation scenarios based on real situations",
            "Ordering kao man gai, som tam, 7-Eleven run and more",
        ],
    },
    {
        "version": "1.0.4",
        "title": "Cloud Content & Auto Audio 🌐",
        "date": datetime(2026, 5, 1, tzinfo=timezone.utc),
        "type": "major",
        "notes": [
            "Lessons now load from the cloud — new content appears without app updates",
            "Audio auto-fetches from Google TTS for any missing pronunciation",
            "All fetched audio cached to device for offline playback",
            "New lessons 38-43 now have full audio: Daily Life, Going Out, "
            "Street Ordering, Goodbyes, Advanced Numbers, Slang",
            "7 new Bangkok conversation scenarios",
            "New hamburger menu in the header replaces icon buttons",
            "Sign out, leaderboard, guide book and settings all in one place",
            "Dev mode: Manage Lessons screen to add or upload lessons to Firestore",
        ],
    },
    {
        "version": "1.0.5",
        "title": "Major UI & Content Update 🎨",
        "date": datetime(2026, 6, 1, tzinfo=timezone.utc),
        "type": "major",
        "notes": [
            "Stage 1 expanded to 28 lessons with new beginner-friendly unlock order",
            "Hexagons redesigned as octagons with layered star borders (bronze/silver/gold)",
            "Smooth green→indigo color gradient across Stage 1",
            "Stage 1 phonetic-only mode — learn sounds before English translations",
            "No conversation exercises in Stage 1 — stays focused on vocabulary",
            "Stage 1 star tally card shows bronze/silver/gold progress",
            "Missed Questions review mode — practice words you never saw",
            "Lessons now pad to 20 questions minimum for longer practice sessions",
            "Words Learned shown prominently in stats",
            "Keyboard no longer blocks typing challenge input field",
        ],
    },
]

if not args.lessons_only:
    print(f"\n{'='*50}")
    print(f"PATCH NOTES  ({len(PATCH_NOTES)} entries)")
    print(f"{'='*50}")

    for note in PATCH_NOTES:
        version = note["version"]
        date = note["date"]

        doc_data = {
            "version": version,
            "title": note["title"],
            "date": date,
            "type": note["type"],
            "notes": note["notes"],
        }

        print(
            f"  {prefix}UP    {version}: {note['title']} "
            f"({len(note['notes'])} notes)"
        )

        if not args.dry_run:
            db.collection("patch_notes").document(version).set(doc_data)

        total_uploaded += 1

# ── Summary ───────────────────────────────────────────────────────────────

print(f"\n{'='*50}")
print(
    f"{'Would upload' if args.dry_run else 'Uploaded'}: {total_uploaded}  "
    f"Skipped: {total_skipped}"
)
print(f"{'='*50}")
