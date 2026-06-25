import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson.dart';

class LessonService {
  static final LessonService _instance = LessonService._internal();
  factory LessonService() => _instance;
  LessonService._internal();

  final Map<int, Lesson> _cache = {};
  final Map<String, Lesson> _alphabetCache = {};
  List<Lesson>? _allLessons;

  // Retained for backward-compat (unlockAllLessons in settings uses this)
  static const int totalLessons = 50;
  static const int stage1Count = 27;
  static const int stage2Start = 23;

  static const List<String> alphabetLessonIds = ['A1', 'A2', 'A3', 'A4', 'A5'];
  static const _prefKey = 'lessons_cache_v2';

  // ── Public API ────────────────────────────────────────────────────────

  /// Load a single lesson. Tries local asset → Firestore in order.
  Future<Lesson> loadLesson(int id) async {
    if (_cache.containsKey(id)) return _cache[id]!;
    // Local asset (fast, works offline, covers lessons shipped in APK)
    try {
      final lesson = await _loadAsset(id);
      _cache[id] = lesson;
      return lesson;
    } catch (_) {}
    // Firestore fallback for lessons not bundled (e.g. delivered post-launch)
    if (!kIsWeb) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('lessons')
            .doc('lesson_${id.toString().padLeft(2, '0')}')
            .get();
        if (doc.exists) {
          final lesson = Lesson.fromJson(doc.data()!);
          _cache[id] = lesson;
          return lesson;
        }
      } catch (_) {}
    }
    throw Exception('Lesson $id not found in assets or Firestore');
  }

  Future<Lesson> loadAlphabetLesson(String id) async {
    if (_alphabetCache.containsKey(id)) return _alphabetCache[id]!;
    final jsonStr =
        await rootBundle.loadString('assets/lessons/lesson_$id.json');
    final lesson = Lesson.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    _alphabetCache[id] = lesson;
    return lesson;
  }

  Future<List<Lesson>> loadAlphabetLessons() async {
    return Future.wait(alphabetLessonIds.map(loadAlphabetLesson));
  }

  /// Load all lessons.
  /// Priority: SharedPreferences cache (instant) → Firestore → local assets.
  /// After a cache hit the Firestore sync runs in background to pick up new
  /// lessons without blocking the UI.
  Future<List<Lesson>> loadAllLessons() async {
    if (_allLessons != null) return _allLessons!;

    // 1. Try SharedPreferences cache (fast, works offline after first load)
    final cached = await _loadFromPrefs();
    if (cached != null && cached.isNotEmpty) {
      _allLessons = cached;
      for (final l in cached) {
        _cache[l.id] = l;
      }
      // Sync Firestore in the background so new lessons appear next launch
      _backgroundFirestoreSync();
      return _allLessons!;
    }

    // 2. Try Firestore (first install, cache miss)
    if (!kIsWeb) {
      try {
        final lessons = await _fetchFirestore();
        if (lessons.isNotEmpty) {
          _allLessons = lessons;
          for (final l in lessons) {
            _cache[l.id] = l;
          }
          await _saveToPrefs(lessons);
          return _allLessons!;
        }
      } catch (_) {}
    }

    // 3. Fall back to locally bundled assets
    final lessons = await _loadAllAssets();
    _allLessons = lessons;
    for (final l in lessons) {
      _cache[l.id] = l;
    }
    return _allLessons!;
  }

  void clearCache() {
    _cache.clear();
    _allLessons = null;
  }

  // ── Firestore helpers ─────────────────────────────────────────────────

  Future<List<Lesson>> _fetchFirestore() async {
    final snap = await FirebaseFirestore.instance
        .collection('lessons')
        .orderBy('id')
        .get();
    return snap.docs.map((d) => Lesson.fromJson(d.data())).toList();
  }

  void _backgroundFirestoreSync() {
    if (kIsWeb) return;
    Future.microtask(() async {
      try {
        final remote = await _fetchFirestore();
        if (remote.isEmpty) return;
        final localIds = _allLessons?.map((l) => l.id).toSet() ?? {};
        final hasNewLessons = remote.any((l) => !localIds.contains(l.id));
        if (hasNewLessons || remote.length > (_allLessons?.length ?? 0)) {
          _allLessons = remote;
          for (final l in remote) {
            _cache[l.id] = l;
          }
          await _saveToPrefs(remote);
        }
      } catch (_) {}
    });
  }

  // ── SharedPreferences helpers ─────────────────────────────────────────

  Future<List<Lesson>?> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      final lessons = list
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      return lessons;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToPrefs(List<Lesson> lessons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(lessons.map((l) => l.toJson()).toList());
      await prefs.setString(_prefKey, encoded);
    } catch (_) {}
  }

  // ── Local asset helpers ───────────────────────────────────────────────

  Future<Lesson> _loadAsset(int id) async {
    final paddedId = id.toString().padLeft(2, '0');
    final jsonStr =
        await rootBundle.loadString('assets/lessons/lesson_$paddedId.json');
    return Lesson.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  Future<List<Lesson>> _loadAllAssets() async {
    final futures = List.generate(totalLessons, (i) async {
      try {
        return await _loadAsset(i + 1);
      } catch (_) {
        return null;
      }
    });
    final results = await Future.wait(futures);
    return results.whereType<Lesson>().toList();
  }
}
