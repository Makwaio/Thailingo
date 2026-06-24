# Thailingo — Project Status

**Last updated:** 2026-06-24 (v9 — Cloud content, audio caching, menu bottom sheet, Manage Lessons screen)  
**App name:** Thailingo (renamed from Thai Lab)  
**Platform:** Flutter (iOS + Android)

---

## Summary

Thailingo is a Bangkok Thai learning app with a Duolingo-style hex map, 3-star lesson system, multiple game types, and a full two-stage curriculum covering 37 lessons plus an optional alphabet Stage 0.

---

## App Identity

| Item | Value |
|------|-------|
| App name | Thailingo |
| `pubspec.yaml` name | `thailingo` |
| Android label | Thailingo |
| iOS display name | Thailingo |
| Theme | Thai flag colors (Red #B5001C, Navy #2D2A6E, Gold #D4A017) |
| Mascot | Custom Thai-dressed character (`BobbingMascot` / `ThaiMascot`) |

---

## Content — Lesson Map

### Stage 0 — Alphabet (Optional, IDs 101-105)

| File | ID | Title | Words |
|------|----|-------|-------|
| lesson_A1.json | 101 | Consonants Part 1 | 15 |
| lesson_A2.json | 102 | Consonants Part 2 | 15 |
| lesson_A3.json | 103 | Vowels | 15 |
| lesson_A4.json | 104 | Tone Marks | 14 |
| lesson_A5.json | 105 | Reading Practice | 12 |

- Unlocks: A1 always open; each requires previous to be **completed** (no 3-star requirement)
- Entry point: **Stage 0 card** (left 40%) on home screen → `Stage0Screen`

### Stage 1 — Foundations (IDs 1-22, `totalLessons` counted: 37 total)

| # | Title | Audio prefix | Words |
|---|-------|-------------|-------|
| 1-10 | (original lessons) | various | 10-15 |
| 11-15 | (original lessons) | various | 10-15 |
| 16 | Body Parts | body_ | 12 |
| 17 | Weather & Nature | weath_ | 12 |
| 18 | Places in Bangkok | place_ | 12 |
| 19 | Jobs & Occupations | job_ | 10 |
| 20 | Home & House | house_ | 12 |
| 21 | Classroom & Study | cls_ | 10 |
| 22 | Polite Particles | pol_ | 10 |
| 38 | Daily Life Sentences | dly_ | 12 |
| 39 | Going Out & Plans | out_ | 10 |
| 40 | Street Ordering & Shopping | str_ | 12 |
| 41 | Goodbyes & Endings | bye_ | 8 |
| 42 | Numbers 11 to 1,000,000 | nm2_ | 15 |
| 43 | Useful Slang & Fillers | slg2_ | 12 |

**Row groupings** (home screen hex map):
1. Greetings & Speaking [1, 11, 13, 22]
2. Numbers & Money [2, 10, 12]
3. Food & Drinks [3, 4, 9]
4. People & Feelings [5, 15, 19, 21]
5. Time & Description [14, 6, 16]
6. Getting Around [7, 8, 18, 17]
7. Home & Life [20]
8. Real Life Thai [38, 39, 40] ← new
9. Language Tools [41, 42, 43] ← new

> **Note:** IDs 38-43 use IDs beyond Stage 2 (23-37) to avoid collision. They appear in the Stage 1 section and unlock after all 22 Stage 1 lessons have 1+ star (same gate as Stage 2).

### Stage 2 — Survival Thai (IDs 23-37)

Unlock condition: ALL Stage 1 lessons (1-22) must have at least 1 star (completed once).

| # | Title | Audio prefix | Words |
|---|-------|-------------|-------|
| 23 | Restaurant Ordering | res_ | 10 |
| 24 | Bargaining | bar_ | 10 |
| 25 | Asking for Help | hlp_ | 10 |
| 26 | At the Hospital | hsp_ | 10 |
| 27 | Making Plans | pln_ | 10 |
| 28 | Talking About Yourself | slf_ | 10 |
| 29 | Past & Future Tense | tns_ | 10 |
| 30 | Thai Classifiers | clf_ | 10 |
| 31 | Thai Slang | slg_ | 10 |
| 32 | Numbers Advanced | nma_ | 10 |
| 33 | Relationships | rel_ | 10 |
| 34 | Technology | tch_ | 10 |
| 35 | Thai Culture | cul_ | 10 |
| 36 | Business Thai | biz_ | 10 |
| 37 | Advanced Directions | dir2_ | 10 |

**Row groupings**:
1. Food & Social [23, 24, 31, 33]
2. Help & Health [25, 26, 35]
3. Planning & Self [27, 28, 29]
4. Language Tools [30, 32, 36, 34]
5. Getting Around Advanced [37]

### Stage 3 — Coming Soon

Placeholder card shown on home screen. Not yet implemented.

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

**Minimum enabled:** 2 (enforced by `SettingsService.setGameType()`).  
**Exercise queue logic:** lives in `ExerciseService.buildQueue()`.

---

## Screens

| Screen | File | Status |
|--------|------|--------|
| Home | `home_screen.dart` | ✅ Rewritten — hex bubbles, per-stage bg colors, fixed overflow, mascot in header, onDark XP bar |
| Lesson | `lesson_screen.dart` | ✅ Updated — routes all 6 exercise types |
| Result | `result_screen.dart` | ✅ Existing |
| Game Over | `game_over_screen.dart` | ✅ Existing |
| Stats | `stats_screen.dart` | ✅ Existing |
| Settings | `settings_screen.dart` | ✅ Updated — game type toggles, 37 lesson count |
| Review | `review_screen.dart` | ✅ Existing |
| Stage 0 | `stage0_screen.dart` | ✅ New — linear A1→A5 map |
| Guide Book | `guide_book_screen.dart` | ✅ New — 6-tab Thai companion guide |
| MC Exercise | `exercise_screens/mc_screen.dart` | ✅ Existing |
| Pairs Exercise | `exercise_screens/pairs_screen.dart` | ✅ Existing |
| Listen Exercise | `exercise_screens/listen_screen.dart` | ✅ Existing |
| Speed Tap | `exercise_screens/speed_tap_screen.dart` | ✅ New |
| Sentence Builder | `exercise_screens/sentence_builder_screen.dart` | ✅ New |
| Conversation | `exercise_screens/conversation_screen.dart` | ✅ New |
| Typing Challenge | `exercise_screens/typing_screen.dart` | ✅ New |

---

## Services

| Service | File | Notes |
|---------|------|-------|
| LessonService | `lesson_service.dart` | `totalLessons=37`, `stage1Count=22`, `loadAlphabetLesson()` |
| ProgressService | `progress_service.dart` | `isLessonUnlocked()` handles Stage 2 gate (all 22 × 3★) |
| ExerciseService | `exercise_service.dart` | Reads settings toggles; 6 exercise types |
| SettingsService | `settings_service.dart` | 6 game type booleans; `setGameType()` guards minimum |
| AudioService | `audio_service.dart` | `startAmbientMusic()`, `stopAmbientMusic()`, `setMusicVolume()` |
| ReviewService | `review_service.dart` | Unchanged |

---

## Models

| Model | Changes |
|-------|---------|
| `Exercise` | Added `ExerciseType.speedTap`, `.sentenceBuilder`, `.conversation`, `.typing` |
| `SentenceBuilderExercise` | New class |
| `ConversationExercise` | New class (with `ConversationLine`, `ConversationQuestion`) |
| `UserProgress` | `allStage1Complete`, `allStage2Complete` getters; alphabet lesson unlock logic; achievements `stage1_master`, `stage2_master` |

---

## UI / Widgets

| Widget | File | Notes |
|--------|------|-------|
| `ThaiMascot` | `ui/widgets/thai_mascot.dart` | CustomPainter Muay Thai fighter — mongkol, hand wraps, guard stance |
| `BobbingMascot` | same file | Animated wrapper with bobbing motion |
| `MascotMood` | same file | `happy`, `excited`, `sad`, `encouraging`, `neutral` |
| `XpProgressBar` | `ui/widgets/common_widgets.dart` | Now has `onDark` param — white text/track, gold fill, 12px height |
| `_HexBubble` | `home_screen.dart` | Flat-top hexagon lesson node with bobbing, stars, lock/check badges |
| `_HexPainter` | `home_screen.dart` | CustomPainter drawing flat-top hexagon path |
| Theme constants | `ui/theme/app_theme.dart` | `thaiRed`, `thaiNavy`, `thaiGold` and dark variants |

---

## Assets

### Lesson JSON files
Located in `assets/lessons/`:
- `lesson_1.json` → `lesson_22.json` (Stage 1, including new 16-22)
- `lesson_23.json` → `lesson_37.json` (Stage 2)
- `lesson_A1.json` → `lesson_A5.json` (Stage 0 alphabet)

### Audio
Located in `assets/audio/`:
- SFX: `sfx_correct.wav`, `sfx_wrong.wav`, `sfx_gameover.wav`, `sfx_complete.wav`, `sfx_combo.wav`, `sfx_click.wav`
- Word audio: generated by `scripts/generate_audio.py` (requires `pip install gtts`)
- Ambient music: `ambient_bg.wav` — generated by `scripts/generate_music.py` (stdlib only)

---

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/generate_audio.py` | gTTS Thai word audio for all lessons |
| `scripts/generate_music.py` | Synthetic ambient WAV using wave module |

---

## Guide Book (Thai Companion)

`GuideBookScreen` — 6 tabs:

| Tab | Content |
|-----|---------|
| 🇹🇭 The Basics | Why Thai, how the app works, tips for success |
| 🎵 Tones Guide | 5 tones with symbols, examples, common mistakes |
| 🔤 Phonetics | Consonant and vowel pronunciation guide |
| 🔡 Alphabet | 15 most common consonants, vowels, consonant classes |
| 🆘 Survival Phrases | 20 most important phrases with usage context |
| 🙏 Thai Culture | 10 cultural tips (wai, head/feet, face, bargaining...) |

---

## Audio Audit (per-screen)

| Screen | correct ✅ | wrong ✅ | Notes |
|--------|-----------|---------|-------|
| `mc_screen.dart` | ✅ `playCorrectThenWord()` | via `lesson_screen` | |
| `pairs_screen.dart` | ✅ `playCorrect()` | via `lesson_screen` | |
| `listen_screen.dart` | ✅ `playCorrect()` | via `lesson_screen` | |
| `speed_tap_screen.dart` | ✅ `playCorrect()` | via `lesson_screen` | Fixed in v2 |
| `sentence_builder_screen.dart` | ✅ `playCorrectThenWord()` | via `lesson_screen` | Fixed in v2 |
| `typing_screen.dart` | ✅ `playCorrectThenWord()` | via `lesson_screen` | Fixed in v2 |
| `lesson_screen.dart` | — | ✅ `playWrong()`, `playCombo()`, `playComplete()`, `playGameOver()` | Central |

---

## Visual Design (v2)

| Element | Value |
|---------|-------|
| Lesson bubbles | Flat-top hexagon 68×78px, CustomPainter |
| Stage 1 bg | `#E8EAF6` (light indigo) / accent navy |
| Stage 2 bg | `#E8F5E9` (light green) / accent `#1B5E20` |
| Stage 3 bg | `#FFF3E0` (light orange) / accent `#E65100` |
| Mascot placement | Integrated in header, speech bubble to the LEFT of mascot (Row layout) |
| XP bar on header | `onDark: true` — white labels, gold fill, 12px height |
| Stage banner trophy | Only shown when `allComplete == true` |
| Entry cards | `IntrinsicHeight` — no fixed `height: 100` |

---

## Firebase Integration (v3)

### Authentication
| Item | Status |
|------|--------|
| Firebase project | `thailingo-5d117` (asia-southeast1) |
| Google Sign In | ✅ Implemented (`FirebaseService.signInWithGoogle()`) |
| Guest mode | ✅ Implemented (skips login, local-only) |
| Auth check on launch | ✅ Splash navigates to Login / ProfileSetup / Home |
| Sign out | ✅ Via ProfileScreen |

> ⚠️ **Google Sign In requires SHA-1** — Add your debug key's SHA-1 to the Firebase Console → Project Settings → Android app, then re-download `google-services.json`. Get debug SHA-1 with: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`

### Firestore Collections
| Collection | Purpose |
|-----------|---------|
| `users/{uid}` | Full user profile, streak, stageProgress, friends list |
| `leaderboard/{uid}` | Mirrored stats for fast leaderboard queries |

### New Screens (v3)
| Screen | File | Status |
|--------|------|--------|
| Login | `login_screen.dart` | ✅ Thai flag theme, Google Sign In, Guest mode |
| Profile Setup | `profile_setup_screen.dart` | ✅ Avatar grid + username — shown on first login |
| Leaderboard | `leaderboard_screen.dart` | ✅ 3 tabs: Global / Weekly / Friends, real-time streams |
| Profile | `profile_screen.dart` | ✅ Stats, rank, avatar change, sign out |

### New Services (v3)
| Service | File | Notes |
|---------|------|-------|
| FirebaseService | `firebase_service.dart` | Singleton; Google Sign In, auth state |
| UserService | `user_service.dart` | Firestore CRUD; leaderboard streams; friends |

### Next 5 Tasks
1. **Upload lessons to Firestore** — run `python scripts/upload_lessons_to_firestore.py` (requires service account key + `pip install firebase-admin`)
2. **Add Firestore index** for `lessons` collection — Firestore Console → Indexes → add composite index on `id ASC`
3. **Add SHA-1 fingerprint** to Firebase Console to enable Google Sign In on device
4. **Create Firestore indexes** for leaderboard — deploy via Firebase CLI or follow links in Android logcat
5. **iOS setup** — add `GoogleService-Info.plist` + update `firebase_options.dart` for iOS

### Known Issues (v3)
- Weekly leaderboard requires a Firestore composite index on `leaderboard` collection (`weeklyXp DESC`). Follow the error link in logcat to auto-create it.
- `getFriends` limits to first 30 friends (Firestore `whereIn` limit).
- `getUserRank` and `getWeeklyRankInfo` use `count()` aggregate — requires Firestore billing plan (Blaze) for large datasets; free tier supports up to 1M reads/day.

---

## v4 Changes — 2026-06-23

### Fix: Conversation Mode Audio
- **Root cause**: `_playCurrentLine()` was using `line.audioFile` to look up a local asset; all conversation lines shared the same (or a missing) audio file so the same sound played every time.
- **Fix**: Added `AudioService.playThai(String thaiText)` method that always uses Google TTS directly (`translate.google.com/translate_tts`), bypassing local file lookup entirely. Each conversation line now plays its own Thai text via TTS.
- **Replay button**: Added 🔊 speaker icon to each dialogue bubble in `_DialogueBubble`. Tapping it calls `AudioService().playThai(line.thai)` to replay that specific line.

### Feature: Bug Reporting System
- **`BugReportService`** (`services/bug_report_service.dart`) — singleton that submits reports to Firestore `bug_reports` collection; falls back to SharedPreferences queue when offline; `retryPendingReports()` called on app start from `main.dart`.
- **`BugReport` model** — fields: type, description, lessonId, lessonName, screen, appVersion, userId, deviceInfo, status, timestamp.
- **`showBugReportDialog()`** (`screens/bug_report_dialog.dart`) — shared dialog with bug type dropdown (6 options), multiline description field, auto-filled lesson/screen/version/device info. Shows confirmation snackbar on submit.
- **Settings screen** — "Report a Bug 🐛" action tile added to Account section. "🐛 View Bug Reports" dev button added to Developer Mode section.
- **Lesson screen** — 🐛 icon button added to top bar next to the close (X) button; opens bug report dialog pre-filled with lesson name and ID.
- **`BugReportsScreen`** (`screens/bug_reports_screen.dart`) — developer-only screen (accessed via Settings → Developer Mode); streams all reports from Firestore ordered by timestamp; shows open bug count banner; tap any report to mark as "fixed", "won't fix", or reopen.

---

## v5 Changes — 2026-06-23

### Feature: Weekly XP Rank Banner
- **`UserService.getWeeklyRankInfo(uid)`** — new method that reads the user's weekly XP from `leaderboard/{uid}`, counts how many users have higher `weeklyXp`, and returns `{'rank': int, 'weeklyXp': int}`. Returns `null` if weeklyXp is 0 or on any error.
- **Home screen banner** — shown as a `SliverToBoxAdapter` below the streak banner. Appears when the user's weekly rank improves (lower rank number than the last stored value in SharedPreferences key `weekly_rank_last`). Auto-dismisses after 6 seconds. Has a "View" button that opens the leaderboard and a dismiss ×.
- **Banner messages** by rank tier: 🥇 #1 · 🏆 top 3 · 🔥 top 10 · 📈 any improvement.
- **`_WeeklyRankBanner`** widget — gold/amber themed container, shows rank + weekly XP earned, consistent animation with streak banner (fadeIn + slideY).
- **Persistence**: SharedPreferences key `weekly_rank_last` stores the last shown rank; banner only fires again when rank numerically improves (prevents re-showing same rank on every app open).

---

## v6 Changes — 2026-06-23

### 1. Star System Rework
- **New star rules** — stars are now based on play count + accuracy:
  - ⭐ 1 star: complete the lesson once (any score)
  - ⭐⭐ 2 stars: complete 2+ times OR get 80%+ accuracy on any attempt
  - ⭐⭐⭐ 3 stars: complete 3+ times OR get 100% accuracy on any attempt
- **`LessonProgress.timesCompleted`** — new field added; migrates from old data using stored star count as estimate.
- **`ProgressService._computeStars()`** — static helper implementing the new rules.
- **Unlock gates updated** — individual lessons now unlock with 1 star (was 3); Stage 2 unlocks when all 22 Stage 1 lessons have 1+ star.
- **`allStage1Mastered` / `allStage2Mastered`** — new getters for the 3-star achievement checks; `allStage1Complete` / `allStage2Complete` now mean "1 star each" (for unlock gates).
- **Result screen** — `timesCompleted` and `newStars` passed from `lesson_screen.dart`; shows "Completed X/3" pill with next-star hint below the star row.
- **Home hex map** — stars now shown below ALL unlocked lessons (not just completed ones).
- **Dev unlock** — `unlockAllLessons()` now sets `timesCompleted = 3`.

### 2. Match Pairs Scoring Fix
- **`PairsScreen.onComplete`** signature changed from `void Function(bool)` to `void Function(int correct, int total)`.
- **Score calculation**: `correct = (totalPairs - mistakes).clamp(0, totalPairs)` — each mistake costs one point.
- **`_onPairsComplete(int, int)`** added to `lesson_screen.dart` — adds all pairs to `_totalAnswered` / `_correct` (each pair is its own point), and loses one heart per wrong match.
- **`review_screen.dart`** — updated to use the new pairs callback signature.

### 3. Patch Notes / Changelog System
- **`PatchNotesService`** (`services/patch_notes_service.dart`) — singleton; reads/writes Firestore `patch_notes` collection; tracks read versions in SharedPreferences (`patch_notes_read_v1`); seeds two initial versions (1.0.0 and 1.0.1) on first run from `main.dart`.
- **`WhatsNewScreen`** (`screens/whats_new_screen.dart`) — full changelog accessible from Settings → "What's New 📋".
- **`WhatsNewDialog`** — popup shown automatically on home screen load when there are unread notes; marks notes as read on dismiss.
- **`showAddPatchNoteDialog()`** — developer-only dialog to add new patch notes to Firestore.
- **Settings screen** — "What's New 📋" action tile added to Account section; "📋 Add Patch Note" dev button added.
- **Home screen** — checks for unread notes once per app session after `_load()` completes.

### 4. Typing Challenge Improvements
- **Fuzzy matching** — threshold raised from fixed `≤2` to `≤30% of answer length` (clamped 2-8); common romanization variants accepted: ph/p, aa/a, th/t, ee/i, oo/u, dt/t, kh/k.
- **Hint system** — 💡 Hint button shown below input field; level 1 shows first letter of each syllable; level 2 shows first 3 letters; max 2 hints per question; using a hint reduces XP reward by 5 (from 10 to 5).

---

## v7 Changes — 2026-06-23

### Muay Thai Mascot Redesign
- **`_MascotPainter` rewritten** — full CustomPainter replacement in `lib/ui/widgets/thai_mascot.dart`. New fighter draws: red Muay Thai shorts with gold waistband and center stripe, athletic trapezoid torso with muscle line, skin-tone arms in a Muay Thai guard stance (upper arm down → forearm back up → fist), white hand wraps with red stripe, oval head with short dark hair, red mongkol headband with gold border and center jewel, angled brows for focused expression. Mood variants: guard stance (happy/neutral), fists raised high (excited), drooping arms (sad), guard + one raised fist (encouraging).
- **Colors** — mongkol red `#B5001C`, mongkol gold `#D4A017`, skin `#D4956A`, dark hair/pupils `#1A0A00`.

### Header Layout Rework
- **Speech bubble moved LEFT of mascot** — `home_screen.dart` `_buildHeader()` right section changed from `Column` (bubble above mascot) to `Row` (bubble left → right-pointing tail → mascot right).
- **`_BubbleTailRightPainter`** — new `CustomPainter` in `home_screen.dart` drawing a right-pointing triangle tail; replaces downward tail from the old layout.
- **Mascot repositioned right** — mascot is the rightmost element in the header row; outer section gap reduced from 10px to 6px for tighter layout on small screens.
- **Mascot size** — reduced from 68px to 64px to compensate for the wider horizontal layout.

### Patch Notes
- **v1.0.2 seeded** in `PatchNotesService.seedInitialPatchNotes()` — title "Muay Thai Mascot Update 🥊", type "minor", 4 notes about the mascot/header/speech bubble changes.

---

## v9 Changes — 2026-06-24

### Cloud Content Pipeline
- `LessonService` now loads from **SharedPreferences cache → Firestore → local assets** in priority order
- Background Firestore sync on every launch picks up new lessons automatically
- New lessons only need to be added to Firestore — no app release needed
- `Lesson.toJson()` / `Word.toJson()` added for cache serialization

### Audio Caching
- `AudioService._playWordAudio()` now has 4-priority fallback:
  1. Bundled asset (fast, offline)
  2. Disk cache in `documents/audio_cache/` (offline after first play)
  3. Google TTS on-demand + background cache to disk
  4. Silent skip
- `path_provider` added to pubspec.yaml
- Fixes missing audio for lessons 38-43 on users who received code via Shorebird patch (no assets)

### Header Menu Redesign (Section 9)
- Replaced 4 individual icon buttons (Guide, Stats, Leaderboard, Settings) with single `☰` hamburger menu
- Menu opens as a bottom sheet with: Profile, Leaderboard, Guide Book, Settings, Bug Report, What's New, Sign Out / Sign In
- All navigation verified and wired to correct screens

### Developer Mode — Manage Lessons
- New `ManageLessonsScreen` accessible from Dev Mode in Settings
- Lists all lessons (from Firestore or local cache)
- Per-lesson "Upload to Firestore" button and "Upload All" action
- "Add Lesson" dialog for creating new lessons with words
- `scripts/upload_lessons_to_firestore.py` — bulk upload script using Firebase Admin SDK

### Patch Notes
- v1.0.4 "Cloud Content & Auto Audio 🌐" seeded as major patch

---

## v8 Changes — 2026-06-23

### 6 New Lessons (IDs 38-43) — Real Bangkok Content
Added to Stage 1 rows 8-9 (`_stage1Rows`). Unlock: lesson 38 requires all Stage 1 (1-22) complete; 39-43 chain sequentially. `LessonService.totalLessons` bumped 37 → 43.

| ID | Title | Prefix | Words |
|----|-------|--------|-------|
| 38 | Daily Life Sentences | dly_ | 12 |
| 39 | Going Out & Plans | out_ | 10 |
| 40 | Street Ordering & Shopping | str_ | 12 |
| 41 | Goodbyes & Endings | bye_ | 8 |
| 42 | Numbers 11 to 1,000,000 | nm2_ | 15 |
| 43 | Useful Slang & Fillers | slg2_ | 12 |

### 7 New Conversation Scenarios
Added to `ExerciseService._conversations` (total now 10):
- 🏪 Going to 7-Eleven
- 🍗 Ordering Kao Man Gai
- 🎬 Planning Movie Night
- 📱 Daily Check-in
- 🚗 Getting a Pickup
- 🛒 Bargaining at Chatuchak
- 🥗 Ordering Som Tam

### Audio Script
`scripts/generate_audio_38_43.py` — generates TTS audio for all 69 new words using gTTS, skipping existing files.

### Patch Notes
v1.0.3 "Real Bangkok Thai Content 🏙️" seeded in `PatchNotesService.seedInitialPatchNotes()`.

---

## Known Gaps / TODO

- [ ] Audio files not yet generated (run `scripts/generate_audio.py`)
- [ ] Ambient music not yet generated (run `scripts/generate_music.py`)
- [ ] Stage 3 content not yet implemented (placeholder only)
- [ ] pubspec.yaml `assets` section — verify all 42 lesson JSON files and new audio prefixes are listed
- [ ] iOS `Info.plist` and Android `strings.xml` — verify app name is "Thailingo" everywhere
- [ ] Review `kStageLessonIds` in `user_progress.dart` — should list all 37 + 101-105 for achievements
- [ ] Add SHA-1 fingerprint to Firebase Console for Google Sign In to work on device

---

## Architecture Notes

- **Singleton services** with factory constructor (`LessonService()`, `ProgressService()`, etc.)
- **JSON-driven lessons** — every lesson is a self-contained JSON asset
- **SharedPreferences** for all persistence (progress, settings, review queue)
- **just_audio** for audio playback (4 isolated `AudioPlayer` instances)
- **flutter_animate** for entrance animations and combos
- **Stage 0 ID space** — uses 101-105 to avoid collision with Stage 1/2 IDs 1-37
