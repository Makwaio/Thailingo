#!/usr/bin/env python3
"""Upload lessons 29-50 and v1.0.6 patch note to Firestore."""
import json
import os
from datetime import datetime, timezone
import firebase_admin
from firebase_admin import credentials, firestore

SERVICE_ACCOUNT_PATH = os.path.join(
    os.path.dirname(__file__), '..', 'firebase-service-account.json'
)

if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred)

db = firestore.client()

NEW_LESSON_IDS = list(range(29, 51))  # 29-50 inclusive
ASSETS_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'lessons')


def upload_lesson(lesson_id: int) -> None:
    padded = str(lesson_id).zfill(2)
    filename = f'lesson_{padded}.json'
    filepath = os.path.join(ASSETS_DIR, filename)

    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    doc_id = f'lesson_{padded}'
    db.collection('lessons').document(doc_id).set(data)
    word_count = len(data.get('words', []))
    print(f'  OK {doc_id} - "{data["title"]}" ({word_count} words)')


def upload_patch_note() -> None:
    patch = {
        'version': '1.0.6',
        'title': 'Stage 2 & Stage 3 Expansion 🏙️🗣️',
        'date': datetime(2026, 6, 25, tzinfo=timezone.utc),
        'type': 'major',
        'notes': [
            '🔷 Stage 1 expanded: Shapes, Sizes & Quantities, Opposites, Clothing, Textures',
            '🏥 Stage 2 — 16 new lessons: Hospital, Celebrations, Plans, About Yourself',
            '⏰ Stage 2 continued: Tense Markers, Classifiers, Advanced Directions',
            '📱 Stage 2 continued: Technology, Business Thai, Relationships & Social',
            '💯 Stage 2 continued: Advanced Numbers, Survival Thai + Bargaining',
            '💬 Stage 3 unlocked: Full Conversations, Thai Proverbs, Thai Script Basics',
            '🎵 Stage 3 continued: Thai Tones Mastery, Bangkok Slang & Street Talk',
            '🎨 Stage 2 color gradient now uses visual position (not lesson ID)',
            '🔓 Unlock All now toggles — tap again to revert to previous progress',
            '🌟 New achievement: Thai Master — complete all Stage 3 lessons',
        ],
    }
    db.collection('patch_notes').add(patch)
    print('  OK patch note v1.0.6 added')


def main() -> None:
    print('Uploading lessons 29-50 to Firestore...\n')
    for lid in NEW_LESSON_IDS:
        upload_lesson(lid)

    print('\nUploading patch note...')
    upload_patch_note()

    print(f'\nDone - {len(NEW_LESSON_IDS)} lessons + 1 patch note uploaded.')


if __name__ == '__main__':
    main()
