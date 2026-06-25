# Thailingo — Project Status

**Last updated:** 2026-06-25 (v1.0.6 — Stage 2 rebuilt (16 lessons), Stage 3 added (5 lessons), 50 total lessons)  
**App name:** Thailingo (renamed from Thai Lab)  
**Platform:** Flutter (iOS + Android)

---

## v1.0.6 Changes — 2026-06-25

### Lesson Structure Overhaul

Complete restructuring of lesson IDs and stages:

| Stage | IDs | Count | Title |
|-------|-----|-------|-------|
| Stage 1 | 1-22 + 29-33 | 27 | Foundations |
| Stage 2 | 23-26 + 34-45 | 16 | Survival Thai |
| Stage 3 | 46-50 | 5 | Conversational Thai |

**Stage 1 new lessons (29-33):**
| ID | Title | Words |
|----|-------|-------|
| 29 | Shapes | 15 |
| 30 | Sizes & Quantities | 18 |
| 31 | Opposites | 14 |
| 32 | Clothing & Accessories | 20 |
| 33 | Textures & Materials | 15 |

**Stage 2 lessons (34-45 new, 23-26 existing):**
| ID | Title | Words |
|----|-------|-------|
| 23 | Restaurant Ordering | 10 |
| 24 | Bargaining & Negotiating | 10 |
| 25 | Asking for Help | 10 |
| 26 | At the Hospital (old) | 10 |
| 34 | At the Hospital | 20 |
| 35 | Thai Celebrations & Culture | 20 |
| 36 | Making Plans & Social Life | 18 |
| 37 | Talking About Yourself | 20 |
| 38 | Past & Future Tense Markers | 18 |
| 39 | Thai Classifiers | 20 |
| 40 | Getting Around Bangkok | 20 |
| 41 | Technology & Modern Life | 20 |
| 42 | Business Thai | 20 |
| 43 | Relationships & Social | 20 |
| 44 | Advanced Numbers | 20 |
| 45 | Survival Thai | 18 |

**Stage 3 lessons (46-50 new):**
| ID | Title | Words |
|----|-------|-------|
| 46 | Full Conversations | 20 |
| 47 | Thai Proverbs & Wisdom | 15 |
| 48 | Thai Script Basics | 20 |
| 49 | Thai Tones Mastery | 15 |
| 50 | Bangkok Slang & Street Talk | 20 |

### Dart Changes

| File | Change |
|------|--------|
| `home_screen.dart` | New Stage 1 rows (29-33), new Stage 2 rows (16 lessons in 5 rows), real Stage 3 section |
| `home_screen.dart` | `_stage1Chain` updated (27 IDs), `_stage2Chain` added (16 IDs), `_stage3Chain` added (5 IDs) |
| `home_screen.dart` | `_s2ColorAnchors` — 14 color stops by visual position (fixes Stage 2 color bug) |
| `home_screen.dart` | `_s3ColorAnchors` added — purple→orange gradient |
| `home_screen.dart` | `_lessonFillColor` uses chains (not hardcoded ID list) for Stage 2 |
| `home_screen.dart` | Emoji map updated for IDs 29-50 |
| `home_screen.dart` | Subtitle: "27 lessons" (Stage 1), "16 lessons" (Stage 2) |
| `home_screen.dart` | `_Stage3Placeholder` removed |
| `user_progress.dart` | `s1Chain` in `isLessonUnlocked` updated to [1..21, 29-33] |
| `user_progress.dart` | `allStage1Complete/Mastered` — 27 IDs |
| `user_progress.dart` | `allStage2Complete/Mastered` — 16 IDs |
| `user_progress.dart` | `allStage3Complete/Mastered` — 5 IDs (new) |
| `user_progress.dart` | `isLessonUnlocked` — full Stage 2 chain, new Stage 3 chain |
| `user_progress.dart` | `kStageLessonIds` — updated groups 4-5, added group 6 |
| `user_progress.dart` | `stage3_master` achievement added |
| `lesson_service.dart` | `totalLessons = 50`, `stage1Count = 27` |
| `exercise_service.dart` | `_visualLessonIds` → {3,4,9,11,16,17,29,32} |
| `exercise_service.dart` | Opposites challenge: `lesson.id == 31` (was 46) |
| `lesson_unlock_manager.dart` | New chains, Stage 3 section, emoji map updated |
| `settings_screen.dart` | Unlock All toggle with snapshot/restore |
| `progress_service.dart` | `exportJson()` and `restoreFromJson()` methods added |

### Upload
- `scripts/upload_new_lessons.py` — uploads lessons 29-50 + patch note v1.0.6

---

## Lesson Map (Current)

### Stage 0 — Alphabet (Optional, IDs 101-105)

| File | ID | Title | Words |
|------|----|-------|-------|
| lesson_A1.json | 101 | Consonants Part 1 | 15 |
| lesson_A2.json | 102 | Consonants Part 2 | 15 |
| lesson_A3.json | 103 | Vowels | 15 |
| lesson_A4.json | 104 | Tone Marks | 14 |
| lesson_A5.json | 105 | Reading Practice | 12 |

### Stage 1 — Foundations (27 lessons)

**Unlock chain:** sequential, each needs previous ≥1★; first always open.

```
Chain: [1, 22, 11, 2, 10, 12, 3, 4, 9, 13, 14, 6, 5, 15, 19, 7, 8, 17, 18, 16, 20, 21, 29, 30, 31, 32, 33]
```

Row groupings on home screen:
| Row | Label | IDs |
|-----|-------|-----|
| 1 | First Steps | 1, 22, 11 |
| 2 | Numbers & Money | 2, 10, 12 |
| 3 | Food & Drinks | 3, 4, 9 |
| 4 | Language Basics | 13, 14, 6 |
| 5 | People & Feelings | 5, 15, 19 |
| 6 | Getting Around | 7, 8, 17, 18 |
| 7 | Home & Learning | 16, 20, 21 |
| 8 | Describing the World | 29, 30, 31 |
| 9 | Things & How They Feel | 32, 33 |

### Stage 2 — Survival Thai (16 lessons)

**Unlock condition:** All 27 Stage 1 lessons ≥1★.

```
Chain: [23, 34, 45, 35, 43, 36, 37, 38, 39, 40, 41, 42, 24, 44, 25, 26]
```

Row groupings:
| Row | Label | IDs |
|-----|-------|-----|
| 1 | Food & Emergency | 23, 34, 45 |
| 2 | Culture & Social | 35, 43, 36 |
| 3 | About You | 37, 38, 39 |
| 4 | Getting Around & Tech | 40, 41, 42, 24 |
| 5 | Numbers & Phrases | 44, 25, 26 |

### Stage 3 — Conversational Thai (5 lessons)

**Unlock condition:** All 16 Stage 2 lessons ≥1★.

```
Chain: [46, 47, 48, 49, 50]
```

Row groupings:
| Row | Label | IDs |
|-----|-------|-----|
| 1 | Language Skills | 46, 47, 48 |
| 2 | Mastery | 49, 50 |

---

## Stage Color Gradients

| Stage | Anchors |
|-------|---------|
| Stage 1 | Light green → teal → blue → deep indigo (positions 1-27) |
| Stage 2 | `#4A148C → #560D99 → ... → #E64A19` (14 stops, positions 1-16) |
| Stage 3 | `#4A148C → #6A1B9A → #E65100 → #F57F17 → #FF8F00` (5 stops) |

---

## Next Steps

1. **Run upload script** — `python scripts/upload_new_lessons.py` to push lessons 29-50 + v1.0.6 patch note to Firestore.
2. **Shorebird Patch** — `shorebird patch android --allow-asset-diffs` (new JSON assets require asset-diff flag).
3. **Stage 1 lesson expansion** — expand existing lessons (01, 22, 02, 03, 04, 06, 05, 23, 24) to 15-25 words each.
4. **Audio generation** — run `scripts/generate_audio.py` for new lessons 29-50.
5. **Visual Spotter** — add emoji fields to lessons 29 and 32 words (already have emoji keys, exercise service uses them).

---

## Game Types

| Type | Class | Toggle key | Default |
|------|-------|-----------|---------|
| Multiple Choice (EN→TH) | `McScreen` | always on | ✅ |
| Multiple Choice (TH→EN) | `McScreen` | always on | ✅ |
| Match Pairs | `PairsScreen` | `gt_match_pairs_v1` | ✅ |
| Listen & Choose | `ListenScreen` | `gt_listen_v1` | ✅ |
| Speed Tap | `SpeedTapScreen` | `gt_speed_tap_v1` | ✅ |
| Sentence Builder | `SentenceBuilderScreen` | `gt_sentence_builder_v1` | ✅ |
| Conversation Mode | `ConversationScreen` | `gt_conversation_v1` | ✅ |
| Typing Challenge | `TypingScreen` | `gt_typing_v1` | ✅ |
| Visual Spotter | `VisualSpotterScreen` | `gt_visual_spotter_v1` | ✅ |
| Opposites Challenge | `OppositesScreen` | `gt_opposites_v1` | ✅ |

---

## Services

| Service | File | Notes |
|---------|------|-------|
| LessonService | `lesson_service.dart` | `totalLessons=50`, `stage1Count=27` |
| ProgressService | `progress_service.dart` | `exportJson()`, `restoreFromJson()` for snapshot toggle |
| ExerciseService | `exercise_service.dart` | Visual spotter {3,4,9,11,16,17,29,32}; opposites for lesson 31 |
| SettingsService | `settings_service.dart` | 8 game type booleans |
| AudioService | `audio_service.dart` | TTS fallback + disk cache |
| ReviewService | `review_service.dart` | Unchanged |

---

## Firebase Integration

| Item | Status |
|------|--------|
| Firebase project | `thailingo-5d117` (asia-southeast1) |
| Google Sign In | ✅ |
| Firestore lessons | Upload via `scripts/upload_new_lessons.py` |
| `flutter analyze` | ✅ 0 issues |

> ⚠️ **Google Sign In requires SHA-1** — Add debug key SHA-1 to Firebase Console → Project Settings → Android app.

---

## Architecture Notes

- **Singleton services** with factory constructor
- **JSON-driven lessons** — every lesson is a self-contained JSON asset (`assets/lessons/`)
- **SharedPreferences** for all persistence (progress, settings, review queue)
- **Stage chains** define both unlock order and color gradient position
- **`_lessonFillColor(id)`** — looks up chain position → lerps color anchors
- **Stage 0 ID space** — uses 101-105 to avoid collision with Stage 1/2/3 IDs 1-50
