import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/word.dart';
import '../../services/audio_service.dart';
import '../../ui/theme/app_theme.dart';

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
  static const _skeetsPerRound = 5;
  static const _hsKey = 'skeet_shooter_hs_v1';

  final _rng = Random();

  // ── Game state ────────────────────────────────────────────────────────
  Word? _targetWord;
  final List<_SkeetBubble> _skeets = [];
  int _score = 0;
  int _lives = _maxLives;
  int _round = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _highScore = 0;
  bool _gameOver = false;
  bool _transitioning = false;

  // ── Effect overlay ────────────────────────────────────────────────────
  String _effectText = '';
  bool _showEffect = false;

  // ── Word pool ─────────────────────────────────────────────────────────
  late List<Word> _pool;
  int _poolIdx = 0;

  // ── Game loop ─────────────────────────────────────────────────────────
  Timer? _gameLoop;

  // Screen size set on first build
  double _screenW = 400;
  double _screenH = 700;

  @override
  void initState() {
    super.initState();
    _pool = List<Word>.from(widget.wordPool)..shuffle(_rng);
    _loadHighScore();
    _startRound();
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }

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

    final target = _pool[_poolIdx % _pool.length];
    _poolIdx++;

    final newSkeets = <_SkeetBubble>[];

    // One correct skeet
    newSkeets.add(_SkeetBubble(
      word: target,
      isCorrect: true,
      id: 'correct_$_round',
      startFromLeft: _rng.nextBool(),
      yFraction: 0.25 + _rng.nextDouble() * 0.45,
      speed: 0.55 + _round * 0.018 + _rng.nextDouble() * 0.2,
      arcHeight: 0.08 + _rng.nextDouble() * 0.14,
    ));

    // Decoy skeets
    final decoys = _pool.where((w) => w.id != target.id).toList()..shuffle(_rng);
    for (int i = 0; i < (_skeetsPerRound - 1) && i < decoys.length; i++) {
      newSkeets.add(_SkeetBubble(
        word: decoys[i],
        isCorrect: false,
        id: 'decoy_${_round}_$i',
        startFromLeft: _rng.nextBool(),
        yFraction: 0.18 + _rng.nextDouble() * 0.55,
        speed: 0.5 + _round * 0.015 + _rng.nextDouble() * 0.25,
        arcHeight: 0.05 + _rng.nextDouble() * 0.18,
      ));
    }
    newSkeets.shuffle(_rng);

    setState(() {
      _targetWord = target;
      _skeets.clear();
      _skeets.addAll(newSkeets);
      _transitioning = false;
    });

    // Game loop: tick every 50ms
    _gameLoop = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      _tick();
    });
  }

  void _tick() {
    if (_gameOver || _transitioning) return;

    bool correctMissed = false;

    for (final s in _skeets) {
      if (s.popped || s.missed) continue;
      s.t += s.dtPerTick;
      if (s.t >= 1.0) {
        s.t = 1.0;
        s.missed = true;
        if (s.isCorrect) correctMissed = true;
      }
    }

    if (correctMissed) {
      _loseLife(showEffect: true, missedSkeet: true);
      if (_gameOver) return;
    }

    final allDone = _skeets.every((s) => s.popped || s.missed);
    if (allDone && !_transitioning) {
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
      Future.delayed(const Duration(milliseconds: 700), _startRound);
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

      final msg = _streak >= 5
          ? 'AMAZING! 🔥 x$_streak'
          : _streak >= 3
              ? 'COMBO! 🎯 x$_streak'
              : 'NICE! 🎯 +$points';

      AudioService().playCombo();
      _showEffectMsg(msg);

      // Pop remaining decoys so round ends cleanly
      for (final s in _skeets) {
        if (!s.isCorrect) s.popped = true;
      }
    } else {
      _loseLife(showEffect: true, missedSkeet: false);
    }

    setState(() {});
  }

  void _loseLife({required bool showEffect, required bool missedSkeet}) {
    _streak = 0;
    _lives--;
    if (showEffect) {
      _showEffectMsg(missedSkeet ? 'MISSED! 💨' : 'WRONG! ❌');
    }
    AudioService().playWrong();
    if (_lives <= 0) {
      Future.delayed(const Duration(milliseconds: 400), _triggerGameOver);
      setState(() => _gameOver = true);
    } else {
      setState(() {});
    }
  }

  void _showEffectMsg(String msg) {
    setState(() {
      _effectText = msg;
      _showEffect = true;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showEffect = false);
    });
  }

  void _triggerGameOver() {
    _gameLoop?.cancel();
    _saveHighScore();
    if (mounted) setState(() => _gameOver = true);
  }

  // ── Reset ─────────────────────────────────────────────────────────────

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
      _pool.shuffle(_rng);
      _poolIdx = 0;
    });
    _startRound();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _screenW = size.width;
    _screenH = size.height;

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

          // Flying skeet bubbles
          if (!_gameOver)
            ..._skeets.map((s) => _buildSkeet(s)),

          // HUD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top bar: lives / round / score
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
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Round
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Round ${(_round + 1).clamp(1, _totalRounds)}/$_totalRounds',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
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
                          style: TextStyle(color: Colors.white60, fontSize: 13)),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Target card
                  if (_targetWord != null && !_gameOver)
                    _buildTargetCard(_targetWord!),

                  // Effect flash
                  if (_showEffect)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _effectText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 12),
                          ],
                        ),
                      ),
                    ).animate().scale(begin: const Offset(0.6, 0.6)).fadeIn(),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
          const SizedBox(height: 4),
          Text(target.thai,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900)),
          Text(target.phonetic,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  fontStyle: FontStyle.italic)),
          Text(target.english,
              style: const TextStyle(
                  color: AppTheme.thaiGold, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSkeet(_SkeetBubble s) {
    if (s.missed || s.popped) return const SizedBox.shrink();

    final progress = s.t.clamp(0.0, 1.0);
    final baseX = s.startFromLeft ? progress : (1.0 - progress);
    final arcY = s.arcHeight * _screenH * sin(pi * progress);
    final px = baseX * _screenW - 40;
    final py = s.yFraction * (_screenH - 120) - arcY;

    return Positioned(
      left: px,
      top: py,
      child: GestureDetector(
        onTap: () => _onSkeetTap(s),
        child: Container(
          width: 80,
          height: 80,
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
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.35), width: 2),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                s.word.thai,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
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
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ── Skeet data model ──────────────────────────────────────────────────────

class _SkeetBubble {
  final Word word;
  final bool isCorrect;
  final String id;
  final bool startFromLeft;
  final double yFraction;
  final double arcHeight;
  final double speed; // fraction of screen per second

  double t = 0.0; // 0 = start, 1 = off-screen
  bool popped = false;
  bool missed = false;

  // 50ms tick → advance t by speed * 0.05
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

// ── Button widget ─────────────────────────────────────────────────────────

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
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.15), width: 1),
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
