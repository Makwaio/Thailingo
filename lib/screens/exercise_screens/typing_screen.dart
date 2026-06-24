import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../services/audio_service.dart';
import '../../ui/theme/app_theme.dart';

class TypingScreen extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool correct, {bool hintUsed}) onAnswer;
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
  int _hintsUsed = 0;
  String? _hintText;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && widget.exercise.targetWord.audio.isNotEmpty) {
        AudioService().playWord(widget.exercise.targetWord.audio,
            thaiText: widget.exercise.targetWord.thai);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalize(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[-\s]'), '');

  String _phoneticsNormalize(String s) => s
      .replaceAll('ph', 'p')
      .replaceAll('aa', 'a')
      .replaceAll('th', 't')
      .replaceAll('ee', 'i')
      .replaceAll('oo', 'u')
      .replaceAll('dt', 't')
      .replaceAll('kh', 'k');

  bool _isCloseEnough(String typed, String target) {
    final t = _normalize(typed);
    final g = _normalize(target);
    if (t == g) return true;
    if (_phoneticsNormalize(t) == _phoneticsNormalize(g)) return true;
    final threshold = (g.length * 0.3).round().clamp(2, 8);
    return _levenshtein(t, g) <= threshold;
  }

  int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final d = List.generate(
        a.length + 1, (i) => List.generate(b.length + 1, (j) => 0));
    for (int i = 0; i <= a.length; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      d[0][j] = j;
    }
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        d[i][j] = a[i - 1] == b[j - 1]
            ? d[i - 1][j - 1]
            : 1 + [d[i - 1][j], d[i][j - 1], d[i - 1][j - 1]].reduce(_min);
      }
    }
    return d[a.length][b.length];
  }

  int _min(int a, int b) => a < b ? a : b;

  String _generateHint(int level) {
    final parts = widget.exercise.targetWord.phonetic.split('-');
    return parts.map((part) {
      if (part.isEmpty) return '';
      final visible = level == 1 ? 1 : part.length.clamp(0, 3);
      final show = part.substring(0, visible.clamp(0, part.length));
      final hide = '_' * (part.length - visible).clamp(0, part.length);
      return show + hide;
    }).join('  ');
  }

  void _useHint() {
    if (_hintsUsed >= 2 || _submitted) return;
    setState(() {
      _hintsUsed++;
      _hintText = _generateHint(_hintsUsed);
    });
  }

  void _submit() {
    if (_submitted || widget.answered) return;
    final correct = _isCloseEnough(
        _controller.text, widget.exercise.targetWord.phonetic);
    setState(() {
      _submitted = true;
      _wasCorrect = correct;
    });
    if (correct) {
      AudioService().playCorrectThenWord(widget.exercise.targetWord.audio,
          thaiText: widget.exercise.targetWord.thai);
    }
    widget.onAnswer(correct, hintUsed: _hintsUsed > 0);
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.exercise.targetWord;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
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
                  color: AppTheme.thaiNavy.withValues(alpha: 0.4),
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
                  onTap: () =>
                      AudioService().playWord(word.audio, thaiText: word.thai),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
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

          const SizedBox(height: 24),

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
              hintStyle: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 16),
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
                borderSide:
                    const BorderSide(color: AppTheme.border, width: 2),
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
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.thaiRed.withValues(alpha: 0.1),
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
            // Hint display
            if (_hintText != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Text(
                      _hintText!,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (_hintsUsed < 2) ...[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _useHint,
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull)),
                      ),
                      child: Text(
                        _hintsUsed == 0 ? '💡 Hint' : '💡 More',
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _buildSubmitButton(),
                  ),
                ] else
                  Expanded(child: _buildSubmitButton()),
              ],
            ),
            const SizedBox(height: 10),
            if (_hintsUsed > 0)
              Text(
                '⚠️ Hint used — XP reduced by 50%',
                style: TextStyle(
                    fontSize: 12, color: Colors.orange.shade700),
                textAlign: TextAlign.center,
              )
            else
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

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.thaiNavy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
      ),
      child: const Text('Submit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    );
  }
}
