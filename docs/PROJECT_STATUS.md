# Thailingo — Project Status

**Last updated:** 2026-07-01 (v1.2.1 — 15 New Focused Lessons)  
**App name:** Thailingo (renamed from Thai Lab)  
**Platform:** Flutter (iOS + Android)

---

## v1.2.1 Changes — 2026-07-01

### 15 New Thematically Focused Lessons (IDs 52–66)

**New Stage 2 lessons (Transport, Dining, Money, Health, Services rows):**

| ID | Title | Words |
|----|-------|-------|
| 52 | Taxis & Ride-Hailing 🚕 | 18 |
| 53 | BTS & MRT Subway 🚆 | 18 |
| 54 | At the Restaurant 🍽️ | 20 |
| 55 | At the Market & Shopping 🛍️ | 20 |
| 56 | Money & Payments 💰 | 18 |
| 57 | At the Hospital & Pharmacy 🏥 | 20 |
| 58 | At the Hotel 🏨 | 18 |
| 59 | At the Bank 🏦 | 15 |
| 60 | Thai Social Etiquette 🙏 | 18 |
| 64 | At the Office & Workplace 💼 | 18 |

**New Stage 3 lessons (About You, Daily Topics rows):**

| ID | Title | Words |
|----|-------|-------|
| 61 | Talking About Your Life 👤 | 20 |
| 62 | Talking About Feelings ❤️ | 20 |
| 63 | Talking About the Weather ⛅ | 18 |
| 65 | Making & Keeping Friends 👫 | 18 |
| 66 | Talking About Food You Like 😋 | 18 |

**Code changes:**
- `assets/lessons/lesson_52.json` through `lesson_66.json` — 15 new lesson JSON files
- `lib/services/lesson_service.dart` — `totalLessons` updated from 50 → 66
- `lib/models/user_progress.dart` — `s3Chain` extended to include 51 & 61-66; new `s2NewChain` [52-60, 64] unlocks after `allStage2Complete`
- `lib/screens/home_screen.dart` — new rows in `_stage2Rows` and `_stage3Rows`; extended `_stage2Chain` and `_stage3Chain`; emoji map for 52-66; extended color anchors
- `lib/services/patch_notes_service.dart` — patch note v1.2.1 seeded
- Total lesson count: 66 standard lessons + 10 alphabet/script bonus lessons

---

## v1.1.3 Changes — 2026-07-01

### Full Rotation Support
- `main.dart` unlocked all four orientations (was portrait-only)
- `AndroidManifest.xml` had no `screenOrientation` lock — no change needed
- `lib/utils/responsive_layout.dart` — new `ResponsiveLayout` utility (isLandscape, pagePadding, titleSize, octagonSize)

### Screen-by-Screen Landscape Layouts

| Screen | Landscape behaviour |
|--------|-------------------|
| `mc_screen.dart` | Left 40%: stimulus card — Right 60%: 2×2 choice grid |
| `speed_tap_screen.dart` | Timer bar full width — Left: word prompt — Right: 2×2 grid |
| `typing_screen.dart` | Compact prompt card (reduced padding/font), ScrollView adapts to keyboard |
| `sentence_builder_screen.dart` | Extra horizontal padding, compact sentence prompt |
| `conversation_screen.dart` | Questions phase: question card left, options right |
| `pairs_screen.dart` | Two-column layout already landscape-ready; no changes needed |
| `speed_mode_screen.dart` | Left: Thai word + phonetic + replay — Right: 2×2 answer grid |
| `skeet_shooter_screen.dart` | Forces landscape on enter; restores all orientations on exit |
| `home_screen.dart` | Lesson octagons use compact mode in landscape; wider horizontal padding |
| `result_screen.dart` | Already scrollable — no structural changes needed |
| `game_over_screen.dart` | Already scrollable — no structural changes needed |

---

## v1.1.2 Changes — 2026-06-30

### Bug Fixes
- **Stage 0 language mode** — Stage 0 now correctly shows E1-E5 (English alphabet) vs A1-A5 (Thai alphabet) based on `AppLanguage`. Added `debugPrint` to confirm mode at load time.
- **Game type toggles** — Settings screen was passing wrong keys (`'gt_match_pairs_v1'` etc.) to `SettingsService.setGameType()`. Fixed all 6 wrong keys to match switch cases (`'matchPairs'`, `'listen'`, `'speedTap'`, `'sentenceBuilder'`, `'conversation'`, `'typing'`).
- **Exercise variety in later lessons** — `buildQueue()` while loop exited after one round when pool reached 20 from a large word list, resulting in only one exercise type. Fixed with `while (pool.length < target || round < minRounds)` and raised safety break to `max(20, minRounds + 4)`. Added `debugPrint` logging to trace exercise types per queue.
- **Star calculation** — First completion with 85%+ was incorrectly awarding 2 stars. Rule: 1 star = first completion (any score), 2 stars = 2nd completion, 3 stars = 3rd completion OR 100% on first attempt.
- **Stage 0 listen phonetic leak** — `ListenScreen` showed Thai text + phonetic in the button for alphabet lessons, giving away the answer. Added `isAlphabetLesson` flag: alphabet lessons show only 🔊 icon; phonetic sublabels also hidden in answer choices.

### New Feature — Skeet Shooter Arcade Game
- `lib/screens/arcade/skeet_shooter_screen.dart` — horizontal shooting gallery
- 20 rounds, 3 lives, combo streak bonus scoring
- Thai gold (#D4A017) bubbles arc across a sunset gradient background
- High score persisted to SharedPreferences (`skeet_shooter_hs_v1`)
- Card added to `arcade_screen.dart` between Speed Mode and Survival Mode

### New Stage 3 Lesson — Real Life Conversations (lesson 51)
- `assets/lessons/lesson_51.json` — 18 words, color #6A1B9A, xpReward=40
- Topics: pharmacy, 7-Eleven, Grab, hair salon, hotel check-in, café wifi
- Added to `home_screen.dart` Stage 3 rows/chain and `user_progress.dart` completion/mastery checks
- Conversation injection frequency boosted for lesson 51

---

## v1.1.1 Changes — 2026-06-29

### Thai Lesson Names
All 50 main lessons (01-50) and 5 alphabet lessons (A1-A5) now have `thaiTitle` set. When in Learning English mode, the lesson map shows Thai lesson names via the existing `_lessonDisplayTitle()` function in `home_screen.dart`.

### English Alphabet Mode (Stage 0)
Stage 0 now switches based on `AppLanguage`:
- **learningThai** (default): Thai Alphabet (A1-A5) — consonants, vowels, tone marks, reading practice
- **learningEnglish**: English Alphabet (E1-E5) — English consonants, vowels, pronunciation rules, common words for Thai speakers

The Stage 0 entry card on the home screen updates its icon (📚 → 🔤), title ("Alphabet" → "ตัวอักษรอังกฤษ"), and subtitle accordingly.

### New Lesson JSON Files (E1-E5)
| File | ID | Title | Thai Title | Words |
|------|-----|-------|------------|-------|
| lesson_E1.json | 201 | English Consonants Part 1 | พยัญชนะอังกฤษ ตอนที่ 1 | 13 |
| lesson_E2.json | 202 | English Consonants Part 2 | พยัญชนะอังกฤษ ตอนที่ 2 | 13 |
| lesson_E3.json | 203 | English Vowels | สระอังกฤษ | 10 |
| lesson_E4.json | 204 | English Pronunciation Rules | กฎการออกเสียงอังกฤษ | 10 |
| lesson_E5.json | 205 | Common English Words | คำอังกฤษที่ใช้บ่อย | 15 |

E-series use DB IDs 201-205 for progress tracking.

### Files Changed
- `assets/lessons/lesson_29.json` through `lesson_50.json` — `thaiTitle` added
- `assets/lessons/lesson_A1.json` through `lesson_A5.json` — `thaiTitle` added
- `assets/lessons/lesson_E1.json` through `lesson_E5.json` — new English Alphabet lessons
- `lib/screens/stage0_screen.dart` — `_englishAlphabetMeta` added; mode switching via `_activeMeta`/`_dbId()`; top bar and info box text now mode-aware
- `lib/screens/home_screen.dart` — Stage 0 entry card switches icon, title, subtitle per `AppLanguage`
- `lib/services/patch_notes_service.dart` — v1.1.1 patch note added

---

## v1.1.0 Changes — 2026-06-29

### Full Thai UI Translation
When `AppLanguage == learningEnglish`, the entire app UI switches to Thai via `LocalizationService.t(key)`.

**Screens updated:**
- `home_screen.dart` — Stage titles, row labels, drawer menu items, review section, entry cards, PRACTICE header, Stage 1 stars card
- `result_screen.dart` — Perfect Score / Lesson Complete / Keep Practicing, XP Earned, Accuracy, Time, Correct, Incorrect, Words, Back to Lessons
- `game_over_screen.dart` — Out of Hearts!, Try Again, Back to Lessons, Questions, Hearts
- `lesson_screen.dart` — Exit dialog (Leave lesson? / Your progress will be lost / Keep going / Leave)
- `guide_book_screen.dart` — Tab names (The Basics, Tones Guide, Phonetics, Alphabet, Survival, Culture)
- `settings_screen.dart` — Section headers (Audio, Game Types, Learning Language, Account, Developer Mode), Sound Effects, Background Music, Reset Progress
- `stats_screen.dart` — Title, OVERVIEW/ACHIEVEMENTS/PERSONAL BESTS sections, all stat card labels

**LocalizationService additions:** ~60 new keys covering all screens above, plus Bronze/Silver/Gold medal labels and row label translations (25+ Thai row name translations).

### Profile Icon
`Icons.menu_rounded` → `Icons.person_rounded` for the circle menu button when no avatar is set.

### XP Bar Position
Removed 10px gap above XP bar/mascot row (header feels more compact).

### Firestore Patch Note
`patch_notes_service.dart` — added v1.1.0 "Full Thai UI + Profile Menu 🎉" (major) seeded via `seedInitialPatchNotes()`.

### Files Changed
- `lib/services/localization_service.dart` — ~60 new keys added to both `_en` and `_th` maps
- `lib/screens/home_screen.dart` — profile icon, XP position, all UI strings translated
- `lib/screens/result_screen.dart` — all UI strings translated
- `lib/screens/game_over_screen.dart` — all UI strings translated
- `lib/screens/lesson_screen.dart` — exit dialog translated
- `lib/screens/guide_book_screen.dart` — tab names translated
- `lib/screens/settings_screen.dart` — section headers and key labels translated
- `lib/screens/stats_screen.dart` — title and section labels translated
- `lib/services/patch_notes_service.dart` — v1.1.0 patch note added

---

## v1.0.9 Changes — 2026-06-29

### Learning English Mode — Full Exercise Direction Fix
All exercise screens now read `SettingsService().appLanguage` and swap prompt/answer direction.

| Screen | learningThai (default) | learningEnglish |
|---|---|---|
| MC | English prompt → pick Thai | Thai prompt → pick English |
| Listen | 🔊 icon → pick Thai word | Thai text+audio → pick English |
| Speed Tap | English stimulus → tap Thai | Thai stimulus → tap English |
| Pairs | Left=English, Right=Thai | Left=Thai, Right=English |
| Typing | Thai word → type phonetic | Thai word+phonetic → type English |
| Sentence Builder | English sentence → arrange Thai chips | Thai sentence → arrange English chips |

### Model Changes
- `SentenceBuilderExercise`: added `thaiSentence` (String) and `englishChips` (List<String>) fields
- All 5 static sentence entries updated with Thai sentence + English chip data

### Files Changed
- `lib/models/exercise.dart` — `SentenceBuilderExercise` new fields
- `lib/services/exercise_service.dart` — updated `_sentences` static data
- `lib/screens/exercise_screens/listen_screen.dart`
- `lib/screens/exercise_screens/speed_tap_screen.dart`
- `lib/screens/exercise_screens/pairs_screen.dart`
- `lib/screens/exercise_screens/typing_screen.dart`
- `lib/screens/exercise_screens/sentence_builder_screen.dart`

---

## v1.0.7 Changes — 2026-06-26

### Thai → English Learning Direction
- `LearningDirection` enum in `SettingsService`: `englishToThai` | `thaiToEnglish` | `mixed`
- `LocalizationService` singleton: UI string map for EN/TH labels + `directionBadge()`
- `ExerciseService.buildQueue`: direction-filtered MC type cycle (multipleChoice vs multipleChoiceTh)
- Settings screen: "Learning Direction 🔁" section with 3 radio-style options
- Lesson screen: tappable direction badge in top bar → quick-switch popup

### Stage 1 Content Expansion
All Stage 1 lessons 1-28 expanded to 15-18 words minimum (was 10-12).

### Translation Fixes
- `lesson_11.json`: phr_08 fixed to ช่วยหน่อยได้ไหม (polite help request, not generic "can you help")
- `lesson_25.json`: ช่วยด้วย labeled as "Help! (emergency)"; polite form ช่วยหน่อยได้ไหม added as hlp_01b

### UI Changes
- Hamburger menu moved to right-side `endDrawer`; new 44×44px navy circle button at top-right
  - Shows user avatar emoji when signed in, ☰ icon when guest
- Mascot repositioned to align with XP bar (bottom of header), size 70px
- Speech bubble floats at mascot head level via Column + SizedBox offset

### Firestore Updates
- All 50 lessons re-uploaded with expanded word counts
- Patch notes v1.0.6 + v1.0.7 added

### New Files
- `lib/services/localization_service.dart`

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
