import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  static const String _key = 'thai_lab_progress_v1';
  UserProgress? _progress;

  Future<UserProgress> load() async {
    if (_progress != null) return _progress!;
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
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
    await prefs.setString(_key, jsonEncode(_progress!.toJson()));
  }

  Future<void> addXp(int amount) async {
    final p = await load();
    p.totalXp += amount;
    await save();
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
    final stars = pct >= 0.9 ? 3 : pct >= 0.7 ? 2 : 1;
    final existing = p.lessonProgress[lessonId];
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Best time: lower is better (0 = not recorded yet)
    int bestTime = existing?.bestTimeSeconds ?? 0;
    if (timeTaken != null && timeTaken.inSeconds > 0) {
      bestTime = (bestTime == 0)
          ? timeTaken.inSeconds
          : min(bestTime, timeTaken.inSeconds);
    }

    p.lessonProgress[lessonId] = LessonProgress(
      completed: true,
      stars: existing != null
          ? max(existing.stars, stars)
          : stars,
      bestScore: existing != null
          ? max(existing.bestScore, score)
          : score,
      bestAccuracy: existing != null
          ? max(existing.bestAccuracy, accuracyPct)
          : accuracyPct,
      timesPlayed: (existing?.timesPlayed ?? 0) + 1,
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
        timesPlayed: max(existing?.timesPlayed ?? 0, 1),
        bestTimeSeconds: existing?.bestTimeSeconds ?? 0,
        lastPlayedDate: existing?.lastPlayedDate ?? today,
      );
    }
    _checkAchievements(p);
    await save();
  }

  /// Clears all stored progress and resets in-memory cache.
  Future<void> clearAll() async {
    _progress = UserProgress();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  UserProgress get current => _progress ?? UserProgress();
}
