import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../services/progress_service.dart';
import '../services/audio_service.dart';
import '../services/missed_questions_service.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/common_widgets.dart';
import 'exercise_screens/mc_screen.dart';
import 'exercise_screens/pairs_screen.dart';

class MissedReviewScreen extends StatefulWidget {
  const MissedReviewScreen({super.key});

  @override
  State<MissedReviewScreen> createState() => _MissedReviewScreenState();
}

class _MissedReviewScreenState extends State<MissedReviewScreen> {
  final _exerciseService = ExerciseService();
  final _progressService = ProgressService();

  List<dynamic> _queue = [];
  int _idx = 0;
  int _xpGained = 0;
  int _combo = 0;
  int _wordsCleared = 0;
  int _totalWords = 0;

  bool _showFeedback = false;
  bool _lastCorrect = false;
  String _correctAnswer = '';
  String? _hint;
  bool _showXpPop = false;
  int _xpPopAmount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    final words = await MissedQuestionsService().getMissedWords();
    final queue = _exerciseService.buildReviewQueue(words);
    if (mounted) {
      setState(() {
        _queue = queue;
        _totalWords = words.length;
        _loading = false;
      });
      if (queue.isEmpty) _finishReview();
    }
  }

  double get _progress => _queue.isEmpty ? 0 : _idx / _queue.length;

  void _onAnswer(bool correct,
      {String correctAns = '', String? hint, int pairsCleared = 0}) {
    if (_showFeedback) return;
    setState(() {
      _showFeedback = true;
      _lastCorrect = correct;
      _correctAnswer = correctAns;
      _hint = hint;

      if (correct) {
        _combo++;
        final cleared = pairsCleared > 0 ? pairsCleared : 1;
        _wordsCleared += cleared;
        final xp = 10 * cleared;
        _xpGained += xp;
        _xpPopAmount = xp;
        _showXpPop = true;
        if (_combo >= 2) AudioService().playCombo();
      } else {
        _combo = 0;
        AudioService().playWrong();
      }
    });
  }

  void _onContinue() {
    setState(() {
      _showFeedback = false;
      _showXpPop = false;
      _idx++;
    });
    if (_idx >= _queue.length) _finishReview();
  }

  Future<void> _finishReview() async {
    AudioService().playComplete();
    if (_xpGained > 0) await _progressService.addXp(_xpGained);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => _MissedCompleteScreen(
          wordsCleared: _wordsCleared,
          totalWords: _totalWords,
          xpGained: _xpGained,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildContent()),
            if (_showFeedback)
              FeedbackBar(
                isCorrect: _lastCorrect,
                correctAnswer: _correctAnswer,
                hint: _hint,
                onContinue: _onContinue,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: _confirmExit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppTheme.textSecondary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 14,
                backgroundColor: AppTheme.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFE65100)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                  color: const Color(0xFFE65100).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('❓', style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text('MISSED',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE65100),
                        letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_idx >= _queue.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final q = _queue[_idx];
    Widget exercise;

    if (q is MatchPairExercise) {
      final pairs = q.pairs;
      exercise = PairsScreen(
        exercise: q,
        onComplete: (correct, total) {
          final allCorrect = correct == total;
          if (allCorrect) {
            for (final word in pairs) {
              MissedQuestionsService().removeWord(word.id);
            }
          }
          _onAnswer(
            allCorrect,
            correctAns: allCorrect
                ? 'Match all pairs'
                : '$correct/$total pairs correct',
            pairsCleared: allCorrect ? pairs.length : 0,
          );
        },
        answered: _showFeedback,
      );
    } else if (q is Exercise) {
      final targetWord = q.targetWord;

      void onMcAnswer(bool correct) {
        if (correct) MissedQuestionsService().removeWord(targetWord.id);
        _onAnswer(
          correct,
          correctAns: q.type == ExerciseType.multipleChoiceTh
              ? '${targetWord.thai} (${targetWord.phonetic})'
              : targetWord.english,
          hint: targetWord.example.isNotEmpty ? targetWord.example : null,
        );
      }

      exercise = McScreen(
        exercise: q,
        onAnswer: onMcAnswer,
        answered: _showFeedback,
        lastCorrect: _lastCorrect,
      );
    } else {
      exercise = const SizedBox.shrink();
    }

    return Stack(
      children: [
        Column(
          children: [
            if (_combo >= 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ComboBanner(combo: _combo, key: ValueKey(_combo)),
              ),
            Expanded(child: exercise),
          ],
        ),
        if (_showXpPop)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: XpPopWidget(
                amount: _xpPopAmount,
                onDone: () => setState(() => _showXpPop = false),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmExit() async {
    AudioService().playClick();
    final exit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave review?'),
        content: const Text('Cleared words are already removed from your list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep going')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (exit == true && mounted) Navigator.pop(context, _wordsCleared > 0);
  }
}

// ── Completion screen ───────────────────────────────────────────────────
class _MissedCompleteScreen extends StatelessWidget {
  final int wordsCleared;
  final int totalWords;
  final int xpGained;

  const _MissedCompleteScreen({
    required this.wordsCleared,
    required this.totalWords,
    required this.xpGained,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3E1500),
              Color(0xFF6E2B00),
              Color(0xFFBF360C),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                const Text('🎉', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 20),
                Text(
                  wordsCleared > 0 ? 'Missed words reviewed!' : 'Good effort!',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  wordsCleared > 0
                      ? 'Great job! $wordsCleared missed ${wordsCleared == 1 ? 'word' : 'words'} reviewed! 🎉'
                      : 'Keep practising — you\'ll get them next time!',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatCard(
                        emoji: '❓',
                        label: 'Cleared',
                        value: '$wordsCleared'),
                    const SizedBox(width: 16),
                    _StatCard(
                        emoji: '⭐',
                        label: 'XP Earned',
                        value: '+$xpGained'),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                    ),
                    child: const Text(
                      'Back to Lessons',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
