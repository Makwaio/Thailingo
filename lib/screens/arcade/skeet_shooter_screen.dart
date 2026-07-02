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

// ── Trajectory pattern ────────────────────────────────────────────────────────

enum _Trajectory {
  leftToRight,
  rightToLeft,
  topLeftToBottomRight,
  topRightToBottomLeft,
  bottomLeftToTopRight,
  bottomRightToTopLeft,
  topToBottom,
  zigzag,
}

// ── Skeet data model ──────────────────────────────────────────────────────────

class _SkeetBubble {
  final Word word;
  final bool isCorrect;
  final String id;
  final _Trajectory trajectory;
  final double crossFrac;
  final double arcHeight;
  final double speed;
  final String displayText;

  double t = 0.0;
  bool popped = false;
  bool missed = false;
  double screenX = 0;
  double screenY = 0;

  bool get done => popped || missed;

  _SkeetBubble({
    required this.word,
    required this.isCorrect,
    required this.id,
    required this.trajectory,
    required this.crossFrac,
    required this.speed,
    required this.arcHeight,
    required this.displayText,
  });
}

// ── Tap/float effect ──────────────────────────────────────────────────────────

class _TapEffect {
  final UniqueKey key = UniqueKey();
  final String text;
  final Color color;
  final double x, y;
  _TapEffect({required this.text, required this.color, required this.x, required this.y});
}

// ── Fragment (explosion/sparkle) effect ───────────────────────────────────────

class _Fragment {
  final UniqueKey key = UniqueKey();
  final double startX, startY;
  final double endDx, endDy;
  final Color color;
  _Fragment({
    required this.startX,
    required this.startY,
    required this.endDx,
    required this.endDy,
    required this.color,
  });
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
  static const _skeetSize = 58.0;
  static const _topBarH   = 40.0;
  static const _bottomBarH = 52.0;

  final _rng = Random();

  // ── Language ──────────────────────────────────────────────────────────
  late final bool _isLearningEnglish;

  // ── Script toggle (Learning Thai only) ───────────────────────────────
  bool _usePhonetic = false;

  // ── Phase ─────────────────────────────────────────────────────────────
  bool _gameStarted = false;

  // ── Round state ────────────────────────────────────────────────────────
  int _currentRound = 0;
  List<Word> _targetWords = [];
  List<Word> _foundWords  = [];
  bool _roundDelaying = false;

  // ── Game state ────────────────────────────────────────────────────────
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
  final List<_Fragment> _fragments = [];

  // Correct shot translation feedback
  bool _showCorrectFeedback = false;
  String _correctFeedbackText = '';

  // Screen shake
  double _shakeX = 0;

  // ── Word pools ────────────────────────────────────────────────────────
  late List<Word> _pool;
  int _poolIdx = 0;
  late List<Word> _decoyPool;
  int _decoyIdx = 0;

  // ── Game loop (Ticker — 60fps frame-rate independent) ────────────────
  late Ticker _gameTicker;
  Duration _lastElapsed = Duration.zero;
  bool _gameActive = false;

  double _screenW = 800;
  double _screenH = 400;

  double get _playH    => _screenH - _topBarH - _bottomBarH;
  double get _playTop  => _topBarH;
  double get _playBottom => _screenH - _bottomBarH;

  // ── Level helpers ──────────────────────────────────────────────────────

  int get _level => (_correctHits ~/ 3 + 1).clamp(1, 100);

  List<_Trajectory> _availableTrajectories(int lv) {
    final list = [_Trajectory.leftToRight, _Trajectory.rightToLeft];
    if (lv >= 5)  list.addAll([_Trajectory.topLeftToBottomRight, _Trajectory.topRightToBottomLeft]);
    if (lv >= 10) list.addAll([_Trajectory.bottomLeftToTopRight, _Trajectory.bottomRightToTopLeft]);
    if (lv >= 20) list.add(_Trajectory.topToBottom);
    if (lv >= 30) list.add(_Trajectory.zigzag);
    return list;
  }

  _Trajectory _pickTrajectory() {
    final opts = _availableTrajectories(_level);
    return opts[_rng.nextInt(opts.length)];
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
    final (mn, mx) = _decoyRange(_level);
    return mn + _rng.nextInt(mx - mn + 1);
  }

  int _getTargetCount(int round) {
    if (round <= 2)  return 1;
    if (round <= 10) return 2 + _rng.nextInt(2); // 2-3
    if (round <= 20) return 3 + _rng.nextInt(2); // 3-4
    return 3 + _rng.nextInt(3);                  // 3-5
  }

  double _skeetSpeed() {
    final lv = _level;
    final minSpeed = 80.0 + lv * 4.0;
    final maxSpeed = 140.0 + lv * 6.0;
    final base = minSpeed + _rng.nextDouble() * (maxSpeed - minSpeed);
    final factor = 0.7 + _rng.nextDouble() * 0.6;
    final px = (base * factor).clamp(80.0, 380.0);
    return px / _screenW * 0.85; // fraction-of-screen per second, 15% slower
  }

  String _skeetTextForWord(Word w) {
    if (_isLearningEnglish) return w.english;
    return _usePhonetic ? w.phonetic : w.thai;
  }

  String _skeetLabel(String text) {
    if (text.length <= 14) return text;
    final words = text.split(' ');
    if (words.length > 1) {
      final two = '${words[0]} ${words[1]}';
      if (two.length <= 14) return two;
    }
    return words[0];
  }

  // ── Init / dispose ────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _isLearningEnglish =
        SettingsService().appLanguage == AppLanguage.learningEnglish;
    _usePhonetic = SettingsService().skeetUsePhonetic;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _pool      = List<Word>.from(widget.wordPool)..shuffle(_rng);
    _decoyPool = List<Word>.from(widget.wordPool)..shuffle(_rng);
    _loadHighScore();
    _gameTicker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _gameTicker.dispose();
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

  // ── Script toggle ─────────────────────────────────────────────────────

  Future<void> _toggleScript() async {
    final next = !_usePhonetic;
    setState(() => _usePhonetic = next);
    await SettingsService().setSkeetUsePhonetic(next);
    setState(() {}); // triggers rebuild — display text is computed at render time
  }

  // We compute display text at render time so toggling updates instantly
  String _skeetLabelOf(_SkeetBubble s) => _skeetLabel(_skeetTextForWord(s.word));

  // ── Round management ──────────────────────────────────────────────────

  void _startGame() {
    _currentRound = 1;
    _lastElapsed = Duration.zero;
    _gameActive = true;
    _beginRound();
  }

  Future<void> _beginRound() async {
    if (!mounted || _gameOver || _victory) return;

    // Pick target words for this round
    final count = _getTargetCount(_currentRound);
    final targets = <Word>[];
    for (int i = 0; i < count; i++) {
      targets.add(_nextTarget());
    }

    setState(() {
      _roundDelaying = true;
      _skeets.clear();
      _targetWords = targets;
      _foundWords  = [];
    });

    // 1 second pause — show target words, no skeets
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted || _gameOver || _victory) return;

    setState(() => _roundDelaying = false);

    // Spawn one correct skeet per target word
    for (final w in _targetWords) {
      _spawnCorrect(w);
      AudioService().playSkeetLaunch();
    }

    // Stagger decoy spawns 500ms apart
    final decoyCount = _targetDecoyCount();
    for (int i = 0; i < decoyCount; i++) {
      final delay = 500 * i;
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted || _gameOver || _victory) return;
        setState(() => _spawnDecoy());
        AudioService().playSkeetLaunch();
      });
    }
  }

  // ── Word selection ────────────────────────────────────────────────────

  Word _nextTarget() {
    final w = _pool[_poolIdx % _pool.length];
    _poolIdx++;
    return w;
  }

  Word _nextDecoy() {
    // Avoid matching any current target word
    Word w;
    int tries = 0;
    do {
      w = _decoyPool[_decoyIdx % _decoyPool.length];
      _decoyIdx++;
      tries++;
    } while (_targetWords.any((t) => t.id == w.id) && tries < 20);
    return w;
  }

  // ── Spawn ─────────────────────────────────────────────────────────────

  Offset _initialScreenPos(_Trajectory traj, double crossFrac) {
    const half = _skeetSize / 2;
    switch (traj) {
      case _Trajectory.leftToRight:
      case _Trajectory.topLeftToBottomRight:
      case _Trajectory.bottomLeftToTopRight:
      case _Trajectory.zigzag:
        return Offset(half, _playTop + crossFrac * (_playH - _skeetSize) + half);
      case _Trajectory.rightToLeft:
      case _Trajectory.topRightToBottomLeft:
      case _Trajectory.bottomRightToTopLeft:
        return Offset(_screenW - half, _playTop + crossFrac * (_playH - _skeetSize) + half);
      case _Trajectory.topToBottom:
        return Offset(crossFrac * (_screenW - _skeetSize) + half, _playTop + half);
    }
  }

  bool _isTooClose(double x, double y) {
    for (final s in _skeets) {
      if (s.done) continue;
      final dx = s.screenX - x;
      final dy = s.screenY - y;
      if (sqrt(dx * dx + dy * dy) < 80) return true;
    }
    return false;
  }

  (double, double, _Trajectory) _pickSpawnParams() {
    for (int attempt = 0; attempt < 5; attempt++) {
      final traj = _pickTrajectory();
      final cf   = 0.1 + _rng.nextDouble() * 0.80;
      final pos  = _initialScreenPos(traj, cf);
      if (!_isTooClose(pos.dx, pos.dy)) return (cf, 0.08 + _rng.nextDouble() * 0.18, traj);
    }
    // Fallback: accept whatever
    final traj = _pickTrajectory();
    final cf   = 0.1 + _rng.nextDouble() * 0.80;
    return (cf, 0.08 + _rng.nextDouble() * 0.18, traj);
  }

  void _spawnCorrect(Word target) {
    final (cf, arc, traj) = _pickSpawnParams();
    _skeets.add(_SkeetBubble(
      word: target,
      isCorrect: true,
      id: 'c_${_correctIdCounter++}',
      trajectory: traj,
      crossFrac: cf,
      speed: _skeetSpeed(),
      arcHeight: arc,
      displayText: _skeetLabel(_skeetTextForWord(target)),
    ));
  }

  void _spawnDecoy() {
    final decoy = _nextDecoy();
    final (cf, arc, traj) = _pickSpawnParams();
    _skeets.add(_SkeetBubble(
      word: decoy,
      isCorrect: false,
      id: 'd_${_decoyIdCounter++}',
      trajectory: traj,
      crossFrac: cf,
      speed: _skeetSpeed(),
      arcHeight: arc,
      displayText: _skeetLabel(_skeetTextForWord(decoy)),
    ));
  }

  void _respawnDecoyDelayed() {
    final delay = 1000 + _rng.nextInt(1001);
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted || _gameOver || _victory || _roundDelaying) return;
      setState(() => _spawnDecoy());
      AudioService().playSkeetLaunch();
    });
  }

  void _respawnCorrectDelayed(Word target) {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || _gameOver || _victory || _roundDelaying) return;
      if (_foundWords.any((f) => f.id == target.id)) return; // already found
      if (_targetWords.any((t) => t.id == target.id)) {
        setState(() => _spawnCorrect(target));
        AudioService().playSkeetLaunch();
      }
    });
  }

  // ── Ticker callback (60fps) ───────────────────────────────────────────

  void _onTick(Duration elapsed) {
    final prev = _lastElapsed;
    _lastElapsed = elapsed;
    if (!mounted || !_gameActive || _roundDelaying || _gameOver || _victory) return;
    if (prev == Duration.zero) return; // skip first frame (no valid dt yet)
    final dt = (elapsed - prev).inMicroseconds / 1_000_000.0;
    _updateSkeets(dt.clamp(0.0, 0.05)); // cap at 50ms to avoid jump on resume
  }

  void _updateSkeets(double dt) {
    if (_gameOver || _victory || _roundDelaying) return;

    for (final s in _skeets) {
      if (s.done) continue;
      s.t += s.speed * dt;
      if (s.t >= 1.0) {
        s.t = 1.0;
        s.missed = true;
        if (s.isCorrect) {
          _addTapEffect('Miss! 💨', Colors.white70, s.screenX, s.screenY - 30);
          _triggerFlash(Colors.red.withValues(alpha: 0.55));
          _loseLife();
          if (_gameOver) return;
          _respawnCorrectDelayed(s.word);
        } else {
          _respawnDecoyDelayed();
        }
      }
    }

    _skeets.removeWhere((s) => s.done);
    _checkLevelUp();
    setState(() {});
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
    if (skeet.done || _gameOver || _victory || _roundDelaying) return;
    _totalShots++;

    if (skeet.isCorrect) {
      skeet.popped = true;
      _totalHits++;
      _correctHits++;
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      final bonus = _streak >= 3 ? (_streak - 2) * 5 : 0;
      final points = 10 + bonus;
      _score += points;

      // Gold sparkle
      _spawnFragments(skeet.screenX, skeet.screenY, correct: true);
      AudioService().playCombo();
      _triggerFlash(Colors.green.withValues(alpha: 0.40));
      _addTapEffect('+$points 🎯', AppTheme.thaiGold, skeet.screenX, skeet.screenY - 30);

      if (_streak >= 3) {
        _addTapEffect(
          _streak >= 5 ? 'AMAZING! 🔥 x$_streak' : 'COMBO! x$_streak',
          AppTheme.thaiGold,
          _screenW / 2 - 50,
          _screenH * 0.32,
        );
      }

      // Mark word as found
      _foundWords.add(skeet.word);

      // Show translation feedback
      _correctFeedbackText = _isLearningEnglish
          ? '${skeet.word.thai} = ${skeet.word.english} ✅'
          : '${skeet.word.english} = ${skeet.word.thai} ✅';
      setState(() => _showCorrectFeedback = true);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _showCorrectFeedback = false);
      });

      _skeets.removeWhere((s) => s.done);
      _checkLevelUp();
      if (_victory) return;

      // Check if all targets found
      if (_foundWords.length >= _targetWords.length) {
        _totalRoundsPlayed++;
        _currentRound++;
        // Clear remaining decoys
        for (final s in _skeets) { s.popped = true; }
        _skeets.clear();
        _beginRound();
      }
    } else {
      // Wrong skeet
      skeet.popped = true;
      _streak = 0;
      _spawnFragments(skeet.screenX, skeet.screenY, correct: false);
      AudioService().playSkeetExplosion();
      _triggerFlash(Colors.red.withValues(alpha: 0.5));
      _addTapEffect('-❤️', Colors.redAccent, skeet.screenX, skeet.screenY - 30);
      _triggerShake();
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

  void _triggerShake() {
    setState(() => _shakeX = 3);
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) setState(() => _shakeX = -3);
    });
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _shakeX = 3);
    });
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _shakeX = 0);
    });
  }

  void _spawnFragments(double x, double y, {required bool correct}) {
    const dirs = [
      Offset(1, 0), Offset(0.7, 0.7), Offset(0, 1), Offset(-0.7, 0.7),
      Offset(-1, 0), Offset(-0.7, -0.7), Offset(0, -1), Offset(0.7, -0.7),
    ];
    final frags = <_Fragment>[];
    for (final d in dirs) {
      final dist = 35.0 + _rng.nextDouble() * 15;
      Color col;
      if (correct) {
        col = (d.dx + d.dy) > 0 ? const Color(0xFFFFD700) : Colors.white;
      } else {
        col = (d.dx + d.dy) > 0 ? Colors.orangeAccent : Colors.redAccent;
      }
      frags.add(_Fragment(startX: x, startY: y, endDx: d.dx * dist, endDy: d.dy * dist, color: col));
    }
    setState(() => _fragments.addAll(frags));
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _fragments.removeWhere((f) => frags.contains(f)));
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
    _gameActive = false;
    _saveHighScore();
    if (mounted) setState(() => _gameOver = true);
  }

  void _triggerVictory() {
    _gameActive = false;
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
      _decoyIdCounter = 0;
      _correctIdCounter = 0;
      _bgIndex = 0;
      _showAreaBanner = false;
      _displayLevel = 1;
      _showLevelUp = false;
      _flashOpacity = 0.0;
      _tapEffects.clear();
      _fragments.clear();
      _showCorrectFeedback = false;
      _roundDelaying = false;
      _currentRound = 1;
      _targetWords = [];
      _foundWords  = [];
      _pool.shuffle(_rng);
      _decoyPool.shuffle(_rng);
      _poolIdx = 0;
      _decoyIdx = 0;
    });
    _lastElapsed = Duration.zero;
    _gameActive = true;
    _beginRound();
  }

  // ── Position computation ──────────────────────────────────────────────

  Offset _skeetPosition(_SkeetBubble s, double progress) {
    const half = _skeetSize / 2;
    final pw = _screenW;
    final ph = _playH;
    final pt = _playTop;
    final arc = s.arcHeight * ph * sin(pi * progress);

    double px, py;

    switch (s.trajectory) {
      case _Trajectory.leftToRight:
        px = progress * pw - half;
        py = pt + s.crossFrac * (ph - _skeetSize) - arc;
      case _Trajectory.rightToLeft:
        px = (1 - progress) * pw - half;
        py = pt + s.crossFrac * (ph - _skeetSize) - arc;
      case _Trajectory.topLeftToBottomRight:
        px = progress * (pw + _skeetSize) - _skeetSize;
        py = pt + progress * (ph - _skeetSize);
        final sArc = s.arcHeight * min(pw, ph) * sin(pi * progress) * 0.35;
        px -= sArc;
        py += sArc * 0.5;
      case _Trajectory.topRightToBottomLeft:
        px = (1 - progress) * (pw + _skeetSize) - _skeetSize;
        py = pt + progress * (ph - _skeetSize);
        final sArc = s.arcHeight * min(pw, ph) * sin(pi * progress) * 0.35;
        px += sArc;
        py += sArc * 0.5;
      case _Trajectory.bottomLeftToTopRight:
        px = progress * (pw + _skeetSize) - _skeetSize;
        py = _playBottom - _skeetSize - progress * (ph - _skeetSize);
        final sArc = s.arcHeight * min(pw, ph) * sin(pi * progress) * 0.35;
        px -= sArc;
        py -= sArc * 0.5;
      case _Trajectory.bottomRightToTopLeft:
        px = (1 - progress) * (pw + _skeetSize) - _skeetSize;
        py = _playBottom - _skeetSize - progress * (ph - _skeetSize);
        final sArc = s.arcHeight * min(pw, ph) * sin(pi * progress) * 0.35;
        px += sArc;
        py -= sArc * 0.5;
      case _Trajectory.topToBottom:
        px = s.crossFrac * (pw - _skeetSize) + sin(pi * progress) * 0.12 * pw;
        py = pt + progress * (ph - _skeetSize);
      case _Trajectory.zigzag:
        px = progress * pw - half;
        final zigzag = s.arcHeight * ph * sin(2 * pi * progress * 2.5) * 0.5;
        py = pt + s.crossFrac * (ph - _skeetSize) + zigzag;
    }

    px = px.clamp(-half, pw - half);
    py = py.clamp(_playTop, _playBottom - _skeetSize);

    return Offset(px, py);
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
        extraContent: !_isLearningEnglish ? _buildScriptToggle() : null,
      );
    }

    return Scaffold(
      body: Transform.translate(
        offset: Offset(_shakeX, 0),
        child: Stack(
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

            // Flying skeet bubbles
            if (!_gameOver && !_victory)
              ..._skeets.map((s) => _buildSkeet(s)),

            // Fragment effects (explosion / sparkle)
            ..._fragments.map((f) => Positioned(
              left: f.startX - 3,
              top:  f.startY - 3,
              child: IgnorePointer(
                child: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: f.color),
                )
                    .animate(key: f.key)
                    .moveX(end: f.endDx, duration: 400.ms, curve: Curves.easeOut)
                    .moveY(end: f.endDy, duration: 400.ms, curve: Curves.easeOut)
                    .fadeOut(duration: 400.ms)
                    .scaleXY(end: 0.3, duration: 400.ms),
              ),
            )),

            // Floating tap effects
            ..._tapEffects.map((e) => Positioned(
                  key: e.key,
                  left: e.x - 30,
                  top:  e.y,
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

            // TOP BAR
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: _topBarH,
                color: const Color(0xAA000000),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text('⚡ $_score',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    if (!_isLearningEnglish)
                      GestureDetector(
                        onTap: _toggleScript,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _usePhonetic ? 'abc' : 'ก',
                            style: const TextStyle(color: Colors.white, fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text('Round $_currentRound',
                        style: const TextStyle(color: Colors.white70, fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Row(
                      children: List.generate(_maxLives, (i) => Text(
                        i < _lives ? '❤️' : '🖤',
                        style: const TextStyle(fontSize: 13),
                      )),
                    ).animate(key: ValueKey(_lives)).shake(duration: 350.ms),
                  ],
                ),
              ),
            ),

            // BOTTOM BAR — target words
            if (!_gameOver && !_victory)
              _buildBottomBar(),

            // Round-start delay hint
            if (_roundDelaying)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Get ready…',
                        style: TextStyle(color: Colors.white70, fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .fadeOut(delay: 700.ms, duration: 200.ms),
                  ),
                ),
              ),

            // Level-up banner
            if (_showLevelUp)
              Positioned(
                top: _screenH * 0.40, left: 0, right: 0,
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
                top: _screenH * 0.52, left: 0, right: 0,
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
                                color: AppTheme.thaiGold, fontSize: 11,
                                fontWeight: FontWeight.w800, letterSpacing: 1.5)),
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
                bottom: _bottomBarH + 12, left: 0, right: 0,
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
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700,
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
            if (_victory)  _buildVictory(),
            if (_gameOver) _buildGameOver(),
          ],
        ),
      ),
    );
  }

  // ── Script toggle widget (start screen) ───────────────────────────────

  Widget _buildScriptToggle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Show on skeets:',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ScriptToggleBtn(
              label: '🇹🇭 Thai Script',
              selected: !_usePhonetic,
              onTap: () async {
                setState(() => _usePhonetic = false);
                await SettingsService().setSkeetUsePhonetic(false);
              },
            ),
            const SizedBox(width: 10),
            _ScriptToggleBtn(
              label: '🔤 Phonetic',
              selected: _usePhonetic,
              onTap: () async {
                setState(() => _usePhonetic = true);
                await SettingsService().setSkeetUsePhonetic(true);
              },
            ),
          ],
        ),
      ],
    );
  }

  // ── Bottom target bar ─────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        height: _bottomBarH,
        decoration: const BoxDecoration(
          color: Color(0xCC000000),
          borderRadius: BorderRadius.only(
            topLeft:  Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎯 ', style: TextStyle(fontSize: 15)),
            if (_roundDelaying)
              // During delay show all targets without checkmarks
              Flexible(child: _targetWordsRow())
            else
              Flexible(child: _targetWordsRow()),
            if (_streak >= 2) ...[
              const SizedBox(width: 10),
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
          ],
        ),
      ),
    );
  }

  Widget _targetWordsRow() {
    if (_targetWords.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _targetWords.asMap().entries.map((entry) {
          final i = entry.key;
          final w = entry.value;
          final found = _foundWords.any((f) => f.id == w.id);
          // In bottom bar, always show the "question" language
          final displayStr = _isLearningEnglish
              ? '${w.thai}  •  ${w.phonetic}'
              : w.english;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('•',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                ),
              Text(
                found ? '$displayStr ✅' : displayStr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: found ? Colors.greenAccent : Colors.white,
                  decoration: found ? TextDecoration.lineThrough : null,
                  shadows: const [Shadow(color: Colors.white54, blurRadius: 6)],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Skeet bubble ──────────────────────────────────────────────────────

  Widget _buildSkeet(_SkeetBubble s) {
    if (s.done) return const SizedBox.shrink();

    final progress = s.t.clamp(0.0, 1.0);
    final pos      = _skeetPosition(s, progress);

    s.screenX = pos.dx + _skeetSize / 2;
    s.screenY = pos.dy + _skeetSize / 2;

    final label = _skeetLabelOf(s);
    final charCount = label.length;
    final double fontSize = charCount <= 6 ? 13
        : charCount <= 10 ? 11
        : charCount <= 14 ? 10
        : 9;

    return Positioned(
      left: pos.dx,
      top:  pos.dy,
      child: GestureDetector(
        onTap: () => _onSkeetTap(s),
        child: Container(
          width: _skeetSize,
          height: _skeetSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF2D2A6E), Color(0xFF1a1740)],
              stops: [0.0, 1.0],
            ),
            border: Border.all(color: const Color(0xFFD4A017), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A017).withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
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
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'Sarabun',
                  letterSpacing: 0.3,
                  height: 1.15,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 2, offset: Offset(0.5, 0.5)),
                    Shadow(color: Colors.black, blurRadius: 2, offset: Offset(-0.5, -0.5)),
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
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ── Script toggle button ──────────────────────────────────────────────────────

class _ScriptToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ScriptToggleBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFD4A017).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? const Color(0xFFD4A017)
                : Colors.white.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFD4A017) : Colors.white60,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
