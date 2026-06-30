import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../services/progress_service.dart';
import '../services/settings_service.dart';
import '../services/audio_service.dart';
import '../services/localization_service.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/common_widgets.dart';
import 'exercise_screens/mc_screen.dart';
import 'exercise_screens/pairs_screen.dart';
import 'exercise_screens/listen_screen.dart';
import 'exercise_screens/speed_tap_screen.dart';
import 'exercise_screens/sentence_builder_screen.dart';
import 'exercise_screens/conversation_screen.dart';
import 'exercise_screens/typing_screen.dart';
import 'exercise_screens/visual_spotter_screen.dart';
import 'exercise_screens/opposites_screen.dart';
import 'result_screen.dart';
import 'game_over_screen.dart';
import '../services/review_service.dart';
import '../services/missed_questions_service.dart';
import 'bug_report_dialog.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with TickerProviderStateMixin {
  final _exerciseService = ExerciseService();
  final _progressService = ProgressService();

  late List<dynamic> _queue;
  int _idx = 0;
  int _correct = 0;
  int _totalAnswered = 0;
  int _xpGained = 0;
  int _combo = 0;
  int _peakCombo = 0;
  int _lives = 3;
  bool _showFeedback = false;
  bool _lastCorrect = false;
  String _correctAnswer = '';
  String? _hint;
  bool _showXpPop = false;
  int _xpPopAmount = 0;
  final Stopwatch _timer = Stopwatch();

  bool _showSparkles = false;
  int _sparkleKey = 0;

  bool _showFlash = false;
  Color _flashColor = AppTheme.success;
  int _flashKey = 0;

  bool _gameOverTriggered = false;
  bool _gameOverSequenceRunning = false;

  int _breakingHeartIdx = -1;
  late AnimationController _heartBreakCtrl;

  bool get _isLearningEnglish =>
      SettingsService.appLanguageNotifier.value == AppLanguage.learningEnglish;

  // Alphabet lessons (A1-A5 = ids 101-105, E1-E5 = ids 201-205)
  bool get _isAlphabetLesson => widget.lesson.id >= 100;

  @override
  void initState() {
    super.initState();
    _queue = _exerciseService.buildQueue(widget.lesson);
    _timer.start();

    _heartBreakCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartBreakCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _breakingHeartIdx = -1);
      }
    });
  }

  @override
  void dispose() {
    _heartBreakCtrl.dispose();
    super.dispose();
  }

  double get _progress => (_idx / 20.0).clamp(0.0, 1.0);

  void _onAnswer(bool correct, {String correctAns = '', String? hint, int bonusXp = 0}) {
    if (_showFeedback || _gameOverSequenceRunning) return;
    setState(() {
      _totalAnswered++;
      _showFeedback = true;
      _lastCorrect = correct;
      _correctAnswer = correctAns;
      _hint = hint;

      if (correct) {
        _correct++;
        _combo++;
        if (_combo > _peakCombo) _peakCombo = _combo;
        final xp = 10 + (_combo >= 3 ? 5 : 0) + bonusXp;
        _xpGained += xp;
        _xpPopAmount = xp;
        _showXpPop = true;
        if (_combo >= 2) AudioService().playCombo();

        _showSparkles = true;
        _sparkleKey++;
        _flashColor = AppTheme.success;
        _showFlash = true;
        _flashKey++;
        Future.delayed(const Duration(milliseconds: 700),
            () { if (mounted) setState(() => _showSparkles = false); });
      } else {
        _combo = 0;
        _lives = (_lives - 1).clamp(0, 3);

        final currentQ = _idx < _queue.length ? _queue[_idx] : null;
        if (currentQ is Exercise) {
          ReviewService().addToQueue(currentQ.targetWord, widget.lesson.id);
          Future.delayed(const Duration(milliseconds: 700), () {
            if (mounted) AudioService().playWord(currentQ.targetWord.audio, thaiText: currentQ.targetWord.thai);
          });
        }

        AudioService().playWrong();

        _flashColor = AppTheme.danger;
        _showFlash = true;
        _flashKey++;

        if (_lives > 0) {
          _breakingHeartIdx = _lives;
          _heartBreakCtrl.forward(from: 0);
        } else {
          _gameOverTriggered = true;
        }
      }
    });
  }

  void _onPairsComplete(int correctMatches, int totalPairs) {
    if (_showFeedback || _gameOverSequenceRunning) return;
    final allCorrect = correctMatches == totalPairs;
    setState(() {
      _totalAnswered++;
      if (allCorrect) _correct++;
      _showFeedback = true;
      _lastCorrect = allCorrect;
      _correctAnswer = allCorrect
          ? 'All $totalPairs pairs matched!'
          : '$correctMatches/$totalPairs pairs correct';
      _hint = null;

      if (allCorrect) {
        _combo++;
        if (_combo > _peakCombo) _peakCombo = _combo;
        final xp = 10 + (_combo >= 3 ? 5 : 0);
        _xpGained += xp;
        _xpPopAmount = xp;
        _showXpPop = true;
        if (_combo >= 2) AudioService().playCombo();
        _showSparkles = true;
        _sparkleKey++;
        _flashColor = AppTheme.success;
        _showFlash = true;
        _flashKey++;
        Future.delayed(const Duration(milliseconds: 700),
            () { if (mounted) setState(() => _showSparkles = false); });
      } else {
        _combo = 0;
        AudioService().playWrong();
        _lives = (_lives - 1).clamp(0, 3);
        if (_lives <= 0) {
          _gameOverTriggered = true;
        } else {
          _breakingHeartIdx = _lives;
          _heartBreakCtrl.forward(from: 0);
        }
        _flashColor = AppTheme.danger;
        _showFlash = true;
        _flashKey++;
      }
    });
  }

  void _onContinue() {
    if (_gameOverTriggered && !_gameOverSequenceRunning) {
      _triggerGameOver();
      return;
    }
    if (_gameOverSequenceRunning) return;
    setState(() {
      _showFeedback = false;
      _showXpPop = false;
      _showFlash = false;
      _idx++;
    });
    if (_idx >= _queue.length) _finishLesson();
  }

  Future<void> _triggerGameOver() async {
    if (_gameOverSequenceRunning) return;
    setState(() {
      _showFeedback = false;
      _showXpPop = false;
      _showFlash = false;
      _gameOverSequenceRunning = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _breakingHeartIdx = 0);
    _heartBreakCtrl.forward(from: 0);

    await AudioService().playGameOver();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => GameOverScreen(
          lesson: widget.lesson,
          questionsAnswered: _totalAnswered,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _finishLesson() async {
    _timer.stop();
    final cappedCorrect = _correct.clamp(0, 20);
    final cappedTotal = _totalAnswered.clamp(1, 20);
    final score = (cappedCorrect / cappedTotal * 100).round();
    AudioService().playComplete();

    final levelBefore = _progressService.current.level;
    await _progressService.addXp(_xpGained + widget.lesson.xpReward);
    await _progressService.completeLesson(
      lessonId: widget.lesson.id,
      score: cappedCorrect,
      maxScore: cappedTotal,
      peakCombo: _peakCombo,
      wordCount: widget.lesson.words.length,
      timeTaken: _timer.elapsed,
    );
    final levelAfter = _progressService.current.level;

    // Track missed words: words not shown in this session's exercise queue
    final lp2 = _progressService.current.lessonProgress[widget.lesson.id];
    if ((lp2?.stars ?? 0) >= 3) {
      final seenIds = _queue
          .whereType<Exercise>()
          .map((e) => e.targetWord.id)
          .toSet();
      for (final word in widget.lesson.words) {
        if (!seenIds.contains(word.id)) {
          await MissedQuestionsService().addMissedWord(word);
        }
      }
    }

    if (!mounted) return;

    if (levelAfter > levelBefore) {
      await showLevelUpOverlay(context, levelAfter);
      if (!mounted) return;
    }

    final lp = _progressService.current.lessonProgress[widget.lesson.id];
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => ResultScreen(
          lesson: widget.lesson,
          correct: cappedCorrect,
          total: cappedTotal,
          xpGained: _xpGained + widget.lesson.xpReward,
          timeTaken: _timer.elapsed,
          score: score,
          timesCompleted: lp?.timesCompleted ?? 1,
          newStars: lp?.stars ?? 1,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  color: Colors.yellow,
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'Mode: ${SettingsService.appLanguageNotifier.value}',
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
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
            if (_showFlash)
              Positioned.fill(
                child: ScreenFlash(key: ValueKey(_flashKey), color: _flashColor),
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
            onTap: _gameOverSequenceRunning ? null : _confirmExit,
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
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _gameOverSequenceRunning
                ? null
                : () => showBugReportDialog(
                      context,
                      lessonId: widget.lesson.id,
                      lessonName: widget.lesson.title,
                      screen: 'Lesson: ${widget.lesson.title}',
                    ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Text('🐛', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(_idx + 1).clamp(1, 20)}/20',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: AppTheme.border,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.success),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: List.generate(3, (i) => _buildHeart(i)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeart(int i) {
    final alive = i < _lives;
    final isBreaking = i == _breakingHeartIdx;

    if (isBreaking) {
      return AnimatedBuilder(
        animation: _heartBreakCtrl,
        builder: (_, __) {
          final t = _heartBreakCtrl.value;
          double scale;
          if (t < 0.25) {
            scale = 1.0 + (t / 0.25) * 0.6;
          } else {
            scale = 1.6 * (1.0 - (t - 0.25) / 0.75);
          }
          return Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Transform.scale(
              scale: scale.clamp(0.0, 2.0),
              child: const Text('❤️', style: TextStyle(fontSize: 16)),
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(alive ? '❤️' : '🖤', style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildContent() {
    if (_idx >= _queue.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final q = _queue[_idx];
    Widget exercise;

    if (q is MatchPairExercise) {
      exercise = PairsScreen(
        exercise: q,
        onComplete: (correct, total) => _onPairsComplete(correct, total),
        answered: _showFeedback,
      );
    } else if (q is OppositesChallengeExercise) {
      exercise = OppositesScreen(
        exercise: q,
        onAnswer: (correct) => _onAnswer(correct, correctAns: q.answerThai),
        answered: _showFeedback,
        lastCorrect: _lastCorrect,
      );
    } else if (q is SentenceBuilderExercise) {
      exercise = SentenceBuilderScreen(
        exercise: q,
        onAnswer: (correct) => _onAnswer(correct,
            correctAns: _isLearningEnglish
                ? q.englishChips.join(' ')
                : q.thaiChips.join(' ')),
        answered: _showFeedback,
        lastCorrect: _lastCorrect,
      );
    } else if (q is ConversationExercise) {
      exercise = ConversationScreen(
        exercise: q,
        onAnswer: (correct) =>
            _onAnswer(correct, correctAns: 'Comprehension check'),
        answered: _showFeedback,
      );
    } else if (q is Exercise) {
      switch (q.type) {
        case ExerciseType.listenAndChoose:
          exercise = ListenScreen(
            exercise: q,
            isAlphabetLesson: _isAlphabetLesson,
            onAnswer: (correct) => _onAnswer(correct,
                correctAns: _isLearningEnglish
                    ? q.targetWord.english
                    : q.targetWord.thai,
                hint: q.targetWord.example.isNotEmpty
                    ? q.targetWord.example
                    : null),
            answered: _showFeedback,
            lastCorrect: _lastCorrect,
          );
        case ExerciseType.speedTap:
          exercise = SpeedTapScreen(
            exercise: q,
            onAnswer: (correct, {int bonusXp = 0}) => _onAnswer(correct,
                correctAns: _isLearningEnglish
                    ? q.targetWord.english
                    : q.targetWord.thai,
                bonusXp: bonusXp),
            answered: _showFeedback,
            lastCorrect: _lastCorrect,
          );
        case ExerciseType.typing:
          exercise = TypingScreen(
            exercise: q,
            onAnswer: (correct, {bool hintUsed = false}) => _onAnswer(
              correct,
              correctAns: _isLearningEnglish
                  ? q.targetWord.english
                  : q.targetWord.phonetic,
              bonusXp: hintUsed ? -5 : 0,
            ),
            answered: _showFeedback,
            lastCorrect: _lastCorrect,
          );
        case ExerciseType.visualSpotter:
          exercise = VisualSpotterScreen(
            exercise: q,
            onAnswer: (correct) => _onAnswer(correct,
                correctAns: q.targetWord.thai),
            answered: _showFeedback,
            lastCorrect: _lastCorrect,
          );
        default:
          exercise = McScreen(
            exercise: q,
            isLearningEnglish: _isLearningEnglish,
            onAnswer: (correct) => _onAnswer(correct,
                correctAns: _isLearningEnglish
                    ? q.targetWord.english
                    : '${q.targetWord.thai} (${q.targetWord.phonetic})',
                hint: q.targetWord.example.isNotEmpty
                    ? q.targetWord.example
                    : null),
            answered: _showFeedback,
            lastCorrect: _lastCorrect,
          );
      }
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
        if (_showSparkles)
          Positioned.fill(
            child: SparkleParticles(key: ValueKey(_sparkleKey)),
          ),
      ],
    );
  }

  Future<void> _confirmExit() async {
    AudioService().playClick();
    final exit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(LocalizationService.t('leave_lesson_title')),
        content: Text(LocalizationService.t('progress_lost')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(LocalizationService.t('keep_going'))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(LocalizationService.t('leave'),
                  style: const TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (exit == true && mounted) Navigator.pop(context);
  }

}
