import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/word.dart';
import '../../services/audio_service.dart';
import '../../services/settings_service.dart';
import '../../ui/theme/app_theme.dart';
import '../../widgets/arcade_countdown_widget.dart';
import '../../widgets/skeet_background.dart';

// ── Spawn side ────────────────────────────────────────────────────────────────

enum _SpawnSide { left, right, top }

// ── Skeet data model ──────────────────────────────────────────────────────────

class _SkeetBubble {
  final Word word;
  final bool isCorrect;
  final String id;
  final _SpawnSide spawnSide;
  final double crossFrac;
  final double arcHeight;
  final double speed;
  final String displayText; // what shows on the bubble face

  double t = 0.0;
  bool popped = false;
  bool missed = false;
  double screenX = 0;
  double screenY = 0;

  bool get done => popped || missed;
  double get dtPerTick => speed * 0.05;

  _SkeetBubble({
    required this.word,
    required this.isCorrect,
    required this.id,
    required this.spawnSide,
    required this.crossFrac,
    required this.speed,
    required this.arcHeight,
    required this.displayText,
  });
}

// ── Tap effect ────────────────────────────────────────────────────────────────

class _TapEffect {
  final UniqueKey key = UniqueKey();
  final String text;
  final Color color;
  final double x, y;
  _TapEffect({required this.text, required this.color, required this.x, required this.y});
}

// ── Button widget ─────────────────────────────────────────────────────────────

class _GameButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _GameButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
      ),
    );
  }
}

// ── Main screen ───────────────────────────────────────────────────────────────

class SkeetShooterScreen extends StatefulWidget {
  final List<Word> wordPool;
  final VoidCallback? onGoHome;

  const SkeetShooterScreen({super.key, required this.wordPool, this.onGoHome});

  @override
  State<SkeetShooterScreen> createState() => _SkeetShooterScreenState();
}

class _SkeetShooterScreenState extends State<SkeetShooterScreen>
    with TickerProviderStateMixin {
  static const _maxLives = 5;
  static const _hsKeyThai = 'skeet_shooter_hs_v2';
  static const _hsKeyEng  = 'skeet_shooter_hs_eng_v1';
  static const _baseSpeed = 120.0;
  static const _topBarH   = 40.0;
  static const _bottomBarH = 58.0;

  final _rng = Random();

  // ── Language mode ─────────────────────────────────────────────────────
  late final bool _isLearningEnglish; // Thai speaker learning English

  // ── Phase ─────────────────────────────────────────────────────────────
  bool _gameStarted = false;

  // ── Game state ────────────────────────────────────────────────────────
  Word? _targetWord;
  final List<_SkeetBubble> _skeets = [];

  int _score = 0;
  int _lives = _maxLives;
  int _correctHits = 0;
  int _totalRoundsPlayed = 0;
  int _totalShots = 0;
  int _totalHits = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _highScore = 0;
  bool _gameOver = false;
  bool _victory = false;

  // Continuous decoy respawn
  int _pendingDecoyRespawns = 0;
  int _decoyIdCounter = 0;
  int _correctIdCounter = 0;

  // Background
  int _bgIndex = 0;
  bool _showAreaBanner = false;
  String _areaName = '';

  // ── Visual feedback ───────────────────────────────────────────────────
  bool _showLevelUp = false;
  int _displayLevel = 1;
  double _flashOpacity = 0.0;
  Color _flashColor = Colors.transparent;
  final List<_TapEffect> _tapEffects = [];

  // Correct shot translation feedback
  bool _showCorrectFeedback = false;
  String _correctFeedbackText = '';

  // ── Word pool ─────────────────────────────────────────────────────────
  late List<Word> _pool;
  int _poolIdx = 0;
  late List<Word> _decoyPool;
  int _decoyIdx = 0;

  // ── Game loop ─────────────────────────────────────────────────────────
  Timer? _gameLoop;

  double _screenW = 800;
  double _screenH = 400;

  // ── Play area (between top bar and bottom bar) ─────────────────────────
  double get _playH => _screenH - _topBarH - _bottomBarH;
  double get _playTop => _topBarH;
  double get _playBottom => _screenH - _bottomBarH;

  // ── Level helpers ──────────────────────────────────────────────────────

  int get _level => (_correctHits ~/ 3 + 1).clamp(1, 100);

  double _speedFrac(double px) => px / _screenW;

  _SpawnSide _getSpawnSide() {
    final lv = _level;
    if (lv < 20) return _rng.nextBool() ? _SpawnSide.left : _SpawnSide.right;
    final r = _rng.nextInt(3);
    return r == 0 ? _SpawnSide.left : r == 1 ? _SpawnSide.right : _SpawnSide.top;
  }

  (int, int) _decoyRange(int lv) {
    if (lv <= 4)  return (2, 3);
    if (lv <= 9)  return (3, 4);
    if (lv <= 14) return (4, 5);
    if (lv <= 19) return (5, 6);
    if (lv <= 29) return (5, 7);
    if (lv <= 49) return (6, 8);
    if (lv <= 74) return (7, 9);
    return (7, 10);
  }

  int _targetDecoyCount() {
    final (min, max) = _decoyRange(_level);
    return min + _rng.nextInt(max - min + 1);
  }

  double _skeetSpeed() {
    final lv = _level;
    final px = _baseSpeed * min(1.0 + lv * 0.05, 6.0);
    final frac = _speedFrac(px);
    return frac + _rng.nextDouble() * frac * 0.15;
  }

  String _correctText(Word w) => _isLearningEnglish ? w.english : w.thai;
  String _decoyText(Word w)   => _isLearningEnglish ? w.english : w.thai;

  // Truncate English text to fit on 55px bubble
  String _skeetLabel(String text) {
    if (text.length <= 12) return text;
    // Try first two words
    final words = text.split(' ');
    if (words.length > 1) {
      final twoWords = '${words[0]} ${words[1]}';
      if (twoWords.length <= 12) return twoWords;
    }
    return words[0];
  }

  // ── Init / dispose ────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _isLearningEnglish =
        SettingsService().appLanguage == AppLanguage.learningEnglish;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _pool = List<Word>.from(widget.wordPool)..shuffle(_rng);
    _decoyPool = List<Word>.from(widget.wordPool)..shuffle(_rng);
    _loadHighScore();
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  // ── High score ────────────────────────────────────────────────────────

  String get _hsKey => _isLearningEnglish ? _hsKeyEng : _hsKeyThai;

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _highScore = prefs.getInt(_hsKey) ?? 0);
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_hsKey, _score);
      _highScore = _score;
    }
  }

  // ── Game start ────────────────────────────────────────────────────────

  void _startGame() {
    _gameLoop?.cancel();
    final target = _nextTarget();
    setState(() {
      _targetWord = target;
      _skeets.clear();
      _pendingDecoyRespawns = 0;
    });
    _spawnCorrect(target);
    for (int i = 0; i < _targetDecoyCount(); i++) {
      _spawnDecoy(target);
    }
    _gameLoop = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      _tick();
    });
  }

  Word _nextTarget() {
    final w = _pool[_poolIdx % _pool.length];
    _poolIdx++;
    return w;
  }

  Word _nextDecoy(Word exclude) {
    Word w;
    int tries = 0;
    do {
      w = _decoyPool[_decoyIdx % _decoyPool.length];
      _decoyIdx++;
      tries++;
    } while (w.id == exclude.id && tries < 20);
    return w;
  }

  void _spawnCorrect(Word target) {
    final side = _getSpawnSide();
    _skeets.add(_SkeetBubble(
      word: target,
      isCorrect: true,
      id: 'correct_${_correctIdCounter++}',
      spawnSide: side,
      crossFrac: side == _SpawnSide.top
          ? 0.15 + _rng.nextDouble() * 0.70
          : 0.15 + _rng.nextDouble() * 0.55,
      speed: _skeetSpeed(),
      arcHeight: 0.12 + _rng.nextDouble() * 0.14,
      displayText: _skeetLabel(_correctText(target)),
    ));
  }

  void _spawnDecoy(Word target) {
    final decoy = _nextDecoy(target);
    final side = _getSpawnSide();
    _skeets.add(_SkeetBubble(
      word: decoy,
      isCorrect: false,
      id: 'decoy_${_decoyIdCounter++}',
      spawnSide: side,
      crossFrac: side == _SpawnSide.top
          ? 0.10 + _rng.nextDouble() * 0.80
          : 0.10 + _rng.nextDouble() * 0.65,
      speed: _skeetSpeed(),
      arcHeight: 0.08 + _rng.nextDouble() * 0.18,
      displayText: _skeetLabel(_decoyText(decoy)),
    ));
  }

  // ── Tick ──────────────────────────────────────────────────────────────

  void _tick() {
    if (_gameOver || _victory) return;

    bool correctMissed = false;

    for (final s in _skeets) {
      if (s.done) continue;
      s.t += s.dtPerTick;
      if (s.t >= 1.0) {
        s.t = 1.0;
        s.missed = true;
        if (s.isCorrect) {
          correctMissed = true;
          _addTapEffect('Miss! 💨', Colors.white70, s.screenX, s.screenY - 30);
        } else {
          _pendingDecoyRespawns++;
          _scheduleDecoyRespawn();
        }
      }
    }

    if (correctMissed) {
      _triggerFlash(Colors.red.withValues(alpha: 0.55));
      _loseLife();
      if (_gameOver) return;
      _skeets.removeWhere((s) => s.isCorrect);
      if (_targetWord != null) _spawnCorrect(_targetWord!);
    }

    _skeets.removeWhere((s) => s.done);
    _checkLevelUp();
    setState(() {});
  }

  void _scheduleDecoyRespawn() {
    final delay = 1000 + _rng.nextInt(1001);
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted || _gameOver || _victory) return;
      if (_pendingDecoyRespawns > 0 && _targetWord != null) {
        _pendingDecoyRespawns--;
        setState(() => _spawnDecoy(_targetWord!));
      }
    });
  }

  void _checkLevelUp() {
    final newLevel = _level;
    if (newLevel > _displayLevel) {
      _displayLevel = newLevel;
      final newBg = ((newLevel - 1) ~/ 5).clamp(0, 19);
      if (newBg != _bgIndex) {
        _bgIndex = newBg;
        _areaName = kSkeetBackgrounds[newBg].name;
        _showAreaBanner = true;
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (mounted) setState(() => _showAreaBanner = false);
        });
      }
      setState(() => _showLevelUp = true);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _showLevelUp = false);
      });
      if (newLevel >= 100) _triggerVictory();
    }
  }

  // ── Tap handling ──────────────────────────────────────────────────────

  void _onSkeetTap(_SkeetBubble skeet) {
    if (skeet.done || _gameOver || _victory) return;
    _totalShots++;

    if (skeet.isCorrect) {
      skeet.popped = true;
      _totalHits++;
      _correctHits++;
      _totalRoundsPlayed++;
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      final bonus = _streak >= 3 ? (_streak - 2) * 5 : 0;
      final points = 10 + bonus;
      _score += points;

      AudioService().playCombo();
      _triggerFlash(Colors.green.withValues(alpha: 0.40));
      _addTapEffect('+$points 🎯', Colors.greenAccent, skeet.screenX, skeet.screenY - 30);

      if (_streak >= 3) {
        _addTapEffect(
          _streak >= 5 ? 'AMAZING! 🔥 x$_streak' : 'COMBO! x$_streak',
          AppTheme.thaiGold,
          _screenW / 2 - 50,
          _screenH * 0.32,
        );
      }

      // Show translation feedback
      if (_targetWord != null) {
        final w = _targetWord!;
        _correctFeedbackText = _isLearningEnglish
            ? '${w.english} = ${w.thai} ✅'
            : '${w.thai} = ${w.english} ✅';
        setState(() => _showCorrectFeedback = true);
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _showCorrectFeedback = false);
        });
      }

      // Pop all decoys
      for (final s in _skeets) { if (!s.isCorrect) s.popped = true; }
      _skeets.removeWhere((s) => s.done);
      _pendingDecoyRespawns = 0;

      _checkLevelUp();
      if (_victory) return;

      final newTarget = _nextTarget();
      setState(() => _targetWord = newTarget);
      _spawnCorrect(newTarget);
      for (int i = 0; i < _targetDecoyCount(); i++) {
        _spawnDecoy(newTarget);
      }
    } else {
      _streak = 0;
      _triggerFlash(Colors.red.withValues(alpha: 0.5));
      _addTapEffect('-1 ❤️', Colors.redAccent, skeet.screenX, skeet.screenY - 30);
      _loseLife();
    }

    setState(() {});
  }

  void _loseLife() {
    _streak = 0;
    _lives--;
    AudioService().playWrong();
    if (_lives <= 0) {
      setState(() => _gameOver = true);
      Future.delayed(const Duration(milliseconds: 400), _triggerGameOver);
    }
  }

  void _triggerFlash(Color color) {
    setState(() { _flashColor = color; _flashOpacity = 1.0; });
    Future.delayed(const Duration(milliseconds: 110), () {
      if (mounted) setState(() => _flashOpacity = 0.0);
    });
  }

  void _addTapEffect(String text, Color color, double x, double y) {
    final effect = _TapEffect(text: text, color: color, x: x, y: y);
    setState(() => _tapEffects.add(effect));
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) setState(() => _tapEffects.remove(effect));
    });
  }

  void _triggerGameOver() {
    _gameLoop?.cancel();
    _saveHighScore();
    if (mounted) setState(() => _gameOver = true);
  }

  void _triggerVictory() {
    _gameLoop?.cancel();
    _saveHighScore();
    if (mounted) setState(() => _victory = true);
  }

  void _restartGame() {
    _gameLoop?.cancel();
    setState(() {
      _score = 0;
      _lives = _maxLives;
      _correctHits = 0;
      _totalRoundsPlayed = 0;
      _totalShots = 0;
      _totalHits = 0;
      _streak = 0;
      _bestStreak = 0;
      _gameOver = false;
      _victory = false;
      _skeets.clear();
      _pendingDecoyRespawns = 0;
      _decoyIdCounter = 0;
      _correctIdCounter = 0;
      _bgIndex = 0;
      _showAreaBanner = false;
      _displayLevel = 1;
      _showLevelUp = false;
      _flashOpacity = 0.0;
      _tapEffects.clear();
      _showCorrectFeedback = false;
      _pool.shuffle(_rng);
      _decoyPool.shuffle(_rng);
      _poolIdx = 0;
      _decoyIdx = 0;
    });
    _startGame();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _screenW = size.width;
    _screenH = size.height;

    if (!_gameStarted) {
      return ArcadeCountdownWidget(
        gameEmoji: '🎯',
        gameTitle: 'Skeet Shooter',
        instruction: _isLearningEnglish
            ? 'Tap the correct English word before it flies off screen!'
            : 'Tap the correct Thai word before it flies off screen!',
        bestScore: _highScore > 0 ? _highScore : null,
        onStart: () => setState(() {
          _gameStarted = true;
          _startGame();
        }),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic background
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1000),
            child: SizedBox.expand(
              key: ValueKey(_bgIndex),
              child: SkeetBackgroundWidget(bg: kSkeetBackgrounds[_bgIndex]),
            ),
          ),

          // Screen edge flash
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 280),
                opacity: _flashOpacity,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _flashColor, width: 12),
                  ),
                ),
              ),
            ),
          ),

          // Flying skeet bubbles (play area only)
          if (!_gameOver && !_victory)
            ..._skeets.map((s) => _buildSkeet(s)),

          // Floating tap effects
          ..._tapEffects.map((e) => Positioned(
                key: e.key,
                left: e.x - 30,
                top: e.y,
                child: IgnorePointer(
                  child: Text(
                    e.text,
                    style: TextStyle(
                      color: e.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  )
                      .animate()
                      .moveY(begin: 0, end: -52, duration: 700.ms, curve: Curves.easeOut)
                      .fadeOut(delay: 400.ms, duration: 300.ms),
                ),
              )),

          // TOP BAR — hearts | level | score
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: _topBarH,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Hearts
                      Row(
                        children: List.generate(_maxLives, (i) => Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Text(i < _lives ? '❤️' : '🖤',
                              style: const TextStyle(fontSize: 16)),
                        )),
                      ).animate(key: ValueKey(_lives)).shake(duration: 350.ms),
                      const Spacer(),
                      // Level
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Lv $_displayLevel',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      // Score
                      Text('$_score',
                          style: const TextStyle(
                              color: AppTheme.thaiGold, fontSize: 20, fontWeight: FontWeight.w900)),
                      const Text(' pts',
                          style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BOTTOM BAR — target word
          if (_targetWord != null && !_gameOver && !_victory)
            _buildBottomBar(_targetWord!),

          // Level-up banner
          if (_showLevelUp)
            Positioned(
              top: _screenH * 0.40,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B00), Color(0xFFD4A017)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.6), blurRadius: 16)],
                  ),
                  child: Text('LEVEL $_displayLevel! 🚀',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                )
                    .animate()
                    .scale(begin: const Offset(0.5, 0.5), duration: 300.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 200.ms),
              ),
            ),

          // NEW AREA banner
          if (_showAreaBanner)
            Positioned(
              top: _screenH * 0.52,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.thaiGold.withValues(alpha: 0.75), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✨ NEW AREA!',
                          style: TextStyle(
                              color: AppTheme.thaiGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5)),
                      Text(_areaName,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .fadeOut(delay: 1800.ms, duration: 400.ms),
              ),
            ),

          // Correct shot translation feedback
          if (_showCorrectFeedback)
            Positioned(
              bottom: _bottomBarH + 12,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Text(
                    _correctFeedbackText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                    ),
                  ),
                )
                    .animate()
                    .slideY(begin: 0.4, end: 0, duration: 280.ms, curve: Curves.easeOut)
                    .fadeIn(duration: 200.ms)
                    .fadeOut(delay: 1000.ms, duration: 400.ms),
              ),
            ),

          // Overlays
          if (_victory) _buildVictory(),
          if (_gameOver) _buildGameOver(),
        ],
      ),
    );
  }

  // ── Bottom target bar ─────────────────────────────────────────────────

  Widget _buildBottomBar(Word target) {
    final findLabel = _isLearningEnglish ? '🎯 หา:' : '🎯 Find:';
    final mainText  = _isLearningEnglish ? target.thai    : target.english;
    final subText   = _isLearningEnglish
        ? '${target.phonetic} • ${target.english}'
        : target.phonetic;

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        height: _bottomBarH,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.78),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Text(findLabel,
                style: const TextStyle(
                    color: AppTheme.thaiGold, fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                    ),
                  ),
                  if (subText.isNotEmpty)
                    Text(
                      subText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            // Streak indicator
            if (_streak >= 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.thaiGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.thaiGold.withValues(alpha: 0.5)),
                ),
                child: Text('🔥 x$_streak',
                    style: const TextStyle(
                        color: AppTheme.thaiGold, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
      ),
    );
  }

  // ── Skeet bubble ──────────────────────────────────────────────────────

  Widget _buildSkeet(_SkeetBubble s) {
    if (s.done) return const SizedBox.shrink();

    const skeetSize = 55.0;
    final progress = s.t.clamp(0.0, 1.0);
    final label = s.displayText;

    // Adaptive font size for English text
    double fontSize;
    if (_isLearningEnglish) {
      if (label.length > 12) {
        fontSize = 8.0;
      } else if (label.length > 8) {
        fontSize = 9.0;
      } else {
        fontSize = 10.0;
      }
    } else {
      fontSize = 11.0;
    }

    double px, py;

    switch (s.spawnSide) {
      case _SpawnSide.left:
        final arcY = s.arcHeight * _playH * sin(pi * progress);
        px = progress * _screenW - skeetSize / 2;
        py = _playTop + s.crossFrac * (_playH - skeetSize) - arcY;
      case _SpawnSide.right:
        final arcY = s.arcHeight * _playH * sin(pi * progress);
        px = (1.0 - progress) * _screenW - skeetSize / 2;
        py = _playTop + s.crossFrac * (_playH - skeetSize) - arcY;
      case _SpawnSide.top:
        px = (s.crossFrac + sin(pi * progress) * 0.12) * _screenW - skeetSize / 2;
        py = _playTop + progress * (_playH - skeetSize);
    }

    // Clamp inside play area
    px = px.clamp(-skeetSize / 2, _screenW - skeetSize / 2);
    py = py.clamp(_playTop, _playBottom - skeetSize);

    s.screenX = px + skeetSize / 2;
    s.screenY = py + skeetSize / 2;

    return Positioned(
      left: px,
      top: py,
      child: GestureDetector(
        onTap: () => _onSkeetTap(s),
        child: Container(
          width: skeetSize,
          height: skeetSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: s.isCorrect
                  ? const [Color(0xFFFFEA60), Color(0xFFFFD740), Color(0xFFB8860B)]
                  : const [Color(0xFFFFD740), Color(0xFFC8A010), Color(0xFF906800)],
              stops: const [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD740).withValues(
                    alpha: s.isCorrect ? 0.70 : 0.35),
                blurRadius: s.isCorrect ? 16 : 8,
                spreadRadius: s.isCorrect ? 2 : 0,
              ),
            ],
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.50), width: 2),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  shadows: const [
                    Shadow(color: Colors.black87, blurRadius: 6),
                    Shadow(color: Colors.black54, blurRadius: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Game Over overlay ─────────────────────────────────────────────────

  Widget _buildGameOver() {
    final isNewHigh = _score > 0 && _score >= _highScore;
    final accuracy = _totalShots > 0
        ? (_totalHits / _totalShots * 100).round()
        : 0;

    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0533), Color(0xFF2D0C00)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppTheme.thaiGold.withValues(alpha: 0.55), width: 2),
            boxShadow: [BoxShadow(
                color: AppTheme.thaiGold.withValues(alpha: 0.15), blurRadius: 24)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isNewHigh ? '🏆 NEW HIGH SCORE!' : '💀 GAME OVER',
                style: TextStyle(
                    color: isNewHigh ? AppTheme.thaiGold : Colors.white,
                    fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              _statRow('Level Reached', 'Lv $_displayLevel', AppTheme.thaiGold),
              _statRow('Score', '$_score pts', Colors.white),
              _statRow('Accuracy', '$accuracy%', Colors.white),
              _statRow('Best Combo', '🔥 x$_bestStreak', Colors.orangeAccent),
              _statRow('Rounds', '$_totalRoundsPlayed', Colors.white70),
              if (_highScore > 0 && !isNewHigh)
                _statRow('High Score', '$_highScore pts', Colors.white38),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: _GameButton(
                      label: '▶  Play Again',
                      color: AppTheme.thaiRed,
                      onTap: _restartGame)),
                  const SizedBox(width: 12),
                  Expanded(child: _GameButton(
                      label: '← Exit',
                      color: Colors.white.withValues(alpha: 0.12),
                      onTap: () => Navigator.pop(context))),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).scale(
        begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack);
  }

  // ── Victory overlay ───────────────────────────────────────────────────

  Widget _buildVictory() {
    final accuracy = _totalShots > 0
        ? (_totalHits / _totalShots * 100).round()
        : 0;

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A1A00), Color(0xFF4A3000), Color(0xFF2A1A00)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.thaiGold, width: 2.5),
            boxShadow: [BoxShadow(
                color: AppTheme.thaiGold.withValues(alpha: 0.4), blurRadius: 32)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              const Text('LEGENDARY!',
                  style: TextStyle(
                      color: AppTheme.thaiGold, fontSize: 28,
                      fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 4),
              const Text('You reached Level 100!',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 20),
              _statRow('Final Score', '$_score pts', AppTheme.thaiGold),
              _statRow('Accuracy', '$accuracy%', Colors.white),
              _statRow('Best Combo', '🔥 x$_bestStreak', Colors.orangeAccent),
              _statRow('Rounds', '$_totalRoundsPlayed', Colors.white70),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: _GameButton(
                      label: '▶  Play Again',
                      color: AppTheme.thaiRed,
                      onTap: _restartGame)),
                  const SizedBox(width: 12),
                  Expanded(child: _GameButton(
                      label: '← Exit',
                      color: Colors.white.withValues(alpha: 0.12),
                      onTap: () => Navigator.pop(context))),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
        begin: const Offset(0.85, 0.85), curve: Curves.elasticOut);
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
