import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/word.dart';
import '../../services/audio_service.dart';
import '../../services/arcade_service.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/thai_mascot.dart';
import 'speed_mode_results_screen.dart';

class SpeedModeScreen extends StatefulWidget {
  final List<Word> wordPool;
  final VoidCallback? onGoHome;

  const SpeedModeScreen({super.key, required this.wordPool, this.onGoHome});

  @override
  State<SpeedModeScreen> createState() => _SpeedModeScreenState();
}

class _SpeedModeScreenState extends State<SpeedModeScreen>
    with TickerProviderStateMixin {

  // ── Game State ────────────────────────────────────────────────────────
  late final List<Word> _questions;   // 20 shuffled picks
  int  _qIdx         = 0;
  int  _score        = 0;
  int  _combo        = 1;
  int  _bestCombo    = 1;
  int  _correctCount = 0;
  int? _fastestMs;

  bool _answered   = false;
  bool _timedOut   = false;
  int  _selectedIdx = -1;
  int  _correctIdx  = 0;
  late List<String> _choices;
  late Word _word;

  // Transient UI flags
  int  _lastEarned      = 0;
  bool _showEarned      = false;
  bool _showComboReset  = false;
  bool _showOnFire      = false;
  bool _showComboAnim   = false;

  // ── Animation Controllers ─────────────────────────────────────────────
  late final AnimationController _timerCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shakeCtrl;

  late DateTime _qStart;

  @override
  void initState() {
    super.initState();

    _timerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener(_onTimerStatus);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..repeat(reverse: true);

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final pool = List<Word>.from(widget.wordPool)..shuffle();
    _questions  = pool.take(20).toList();

    _loadQuestion();
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Question Loading ──────────────────────────────────────────────────

  void _loadQuestion() {
    _word      = _questions[_qIdx];
    _choices   = _buildChoices(_word);
    _correctIdx = _choices.indexOf(_word.english);
    _answered  = false;
    _timedOut  = false;
    _selectedIdx = -1;
    _qStart    = DateTime.now();

    _timerCtrl.reset();
    _timerCtrl.forward();
    AudioService().playWord(_word.audio, thaiText: _word.thai);
  }

  List<String> _buildChoices(Word correct) {
    final wrong = widget.wordPool
        .where((w) => w.id != correct.id && w.english != correct.english)
        .toList()
      ..shuffle();
    final chosen = wrong.take(3).map((w) => w.english).toList();
    while (chosen.length < 3) { chosen.add('—'); }
    return [correct.english, ...chosen]..shuffle();
  }

  // ── Timer ─────────────────────────────────────────────────────────────

  void _onTimerStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && !_answered) _onTimeout();
  }

  void _onTimeout() {
    if (_answered) return;
    _answered = true;
    _timedOut = true;
    AudioService().playWrong();
    _shakeCtrl.forward(from: 0);
    setState(() {
      _combo       = 1;
      _showComboReset = true;
      _showOnFire  = false;
      _showComboAnim = false;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _showComboReset = false);
      _advance();
    });
  }

  // ── Answer Handling ───────────────────────────────────────────────────

  void _onAnswer(int idx) {
    if (_answered) return;
    _answered = true;
    _timerCtrl.stop();

    final elapsedMs = DateTime.now().difference(_qStart).inMilliseconds;
    final isCorrect = idx == _correctIdx;

    setState(() => _selectedIdx = idx);

    if (isCorrect) {
      AudioService().playCorrect();
      if (_fastestMs == null || elapsedMs < _fastestMs!) _fastestMs = elapsedMs;

      final base   = max(100, 500 - (elapsedMs ~/ 1000 * 80));
      final earned = base * _combo;

      setState(() {
        _score       += earned;
        _correctCount++;
        _lastEarned  = earned;
        _showEarned  = true;
        _combo        = min(_combo + 1, 5);
        if (_combo > _bestCombo) _bestCombo = _combo;
        _showComboAnim = _combo >= 2;
        _showOnFire    = _combo >= 5;
        _showComboReset = false;
      });

      if (_combo >= 2) AudioService().playCombo();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() { _showEarned = false; _showComboAnim = false; });
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _advance();
      });
    } else {
      AudioService().playWrong();
      _shakeCtrl.forward(from: 0);
      setState(() {
        _combo        = 1;
        _showComboReset = true;
        _showOnFire   = false;
        _showComboAnim = false;
        _showEarned   = false;
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() => _showComboReset = false);
        _advance();
      });
    }
  }

  void _advance() {
    if (_qIdx >= 19) {
      _goToResults();
      return;
    }
    setState(() => _qIdx++);
    _loadQuestion();
  }

  Future<void> _goToResults() async {
    final prevBest = await ArcadeService().getHighScore();
    final isNewHigh = await ArcadeService().saveScore(
      score: _score,
      combo: _bestCombo,
      correct: _correctCount,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SpeedModeResultsScreen(
          score:               _score,
          correct:             _correctCount,
          bestCombo:           _bestCombo,
          fastestAnswerSeconds: _fastestMs != null ? _fastestMs! / 1000.0 : null,
          isNewHighScore:      isNewHigh,
          previousBest:        prevBest,
          wordPool:            widget.wordPool,
          onGoHome:            widget.onGoHome,
        ),
      ),
    );
  }

  // ── Button color helper ───────────────────────────────────────────────

  Color _btnBg(int idx) {
    if (!_answered) return Colors.white;
    if (idx == _correctIdx) return const Color(0xFF4CAF50);
    if (!_timedOut && idx == _selectedIdx) return const Color(0xFFF44336);
    return Colors.white.withValues(alpha: 0.25);
  }

  Color _btnText(int idx) {
    if (!_answered) return AppTheme.thaiNavy;
    if (idx == _correctIdx) return Colors.white;
    if (!_timedOut && idx == _selectedIdx) return Colors.white;
    return Colors.white.withValues(alpha: 0.5);
  }

  Color _comboColor() {
    if (_combo >= 5) return AppTheme.thaiGold;
    if (_combo == 4) return Colors.redAccent;
    if (_combo == 3) return Colors.orange;
    if (_combo == 2) return Colors.yellow;
    return Colors.white;
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (ctx, child) {
        final shake = sin(_shakeCtrl.value * pi * 6) * 6 * (1 - _shakeCtrl.value);
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1F3A),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildTimerBar(),
              Expanded(child: _buildMainContent()),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SCORE',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: Colors.white.withValues(alpha: 0.5))),
              Text('$_score',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ],
          ),
          const Spacer(),
          // Combo (center)
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final glow = _combo >= 2
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      boxShadow: [
                        BoxShadow(
                          color: _comboColor().withValues(alpha: 0.4 + 0.2 * _pulseCtrl.value),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    )
                  : null;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: _combo >= 2
                        ? _comboColor().withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ).copyWith(
                  boxShadow: glow?.boxShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_combo >= 2) const Text('🔥', style: TextStyle(fontSize: 14)),
                    Text(' x$_combo',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _comboColor())),
                  ],
                ),
              );
            },
          ),
          const Spacer(),
          // Question counter
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Q',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: Colors.white.withValues(alpha: 0.5))),
              Text('${_qIdx + 1}/20',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
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
        Color barColor;
        if (remaining > 0.5) {
          barColor = Color.lerp(Colors.yellow, const Color(0xFF4CAF50), (remaining - 0.5) * 2)!;
        } else if (remaining > 0.25) {
          barColor = Color.lerp(Colors.orange, Colors.yellow, (remaining - 0.25) * 4)!;
        } else {
          barColor = Colors.red;
        }

        final alpha = remaining <= 0.3
            ? (0.7 + 0.3 * _pulseCtrl.value).clamp(0.0, 1.0)
            : 1.0;

        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: remaining.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: alpha),
                  boxShadow: remaining <= 0.3
                      ? [BoxShadow(color: barColor.withValues(alpha: 0.6), blurRadius: 6)]
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Thai word
              Text(
                _word.thai,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Sarabun',
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _word.phonetic,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Replay button
              GestureDetector(
                onTap: () => AudioService().playWord(_word.audio, thaiText: _word.thai),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up_rounded, color: Colors.white70, size: 18),
                      SizedBox(width: 6),
                      Text('Replay', style: TextStyle(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Answer buttons 2×2
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.6,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(_choices.length, (i) {
                  final bg   = _btnBg(i);
                  final txt  = _btnText(i);
                  final isCorrectAnswer = _answered && i == _correctIdx;
                  return GestureDetector(
                    onTap: () => _onAnswer(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: isCorrectAnswer
                              ? const Color(0xFF4CAF50)
                              : (!_answered ? AppTheme.thaiNavy.withValues(alpha: 0.15) : Colors.transparent),
                          width: isCorrectAnswer ? 2.0 : 1.0,
                        ),
                        boxShadow: !_answered
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _choices[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: txt,
                          ),
                        ),
                      ),
                    ),
                  ).animate(target: _answered ? 0.0 : 1.0).scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.0, 1.0),
                    duration: 100.ms,
                  );
                }),
              ),
            ],
          ),
        ),

        // Floating "+X pts" text
        if (_showEarned)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '+$_lastEarned pts',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.thaiGold,
                ),
              )
                  .animate()
                  .fadeIn(duration: 150.ms)
                  .moveY(begin: 0, end: -24, duration: 500.ms, curve: Curves.easeOut)
                  .fadeOut(delay: 300.ms, duration: 200.ms),
            ),
          ),

        // Combo text "COMBO x3! 🔥"
        if (_showComboAnim)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  color: _comboColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(color: _comboColor().withValues(alpha: 0.5)),
                ),
                child: Text(
                  'COMBO x$_combo! 🔥',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _comboColor(),
                  ),
                ),
              )
                  .animate()
                  .scale(begin: const Offset(0.6, 0.6), duration: 200.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 150.ms),
            ),
          ),

        // Combo reset text
        if (_showComboReset)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'COMBO RESET 💔',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.red.shade300,
                ),
              )
                  .animate()
                  .fadeIn(duration: 200.ms),
            ),
          ),

        // ON FIRE banner (combo 5)
        if (_showOnFire)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFD4A017)],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.6),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Text(
                    'ON FIRE! 🔥🔥🔥',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                )
                    .animate()
                    .scale(begin: const Offset(0.5, 0.5), duration: 300.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 200.ms),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final mood = _showOnFire
        ? MascotMood.excited
        : _showComboReset
            ? MascotMood.sad
            : _combo >= 2
                ? MascotMood.happy
                : MascotMood.neutral;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              'Best Combo: x$_bestCombo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          BobbingMascot(size: 44, mood: mood),
        ],
      ),
    );
  }
}
