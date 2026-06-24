import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';

class MissedQuestionsService {
  static final MissedQuestionsService _instance =
      MissedQuestionsService._internal();
  factory MissedQuestionsService() => _instance;
  MissedQuestionsService._internal();

  static const _key = 'missed_questions';
  List<Word>? _cache;

  Future<List<Word>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _cache = [];
      return _cache!;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _cache = list
          .map((e) => Word.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _cache = [];
    }
    return _cache!;
  }

  Future<void> _save() async {
    if (_cache == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(_cache!.map((w) => w.toJson()).toList()));
  }

  Future<void> addMissedWord(Word word) async {
    final list = await _load();
    if (list.any((w) => w.id == word.id)) return;
    list.add(word);
    await _save();
  }

  Future<List<Word>> getMissedWords() => _load();

  Future<int> getMissedCount() async => (await _load()).length;

  Future<void> removeWord(String wordId) async {
    final list = await _load();
    final before = list.length;
    list.removeWhere((w) => w.id == wordId);
    if (list.length != before) await _save();
  }

  Future<void> clearAll() async {
    _cache = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  void invalidateCache() => _cache = null;
}
