import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_service.dart';

enum AppLanguage { learningThai, learningEnglish }

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _soundKey = 'settings_sound_v1';
  static const _musicKey = 'settings_music_v1';
  static const _devKey = 'settings_devmode_v1';

  // Game type toggle keys
  static const _gtMatchPairsKey = 'gt_match_pairs_v1';
  static const _gtListenKey = 'gt_listen_v1';
  static const _gtSpeedTapKey = 'gt_speed_tap_v1';
  static const _gtSentenceBuilderKey = 'gt_sentence_builder_v1';
  static const _gtConversationKey = 'gt_conversation_v1';
  static const _gtTypingKey = 'gt_typing_v1';
  static const _gtVisualSpotterKey = 'gt_visual_spotter_v1';
  static const _gtOppositesKey = 'gt_opposites_v1';
  static const _appLanguageKey = 'app_language';
  static const _skeetPhoneticKey = 'skeet_use_phonetic';

  static final ValueNotifier<AppLanguage> appLanguageNotifier =
      ValueNotifier(AppLanguage.learningThai);

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _devMode = false;

  bool _gtMatchPairs = true;
  bool _gtListen = true;
  bool _gtSpeedTap = true;
  bool _gtSentenceBuilder = true;
  bool _gtConversation = true;
  bool _gtTyping = true;
  bool _gtVisualSpotter = true;
  bool _gtOpposites = true;
  AppLanguage _appLanguage = AppLanguage.learningThai;
  bool _skeetUsePhonetic = false;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get devMode => _devMode;

  bool get gtMatchPairs => _gtMatchPairs;
  bool get gtListen => _gtListen;
  bool get gtSpeedTap => _gtSpeedTap;
  bool get gtSentenceBuilder => _gtSentenceBuilder;
  bool get gtConversation => _gtConversation;
  bool get gtTyping => _gtTyping;
  bool get gtVisualSpotter => _gtVisualSpotter;
  bool get gtOpposites => _gtOpposites;
  AppLanguage get appLanguage => _appLanguage;
  bool get skeetUsePhonetic => _skeetUsePhonetic;

  int get enabledGameTypeCount {
    int count = 1; // MC always on
    if (_gtMatchPairs) count++;
    if (_gtListen) count++;
    if (_gtSpeedTap) count++;
    if (_gtSentenceBuilder) count++;
    if (_gtConversation) count++;
    if (_gtTyping) count++;
    return count;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundKey) ?? true;
    _musicEnabled = prefs.getBool(_musicKey) ?? true;
    _devMode = prefs.getBool(_devKey) ?? false;
    _gtMatchPairs = prefs.getBool(_gtMatchPairsKey) ?? true;
    _gtListen = prefs.getBool(_gtListenKey) ?? true;
    _gtSpeedTap = prefs.getBool(_gtSpeedTapKey) ?? true;
    _gtSentenceBuilder = prefs.getBool(_gtSentenceBuilderKey) ?? true;
    _gtConversation = prefs.getBool(_gtConversationKey) ?? true;
    _gtTyping = prefs.getBool(_gtTypingKey) ?? true;
    _gtVisualSpotter = prefs.getBool(_gtVisualSpotterKey) ?? true;
    _gtOpposites = prefs.getBool(_gtOppositesKey) ?? true;
    final langIndex = prefs.getInt(_appLanguageKey) ?? 0;
    _appLanguage = AppLanguage.values[langIndex.clamp(0, AppLanguage.values.length - 1)];
    _skeetUsePhonetic = prefs.getBool(_skeetPhoneticKey) ?? false;
    appLanguageNotifier.value = _appLanguage;
    AudioService().setSoundEnabled(_soundEnabled);
  }

  Future<void> setSoundEnabled(bool v) async {
    _soundEnabled = v;
    AudioService().setSoundEnabled(v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, v);
  }

  Future<void> setMusicEnabled(bool v) async {
    _musicEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, v);
  }

  Future<void> setDevMode(bool v) async {
    _devMode = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devKey, v);
  }

  Future<bool> setGameType(String key, bool v) async {
    // Must keep at least 2 game types enabled (MC + 1 other)
    if (!v && enabledGameTypeCount <= 2) return false;
    final prefs = await SharedPreferences.getInstance();
    switch (key) {
      case 'matchPairs':
        _gtMatchPairs = v;
        await prefs.setBool(_gtMatchPairsKey, v);
      case 'listen':
        _gtListen = v;
        await prefs.setBool(_gtListenKey, v);
      case 'speedTap':
        _gtSpeedTap = v;
        await prefs.setBool(_gtSpeedTapKey, v);
      case 'sentenceBuilder':
        _gtSentenceBuilder = v;
        await prefs.setBool(_gtSentenceBuilderKey, v);
      case 'conversation':
        _gtConversation = v;
        await prefs.setBool(_gtConversationKey, v);
      case 'typing':
        _gtTyping = v;
        await prefs.setBool(_gtTypingKey, v);
      case 'visualSpotter':
        _gtVisualSpotter = v;
        await prefs.setBool(_gtVisualSpotterKey, v);
      case 'opposites':
        _gtOpposites = v;
        await prefs.setBool(_gtOppositesKey, v);
    }
    return true;
  }

  Future<void> setSkeetUsePhonetic(bool v) async {
    _skeetUsePhonetic = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skeetPhoneticKey, v);
  }

  Future<void> setAppLanguage(AppLanguage lang) async {
    _appLanguage = lang;
    appLanguageNotifier.value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_appLanguageKey, lang.index);
  }
}
