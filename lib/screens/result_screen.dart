import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/lesson.dart';
import '../services/audio_service.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/common_widgets.dart';

class ResultScreen extends StatefulWidget {
  final Lesson lesson;
  final int correct;
  final int total;
  final int xpGained;
  final Duration timeTaken;
  final int score;
  final int timesCompleted;
  final int newStars;

  const ResultScreen({
    super.key,
    required this.lesson,
    required this.correct,
    required this.total,
    required this.xpGained,
    required this.timeTaken,
    required this.score,
    required this.timesCompleted,
    required this.newStars,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _xpCtrl;
  late Animation<double> _xpAnim;

  String get _progressHint {
    if (widget.newStars >= 3) return '🌟 Mastered!';
    if (widget.newStars == 2) return '→ 1 more play for ⭐⭐⭐';
    return '→ 1 more play for ⭐⭐';
  }

  String get _timeStr {
    final s = widget.timeTaken.inSeconds;
    return s < 60 ? '${s}s' : '${s ~/ 60}m ${s % 60}s';
  }

  @override
  void initState() {
    super.initState();

    // XP counter: animates from 0 → xpGained over 1.4 seconds
    _xpCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _xpAnim = Tween<double>(begin: 0, end: widget.xpGained.toDouble())
        .animate(CurvedAnimation(parent: _xpCtrl, curve: Curves.easeOut));
    Future.delayed(500.ms, () {
      if (mounted) _xpCtrl.forward();
    });

    // Star pop sounds: click for stars 1 & 2, correct tone for star 3
    if (widget.newStars >= 1) Future.delayed(400.ms, () { if (mounted) AudioService().playClick(); });
    if (widget.newStars >= 2) Future.delayed(580.ms, () { if (mounted) AudioService().playClick(); });
    if (widget.newStars >= 3) Future.delayed(760.ms, () { if (mounted) AudioService().playCorrect(); });
  }

  @override
  void dispose() {
    _xpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonColor = HexColor.fromHex(widget.lesson.colorHex);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [lessonColor.withValues(alpha: 0.08), Colors.white, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        widget.score == 100 ? '🏆' : widget.newStars >= 2 ? '🎉' : '💪',
                        style: const TextStyle(fontSize: 80),
                      )
                          .animate()
                          .scale(
                              begin: const Offset(0, 0),
                              duration: 600.ms,
                              curve: Curves.elasticOut),

                      const SizedBox(height: 16),
                      Text(
                        widget.score == 100
                            ? 'Perfect Score!'
                            : widget.newStars >= 2
                                ? 'Lesson Complete!'
                                : 'Keep Practicing!',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary),
                        textAlign: TextAlign.center,
                      ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3),

                      const SizedBox(height: 6),
                      Text(widget.lesson.title,
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textSecondary))
                          .animate(delay: 300.ms)
                          .fadeIn(),

                      const SizedBox(height: 24),

                      // Stars — one by one with elasticOut scale
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('⭐',
                                    style: TextStyle(
                                        fontSize: 44,
                                        color: i < widget.newStars
                                            ? null
                                            : Colors.grey.withValues(alpha: 0.3)))
                                .animate(delay: (400 + i * 180).ms)
                                .scale(
                                    begin: const Offset(0.1, 0.1),
                                    curve: Curves.elasticOut,
                                    duration: 550.ms),
                          );
                        }),
                      ),

                      const SizedBox(height: 10),

                      // Completion progress + next star hint
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: widget.newStars >= 3
                              ? AppTheme.success.withValues(alpha: 0.1)
                              : AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                              color: widget.newStars >= 3
                                  ? AppTheme.success.withValues(alpha: 0.4)
                                  : AppTheme.border),
                        ),
                        child: Text(
                          'Completed ${widget.timesCompleted}/3  $_progressHint',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.newStars >= 3
                                  ? AppTheme.success
                                  : AppTheme.textSecondary),
                        ),
                      ).animate(delay: 450.ms).fadeIn(),

                      const SizedBox(height: 22),

                      // Stat boxes — XP is animated counter
                      Row(
                        children: [
                          // Animated XP box
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _xpAnim,
                              builder: (_, __) => _StatBox(
                                icon: '⭐',
                                label: 'XP Earned',
                                value: '+${_xpAnim.value.round()}',
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatBox(
                                icon: '🎯',
                                label: 'Accuracy',
                                value: '${widget.score}%',
                                color: AppTheme.success),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatBox(
                                icon: '⏱️',
                                label: 'Time',
                                value: _timeStr,
                                color: AppTheme.primary),
                          ),
                        ],
                      ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.3),

                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(children: [
                                Text('${widget.correct}',
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.success)),
                                const Text('Correct',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary)),
                              ]),
                            ),
                            Container(
                                width: 1, height: 40, color: AppTheme.border),
                            Expanded(
                              child: Column(children: [
                                Text('${widget.total - widget.correct}',
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.danger)),
                                const Text('Incorrect',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary)),
                              ]),
                            ),
                            Container(
                                width: 1, height: 40, color: AppTheme.border),
                            Expanded(
                              child: Column(children: [
                                Text('${widget.lesson.words.length}',
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.primary)),
                                const Text('Words',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary)),
                              ]),
                            ),
                          ],
                        ),
                      ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
                child: PrimaryButton(
                  label: '← Back to Lessons',
                  color: lessonColor,
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.3),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
    );
  }
}
