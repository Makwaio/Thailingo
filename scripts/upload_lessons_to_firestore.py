"""
Upload all lesson JSON files to Firestore collection "lessons".

Usage:
    pip install firebase-admin
    python scripts/upload_lessons_to_firestore.py

Requires a Firebase service account key JSON file.
Download it from: Firebase Console → Project Settings → Service Accounts
→ Generate new private key

Place it at: scripts/thailingo-service-account.json
OR set the path via --key argument:
    python scripts/upload_lessons_to_firestore.py --key path/to/key.json
"""

import argparse
import glob
import json
import os
import sys
from datetime import datetime, timezone

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("ERROR: firebase-admin not installed. Run: pip install firebase-admin")
    sys.exit(1)

DEFAULT_KEY = "scripts/thailingo-service-account.json"

parser = argparse.ArgumentParser()
parser.add_argument("--key", default=DEFAULT_KEY, help="Path to service account JSON")
parser.add_argument("--dry-run", action="store_true", help="Print what would be uploaded without writing")
args = parser.parse_args()

if not os.path.exists(args.key):
    print(f"ERROR: Service account key not found at: {args.key}")
    print("Download it from Firebase Console → Project Settings → Service Accounts")
    sys.exit(1)

cred = credentials.Certificate(args.key)
firebase_admin.initialize_app(cred)
db = firestore.client()

lesson_files = sorted(glob.glob("assets/lessons/lesson_[0-9]*.json"))

if not lesson_files:
    print("ERROR: No lesson JSON files found in assets/lessons/")
    sys.exit(1)

print(f"Found {len(lesson_files)} lesson files")
print(f"{'DRY RUN — ' if args.dry_run else ''}Uploading to Firestore...\n")

uploaded = 0
skipped = 0

for filepath in lesson_files:
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    lesson_id = data.get("id")
    if lesson_id is None:
        print(f"  SKIP  {filepath}: missing 'id' field")
        skipped += 1
        continue

    doc_id = f"lesson_{str(lesson_id).zfill(2)}"
    data["lastUpdated"] = datetime.now(timezone.utc).isoformat()

    print(f"  {'DRY ' if args.dry_run else ''}UP    {doc_id}: {data.get('title', '?')} "
          f"({len(data.get('words', []))} words)")

    if not args.dry_run:
        db.collection("lessons").document(doc_id).set(data)

    uploaded += 1

print(f"\n{'=' * 50}")
print(f"{'Would upload' if args.dry_run else 'Uploaded'}: {uploaded}  Skipped: {skipped}")
print(f"{'=' * 50}")
