import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../../services/audio_service.dart';

// ── XP Progress Bar ───────────────────────────────────────────────────
class XpProgressBar extends StatelessWidget {
  final int xp;
  final int level;
  final bool onDark;
  const XpProgressBar({super.key, required this.xp, required this.level, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final xpInLevel = xp % 200;
    final pct = xpInLevel / 200.0;
    final textColor = onDark ? Colors.white : AppTheme.textSecondary;
    final trackColor = onDark ? Colors.white.withValues(alpha: 0.25) : AppTheme.border;
    final fillColor = onDark ? AppTheme.thaiGold : AppTheme.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Level $level',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    letterSpacing: 1.2, color: textColor)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onDark) const Text('⭐ ', style: TextStyle(fontSize: 10)),
                Text('$xpInLevel / 200 XP',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        letterSpacing: 1.2, color: textColor)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: onDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stat Pill ─────────────────────────────────────────────────────────
class StatPill extends StatelessWidget {
  final String emoji;
  final String value;
  final Color color;
  const StatPill(
      {super.key,
      required this.emoji,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

// ── Primary Button ────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  const PrimaryButton(
      {super.key, required this.label, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap != null
          ? () {
              AudioService().playClick();
              onTap!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onTap != null ? bg : AppTheme.locked,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: onTap != null ? AppTheme.shadowMd : [],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3)),
        ),
      ),
    );
  }
}

// ── Choice State ──────────────────────────────────────────────────────
enum ChoiceState { idle, selected, correct, wrong, revealed }

// ── Choice Card (StatefulWidget for shake + bounce) ───────────────────
class ChoiceCard extends StatefulWidget {
  final String label;
  final String? sublabel;
  final ChoiceState state;
  final VoidCallback? onTap;

  const ChoiceCard({
    super.key,
    required this.label,
    this.sublabel,
    this.state = ChoiceState.idle,
    this.onTap,
  });

  @override
  State<ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<ChoiceCard>
    with TickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
  }

  @override
  void didUpdateWidget(ChoiceCard old) {
    super.didUpdateWidget(old);
    if (widget.state == ChoiceState.wrong && old.state != ChoiceState.wrong) {
      _shakeCtrl.forward(from: 0);
    }
    if (widget.state == ChoiceState.correct &&
        old.state != ChoiceState.correct) {
      _bounceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  // Damped sine shake: oscillates 6 times, amplitude decays
  double _shakeDx(double t) => sin(t * pi * 6) * 8.0 * (1.0 - t);

  // Quick scale bump then back: 1.0 → 1.08 → 1.0
  double _bounceScale(double t) =>
      1.0 + sin(t * pi) * 0.08;

  @override
  Widget build(BuildContext context) {
    Color bg, borderColor, textColor;
    switch (widget.state) {
      case ChoiceState.correct:
      case ChoiceState.revealed:
        bg = const Color(0xFFE8FAD8);
        borderColor = AppTheme.success;
        textColor = const Color(0xFF2D7A00);
        break;
      case ChoiceState.wrong:
        bg = const Color(0xFFFFE0E0);
        borderColor = AppTheme.danger;
        textColor = const Color(0xFFA80000);
        break;
      case ChoiceState.selected:
        bg = const Color(0xFFEEF8FF);
        borderColor = AppTheme.primary;
        textColor = AppTheme.primary;
        break;
      default:
        bg = AppTheme.card;
        borderColor = AppTheme.border;
        textColor = AppTheme.textPrimary;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_shakeCtrl, _bounceCtrl]),
      builder: (_, child) {
        final dx = _shakeCtrl.isAnimating ? _shakeDx(_shakeCtrl.value) : 0.0;
        final scale =
            _bounceCtrl.isAnimating ? _bounceScale(_bounceCtrl.value) : 1.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.state == ChoiceState.idle ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: borderColor, width: 2),
            boxShadow:
                widget.state == ChoiceState.idle ? AppTheme.shadowSm : [],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    if (widget.sublabel != null) ...[
                      const SizedBox(height: 2),
                      Text(widget.sublabel!,
                          style: TextStyle(
                              fontSize: 13,
                              color: textColor.withOpacity(0.7))),
                    ],
                  ],
                ),
              ),
              if (widget.state == ChoiceState.correct ||
                  widget.state == ChoiceState.revealed)
                Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 22),
              if (widget.state == ChoiceState.wrong)
                Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── XP Pop ───────────────────────────────────────────────────────────
class XpPopWidget extends StatefulWidget {
  final int amount;
  final VoidCallback onDone;
  const XpPopWidget({super.key, required this.amount, required this.onDone});

  @override
  State<XpPopWidget> createState() => _XpPopWidgetState();
}

class _XpPopWidgetState extends State<XpPopWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _translateY;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300));

    // Scale: punch up to 1.25, back to 1.0, then stay at 1.0 until fade
    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.6, end: 1.25)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 1.25, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
    ]).animate(_ctrl);

    _opacity = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
    ]).animate(_ctrl);

    _translateY = Tween(begin: 0.0, end: -70.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _translateY.value),
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                boxShadow: AppTheme.shadowMd,
              ),
              child: Text('+${widget.amount} XP ⭐',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF5A3E00))),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Combo Banner ──────────────────────────────────────────────────────
class ComboBanner extends StatelessWidget {
  final int combo;
  const ComboBanner({super.key, required this.combo});

  @override
  Widget build(BuildContext context) {
    if (combo < 2) return const SizedBox.shrink();
    final labels = [
      '', '', '🔥 2x Combo!', '🔥🔥 3x Combo!', '💥 4x!!', '🌟 5x!!!'
    ];
    final colors = [
      Colors.transparent, Colors.transparent,
      const Color(0xFFFF9600), const Color(0xFFE91E8C),
      const Color(0xFF9C27B0), const Color(0xFF1565C0),
    ];
    final idx = combo.clamp(0, 5);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: colors[idx],
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(labels[idx],
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white)),
    )
        .animate()
        .slideY(
            begin: -2.5,
            duration: 500.ms,
            curve: Curves.elasticOut)
        .fadeIn(duration: 200.ms);
  }
}

// ── Screen Flash ──────────────────────────────────────────────────────
/// Brief full-screen colour tint (correct = green, wrong = red). Auto-fades.
class ScreenFlash extends StatelessWidget {
  final Color color;
  const ScreenFlash({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(color: color.withOpacity(0.18))
          .animate()
          .fadeIn(duration: 60.ms)
          .then()
          .fadeOut(duration: 320.ms),
    );
  }
}

// ── Sparkle Particles ─────────────────────────────────────────────────
/// 8 sparkle emojis that burst upward and fade when a correct answer fires.
class SparkleParticles extends StatelessWidget {
  const SparkleParticles({super.key});

  static const _sparks = ['✨', '⭐', '✨', '⭐', '✨', '⭐', '✨', '⭐'];

  @override
  Widget build(BuildContext context) {
    // Deterministic offsets spread across the card width
    final rng = Random(42);
    return IgnorePointer(
      child: Stack(
        children: List.generate(_sparks.length, (i) {
          final dx = (rng.nextDouble() - 0.5) * 260;
          final dy = -(60 + rng.nextDouble() * 120);
          final delay = (i * 55).ms;
          return Align(
            alignment: Alignment.center,
            child: Text(_sparks[i], style: const TextStyle(fontSize: 22))
                .animate(delay: delay)
                .fadeIn(duration: 120.ms)
                .move(begin: Offset.zero, end: Offset(dx, dy), duration: 700.ms,
                    curve: Curves.easeOut)
                .fadeOut(begin: 0.4, duration: 700.ms),
          );
        }),
      ),
    );
  }
}

// ── Level-Up Overlay ──────────────────────────────────────────────────
/// Shows a full-screen level-up celebration and awaits its dismissal.
Future<void> showLevelUpOverlay(BuildContext context, int level) async {
  Future.delayed(const Duration(milliseconds: 2600), () {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  });
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss',
    barrierColor: Colors.black.withOpacity(0.75),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, _, __) => GestureDetector(
      onTap: () => Navigator.pop(ctx),
      child: _LevelUpContent(level: level),
    ),
    transitionBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}

class _LevelUpContent extends StatelessWidget {
  final int level;
  const _LevelUpContent({required this.level});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 90))
                .animate()
                .scale(
                    begin: const Offset(0.2, 0.2),
                    duration: 700.ms,
                    curve: Curves.elasticOut)
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
            const Text(
              'LEVEL UP!',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.4, curve: Curves.easeOut),
            const SizedBox(height: 8),
            Text(
              'Level $level',
              style: const TextStyle(
                  fontSize: 24, color: AppTheme.accent, fontWeight: FontWeight.w800),
            ).animate(delay: 500.ms).fadeIn(),
            const SizedBox(height: 24),
            // Sparkles row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                return Text('✨', style: const TextStyle(fontSize: 28))
                    .animate(delay: (600 + i * 80).ms)
                    .scale(
                        begin: const Offset(0, 0),
                        duration: 400.ms,
                        curve: Curves.elasticOut);
              }),
            ),
            const SizedBox(height: 32),
            Text(
              'Tap to continue',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
            ).animate(delay: 1200.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

// ── Feedback Bar ──────────────────────────────────────────────────────
class FeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;
  final String? hint;
  final VoidCallback onContinue;

  const FeedbackBar({
    super.key,
    required this.isCorrect,
    required this.correctAnswer,
    this.hint,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isCorrect ? const Color(0xFFE8FAD8) : const Color(0xFFFFE0E0);
    final borderColor = isCorrect ? AppTheme.success : AppTheme.danger;
    final titleColor =
        isCorrect ? const Color(0xFF2D7A00) : const Color(0xFFA80000);

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: borderColor, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(isCorrect ? '🎉' : '💔',
                  style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isCorrect ? 'Correct!' : 'Incorrect',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: titleColor)),
                    if (!isCorrect)
                      Text('Answer: $correctAnswer',
                          style: TextStyle(
                              fontSize: 14,
                              color: titleColor.withOpacity(0.8))),
                    if (hint != null)
                      Text(hint!,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Continue →',
            color: isCorrect ? AppTheme.success : AppTheme.danger,
            onTap: onContinue,
          ),
        ],
      ),
    ).animate().slideY(begin: 1, duration: 250.ms, curve: Curves.easeOut);
  }
}
