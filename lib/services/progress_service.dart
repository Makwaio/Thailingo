import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress.dart';
import 'firebase_service.dart';
import 'user_service.dart';
import 'settings_service.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  // Legacy key — used for migration only
  static const String _legacyKey = 'thai_lab_progress_v1';

  // Per-language keys
  static const String _keyLearningThai = 'progress_en';
  static const String _keyLearningEnglish = 'progress_th';

  String get _currentKey =>
      SettingsService().appLanguage == AppLanguage.learningEnglish
          ? _keyLearningEnglish
          : _keyLearningThai;

  UserProgress? _progress;

  Future<UserProgress> load() async {
    if (_progress != null) return _progress!;
    final prefs = await SharedPreferences.getInstance();
    // Try current language key first, fall back to legacy key for migration
    var json = prefs.getString(_currentKey);
    if (json == null) {
      json = prefs.getString(_legacyKey);
      if (json != null) {
        // Migrate legacy data into the per-language key
        await prefs.setString(_currentKey, json);
      }
    }
    if (json == null) {
      _progress = UserProgress();
    } else {
      try {
        _progress = UserProgress.fromJson(
            jsonDecode(json) as Map<String, dynamic>);
      } catch (_) {
        _progress = UserProgress();
      }
    }
    return _progress!;
  }

  Future<void> save() async {
    if (_progress == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentKey, jsonEncode(_progress!.toJson()));
  }

  /// Call BEFORE switching language — saves current progress under old key,
  /// invalidates cache so next load() reads from new key.
  Future<void> switchLanguage() async {
    await save();
    _progress = null;
  }

  Future<void> addXp(int amount) async {
    final p = await load();
    p.totalXp += amount;
    await save();
  }

  static int _computeStars(int timesCompleted, int bestAccuracy) {
    if (timesCompleted >= 3 || bestAccuracy >= 100) return 3;
    if (timesCompleted >= 2 || bestAccuracy >= 80) return 2;
    return 1;
  }

  Future<void> completeLesson({
    required int lessonId,
    required int score,
    required int maxScore,
    int peakCombo = 0,
    int wordCount = 0,
    Duration? timeTaken,
  }) async {
    final p = await load();
    final pct = maxScore > 0 ? score / maxScore : 0.0;
    final accuracyPct = (pct * 100).round();
    final existing = p.lessonProgress[lessonId];
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final timesCompleted = (existing?.timesCompleted ?? 0) + 1;
    final bestAccuracy = max(existing?.bestAccuracy ?? 0, accuracyPct);
    final newStars = _computeStars(timesCompleted, bestAccuracy);
    final stars = max(existing?.stars ?? 0, newStars);

    // Best time: lower is better (0 = not recorded yet)
    int bestTime = existing?.bestTimeSeconds ?? 0;
    if (timeTaken != null && timeTaken.inSeconds > 0) {
      bestTime = (bestTime == 0)
          ? timeTaken.inSeconds
          : min(bestTime, timeTaken.inSeconds);
    }

    p.lessonProgress[lessonId] = LessonProgress(
      completed: true,
      stars: stars,
      bestScore: existing != null
          ? max(existing.bestScore, score)
          : score,
      bestAccuracy: bestAccuracy,
      timesPlayed: (existing?.timesPlayed ?? 0) + 1,
      timesCompleted: timesCompleted,
      bestTimeSeconds: bestTime,
      lastPlayedDate: today,
    );

    // Streak
    if (p.lastPlayedDate == null) {
      p.streak = 1;
    } else if (p.lastPlayedDate != today) {
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      p.streak = p.lastPlayedDate == yesterday ? p.streak + 1 : 1;
    }
    p.lastPlayedDate = today;
    if (p.streak > p.longestStreak) p.longestStreak = p.streak;

    // Peak combo
    if (peakCombo > p.maxCombo) p.maxCombo = peakCombo;

    // Check achievements that can be evaluated here
    _checkAchievements(p);

    await save();
    _trySyncToFirestore(p);
  }

  void _checkAchievements(UserProgress p) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    void unlock(String id) => p.achievementsUnlocked.putIfAbsent(id, () => today);

    if (p.lessonProgress.values.any((lp) => lp.completed)) unlock('first_step');
    if (p.streak >= 3 || p.longestStreak >= 3) unlock('on_fire');
    if (p.lessonProgress.values.any((lp) => lp.bestAccuracy == 100)) unlock('perfectionist');
    if (p.lessonProgress.values
        .any((lp) => lp.bestTimeSeconds > 0 && lp.bestTimeSeconds < 60)) {
      unlock('speed_demon');
    }
    if (p.maxCombo >= 10) unlock('sharp_shooter');
    if (p.totalXp >= 2000) unlock('diamond');
    if (kStageLessonIds.any(
        (ids) => ids.every((id) => (p.lessonProgress[id]?.stars ?? 0) >= 3))) {
      unlock('stage_master');
    }
    if (List.generate(15, (i) => i + 1)
        .every((id) => (p.lessonProgress[id]?.stars ?? 0) >= 3)) {
      unlock('bangkok_ready');
    }
    // word_collector checked externally (needs lesson word counts)
  }

  Future<void> addWordsReviewed(int count) async {
    final p = await load();
    p.totalWordsReviewed += count;
    _checkAchievements(p);
    await save();
  }

  /// Dev mode: sets all lessons up to [totalLessons] to 3 stars / completed.
  Future<void> unlockAllLessons(int totalLessons) async {
    final p = await load();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    for (int i = 1; i <= totalLessons; i++) {
      final existing = p.lessonProgress[i];
      p.lessonProgress[i] = LessonProgress(
        completed: true,
        stars: 3,
        bestScore: max(existing?.bestScore ?? 0, 10),
        bestAccuracy: max(existing?.bestAccuracy ?? 0, 100),
        timesPlayed: max(existing?.timesPlayed ?? 0, 3),
        timesCompleted: max(existing?.timesCompleted ?? 0, 3),
        bestTimeSeconds: existing?.bestTimeSeconds ?? 0,
        lastPlayedDate: existing?.lastPlayedDate ?? today,
      );
    }
    _checkAchievements(p);
    await save();
  }

  void _trySyncToFirestore(UserProgress p) {
    final uid = FirebaseService().getUserId();
    if (uid == null) return;
    UserService().syncProgressToFirestore(uid, p).catchError((_) {});
  }

  /// Resets lesson progress only — keeps XP, streaks, and stats.
  Future<void> resetLessonsOnly() async {
    final p = await load();
    p.lessonProgress.clear();
    await save();
    _trySyncToFirestore(p);
  }

  /// Marks the given lesson IDs as accessible (stars ≥ 1, timesCompleted ≥ 1)
  /// or removes their progress entry. Does NOT award XP.
  Future<void> setLessonsAccessible(List<int> ids, bool accessible) async {
    final p = await load();
    for (final id in ids) {
      if (accessible) {
        final ex = p.lessonProgress[id];
        p.lessonProgress[id] = LessonProgress(
          completed: true,
          stars: max(ex?.stars ?? 0, 1),
          bestScore: ex?.bestScore ?? 0,
          bestAccuracy: ex?.bestAccuracy ?? 0,
          timesPlayed: ex?.timesPlayed ?? 0,
          timesCompleted: max(ex?.timesCompleted ?? 0, 1),
          bestTimeSeconds: ex?.bestTimeSeconds ?? 0,
          lastPlayedDate: ex?.lastPlayedDate,
        );
      } else {
        p.lessonProgress.remove(id);
      }
    }
    await save();
    _trySyncToFirestore(p);
  }

  /// Clears all stored progress (both language keys) and resets in-memory cache.
  Future<void> clearAll() async {
    _progress = UserProgress();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentKey);
  }

  /// Export current progress as a JSON string (for snapshot/backup).
  Future<String> exportJson() async {
    final p = await load();
    return jsonEncode(p.toJson());
  }

  /// Restore progress from a JSON string snapshot.
  Future<void> restoreFromJson(String json) async {
    try {
      final p = UserProgress.fromJson(jsonDecode(json) as Map<String, dynamic>);
      _progress = p;
      await save();
    } catch (_) {}
  }

  UserProgress get current => _progress ?? UserProgress();
}
