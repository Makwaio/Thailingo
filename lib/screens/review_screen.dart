import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../services/progress_service.dart';
import '../services/audio_service.dart';
import '../services/review_service.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/common_widgets.dart';
import 'exercise_screens/mc_screen.dart';
import 'exercise_screens/pairs_screen.dart';
import 'review_complete_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _exerciseService = ExerciseService();
  final _progressService = ProgressService();

  List<dynamic> _queue = [];
  int _idx = 0;
  int _xpGained = 0;
  int _combo = 0;
  int _wordsCleared = 0;

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
    final reviewWords = await ReviewService().getQueue();
    final words = reviewWords.map((rw) => rw.word).toList();
    final queue = _exerciseService.buildReviewQueue(words);
    if (mounted) {
      setState(() {
        _queue = queue;
        _loading = false;
      });
      if (queue.isEmpty) _finishReview();
    }
  }

  double get _progress => _queue.isEmpty ? 0 : _idx / _queue.length;

  // ── Answer handling ────────────────────────────────────────────────

  void _onAnswer(bool correct, {String correctAns = '', String? hint, int pairsCleared = 0}) {
    if (_showFeedback) return;
    setState(() {
      _showFeedback = true;
      _lastCorrect = correct;
      _correctAnswer = correctAns;
      _hint = hint;

      if (correct) {
        _combo++;

        // For MC: clear 1 word; for pairs: caller passes count
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
        pageBuilder: (_, anim, __) => ReviewCompleteScreen(
          wordsCleared: _wordsCleared,
          xpGained: _xpGained,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

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
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📝', style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text('REVIEW',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7C3AED),
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
      // Keep a reference to the pairs so the onComplete closure can access them
      final pairs = q.pairs;
      exercise = PairsScreen(
        exercise: q,
        onComplete: (correct) {
          if (correct) {
            // Remove all pair words from the queue
            for (final word in pairs) {
              ReviewService().removeFromQueue(word.id);
            }
          }
          _onAnswer(
            correct,
            correctAns: 'Match all pairs',
            pairsCleared: correct ? pairs.length : 0,
          );
        },
        answered: _showFeedback,
      );
    } else if (q is Exercise) {
      final targetWord = q.targetWord;

      // Remove from review queue immediately on correct (MC exercises only)
      void onMcAnswer(bool correct) {
        if (correct) ReviewService().removeFromQueue(targetWord.id);
        _onAnswer(
          correct,
          correctAns: q.type == ExerciseType.multipleChoiceTh
              ? '${targetWord.thai} (${targetWord.phonetic})'
              : targetWord.english,
          hint: targetWord.example.isNotEmpty ? targetWord.example : null,
          pairsCleared: 0,
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
        content: const Text('Your cleared words are already saved.'),
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
