import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../services/audio_service.dart';
import '../../ui/theme/app_theme.dart';

class TypingScreen extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool correct) onAnswer;
  final bool answered;
  final bool lastCorrect;

  const TypingScreen({
    super.key,
    required this.exercise,
    required this.onAnswer,
    required this.answered,
    required this.lastCorrect,
  });

  @override
  State<TypingScreen> createState() => _TypingScreenState();
}

class _TypingScreenState extends State<TypingScreen> {
  final _controller = TextEditingController();
  bool _submitted = false;
  bool? _wasCorrect;

  @override
  void initState() {
    super.initState();
    // Play the word audio automatically
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && widget.exercise.targetWord.audio.isNotEmpty) {
        AudioService().playWord(widget.exercise.targetWord.audio, thaiText: widget.exercise.targetWord.thai);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isCloseEnough(String typed, String target) {
    final t = typed.trim().toLowerCase().replaceAll(RegExp(r'[-\s]'), '');
    final g = target.trim().toLowerCase().replaceAll(RegExp(r'[-\s]'), '');
    if (t == g) return true;
    // Levenshtein distance <= 2
    return _levenshtein(t, g) <= 2;
  }

  int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final d = List.generate(
        a.length + 1, (i) => List.generate(b.length + 1, (j) => 0));
    for (int i = 0; i <= a.length; i++) d[i][0] = i;
    for (int j = 0; j <= b.length; j++) d[0][j] = j;
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        d[i][j] = a[i - 1] == b[j - 1]
            ? d[i - 1][j - 1]
            : 1 + [d[i - 1][j], d[i][j - 1], d[i - 1][j - 1]].reduce(min);
      }
    }
    return d[a.length][b.length];
  }

  int min(int a, int b) => a < b ? a : b;

  void _submit() {
    if (_submitted || widget.answered) return;
    final correct = _isCloseEnough(
        _controller.text, widget.exercise.targetWord.phonetic);
    setState(() {
      _submitted = true;
      _wasCorrect = correct;
    });
    if (correct) {
      AudioService().playCorrectThenWord(widget.exercise.targetWord.audio, thaiText: widget.exercise.targetWord.thai);
    }
    widget.onAnswer(correct);
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.exercise.targetWord;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Thai word display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.thaiNavy,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.thaiNavy.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Type the phonetic spelling',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text(
                  word.thai,
                  style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => AudioService().playWord(word.audio, thaiText: word.thai),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Play again',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Input field
          TextField(
            controller: _controller,
            enabled: !_submitted && !widget.answered,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. sa-wat-dee',
              hintStyle:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLg),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLg),
                borderSide: const BorderSide(color: AppTheme.border, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLg),
                borderSide:
                    const BorderSide(color: AppTheme.thaiNavy, width: 2),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),

          if (_submitted) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_wasCorrect == true)
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.thaiRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(
                  color: (_wasCorrect == true)
                      ? AppTheme.success
                      : AppTheme.thaiRed,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _wasCorrect == true ? '✓ Correct!' : '✗ The answer was:',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _wasCorrect == true
                            ? AppTheme.success
                            : AppTheme.thaiRed),
                  ),
                  if (_wasCorrect != true) ...[
                    const SizedBox(height: 4),
                    Text(
                      word.phonetic,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.thaiNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull)),
                ),
                child: const Text('Submit',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Accepted: ${word.phonetic} (close spellings OK)',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
