# Thailingo — Project Status

**Last updated:** 2026-06-23 (v3 — Firebase Auth + Firestore leaderboard)  
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

**Row groupings** (home screen hex map):
1. Greetings & Speaking [1, 11, 13, 22]
2. Numbers & Money [2, 10, 12]
3. Food & Drinks [3, 4, 9]
4. People & Feelings [5, 15, 19, 21]
5. Time & Description [14, 6, 16]
6. Getting Around [7, 8, 18, 17]
7. Home & Life [20]

### Stage 2 — Survival Thai (IDs 23-37)

Unlock condition: ALL Stage 1 lessons (1-22) must have 3 stars.

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
| `ThaiMascot` | `ui/widgets/thai_mascot.dart` | CustomPainter Thai-dressed character |
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
| Mascot placement | Integrated in header, speech bubble above mascot |
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
1. **Add SHA-1 fingerprint** to Firebase Console to enable Google Sign In on device
2. **Create Firestore indexes** — deploy via Firebase CLI or follow the auto-generated links in the Android logcat when running `getLeaderboard()` / `getWeeklyLeaderboard()`
3. **iOS setup** — add `GoogleService-Info.plist` + update `firebase_options.dart` for iOS
4. **Friend requests system** — currently add-by-username (no request/accept flow)
5. **Weekly XP banner** — show in home screen when weekly rank changes

### Known Issues (v3)
- Weekly leaderboard requires a Firestore composite index on `leaderboard` collection (`weeklyXp DESC`). Follow the error link in logcat to auto-create it.
- `getFriends` limits to first 30 friends (Firestore `whereIn` limit).
- `getUserRank` uses `count()` aggregate — requires Firestore billing plan (Blaze) for large datasets; free tier supports up to 1M reads/day.

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
