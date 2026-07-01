import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/word.dart';
import '../../services/audio_service.dart';
import '../../ui/theme/app_theme.dart';
import '../../widgets/arcade_countdown_widget.dart';

class SkeetShooterScreen extends StatefulWidget {
  final List<Word> wordPool;
  final VoidCallback? onGoHome;

  const SkeetShooterScreen({
    super.key,
    required this.wordPool,
    this.onGoHome,
  });

  @override
  State<SkeetShooterScreen> createState() => _SkeetShooterScreenState();
}

class _SkeetShooterScreenState extends State<SkeetShooterScreen>
    with TickerProviderStateMixin {
  static const _totalRounds = 20;
  static const _maxLives = 3;
  static const _hsKey = 'skeet_shooter_hs_v1';
  static const _baseSpeed = 120.0; // px/s at level 1

  final _rng = Random();

  // ── Phase ─────────────────────────────────────────────────────────────
  bool _gameStarted = false;

  // ── Game state ────────────────────────────────────────────────────────
  Word? _targetWord;
  final List<_SkeetBubble> _skeets = [];
  List<_SkeetBubble> _pendingSkeets = [];
  int _launchGapMs = 0;
  int _msSinceLaunch = 0;

  int _score = 0;
  int _lives = _maxLives;
  int _round = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _highScore = 0;
  bool _gameOver = false;
  bool _transitioning = false;
  int _currentLevel = 1;

  // ── Visual feedback ───────────────────────────────────────────────────
  bool _showLevelUp = false;
  double _flashOpacity = 0.0;
  Color _flashColor = Colors.transparent;
  final List<_TapEffect> _tapEffects = [];

  // ── Word pool ─────────────────────────────────────────────────────────
  late List<Word> _pool;
  int _poolIdx = 0;

  // ── Game loop ─────────────────────────────────────────────────────────
  Timer? _gameLoop;

  double _screenW = 800;
  double _screenH = 400;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _pool = List<Word>.from(widget.wordPool)..shuffle(_rng);
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

  // ── Level helpers ──────────────────────────────────────────────────────

  int get _level => (_round ~/ 3) + 1;

  int _skeetsForLevel(int lv) {
    if (lv >= 15) return 1 + _rng.nextInt(4);
    if (lv >= 10) return 1 + _rng.nextInt(3);
    if (lv >= 5) return 1 + _rng.nextInt(2);
    return 1;
  }

  int _launchGapMsForLevel(int lv) {
    if (lv >= 15) return 500;
    if (lv >= 10) return 600;
    if (lv >= 5) return 800;
    return 0;
  }

  double _speedFrac(double px) => px / _screenW;

  // ── Loading ───────────────────────────────────────────────────────────

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

  // ── Round management ──────────────────────────────────────────────────

  void _startRound() {
    if (!mounted) return;
    _gameLoop?.cancel();

    final lv = _level;
    final speedMult = 1.0 + (lv * 0.08);
    final baseFrac = _speedFrac(_baseSpeed * speedMult);

    // Level-up banner
    if (lv > _currentLevel) {
      _currentLevel = lv;
      setState(() => _showLevelUp = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _showLevelUp = false);
      });
    } else {
      _currentLevel = lv;
    }

    final target = _pool[_poolIdx % _pool.length];
    _poolIdx++;

    final count = _skeetsForLevel(lv);
    final gapMs = _launchGapMsForLevel(lv);

    // Staggered arc heights/y-fractions to prevent visual overlap
    const arcH = [0.14, 0.26, 0.08, 0.32];
    const yFrac = [0.38, 0.20, 0.58, 0.16];

    final decoys = _pool.where((w) => w.id != target.id).toList()..shuffle(_rng);
    final correctSlot = _rng.nextInt(count);
    final allSkeets = <_SkeetBubble>[];
    int decoyIdx = 0;

    for (int i = 0; i < count; i++) {
      final isCorrect = i == correctSlot;
      final word = isCorrect ? target : decoys[decoyIdx++ % decoys.length];
      allSkeets.add(_SkeetBubble(
        word: word,
        isCorrect: isCorrect,
        id: isCorrect ? 'correct_$_round' : 'decoy_${_round}_$i',
        startFromLeft: _rng.nextBool(),
        yFraction: yFrac[i % yFrac.length],
        speed: baseFrac + _rng.nextDouble() * baseFrac * 0.15,
        arcHeight: arcH[i % arcH.length],
      ));
    }

    setState(() {
      _targetWord = target;
      _skeets.clear();
      _pendingSkeets = count > 1 ? allSkeets.sublist(1) : [];
      _skeets.add(allSkeets[0]);
      _launchGapMs = gapMs;
      _msSinceLaunch = 0;
      _transitioning = false;
    });

    _gameLoop = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      _tick();
    });
  }

  void _tick() {
    if (_gameOver || _transitioning) return;

    // Sequential launch of pending skeets
    if (_pendingSkeets.isNotEmpty && _launchGapMs > 0) {
      _msSinceLaunch += 50;
      if (_msSinceLaunch >= _launchGapMs) {
        _msSinceLaunch = 0;
        setState(() => _skeets.add(_pendingSkeets.removeAt(0)));
        return;
      }
    }

    bool correctMissed = false;

    for (final s in _skeets) {
      if (s.popped || s.missed) continue;
      s.t += s.dtPerTick;
      if (s.t >= 1.0) {
        s.t = 1.0;
        s.missed = true;
        if (s.isCorrect) {
          correctMissed = true;
          final edgeX = s.startFromLeft ? _screenW - 90.0 : 20.0;
          final edgeY = s.yFraction * (_screenH * 0.55) + 60;
          _addTapEffect('Miss! 💨', Colors.white70, edgeX, edgeY);
        }
      }
    }

    if (correctMissed) {
      _triggerFlash(Colors.red.withValues(alpha: 0.55));
      _loseLife();
      if (_gameOver) return;
    }

    final allActiveHandled = _skeets.every((s) => s.popped || s.missed);
    if (allActiveHandled && _pendingSkeets.isEmpty && !_transitioning) {
      _onRoundEnd();
    } else {
      setState(() {});
    }
  }

  void _onRoundEnd() {
    _gameLoop?.cancel();
    setState(() => _transitioning = true);
    _round++;
    if (_round >= _totalRounds) {
      Future.delayed(const Duration(milliseconds: 600), _triggerGameOver);
    } else {
      Future.delayed(const Duration(milliseconds: 300), _startRound);
    }
  }

  // ── Tap handling ──────────────────────────────────────────────────────

  void _onSkeetTap(_SkeetBubble skeet) {
    if (skeet.popped || skeet.missed || _transitioning || _gameOver) return;
    skeet.popped = true;

    if (skeet.isCorrect) {
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      final bonus = _streak >= 3 ? (_streak - 2) * 5 : 0;
      final points = 10 + bonus;
      _score += points;

      AudioService().playCombo();
      _triggerFlash(Colors.green.withValues(alpha: 0.45));
      _addTapEffect('+$points 🎯', Colors.greenAccent, skeet.screenX, skeet.screenY - 30);

      if (_streak >= 3) {
        _addTapEffect(
          _streak >= 5 ? 'AMAZING! 🔥 x$_streak' : 'COMBO! x$_streak',
          AppTheme.thaiGold,
          _screenW / 2 - 50,
          _screenH * 0.32,
        );
      }

      for (final s in _skeets) {
        if (!s.isCorrect) s.popped = true;
      }
      _pendingSkeets.clear();
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
      Future.delayed(const Duration(milliseconds: 400), _triggerGameOver);
      setState(() => _gameOver = true);
    } else {
      setState(() {});
    }
  }

  void _triggerFlash(Color color) {
    setState(() {
      _flashColor = color;
      _flashOpacity = 1.0;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
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

  void _restartGame() {
    _gameLoop?.cancel();
    setState(() {
      _score = 0;
      _lives = _maxLives;
      _round = 0;
      _streak = 0;
      _bestStreak = 0;
      _gameOver = false;
      _transitioning = false;
      _skeets.clear();
      _pendingSkeets.clear();
      _pool.shuffle(_rng);
      _poolIdx = 0;
      _currentLevel = 1;
      _showLevelUp = false;
      _flashOpacity = 0.0;
      _tapEffects.clear();
    });
    _startRound();
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
        instruction: 'Tap the correct Thai word before it flies off screen!',
        bestScore: _highScore > 0 ? _highScore : null,
        onStart: () => setState(() {
          _gameStarted = true;
          _startRound();
        }),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Sunset sky background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D0620),
                  Color(0xFF4A1010),
                  Color(0xFFB83A10),
                  Color(0xFFF5832A),
                  Color(0xFFF5C842),
                ],
                stops: [0.0, 0.25, 0.55, 0.8, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Ground strip
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 56,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0A00), Color(0xFF2D1500)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
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
                    border: Border.all(color: _flashColor, width: 10),
                  ),
                ),
              ),
            ),
          ),

          // Flying skeet bubbles
          if (!_gameOver)
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
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                  )
                      .animate()
                      .moveY(
                          begin: 0,
                          end: -52,
                          duration: 700.ms,
                          curve: Curves.easeOut)
                      .fadeOut(delay: 400.ms, duration: 300.ms),
                ),
              )),

          // HUD
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Lives
                          Row(
                            children: List.generate(
                              _maxLives,
                              (i) => Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Text(
                                  i < _lives ? '❤️' : '🖤',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Level + Round
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Lv$_currentLevel · Round ${(_round + 1).clamp(1, _totalRounds)}/$_totalRounds',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          const Spacer(),
                          // Score
                          Text(
                            '$_score',
                            style: const TextStyle(
                                color: AppTheme.thaiGold,
                                fontSize: 22,
                                fontWeight: FontWeight.w900),
                          ),
                          const Text(' pts',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Round progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _round / _totalRounds,
                          minHeight: 3,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.thaiGold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Target card
                if (_targetWord != null && !_gameOver)
                  _buildTargetCard(_targetWord!),
              ],
            ),
          ),

          // Level-up banner
          if (_showLevelUp)
            Positioned(
              top: _screenH * 0.40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFD4A017)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.6),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Text(
                    'LEVEL $_currentLevel! 🚀',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                )
                    .animate()
                    .scale(
                        begin: const Offset(0.5, 0.5),
                        duration: 300.ms,
                        curve: Curves.elasticOut)
                    .fadeIn(duration: 200.ms),
              ),
            ),

          // Back button
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // Game-over overlay
          if (_gameOver) _buildGameOver(),
        ],
      ),
    );
  }

  Widget _buildTargetCard(Word target) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.thaiGold.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.thaiGold.withValues(alpha: 0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎯  FIND THIS WORD',
              style: TextStyle(
                  color: AppTheme.thaiGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
          const SizedBox(height: 3),
          Text(target.thai,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          Text(target.phonetic,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontStyle: FontStyle.italic)),
          Text(target.english,
              style: const TextStyle(
                  color: AppTheme.thaiGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSkeet(_SkeetBubble s) {
    if (s.missed || s.popped) return const SizedBox.shrink();

    const skeetSize = 65.0;
    final progress = s.t.clamp(0.0, 1.0);
    final baseX = s.startFromLeft ? progress : (1.0 - progress);
    final arcY = s.arcHeight * _screenH * sin(pi * progress);
    final px = baseX * _screenW - skeetSize / 2;
    final py = s.yFraction * (_screenH - 120) - arcY;

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
            gradient: const RadialGradient(
              colors: [
                Color(0xFFFFD740),
                Color(0xFFD4A017),
                Color(0xFFA07010),
              ],
              stops: [0.0, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A017).withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.35), width: 2),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Text(
                s.word.thai,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final isNewHigh = _score > 0 && _score >= _highScore;
    final roundsPlayed = _round.clamp(0, _totalRounds);

    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0533), Color(0xFF2D0C00)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppTheme.thaiGold.withValues(alpha: 0.55), width: 2),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.thaiGold.withValues(alpha: 0.15),
                  blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isNewHigh ? '🏆 NEW HIGH SCORE!' : '🎯 GAME OVER',
                style: TextStyle(
                    color: isNewHigh ? AppTheme.thaiGold : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              _statRow('Score', '$_score pts', AppTheme.thaiGold),
              _statRow('Best Streak', '$_bestStreak 🎯', Colors.white),
              _statRow('Rounds', '$roundsPlayed / $_totalRounds', Colors.white70),
              if (_highScore > 0 && !isNewHigh)
                _statRow('High Score', '$_highScore pts', Colors.white38),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _GameButton(
                      label: '▶  Play Again',
                      color: AppTheme.thaiRed,
                      onTap: _restartGame,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GameButton(
                      label: '← Exit',
                      color: Colors.white.withValues(alpha: 0.12),
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).scale(
          begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack);
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

// ── Tap effect ────────────────────────────────────────────────────────────────

class _TapEffect {
  final UniqueKey key = UniqueKey();
  final String text;
  final Color color;
  final double x, y;

  _TapEffect(
      {required this.text,
      required this.color,
      required this.x,
      required this.y});
}

// ── Skeet data model ──────────────────────────────────────────────────────────

class _SkeetBubble {
  final Word word;
  final bool isCorrect;
  final String id;
  final bool startFromLeft;
  final double yFraction;
  final double arcHeight;
  final double speed; // fraction of screen per second

  double t = 0.0;
  bool popped = false;
  bool missed = false;
  double screenX = 0;
  double screenY = 0;

  double get dtPerTick => speed * 0.05;

  _SkeetBubble({
    required this.word,
    required this.isCorrect,
    required this.id,
    required this.startFromLeft,
    required this.yFraction,
    required this.speed,
    required this.arcHeight,
  });
}

// ── Button widget ─────────────────────────────────────────────────────────────

class _GameButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GameButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14),
          ),
        ),
      ),
    );
  }
}
