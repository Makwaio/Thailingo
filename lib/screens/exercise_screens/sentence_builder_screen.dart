import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exercise.dart';
import '../../services/audio_service.dart';
import '../../services/settings_service.dart';
import '../../ui/theme/app_theme.dart';

class SentenceBuilderScreen extends StatefulWidget {
  final SentenceBuilderExercise exercise;
  final void Function(bool correct) onAnswer;
  final bool answered;
  final bool lastCorrect;

  const SentenceBuilderScreen({
    super.key,
    required this.exercise,
    required this.onAnswer,
    required this.answered,
    required this.lastCorrect,
  });

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen>
    with SingleTickerProviderStateMixin {
  late List<String> _bank;
  final List<String> _placed = [];
  bool _shakeWrong = false;
  late AnimationController _shakeCtrl;

  bool get _isLearningEnglish =>
      SettingsService.appLanguageNotifier.value == AppLanguage.learningEnglish;

  List<String> get _activeChips => _isLearningEnglish
      ? widget.exercise.englishChips
      : widget.exercise.thaiChips;

  @override
  void initState() {
    super.initState();
    _bank = List<String>.from(_activeChips)..shuffle();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _shakeCtrl.reset();
        setState(() {
          _shakeWrong = false;
          _bank = List<String>.from(_activeChips)..shuffle();
          _placed.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _tapBank(String chip) {
    if (widget.answered) return;
    AudioService().playClick();
    setState(() {
      _bank.remove(chip);
      _placed.add(chip);
    });
    if (_placed.length == _activeChips.length) {
      _checkAnswer();
    }
  }

  void _tapPlaced(String chip) {
    if (widget.answered) return;
    AudioService().playClick();
    setState(() {
      _placed.remove(chip);
      _bank.add(chip);
    });
  }

  void _checkAnswer() {
    final correct = _listEquals(_placed, _activeChips);
    if (correct) {
      AudioService().playCorrectThenWord(widget.exercise.audioFile, thaiText: widget.exercise.thaiChips.join(''));
    } else {
      setState(() => _shakeWrong = true);
      _shakeCtrl.forward();
    }
    widget.onAnswer(correct);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt sentence
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.thaiNavy,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Column(
              children: [
                Text(
                  _isLearningEnglish
                      ? 'Build the English sentence'
                      : 'Build the Thai sentence',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  _isLearningEnglish
                      ? widget.exercise.thaiSentence
                      : widget.exercise.englishSentence,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: _isLearningEnglish ? 28 : 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Answer area
          const Text('Your answer:',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),

          AnimatedBuilder(
            animation: _shakeCtrl,
            builder: (_, child) {
              final shake =
                  _shakeWrong ? ((_shakeCtrl.value * 6 - 3).abs() - 1.5) * 8 : 0.0;
              return Transform.translate(
                offset: Offset(shake, 0),
                child: child,
              );
            },
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.answered && widget.lastCorrect
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : widget.answered
                        ? AppTheme.thaiRed.withValues(alpha: 0.1)
                        : AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(
                  color: widget.answered && widget.lastCorrect
                      ? AppTheme.success
                      : widget.answered
                          ? AppTheme.thaiRed
                          : AppTheme.border,
                  width: 2,
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _placed
                    .map((chip) => _Chip(
                          label: chip,
                          color: AppTheme.thaiNavy,
                          textColor: Colors.white,
                          onTap: () => _tapPlaced(chip),
                        ))
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Word bank
          const Text('Word bank:',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bank
                .map((chip) => _Chip(
                      label: chip,
                      color: Colors.white,
                      textColor: AppTheme.textPrimary,
                      onTap: () => _tapBank(chip),
                      border: AppTheme.border,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final Color? border;

  const _Chip({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: border != null ? Border.all(color: border!, width: 1.5) : null,
          boxShadow: AppTheme.shadowSm,
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor),
        ),
      ),
    ).animate().scale(
        begin: const Offset(0.8, 0.8), duration: 200.ms, curve: Curves.easeOut);
  }
}
