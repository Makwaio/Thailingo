import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/word.dart';
import '../../services/audio_service.dart';
import '../../services/arcade_service.dart';
import '../../services/settings_service.dart';
import '../../ui/theme/app_theme.dart';
import '../../widgets/arcade_countdown_widget.dart';

// ── Power-up types ────────────────────────────────────────────────────────────
enum _PowerUp { time5s, reveal, doublePoints }

extension _PowerUpExt on _PowerUp {
  String get emoji {
    switch (this) {
      case _PowerUp.time5s:      return '⚡';
      case _PowerUp.reveal:      return '🔍';
      case _PowerUp.doublePoints: return '💫';
    }
  }
  String get label {
    switch (this) {
      case _PowerUp.time5s:      return '+5s';
      case _PowerUp.reveal:      return 'Reveal';
      case _PowerUp.doublePoints: return 'Double';
    }
  }
}

// ── Tile model ────────────────────────────────────────────────────────────────
class _Tile {
  final String text;
  final int    pairId;
  final bool   isThai;
  bool matched  = false;
  bool selected = false;
  bool wrong    = false;

  _Tile({required this.text, required this.pairId, required this.isThai});
}

class WordBlitzScreen extends StatefulWidget {
  final List<Word> wordPool;
  const WordBlitzScreen({super.key, required this.wordPool});

  @override
  State<WordBlitzScreen> createState() => _WordBlitzScreenState();
}

class _WordBlitzScreenState extends State<WordBlitzScreen>
    with TickerProviderStateMixin {
  // ── Start screen ──────────────────────────────────────────────────────
  bool   _showStart  = true;
  int    _highScore  = 0;
  String _bestGrade  = '';

  // ── Game state ────────────────────────────────────────────────────────
  int    _score      = 0;
  int    _timeLeft   = 60;
  int    _combo      = 0;
  int    _matchCount = 0;
  bool   _gameOver   = false;
  bool   _doubleActive = false;
  bool   _revealActive = false;

  // ── Tiles ─────────────────────────────────────────────────────────────
  List<_Tile> _tiles = [];
  _Tile? _firstSelected;
  int?   _firstIdx;
  bool   _evaluating = false;

  // ── Word pool ─────────────────────────────────────────────────────────
  late List<Word> _pool;
  int _poolIdx = 0;
  final _rng = Random();

  // ── Power-ups ─────────────────────────────────────────────────────────
  final Map<_PowerUp, int> _powerUpCharges = {
    _PowerUp.time5s:      1,
    _PowerUp.reveal:      1,
    _PowerUp.doublePoints: 1,
  };

  // ── Timer ─────────────────────────────────────────────────────────────
  Timer? _timer;
  late AnimationController _timerCtrl;
  late AnimationController _comboCtrl;

  // ── Grid ─────────────────────────────────────────────────────────────
  static const _cols = 4;

  @override
  void initState() {
    super.initState();
    _timerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 60));
    _comboCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _pool = List<Word>.from(widget.wordPool)..shuffle(_rng);

    ArcadeService().getWordBlitzBestScore().then((v) {
      if (mounted) setState(() => _highScore = v);
    });
    ArcadeService().getWordBlitzBestGrade().then((v) {
      if (mounted) setState(() => _bestGrade = v);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerCtrl.dispose();
    _comboCtrl.dispose();
    super.dispose();
  }

  // ── Start ─────────────────────────────────────────────────────────────

  void _onGameStart() {
    setState(() => _showStart = false);
    _fillGrid();
    _startTimer();
  }

  // ── Grid management ───────────────────────────────────────────────────

  void _fillGrid() {
    // 8 tiles = 4 pairs
    final words = _pickWords(4);
    final newTiles = <_Tile>[];
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final usePhonetic = SettingsService().skeetUsePhonetic;
      newTiles.add(_Tile(
          text: usePhonetic ? w.phonetic : w.thai, pairId: i, isThai: true));
      newTiles.add(_Tile(text: w.english, pairId: i, isThai: false));
    }
    newTiles.shuffle(_rng);
    setState(() => _tiles = newTiles);
  }

  List<Word> _pickWords(int count) {
    final out = <Word>[];
    for (int i = 0; i < count; i++) {
      if (_poolIdx >= _pool.length) {
        _pool.shuffle(_rng);
        _poolIdx = 0;
      }
      out.add(_pool[_poolIdx++]);
    }
    return out;
  }

  void _replacePair(int pairId) {
    // Replace matched pair with 2 new tiles from the pool
    if (_poolIdx >= _pool.length) {
      _pool.shuffle(_rng);
      _poolIdx = 0;
    }
    final w = _pool[_poolIdx++];
    final usePhonetic = SettingsService().skeetUsePhonetic;
    final idxList =
        _tiles.indexed.where((e) => e.$2.pairId == pairId).map((e) => e.$1).toList();
    if (idxList.length != 2) return;
    final newPairId = DateTime.now().microsecondsSinceEpoch; // unique id
    _tiles[idxList[0]] = _Tile(
        text: usePhonetic ? w.phonetic : w.thai,
        pairId: newPairId,
        isThai: true);
    _tiles[idxList[1]] =
        _Tile(text: w.english, pairId: newPairId, isThai: false);
    // Shuffle those 2 positions (just swap randomly)
    if (_rng.nextBool()) {
      final tmp = _tiles[idxList[0]];
      _tiles[idxList[0]] = _tiles[idxList[1]];
      _tiles[idxList[1]] = tmp;
    }
  }

  // ── Timer ─────────────────────────────────────────────────────────────

  void _startTimer() {
    _timerCtrl.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _endGame();
    });
  }

  // ── Tile selection ────────────────────────────────────────────────────

  void _onTileTap(int idx) {
    if (_evaluating || _gameOver || _tiles[idx].matched) return;
    final tile = _tiles[idx];
    if (tile.selected) {
      setState(() {
        tile.selected = false;
        _firstSelected = null;
        _firstIdx = null;
      });
      return;
    }
    if (_firstSelected == null) {
      setState(() {
        tile.selected = true;
        _firstSelected = tile;
        _firstIdx = idx;
      });
    } else {
      final first = _firstSelected!;
      if (idx == _firstIdx) return;
      if (tile.pairId == first.pairId && tile.isThai != first.isThai) {
        // Match!
        _evaluating = true;
        setState(() => tile.selected = true);
        Future.delayed(const Duration(milliseconds: 220), () {
          if (!mounted) return;
          _combo++;
          int points = 10;
          if (_combo >= 3) points = 15; // combo bonus x1.5
          if (_doubleActive) points *= 2;

          setState(() {
            _score += points;
            _matchCount++;
            tile.matched = true;
            first.matched = true;
            tile.selected = false;
            first.selected = false;
            _firstSelected = null;
            _firstIdx = null;
          });
          AudioService().playCorrect();
          if (_combo >= 3) _comboCtrl.forward(from: 0);
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            _replacePair(tile.pairId);
            if (_doubleActive && _matchCount % 4 == 0) {
              setState(() => _doubleActive = false);
            }
            setState(() {});
            _evaluating = false;
          });
        });
      } else {
        // Wrong
        _evaluating = true;
        _combo = 0;
        setState(() {
          tile.wrong = true;
          first.wrong = true;
          tile.selected = true;
        });
        AudioService().playWrong();
        Future.delayed(const Duration(milliseconds: 450), () {
          if (!mounted) return;
          setState(() {
            tile.wrong = false;
            first.wrong = false;
            tile.selected = false;
            first.selected = false;
            _firstSelected = null;
            _firstIdx = null;
          });
          _evaluating = false;
        });
      }
    }
  }

  // ── Power-ups ─────────────────────────────────────────────────────────

  void _usePowerUp(_PowerUp p) {
    if ((_powerUpCharges[p] ?? 0) <= 0 || _gameOver) return;
    setState(() => _powerUpCharges[p] = (_powerUpCharges[p]! - 1));
    switch (p) {
      case _PowerUp.time5s:
        setState(() => _timeLeft = (_timeLeft + 5).clamp(0, 99));
        break;
      case _PowerUp.reveal:
        setState(() => _revealActive = true);
        Future.delayed(const Duration(seconds: 3),
            () { if (mounted) setState(() => _revealActive = false); });
        break;
      case _PowerUp.doublePoints:
        setState(() => _doubleActive = true);
        break;
    }
  }

  // ── End game ──────────────────────────────────────────────────────────

  Future<void> _endGame() async {
    _timer?.cancel();
    _timerCtrl.stop();
    final grade = _gradeFor(_score);
    await ArcadeService().saveWordBlitzScore(score: _score, grade: grade);
    final best     = await ArcadeService().getWordBlitzBestScore();
    final bestGrade = await ArcadeService().getWordBlitzBestGrade();
    if (mounted) {
      setState(() {
        _gameOver  = true;
        _highScore = best;
        _bestGrade = bestGrade;
      });
    }
  }

  static String _gradeFor(int score) {
    if (score >= 400) return 'BLITZ LEGEND 👑';
    if (score >= 250) return 'Word Master 🏆';
    if (score >= 150) return 'Blitz Expert ⚡';
    if (score >= 60)  return 'Word Matcher 🔤';
    return 'Just Starting 🌱';
  }

  void _restart() {
    _timer?.cancel();
    _timerCtrl.reset();
    setState(() {
      _score       = 0;
      _timeLeft    = 60;
      _combo       = 0;
      _matchCount  = 0;
      _gameOver    = false;
      _doubleActive  = false;
      _revealActive  = false;
      _firstSelected = null;
      _firstIdx      = null;
      _evaluating    = false;
      _powerUpCharges.updateAll((_, __) => 1);
      _pool.shuffle(_rng);
      _poolIdx = 0;
    });
    _fillGrid();
    _startTimer();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showStart) {
      return ArcadeCountdownWidget(
        gameEmoji: '⚡',
        gameTitle: 'Word Blitz',
        instruction: 'Match Thai ↔ English pairs as fast as you can! 60 seconds on the clock.',
        bestScore: _highScore > 0 ? _highScore : null,
        onStart: _onGameStart,
        extraContent: _highScore > 0
            ? Text(_bestGrade,
                style: const TextStyle(
                    color: AppTheme.thaiGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w700))
            : null,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0d001a),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildTimerBar(),
                Expanded(child: _buildGrid()),
                _buildPowerUps(),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (_gameOver) _buildGameOver(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SCORE',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Colors.white.withValues(alpha: 0.45))),
            Text('$_score',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ]),
          const Spacer(),
          AnimatedBuilder(
            animation: _timerCtrl,
            builder: (_, __) {
              return Column(children: [
                Text('TIME',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: Colors.white.withValues(alpha: 0.45))),
                Text(
                  '$_timeLeft',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _timeLeft <= 10
                          ? Colors.redAccent
                          : Colors.white),
                ),
              ]);
            },
          ),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (_doubleActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B2FBE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('💫 2×',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
            if (_combo >= 3)
              Text('🔥 Combo x${(_combo >= 3 ? 1.5 : 1.0).toStringAsFixed(1)}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.thaiGold)),
          ]),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    final frac = (_timeLeft / 60.0).clamp(0.0, 1.0);
    final Color barColor;
    if (frac > 0.5) {
      barColor = Color.lerp(const Color(0xFF9B59B6), const Color(0xFF6C3483), frac)!;
    } else if (frac > 0.25) {
      barColor = Color.lerp(Colors.orange, const Color(0xFF9B59B6), frac * 2)!;
    } else {
      barColor = Colors.redAccent;
    }
    return Container(
      height: 6,
      color: Colors.white.withValues(alpha: 0.06),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 800),
          widthFactor: frac,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [barColor, barColor.withValues(alpha: 0.6)]),
              boxShadow: [
                BoxShadow(color: barColor.withValues(alpha: 0.6), blurRadius: 8)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: GridView.count(
        crossAxisCount: _cols,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(_tiles.length, (i) => _buildTile(i)),
      ),
    );
  }

  Widget _buildTile(int idx) {
    final tile = _tiles[idx];
    Color bg;
    Color border;
    Color text = Colors.white;

    if (tile.matched) {
      bg     = Colors.transparent;
      border = Colors.transparent;
      text   = Colors.transparent;
    } else if (tile.wrong) {
      bg     = Colors.red.withValues(alpha: 0.3);
      border = Colors.redAccent;
    } else if (tile.selected) {
      bg     = const Color(0xFF7B2FBE).withValues(alpha: 0.8);
      border = const Color(0xFFD0A0FF);
    } else if (_revealActive) {
      bg     = const Color(0xFF1a0033);
      border = const Color(0xFF9B59B6).withValues(alpha: 0.8);
      text   = Colors.white.withValues(alpha: 0.85);
    } else {
      bg     = const Color(0xFF1a0033);
      border = const Color(0xFF6C3483).withValues(alpha: 0.6);
    }

    return GestureDetector(
      onTap: () => _onTileTap(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.5),
          boxShadow: tile.selected
              ? [
                  BoxShadow(
                      color: const Color(0xFF9B59B6).withValues(alpha: 0.5),
                      blurRadius: 10)
                ]
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: _revealActive && !tile.matched
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tile.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: text,
                              fontFamily: tile.isThai ? 'Sarabun' : null)),
                      Text('pair ${tile.pairId % 1000}',
                          style: TextStyle(
                              fontSize: 7,
                              color: Colors.white.withValues(alpha: 0.35))),
                    ],
                  )
                : Text(
                    tile.matched ? '' : tile.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: text,
                        fontFamily: tile.isThai ? 'Sarabun' : null),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPowerUps() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _PowerUp.values.map((p) {
          final charges = _powerUpCharges[p] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: charges > 0 ? () => _usePowerUp(p) : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: charges > 0 ? 1.0 : 0.3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: charges > 0
                        ? const LinearGradient(
                            colors: [Color(0xFF7B2FBE), Color(0xFF5B108C)])
                        : null,
                    color: charges <= 0
                        ? Colors.white.withValues(alpha: 0.08)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: charges > 0
                            ? const Color(0xFFD0A0FF).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.emoji,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(p.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGameOver() {
    final grade   = _gradeFor(_score);
    final isNew   = _score >= _highScore && _score > 0;
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1a0033), Color(0xFF0d001a)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFF9B59B6).withValues(alpha: 0.6),
                width: 2),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF7B2FBE).withValues(alpha: 0.3),
                  blurRadius: 32)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isNew ? '🏆 NEW BEST!' : '⚡ TIME\'S UP!',
                  style: TextStyle(
                      color: isNew
                          ? AppTheme.thaiGold
                          : const Color(0xFFD0A0FF),
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Text('$_score',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w900)),
              Text('points',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14)),
              const SizedBox(height: 8),
              Text('$_matchCount pairs matched',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B2FBE).withValues(alpha: 0.3),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                      color: const Color(0xFFD0A0FF).withValues(alpha: 0.4)),
                ),
                child: Text(grade,
                    style: const TextStyle(
                        color: AppTheme.thaiGold,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ),
              if (_highScore > 0 && !isNew) ...[
                const SizedBox(height: 8),
                Text('Best: $_highScore — $_bestGrade',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12)),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _BlitzBtn(
                        label: '▶  Play Again',
                        color: const Color(0xFF7B2FBE),
                        onTap: _restart),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BlitzBtn(
                        label: '← Exit',
                        color: Colors.white.withValues(alpha: 0.12),
                        onTap: () => Navigator.pop(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .scale(
            begin: const Offset(0.92, 0.92),
            curve: Curves.easeOutBack);
  }
}

class _BlitzBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BlitzBtn(
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
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ),
      ),
    );
  }
}
