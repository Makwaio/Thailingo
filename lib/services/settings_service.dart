import 'package:shared_preferences/shared_preferences.dart';
import 'audio_service.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _soundKey = 'settings_sound_v1';
  static const _musicKey = 'settings_music_v1';
  static const _devKey = 'settings_devmode_v1';

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _devMode = false;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get devMode => _devMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundKey) ?? true;
    _musicEnabled = prefs.getBool(_musicKey) ?? true;
    _devMode = prefs.getBool(_devKey) ?? false;
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
    // Background music not yet implemented — saves preference for future use.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, v);
  }

  Future<void> setDevMode(bool v) async {
    _devMode = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devKey, v);
  }
}
