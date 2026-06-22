import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/lesson.dart';

class LessonService {
  static final LessonService _instance = LessonService._internal();
  factory LessonService() => _instance;
  LessonService._internal();

  final Map<int, Lesson> _cache = {};
  List<Lesson>? _allLessons;
  static const int totalLessons = 15;

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

  Future<List<Lesson>> loadAllLessons() async {
    if (_allLessons != null) return _allLessons!;
    final futures = List.generate(totalLessons, (i) => loadLesson(i + 1));
    _allLessons = await Future.wait(futures);
    return _allLessons!;
  }
}
