import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';

class ReviewWord {
  final Word word;
  final int lessonId;

  ReviewWord(this.word, this.lessonId);

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'word': {
          'id': word.id,
          'thai': word.thai,
          'phonetic': word.phonetic,
          'english': word.english,
          'image': word.image,
          'audio': word.audio,
          'example': word.example,
        },
      };

  factory ReviewWord.fromJson(Map<String, dynamic> json) {
    final w = json['word'] as Map<String, dynamic>;
    return ReviewWord(
      Word(
        id: w['id'] as String,
        thai: w['thai'] as String,
        phonetic: w['phonetic'] as String,
        english: w['english'] as String,
        image: w['image'] as String? ?? '',
        audio: w['audio'] as String? ?? '',
        example: w['example'] as String? ?? '',
      ),
      json['lessonId'] as int? ?? 0,
    );
  }
}

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  static const _key = 'thai_lab_review_v1';
  List<ReviewWord>? _cache;

  Future<List<ReviewWord>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _cache = [];
      return _cache!;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _cache =
          list.map((e) => ReviewWord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _cache = [];
    }
    return _cache!;
  }

  Future<void> _save() async {
    if (_cache == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(_cache!.map((e) => e.toJson()).toList()));
  }

  /// Adds a word to the queue if it is not already present.
  Future<void> addToQueue(Word word, int lessonId) async {
    final q = await _load();
    if (q.any((rw) => rw.word.id == word.id)) return;
    q.add(ReviewWord(word, lessonId));
    await _save();
  }

  /// Removes a word from the queue (called after a correct review answer).
  Future<void> removeFromQueue(String wordId) async {
    final q = await _load();
    final before = q.length;
    q.removeWhere((rw) => rw.word.id == wordId);
    if (q.length != before) await _save();
  }

  /// Returns all review words currently in the queue.
  Future<List<ReviewWord>> getQueue() => _load();

  /// Returns the number of words currently pending review.
  Future<int> getCount() async => (await _load()).length;

  /// Returns whether a specific word is in the queue.
  Future<bool> isInQueue(String wordId) async {
    final q = await _load();
    return q.any((rw) => rw.word.id == wordId);
  }

  /// Clears the entire review queue.
  Future<void> clearQueue() async {
    _cache = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
