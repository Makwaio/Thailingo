import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exercise.dart';
import '../../models/word.dart';
import '../../services/audio_service.dart';
import '../../ui/theme/app_theme.dart';

class VisualSpotterScreen extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;
  final bool answered;
  final bool lastCorrect;

  const VisualSpotterScreen({
    super.key,
    required this.exercise,
    required this.onAnswer,
    required this.answered,
    required this.lastCorrect,
  });

  @override
  State<VisualSpotterScreen> createState() => _VisualSpotterScreenState();
}

class _VisualSpotterScreenState extends State<VisualSpotterScreen> {
  Word? _selected;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        AudioService().playWord(
          widget.exercise.targetWord.audio,
          thaiText: widget.exercise.targetWord.thai,
        );
      }
    });
  }

  @override
  void didUpdateWidget(VisualSpotterScreen old) {
    super.didUpdateWidget(old);
    if (!widget.answered) {
      _selected = null;
      if (old.exercise.targetWord.id != widget.exercise.targetWord.id) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            AudioService().playWord(
              widget.exercise.targetWord.audio,
              thaiText: widget.exercise.targetWord.thai,
            );
          }
        });
      }
    }
  }

  void _select(Word word) {
    if (widget.answered) return;
    setState(() => _selected = word);
    final correct = word.id == widget.exercise.targetWord.id;
    if (correct) {
      AudioService().playCorrectThenWord(
        widget.exercise.targetWord.audio,
        thaiText: widget.exercise.targetWord.thai,
      );
    }
    widget.onAnswer(correct);
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.exercise.targetWord;
    final emoji = target.emoji.isNotEmpty ? target.emoji : '🔤';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'WHAT IS THIS IN THAI?',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Emoji stimulus card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: const Color(0xFFF48FB1), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 72),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  target.english,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => AudioService().playWord(target.audio, thaiText: target.thai),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(color: const Color(0xFFF48FB1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up_rounded, size: 14, color: Color(0xFFE91E63)),
                        SizedBox(width: 4),
                        Text('🔊', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.9, 0.9),
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'TAP THE THAI WORD',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2×2 grid of Thai word choices
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: widget.exercise.options.asMap().entries.map((entry) {
              final i = entry.key;
              final word = entry.value;
              final isTarget = word.id == target.id;

              Color bg;
              Color border;
              Color textColor = AppTheme.textPrimary;
              if (widget.answered) {
                if (isTarget) {
                  bg = AppTheme.success.withValues(alpha: 0.12);
                  border = AppTheme.success;
                  textColor = AppTheme.success;
                } else if (_selected?.id == word.id) {
                  bg = AppTheme.danger.withValues(alpha: 0.1);
                  border = AppTheme.danger;
                  textColor = AppTheme.danger;
                } else {
                  bg = Colors.white;
                  border = AppTheme.border;
                }
              } else if (_selected?.id == word.id) {
                bg = AppTheme.primary.withValues(alpha: 0.1);
                border = AppTheme.primary;
                textColor = AppTheme.primary;
              } else {
                bg = Colors.white;
                border = AppTheme.border;
              }

              return GestureDetector(
                onTap: () => _select(word),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: border, width: 2),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        word.thai,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        word.phonetic,
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: (i * 60).ms)
                  .fadeIn(duration: 280.ms)
                  .slideY(begin: 0.15, duration: 280.ms, curve: Curves.easeOut);
            }).toList(),
          ),
        ],
      ),
    );
  }
}
