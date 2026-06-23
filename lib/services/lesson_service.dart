import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/lesson.dart';

class LessonService {
  static final LessonService _instance = LessonService._internal();
  factory LessonService() => _instance;
  LessonService._internal();

  final Map<int, Lesson> _cache = {};
  final Map<String, Lesson> _alphabetCache = {};
  List<Lesson>? _allLessons;
  static const int totalLessons = 43;
  static const int stage1Count = 22;
  static const int stage2Start = 23;

  static const List<String> alphabetLessonIds = ['A1', 'A2', 'A3', 'A4', 'A5'];

  Future<Lesson> loadLesson(int id) async {
    if (_cache.containsKey(id)) return _cache[id]!;
    final paddedId = id.toString().padLeft(2, '0');
    final jsonStr =
        await rootBundle.loadString('assets/lessons/lesson_$paddedId.json');
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final lesson = Lesson.fromJson(json);
    _cache[id] = lesson;
    return lesson;
  }

  Future<Lesson> loadAlphabetLesson(String id) async {
    if (_alphabetCache.containsKey(id)) return _alphabetCache[id]!;
    final jsonStr =
        await rootBundle.loadString('assets/lessons/lesson_$id.json');
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final lesson = Lesson.fromJson(json);
    _alphabetCache[id] = lesson;
    return lesson;
  }

  Future<List<Lesson>> loadAllLessons() async {
    if (_allLessons != null) return _allLessons!;
    final futures = List.generate(totalLessons, (i) => loadLesson(i + 1));
    _allLessons = await Future.wait(futures);
    return _allLessons!;
  }

  Future<List<Lesson>> loadAlphabetLessons() async {
    return Future.wait(alphabetLessonIds.map(loadAlphabetLesson));
  }

  void clearCache() {
    _cache.clear();
    _allLessons = null;
  }
}
