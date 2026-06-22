import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exercise.dart';
import '../../services/audio_service.dart';
import '../../ui/theme/app_theme.dart';

class ConversationScreen extends StatefulWidget {
  final ConversationExercise exercise;
  final void Function(bool correct) onAnswer;
  final bool answered;

  const ConversationScreen({
    super.key,
    required this.exercise,
    required this.onAnswer,
    required this.answered,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  int _lineIdx = 0;
  bool _showingQuestions = false;
  int _questionIdx = 0;
  int _correctAnswers = 0;
  int? _selectedOption;

  @override
  void initState() {
    super.initState();
    _playCurrentLine();
  }

  void _playCurrentLine() {
    if (_lineIdx < widget.exercise.lines.length) {
      final line = widget.exercise.lines[_lineIdx];
      if (line.audioFile.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) AudioService().playWord(line.audioFile);
        });
      }
    }
  }

  void _nextLine() {
    if (_lineIdx < widget.exercise.lines.length - 1) {
      setState(() => _lineIdx++);
      _playCurrentLine();
    } else {
      setState(() => _showingQuestions = true);
    }
  }

  void _selectOption(int idx) {
    if (_selectedOption != null || widget.answered) return;
    AudioService().playClick();
    setState(() => _selectedOption = idx);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final correct = idx ==
          widget.exercise.questions[_questionIdx].correctIndex;
      if (correct) _correctAnswers++;

      if (_questionIdx < widget.exercise.questions.length - 1) {
        setState(() {
          _questionIdx++;
          _selectedOption = null;
        });
      } else {
        final allCorrect =
            _correctAnswers == widget.exercise.questions.length;
        widget.onAnswer(allCorrect);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showingQuestions ? _buildQuestions() : _buildDialogue();
  }

  Widget _buildDialogue() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scenario title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.thaiNavy,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              widget.exercise.scenarioTitle,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),

          const SizedBox(height: 20),

          // Dialogue lines
          Expanded(
            child: ListView.builder(
              itemCount: min(_lineIdx + 1, widget.exercise.lines.length),
              itemBuilder: (_, i) {
                final line = widget.exercise.lines[i];
                final isNew = i == _lineIdx;
                return _DialogueBubble(
                  line: line,
                  isNew: isNew,
                ).animate(key: ValueKey(i)).fadeIn(duration: 350.ms).slideY(
                    begin: 0.2, duration: 350.ms, curve: Curves.easeOut);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Next button or done
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextLine,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.thaiNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull)),
              ),
              child: Text(
                _lineIdx < widget.exercise.lines.length - 1
                    ? 'Next →'
                    : 'Answer Questions →',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestions() {
    if (_questionIdx >= widget.exercise.questions.length) {
      return const Center(child: CircularProgressIndicator());
    }
    final q = widget.exercise.questions[_questionIdx];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.thaiNavy,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Text(
              q.question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 24),

          Text(
            'Question ${_questionIdx + 1} of ${widget.exercise.questions.length}',
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 16),

          ...q.options.asMap().entries.map((e) {
            final i = e.key;
            final opt = e.value;
            Color bg = Colors.white;
            Color border = AppTheme.border;

            if (_selectedOption != null) {
              if (i == q.correctIndex) {
                bg = AppTheme.success.withOpacity(0.1);
                border = AppTheme.success;
              } else if (i == _selectedOption) {
                bg = AppTheme.thaiRed.withOpacity(0.1);
                border = AppTheme.thaiRed;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectOption(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: border, width: 2),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Text(
                    opt,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}

class _DialogueBubble extends StatelessWidget {
  final ConversationLine line;
  final bool isNew;

  const _DialogueBubble({required this.line, required this.isNew});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line.speaker,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isNew ? AppTheme.thaiNavy : AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                  color: isNew ? AppTheme.thaiNavy : AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.thai,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isNew ? Colors.white : AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  line.phonetic,
                  style: TextStyle(
                      fontSize: 13,
                      color: isNew
                          ? Colors.white70
                          : AppTheme.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  line.english,
                  style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isNew
                          ? Colors.white60
                          : AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
