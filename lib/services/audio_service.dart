import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

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
  /// never falls back to a local asset. Use for conversation lines.
  Future<void> playThai(String thaiText) async {
    if (!_soundEnabled || thaiText.isEmpty || kIsWeb) return;
    try {
      final url = _ttsUrl(thaiText);
      await _wordPlayer.setUrl(url);
      _wordPlayer.play();
    } catch (_) {}
  }

  Future<void> _playWordAudio(String audioFile, {String? thaiText}) async {
    // Priority 1: bundled asset (fast, fully offline)
    try {
      await _wordPlayer.setAsset('assets/audio/$audioFile');
      _wordPlayer.play();
      return;
    } catch (_) {}

    if (kIsWeb) return;

    // Priority 2: disk cache from a previous TTS fetch
    try {
      final cached = await _cachedFile(audioFile);
      if (cached != null && await cached.exists()) {
        await _wordPlayer.setFilePath(cached.path);
        _wordPlayer.play();
        return;
      }
    } catch (_) {}

    // Priority 3: fetch from Google TTS, play, then cache in background
    if (thaiText != null && thaiText.isNotEmpty) {
      try {
        final url = _ttsUrl(thaiText);
        await _wordPlayer.setUrl(url);
        _wordPlayer.play();
        // Cache silently so next play uses disk
        _downloadToCache(audioFile, url);
      } catch (_) {}
    }
    // Priority 4: silent skip — all strategies exhausted
  }

  String _ttsUrl(String text) =>
      'https://translate.google.com/translate_tts'
      '?ie=UTF-8&q=${Uri.encodeComponent(text)}&tl=th&client=tw-ob';

  Future<File?> _cachedFile(String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/audio_cache/$filename');
    } catch (_) {
      return null;
    }
  }

  void _downloadToCache(String filename, String url) {
    Future.microtask(() async {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final cacheDir = Directory('${dir.path}/audio_cache');
        await cacheDir.create(recursive: true);
        final file = File('${cacheDir.path}/$filename');
        if (await file.exists()) return;
        final client = HttpClient();
        final req = await client.getUrl(Uri.parse(url));
        req.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0');
        final resp = await req.close();
        if (resp.statusCode == 200) {
          await resp.pipe(file.openWrite());
        }
        client.close();
      } catch (_) {}
    });
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
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  Future<void> setMusicVolume(double v) async {
    _musicVolume = v.clamp(0.0, 1.0);
    try {
      await _musicPlayer.setVolume(_musicVolume);
    } catch (_) {}
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
    try {
      await _sfxPlayer.stop();
    } catch (_) {}
    try {
      await _clickPlayer.stop();
    } catch (_) {}
    try {
      await _wordPlayer.stop();
    } catch (_) {}
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _sfxPlayer.dispose();
    await _clickPlayer.dispose();
    await _wordPlayer.dispose();
    await _musicPlayer.dispose();
  }
}
