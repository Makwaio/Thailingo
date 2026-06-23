import '../../services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exercise.dart';
import '../../models/word.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/common_widgets.dart';

class ListenScreen extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;
  final bool answered;
  final bool lastCorrect;

  const ListenScreen({
    super.key,
    required this.exercise,
    required this.onAnswer,
    required this.answered,
    required this.lastCorrect,
  });

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen>
    with SingleTickerProviderStateMixin {
  Word? _selected;
  bool _played = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  void didUpdateWidget(ListenScreen old) {
    super.didUpdateWidget(old);
    if (!widget.answered) { _selected = null; _played = false; }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((ex.promptText ?? 'LISTEN AND CHOOSE').toUpperCase(),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: AppTheme.textSecondary)),
          const SizedBox(height: 20),

          // Word display (since we have no audio yet, show the Thai)
          Center(
            child: GestureDetector(
              onTap: () {
  setState(() => _played = true);
  AudioService().playWord(widget.exercise.targetWord.audio, thaiText: widget.exercise.targetWord.thai);
},
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, child) => Transform.scale(
                  scale: _played ? 1.0 : 1.0 + _pulseCtrl.value * 0.05,
                  child: child,
                ),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(ex.targetWord.thai,
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(ex.targetWord.phonetic,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70,
                              fontStyle: FontStyle.italic)),
                      const SizedBox(height: 6),
                      Text(_played ? 'Tap to review' : 'Tap to reveal',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white60,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ).animate().scale(
                  begin: const Offset(0.6, 0.6),
                  duration: 500.ms,
                  curve: Curves.elasticOut),
          ),

          const SizedBox(height: 28),
          const Text('SELECT THE ANSWER',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),

          ...ex.options.asMap().entries.map((entry) {
            final i = entry.key;
            final word = entry.value;
            ChoiceState state = ChoiceState.idle;
            if (widget.answered) {
              if (word.id == ex.targetWord.id) state = ChoiceState.correct;
              else if (_selected?.id == word.id) state = ChoiceState.wrong;
            } else if (_selected?.id == word.id) {
              state = ChoiceState.selected;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ChoiceCard(
                label: word.english,
                state: state,
                onTap: () => _select(word),
              ),
            )
                .animate(delay: (i * 60).ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2, duration: 300.ms, curve: Curves.easeOut);
          }),
        ],
      ),
    );
  }

  void _select(Word word) {
    if (widget.answered) return;
    setState(() { _selected = word; _played = true; });
    final correct = word.id == widget.exercise.targetWord.id;
    if (correct) AudioService().playCorrect();
    widget.onAnswer(correct);
  }
}
