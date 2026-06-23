import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Separate players so clicks never interrupt sfx or word audio
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _wordPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _musicEnabled = false;
  double _musicVolume = 0.3;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get musicVolume => _musicVolume;

  void toggleSound() => _soundEnabled = !_soundEnabled;
  void setSoundEnabled(bool v) => _soundEnabled = v;

  // setAsset() already stops current playback and seeks to zero — no need for
  // explicit stop()/seek() calls, which only add latency.
  Future<void> _sfx(String asset, {bool wait = false}) async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.setAsset(asset);
      if (wait) {
        await _sfxPlayer.play();
      } else {
        _sfxPlayer.play();
      }
    } catch (_) {}
  }

  /// Plays correct ding then the Thai word audio after a short gap.
  Future<void> playCorrectThenWord(String audioFile, {String? thaiText}) async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.setAsset('assets/audio/sfx_correct.wav');
      _sfxPlayer.play();
      await Future.delayed(const Duration(milliseconds: 500));
      await _playWordAudio(audioFile, thaiText: thaiText);
    } catch (_) {}
  }

  Future<void> playCorrect() => _sfx('assets/audio/sfx_correct.wav');
  Future<void> playWrong() => _sfx('assets/audio/sfx_wrong.wav');
  Future<void> playGameOver() =>
      _sfx('assets/audio/sfx_gameover.wav', wait: true);
  Future<void> playComplete() => _sfx('assets/audio/sfx_complete.wav');
  Future<void> playCombo() => _sfx('assets/audio/sfx_combo.wav');

  /// Click uses its own isolated player so it never cuts sfx or word audio.
  Future<void> playClick() async {
    if (!_soundEnabled) return;
    try {
      await _clickPlayer.setAsset('assets/audio/sfx_click.wav');
      _clickPlayer.play();
    } catch (_) {}
  }

  Future<void> playWord(String audioFile, {String? thaiText}) async {
    if (!_soundEnabled) return;
    await _playWordAudio(audioFile, thaiText: thaiText);
  }

  /// Plays Thai text via Google TTS directly — always uses the provided text,
  /// never falls back to a local asset. Use for conversation lines where each
  /// line has unique Thai text.
  Future<void> playThai(String thaiText) async {
    if (!_soundEnabled || thaiText.isEmpty || kIsWeb) return;
    try {
      final url = 'https://translate.google.com/translate_tts'
          '?ie=UTF-8&q=${Uri.encodeComponent(thaiText)}&tl=th&client=tw-ob';
      await _wordPlayer.setUrl(url);
      _wordPlayer.play();
    } catch (_) {}
  }

  Future<void> _playWordAudio(String audioFile, {String? thaiText}) async {
    try {
      await _wordPlayer.setAsset('assets/audio/$audioFile');
      _wordPlayer.play();
      return;
    } catch (_) {}
    // Local asset missing — fall back to Google TTS (Android/iOS only)
    if (thaiText != null && thaiText.isNotEmpty && !kIsWeb) {
      try {
        final url = 'https://translate.google.com/translate_tts'
            '?ie=UTF-8&q=${Uri.encodeComponent(thaiText)}&tl=th&client=tw-ob';
        await _wordPlayer.setUrl(url);
        _wordPlayer.play();
      } catch (_) {}
    }
  }

  Future<void> startAmbientMusic() async {
    if (!_musicEnabled) return;
    try {
      await _musicPlayer.setAsset('assets/audio/ambient_bg.wav');
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.setLoopMode(LoopMode.one);
      _musicPlayer.play();
    } catch (_) {}
  }

  Future<void> stopAmbientMusic() async {
    try { await _musicPlayer.stop(); } catch (_) {}
  }

  Future<void> setMusicVolume(double v) async {
    _musicVolume = v.clamp(0.0, 1.0);
    try { await _musicPlayer.setVolume(_musicVolume); } catch (_) {}
  }

  Future<void> setMusicEnabled(bool v) async {
    _musicEnabled = v;
    if (v) {
      await startAmbientMusic();
    } else {
      await stopAmbientMusic();
    }
  }

  Future<void> stopAll() async {
    try { await _sfxPlayer.stop(); } catch (_) {}
    try { await _clickPlayer.stop(); } catch (_) {}
    try { await _wordPlayer.stop(); } catch (_) {}
    try { await _musicPlayer.stop(); } catch (_) {}
  }

  Future<void> dispose() async {
    await _sfxPlayer.dispose();
    await _clickPlayer.dispose();
    await _wordPlayer.dispose();
    await _musicPlayer.dispose();
  }
}
