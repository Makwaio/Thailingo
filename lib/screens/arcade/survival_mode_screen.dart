import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/word.dart';
import '../../services/audio_service.dart';
import '../../services/arcade_service.dart';
import '../../services/settings_service.dart';
import '../../ui/theme/app_theme.dart';
import '../../widgets/arcade_countdown_widget.dart';

class SurvivalModeScreen extends StatefulWidget {
  final List<Word> wordPool;
  final VoidCallback? onGoHome;
  const SurvivalModeScreen({super.key, required this.wordPool, this.onGoHome});

  @override
  State<SurvivalModeScreen> createState() => _SurvivalModeScreenState();
}

class _SurvivalModeScreenState extends State<SurvivalModeScreen>
    with TickerProviderStateMixin {
  // ── Start screen ──────────────────────────────────────────────────────
  bool _showStart = true;
  int  _highScore = 0;
  String _bestGrade = '';

  // ── Game state ────────────────────────────────────────────────────────
  int    _score     = 0;
  double _timeLimit = 6.0;
  bool   _gameOver  = false;
  bool   _answered  = false;
  bool   _timedOut  = false;
  int    _selectedIdx = -1;

  late Word         _word;
  late List<String> _choices;
  int               _correctIdx = 0;

  // ── Flash ─────────────────────────────────────────────────────────────
  double _flashOpacity = 0.0;

  // ── Timer AnimationController ─────────────────────────────────────────
  late AnimationController _timerCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shakeCtrl;

  // ── Word pool ─────────────────────────────────────────────────────────
  late List<Word> _pool;
  int _poolIdx = 0;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _timerCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_timeLimit * 1000).round()),
    )..addStatusListener(_onTimerStatus);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pool = List<Word>.from(widget.wordPool)..shuffle(_rng);

    ArcadeService().getSurvivalBestScore().then((v) {
      if (mounted) setState(() => _highScore = v);
    });
    ArcadeService().getSurvivalBestGrade().then((v) {
      if (mounted) setState(() => _bestGrade = v);
    });
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Game start ────────────────────────────────────────────────────────

  void _onGameStart() {
    setState(() => _showStart = false);
    _loadQuestion();
  }

  void _loadQuestion() {
    if (_poolIdx >= _pool.length) {
      _pool.shuffle(_rng);
      _poolIdx = 0;
    }
    _word       = _pool[_poolIdx++];
    _choices    = _buildChoices(_word);
    _correctIdx = _choices.indexOf(_word.english);
    _answered   = false;
    _timedOut   = false;
    _selectedIdx = -1;

    _timerCtrl.duration =
        Duration(milliseconds: (_timeLimit * 1000).round());
    _timerCtrl.reset();
    _timerCtrl.forward();

    AudioService().playWord(_word.audio, thaiText: _word.thai);
  }

  List<String> _buildChoices(Word correct) {
    final wrong = widget.wordPool
        .where((w) => w.id != correct.id && w.english != correct.english)
        .toList()
      ..shuffle(_rng);
    final chosen = wrong.take(3).map((w) => w.english).toList();
    while (chosen.length < 3) {
      chosen.add('—');
    }
    return [correct.english, ...chosen]..shuffle(_rng);
  }

  void _onTimerStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && !_answered) _onTimeout();
  }

  void _onTimeout() {
    if (_answered) return;
    _answered = true;
    _timedOut = true;
    AudioService().playWrong();
    _shakeCtrl.forward(from: 0);
    _flashRed();
    setState(() => _gameOver = true);
    Future.delayed(const Duration(milliseconds: 800), _endGame);
  }

  void _onAnswer(int idx) {
    if (_answered || _gameOver) return;
    _answered = true;
    _timerCtrl.stop();
    setState(() => _selectedIdx = idx);

    if (idx == _correctIdx) {
      AudioService().playCorrect();
      _score++;
      if (_score % 10 == 0) {
        _timeLimit = max(2.0, _timeLimit - 0.5);
      }
      // Milestone flash
      if (_score == 10 || _score == 25 || _score == 50 || _score == 100) {
        _showMilestone(_score);
      }
      setState(() {});
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_gameOver) _loadQuestion();
      });
    } else {
      AudioService().playWrong();
      _shakeCtrl.forward(from: 0);
      _flashRed();
      setState(() => _gameOver = true);
      Future.delayed(const Duration(milliseconds: 800), _endGame);
    }
  }

  void _flashRed() {
    setState(() => _flashOpacity = 1.0);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _flashOpacity = 0.0);
    });
  }

  bool _showMilestoneFlag = false;
  int  _milestoneScore   = 0;
  void _showMilestone(int score) {
    setState(() { _showMilestoneFlag = true; _milestoneScore = score; });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showMilestoneFlag = false);
    });
  }

  Future<void> _endGame() async {
    _timerCtrl.stop();
    final grade = _gradeFor(_score);
    await ArcadeService().saveSurvivalScore(score: _score, grade: grade);
    final best = await ArcadeService().getSurvivalBestScore();
    final bestGrade = await ArcadeService().getSurvivalBestGrade();
    if (mounted) setState(() { _highScore = best; _bestGrade = bestGrade; });
  }

  static String _gradeFor(int score) {
    if (score >= 100) return 'LEGENDARY 👑';
    if (score >= 50)  return 'Champion 🏆';
    if (score >= 25)  return 'Warrior ⚔️';
    if (score >= 10)  return 'Survivor 🏃';
    return 'Beginner 🌱';
  }

  int _getMultiplier() {
    if (_score >= 36) return 5;
    if (_score >= 21) return 4;
    if (_score >= 11) return 3;
    if (_score >= 6)  return 2;
    return 1;
  }

  void _restart() {
    setState(() {
      _score      = 0;
      _timeLimit  = 6.0;
      _gameOver   = false;
      _answered   = false;
      _timedOut   = false;
      _selectedIdx = -1;
      _flashOpacity = 0.0;
      _showMilestoneFlag = false;
      _pool.shuffle(_rng);
      _poolIdx    = 0;
    });
    _loadQuestion();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showStart) {
      return ArcadeCountdownWidget(
        gameEmoji: '💀',
        gameTitle: 'Survival Mode',
        instruction: 'One mistake and it\'s over! How far can you go?',
        bestScore: _highScore > 0 ? _highScore : null,
        onStart: _onGameStart,
        extraContent: _highScore > 0
            ? Text(
                _bestGrade,
                style: const TextStyle(
                    color: AppTheme.thaiGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              )
            : null,
      );
    }

    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) {
        final shake =
            sin(_shakeCtrl.value * pi * 6) * 6 * (1 - _shakeCtrl.value);
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1a0000),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildTimerBar(),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
            // Red edge flash
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _flashOpacity,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.8), width: 14),
                    ),
                  ),
                ),
              ),
            ),
            // Milestone banner
            if (_showMilestoneFlag)
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B00), Color(0xFFD4A017)]),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.6),
                            blurRadius: 16)
                      ],
                    ),
                    child: Text('SURVIVE! 🔥  $_milestoneScore',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                  )
                      .animate()
                      .scale(
                          begin: const Offset(0.5, 0.5),
                          duration: 300.ms,
                          curve: Curves.elasticOut)
                      .fadeIn(duration: 200.ms),
                ),
              ),
            // Game Over overlay
            if (_gameOver && _timerCtrl.status == AnimationStatus.dismissed ||
                _gameOver && _answered)
              _buildGameOver(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final mult = _getMultiplier();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
          const Spacer(),
          // Heart
          const Text('❤️', style: TextStyle(fontSize: 36)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mult > 1 ? 'x$mult COMBO 🔥' : 'Streak: $_score',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: mult > 1
                        ? AppTheme.thaiGold
                        : Colors.white.withValues(alpha: 0.5)),
              ),
              Text(
                '${_timeLimit.toStringAsFixed(1)}s',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _timeLimit <= 3
                        ? Colors.redAccent
                        : Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    return AnimatedBuilder(
      animation: Listenable.merge([_timerCtrl, _pulseCtrl]),
      builder: (_, __) {
        final remaining = 1 - _timerCtrl.value;
        final Color barColor;
        if (remaining > 0.5) {
          barColor = Color.lerp(
              Colors.yellow, const Color(0xFF4CAF50), (remaining - 0.5) * 2)!;
        } else if (remaining > 0.25) {
          barColor =
              Color.lerp(Colors.orange, Colors.yellow, (remaining - 0.25) * 4)!;
        } else {
          barColor = Colors.red;
        }
        final alpha = remaining <= 0.3
            ? (0.7 + 0.3 * _pulseCtrl.value).clamp(0.0, 1.0)
            : 1.0;
        return Container(
          height: 8,
          color: Colors.white.withValues(alpha: 0.06),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: remaining.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: alpha),
                  boxShadow: remaining <= 0.3
                      ? [
                          BoxShadow(
                              color: barColor.withValues(alpha: 0.7),
                              blurRadius: 8)
                        ]
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return isLandscape ? _buildLandscape() : _buildPortrait();
  }

  Widget _buildWordPanel({bool compact = false}) {
    final usePhonetic = SettingsService().skeetUsePhonetic;
    final questionText = usePhonetic ? _word.phonetic : _word.thai;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          questionText,
          style: TextStyle(
            fontSize: compact ? 32 : 48,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFamily: 'Sarabun',
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: compact ? 4 : 6),
        if (!usePhonetic)
          Text(
            _word.phonetic,
            style: TextStyle(
                fontSize: compact ? 13 : 16,
                color: Colors.white.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
        SizedBox(height: compact ? 6 : 10),
        GestureDetector(
          onTap: () =>
              AudioService().playWord(_word.audio, thaiText: _word.thai),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.volume_up_rounded,
                    color: Colors.white70, size: 16),
                SizedBox(width: 4),
                Text('Replay',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButtons({double aspectRatio = 2.8}) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: aspectRatio,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(_choices.length, (i) {
        final isCorrect = _answered && i == _correctIdx;
        final isWrong   = _answered && !_timedOut && i == _selectedIdx && i != _correctIdx;
        Color bg = Colors.white;
        Color txt = AppTheme.thaiNavy;
        if (_answered) {
          if (isCorrect)    { bg = const Color(0xFF4CAF50); txt = Colors.white; }
          else if (isWrong) { bg = const Color(0xFFF44336); txt = Colors.white; }
          else              { bg = Colors.white.withValues(alpha: 0.2); txt = Colors.white.withValues(alpha: 0.45); }
        }
        return GestureDetector(
          onTap: () => _onAnswer(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                  color: isCorrect
                      ? const Color(0xFF4CAF50)
                      : Colors.transparent,
                  width: isCorrect ? 2.0 : 1.0),
            ),
            child: Center(
              child: Text(_choices[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: txt)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPortrait() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildWordPanel(),
          const SizedBox(height: 28),
          _buildChoiceButtons(),
        ],
      ),
    );
  }

  Widget _buildLandscape() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(flex: 4, child: _buildWordPanel(compact: true)),
          const SizedBox(width: 16),
          Expanded(flex: 6, child: _buildChoiceButtons(aspectRatio: 2.4)),
        ],
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
              colors: [Color(0xFF2A0000), Color(0xFF1a0000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withValues(alpha: 0.25), blurRadius: 32)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isNew ? '🏆 NEW BEST!' : '💀 ELIMINATED!',
                  style: TextStyle(
                      color: isNew ? AppTheme.thaiGold : Colors.redAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Text(
                '$_score',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w900),
              ),
              Text('correct in a row',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
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
                    child: _SurvivalBtn(
                        label: '▶  Try Again',
                        color: const Color(0xFFB5001C),
                        onTap: _restart),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SurvivalBtn(
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
        .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack);
  }
}

class _SurvivalBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SurvivalBtn(
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
