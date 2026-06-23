import '../../services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exercise.dart';
import '../../models/word.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/common_widgets.dart';

class McScreen extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;
  final bool answered;
  final bool lastCorrect;

  const McScreen({
    super.key,
    required this.exercise,
    required this.onAnswer,
    required this.answered,
    required this.lastCorrect,
  });

  @override
  State<McScreen> createState() => _McScreenState();
}

class _McScreenState extends State<McScreen> {
  Word? _selected;

  @override
  void didUpdateWidget(McScreen old) {
    super.didUpdateWidget(old);
    if (!widget.answered) _selected = null;
  }

  bool get _isTh2En =>
      widget.exercise.type == ExerciseType.multipleChoice ||
      widget.exercise.type == ExerciseType.fillInBlank;

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final target = ex.targetWord;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (ex.promptText ?? '').toUpperCase(),
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          _buildStimulus(target),
          const SizedBox(height: 24),
          const Text('CHOOSE THE ANSWER',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          ...ex.options.asMap().entries.map((entry) {
            final i = entry.key;
            final word = entry.value;
            final label = _isTh2En ? word.english : word.thai;
            final sublabel = _isTh2En ? null : word.phonetic;

            ChoiceState state = ChoiceState.idle;
            if (widget.answered) {
              if (word.id == target.id) {
                state = ChoiceState.correct;
              } else if (_selected?.id == word.id) {
                state = ChoiceState.wrong;
              }
            } else if (_selected?.id == word.id) {
              state = ChoiceState.selected;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ChoiceCard(
                label: label,
                sublabel: sublabel,
                state: state,
                onTap: () => _select(word),
              ),
            )
                .animate(delay: (i * 60).ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.1, duration: 300.ms, curve: Curves.easeOut);
          }),
        ],
      ),
    );
  }

  Widget _buildStimulus(Word target) {
    if (_isTh2En) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
        ),
        child: Column(
          children: [
            Text(target.thai,
                style: const TextStyle(
                    fontSize: 48, fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(target.phonetic,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500,
                    color: AppTheme.primary, fontStyle: FontStyle.italic)),
          ],
        ),
      ).animate().scale(
            begin: const Offset(0.9, 0.9),
            duration: 400.ms,
            curve: Curves.elasticOut,
          );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.accent, width: 1.5),
        ),
        child: Text(target.english,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
      ).animate().scale(
            begin: const Offset(0.9, 0.9),
            duration: 400.ms,
            curve: Curves.elasticOut,
          );
    }
  }

void _select(Word word) {
    if (widget.answered) return;
    setState(() => _selected = word);
    final correct = word.id == widget.exercise.targetWord.id;
    if (correct) {
      AudioService().playCorrectThenWord(widget.exercise.targetWord.audio, thaiText: widget.exercise.targetWord.thai);
    }
    widget.onAnswer(correct);
  }
}