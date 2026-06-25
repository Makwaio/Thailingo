import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exercise.dart';
import '../../services/audio_service.dart';
import '../../ui/theme/app_theme.dart';

class OppositesScreen extends StatefulWidget {
  final OppositesChallengeExercise exercise;
  final void Function(bool) onAnswer;
  final bool answered;
  final bool lastCorrect;

  const OppositesScreen({
    super.key,
    required this.exercise,
    required this.onAnswer,
    required this.answered,
    required this.lastCorrect,
  });

  @override
  State<OppositesScreen> createState() => _OppositesScreenState();
}

class _OppositesScreenState extends State<OppositesScreen> {
  String? _selected;
  late List<_Choice> _choices;

  @override
  void initState() {
    super.initState();
    _buildChoices();
    Future.delayed(const Duration(milliseconds: 350), _playPrompt);
  }

  @override
  void didUpdateWidget(OppositesScreen old) {
    super.didUpdateWidget(old);
    if (!widget.answered) {
      _selected = null;
      if (old.exercise.promptThai != widget.exercise.promptThai) {
        _buildChoices();
        Future.delayed(const Duration(milliseconds: 350), _playPrompt);
      }
    }
  }

  void _buildChoices() {
    final ex = widget.exercise;
    final all = [
      _Choice(ex.answerThai, ex.answerPhonetic, isCorrect: true),
      ...ex.wrongChoices.map((c) => _Choice(c.$1, c.$2, isCorrect: false)),
    ]..shuffle();
    _choices = all;
  }

  void _playPrompt() {
    if (!mounted) return;
    AudioService().playWord(
      widget.exercise.promptAudio,
      thaiText: widget.exercise.promptThai,
    );
  }

  void _select(String thai) {
    if (widget.answered) return;
    setState(() => _selected = thai);
    final correct = thai == widget.exercise.answerThai;
    if (correct) {
      AudioService().playCorrectThenWord(
        widget.exercise.answerAudio,
        thaiText: widget.exercise.answerThai,
      );
    }
    widget.onAnswer(correct);
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "WHAT'S THE OPPOSITE?",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Prompt card
          GestureDetector(
            onTap: _playPrompt,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(color: const Color(0xFF4DB6AC), width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    ex.promptThai,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF004D40),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ex.promptPhonetic,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF00695C),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ex.promptEnglish,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volume_up_rounded, size: 14, color: Color(0xFF00695C)),
                      SizedBox(width: 4),
                      Text(
                        'Tap to hear',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF00695C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
              'TAP THE OPPOSITE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),

          ...(_choices.asMap().entries.map((entry) {
            final i = entry.key;
            final choice = entry.value;

            Color bg;
            Color border;
            Color textColor = AppTheme.textPrimary;

            if (widget.answered) {
              if (choice.isCorrect) {
                bg = AppTheme.success.withValues(alpha: 0.12);
                border = AppTheme.success;
                textColor = AppTheme.success;
              } else if (_selected == choice.thai) {
                bg = AppTheme.danger.withValues(alpha: 0.1);
                border = AppTheme.danger;
                textColor = AppTheme.danger;
              } else {
                bg = Colors.white;
                border = AppTheme.border;
              }
            } else if (_selected == choice.thai) {
              bg = AppTheme.primary.withValues(alpha: 0.1);
              border = AppTheme.primary;
              textColor = AppTheme.primary;
            } else {
              bg = Colors.white;
              border = AppTheme.border;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _select(choice.thai),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: border, width: 2),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          choice.thai,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                      Text(
                        choice.phonetic,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.65),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate(delay: (i * 70).ms)
                .fadeIn(duration: 260.ms)
                .slideX(begin: 0.1, duration: 260.ms, curve: Curves.easeOut);
          })),
        ],
      ),
    );
  }
}

class _Choice {
  final String thai;
  final String phonetic;
  final bool isCorrect;
  const _Choice(this.thai, this.phonetic, {required this.isCorrect});
}
