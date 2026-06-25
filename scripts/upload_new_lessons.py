#!/usr/bin/env python3
"""Upload lessons 44-48 and v1.0.5 patch note to Firestore."""
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

NEW_LESSON_IDS = [44, 45, 46, 47, 48]
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
        'version': '1.0.5',
        'title': 'New Vocabulary & Game Modes 🎮',
        'date': datetime(2026, 6, 25, tzinfo=timezone.utc),
        'type': 'minor',
        'notes': [
            '🔷 New lesson: Shapes — circles, triangles, spheres & more',
            '📏 New lesson: Sizes & Quantities — big, small, full, empty',
            '↔️ New lesson: Opposites — learn 14 word pairs (Hot/Cold, Fast/Slow...)',
            '👕 New lesson: Clothing & Accessories — shirts, shoes, jewellery',
            '🪨 New lesson: Textures & Materials — soft, hard, wood, metal, plastic',
            '👁️ New game mode: Visual Spotter — see an emoji, tap the Thai word',
            '🔄 New game mode: Opposites Challenge — match words with their opposites',
            '🐛 Fixed lesson counter sometimes showing 21/20',
            '🔊 Audio now plays after every wrong answer',
        ],
    }
    db.collection('patch_notes').add(patch)
    print('  OK patch note v1.0.5 added')


def main() -> None:
    print('Uploading new lessons to Firestore...\n')
    for lid in NEW_LESSON_IDS:
        upload_lesson(lid)

    print('\nUploading patch note...')
    upload_patch_note()

    print(f'\nDone - {len(NEW_LESSON_IDS)} lessons + 1 patch note uploaded.')


if __name__ == '__main__':
    main()
