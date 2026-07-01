"""
Upload all patch notes to Firestore collection "patch_notes".
Overwrites existing docs with correct dates so sort order is right.

Usage:
    pip install firebase-admin
    python scripts/upload_patch_notes.py
"""

import os
import sys
# Force UTF-8 output on Windows
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta

possible_keys = [
    'firebase-service-account.json',
    'service-account.json',
    'scripts/firebase-service-account.json',
    'scripts/service-account.json',
]
key_path = next((p for p in possible_keys if os.path.exists(p)), None)
if not key_path:
    print("ERROR: No service account key found. Place firebase-service-account.json in project root.")
    exit(1)

print(f"Using key: {key_path}")
cred = credentials.Certificate(key_path)
firebase_admin.initialize_app(cred)
db = firestore.client()

base_date = datetime(2026, 7, 2, 12, 0, 0)  # today at noon

patch_notes = [
    {
        'version': '1.2.5',
        'title': 'Patch Notes Fix + Skeet Word Mode 🎯',
        'type': 'minor',
        'date': base_date,
        'notes': [
            'Patch notes now sorted newest first',
            'All version history added',
            'Skeet Shooter shows English words on skeets in Thai-learning mode',
            'Skeet Shooter shows Thai words on skeets in English-learning mode',
            'Find word box moved to bottom bar — more screen space for skeets',
            'Correct shot shows word translation briefly',
            'Type badges added: 🟢 Major | 🔵 Minor | ⚪ Patch',
            'Current version highlighted with CURRENT badge',
        ],
    },
    {
        'version': '1.2.4',
        'title': 'Skeet Shooter Overhaul 🎮',
        'type': 'major',
        'date': base_date - timedelta(days=1),
        'notes': [
            'Continuous spawning — no more round limit',
            'Decoy count scales with level (2–10 decoys)',
            '20 unique backgrounds that change every 5 levels',
            'Backgrounds: Morning Bangkok → Golden Temple at level 100',
            'Game ends at Level 100 with LEGENDARY victory screen',
            'Skeets spawn from left/right at early levels, add top spawn at level 20+',
            'Red edge flash and heart shake animation on life loss',
            'Game Over shows level reached, accuracy %, longest combo, total rounds',
            'Word pool fixed to include all Stage 1–3 lessons',
        ],
    },
    {
        'version': '1.2.3',
        'title': 'Skeet UI Layout Fix',
        'type': 'patch',
        'date': base_date - timedelta(days=2),
        'notes': [
            'Skeet shooter UI redesigned for more play area',
            'Score and hearts moved to compact top bar',
            'Find word bar anchored to bottom of screen',
        ],
    },
    {
        'version': '1.2.2',
        'title': 'Arcade Countdown + Skeet Fixes ⏱️',
        'type': 'minor',
        'date': base_date - timedelta(days=3),
        'notes': [
            '3–2–1–GO countdown added before every arcade game',
            'Start screen shows best score before each game',
            'Skeets slower and more readable at lower levels',
            'Skeet count progression fixed per level',
            'All arcade games now use 5 hearts',
        ],
    },
    {
        'version': '1.2.1',
        'title': '15 New Focused Lessons 🎯',
        'type': 'major',
        'date': base_date - timedelta(days=4),
        'notes': [
            'Taxis & Ride-Hailing lesson 🚕',
            'BTS & MRT Subway lesson 🚆',
            'At the Restaurant lesson 🍽️',
            'Market & Shopping lesson 🛍️',
            'Money & Payments lesson 💰',
            'Hospital & Pharmacy lesson 🏥',
            'Hotel lesson 🏨',
            'Bank lesson 🏦',
            'Social Etiquette lesson 🙏',
            'Office & Workplace lesson 💼',
            'Your Life Story lesson 👤',
            'Talking About Feelings lesson ❤️',
            'Making Friends lesson 👫',
            'Weather Talk lesson ⛅',
            'Food Preferences lesson 😋',
        ],
    },
    {
        'version': '1.2.0',
        'title': 'Stage Review, Final Exam & Dictionary 📖',
        'type': 'major',
        'date': base_date - timedelta(days=5),
        'notes': [
            'Stage banners now clickable after completion',
            'Stage Review: replay all stage lessons in one session',
            'Final Exam: 40 questions — earn gold, silver or bronze',
            'Stage Dictionary: browse all words learned in a stage',
            'Words Learned counter per stage',
        ],
    },
    {
        'version': '1.1.3',
        'title': 'Full Landscape Rotation 📱',
        'type': 'minor',
        'date': base_date - timedelta(days=6),
        'notes': [
            'App now rotates to landscape on all screens',
            'Exercise screens show word panel + answers side-by-side in landscape',
            'Skeet Shooter forces landscape for max play area',
            'All overlays and dialogs support landscape layout',
        ],
    },
    {
        'version': '1.1.2',
        'title': 'Major Bug Fixes + Skeet Shooter 🎯',
        'type': 'major',
        'date': base_date - timedelta(days=7),
        'notes': [
            'New arcade game: Skeet Shooter 🎯 — shoot the right words before they fly by',
            'Fixed Stage 0 not switching content for English-learning mode',
            'Fixed game type toggles not saving between sessions',
            'Fixed later lessons showing only one exercise type',
            'Fixed first completion always giving exactly 1 star',
            'Fixed Stage 0 Listen exercise showing the answer too early',
        ],
    },
    {
        'version': '1.1.1',
        'title': 'Thai Lesson Names + English Alphabet 🔤',
        'type': 'minor',
        'date': base_date - timedelta(days=8),
        'notes': [
            'Lesson names now show in Thai in Learning English mode',
            'Stage 0 switches to English Alphabet (A–Z) for Thai speakers',
            '5 English Alphabet lessons: Consonants 1 & 2, Vowels, Pronunciation Rules, Common Words',
        ],
    },
    {
        'version': '1.1.0',
        'title': 'Full Thai UI + Profile Menu 🎉',
        'type': 'major',
        'date': base_date - timedelta(days=9),
        'notes': [
            'Complete UI translated to Thai in Learning English mode',
            'Stage names, menus and settings all in Thai',
            'Profile icon replaces hamburger menu — slides open from right',
            'XP bar and mascot repositioned for cleaner header',
        ],
    },
    {
        'version': '1.0.9',
        'title': 'Learning English Fix ✅',
        'type': 'patch',
        'date': base_date - timedelta(days=10),
        'notes': [
            'Fixed feedback bar showing wrong language after wrong answer',
            'Typing wrong answer now shows correct language meaning',
            'Review screen uses consistent language per setting',
        ],
    },
    {
        'version': '1.0.8',
        'title': 'Thai Speakers Can Learn English 🌏',
        'type': 'major',
        'date': base_date - timedelta(days=11),
        'notes': [
            'Full Thai → English learning mode added',
            'All 50 lessons work in both directions',
            'UI switches fully to Thai in Learning English mode',
            'Separate progress tracked per language direction',
        ],
    },
    {
        'version': '1.0.7',
        'title': 'Thai > English Mode 🌏',
        'type': 'major',
        'date': base_date - timedelta(days=12),
        'notes': [
            'Learning direction toggle added in Settings',
            'Stage 1 lessons expanded to 15–18 words each',
            'Hamburger menu moved to right side',
            'Mascot repositioned for better readability',
        ],
    },
    {
        'version': '1.0.6',
        'title': 'Stage 2 & 3 Complete 🎓',
        'type': 'major',
        'date': base_date - timedelta(days=13),
        'notes': [
            'Stage 2 fully built with 15 lessons',
            'Stage 3 added with 5 advanced lessons',
            '50 total lessons available',
            'All Stage 1 lessons expanded with more vocabulary',
        ],
    },
    {
        'version': '1.0.5',
        'title': 'Major UI & Content Update 🎨',
        'type': 'major',
        'date': base_date - timedelta(days=14),
        'notes': [
            'Octagon shaped lesson bubbles with layered star borders (bronze/silver/gold)',
            'Smooth color gradient across stages',
            'Lessons reordered for optimal learning progression',
            'Missed Questions tracker — review words you never answered in a session',
            'Lessons now pad to 20 questions minimum',
            'Words Learned shown prominently in stats',
        ],
    },
    {
        'version': '1.0.4',
        'title': 'Cloud Content & Auto Audio 🌐',
        'type': 'major',
        'date': base_date - timedelta(days=15),
        'notes': [
            'Lessons now load from the cloud — new content without app updates',
            'Audio auto-fetches from Google TTS for any missing pronunciation',
            'All fetched audio cached to device for offline playback',
            '7 new Bangkok conversation scenarios',
            'New hamburger menu replaces icon buttons',
        ],
    },
    {
        'version': '1.0.3',
        'title': 'Real Bangkok Thai Content 🏙️',
        'type': 'minor',
        'date': base_date - timedelta(days=16),
        'notes': [
            '6 new lessons from real Bangkok daily life',
            'Daily life sentences, going out and making plans',
            'Street ordering and shopping phrases',
            'Goodbyes, advanced numbers, Bangkok slang',
            '7 new conversation scenarios (ordering kao man gai, som tam and more)',
        ],
    },
    {
        'version': '1.0.2',
        'title': 'Muay Thai Mascot Update 🥊',
        'type': 'minor',
        'date': base_date - timedelta(days=17),
        'notes': [
            'Mascot redesigned as Muay Thai fighter with mongkol headband',
            'Mascot repositioned to right of header',
            'Speech bubble repositioned for readability',
            'Various bug fixes and UI polish',
        ],
    },
    {
        'version': '1.0.1',
        'title': 'Bug Fixes & Improvements',
        'type': 'patch',
        'date': base_date - timedelta(days=18),
        'notes': [
            'Fixed conversation mode audio playing wrong sounds',
            'Added in-app bug reporting — tap 🐛 in any lesson',
            "What's New screen added",
            'Star system rework — easier to earn stars, based on play count',
            'Match Pairs now scores each pair individually',
            'Google Sign In reliability improved',
        ],
    },
    {
        'version': '1.0.0',
        'title': 'Initial Release 🎉',
        'type': 'major',
        'date': base_date - timedelta(days=19),
        'notes': [
            'Thailingo launches!',
            '22 Stage 1 lessons covering essential Bangkok Thai',
            '7 game types: Multiple Choice, Match Pairs, Listen & Choose, Speed Tap, Sentence Builder, Conversation, Typing Challenge',
            'Thai flag themed UI with Muay Thai mascot',
            'XP system, streaks, and 3-star ratings per lesson',
            'Google Sign In and Firestore leaderboard',
            'Shorebird OTA updates for instant patches',
        ],
    },
]

print(f"Uploading {len(patch_notes)} patch notes to Firestore...")
for note in patch_notes:
    doc = {
        'version': note['version'],
        'title': note['title'],
        'type': note['type'],
        'date': note['date'],
        'notes': note['notes'],
    }
    db.collection('patch_notes').document(note['version']).set(doc)
    print(f"  OK {note['version']}: {note['title']}")

print(f"\nDone! Uploaded {len(patch_notes)} patch notes.")
print("Firestore patch_notes collection is now complete and sorted correctly.")
