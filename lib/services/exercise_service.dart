import 'dart:math';
import '../models/exercise.dart';
import '../models/lesson.dart';
import '../models/word.dart';

class ExerciseService {
  static final ExerciseService _instance = ExerciseService._internal();
  factory ExerciseService() => _instance;
  ExerciseService._internal();

  final Random _rng = Random();

  List<dynamic> buildQueue(Lesson lesson) {
    final words = List<Word>.from(lesson.words)..shuffle(_rng);
    final queue = <dynamic>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final others = words.where((w) => w.id != word.id).toList()..shuffle(_rng);
      final distractors = others.take(3).toList();

      switch (i % 4) {
        case 0:
          queue.add(Exercise(
            type: ExerciseType.multipleChoice,
            targetWord: word,
            options: _shuffle([word, ...distractors]),
            promptText: 'What does this mean?',
          ));
          break;
        case 1:
          queue.add(Exercise(
            type: ExerciseType.multipleChoiceTh,
            targetWord: word,
            options: _shuffle([word, ...distractors]),
            promptText: 'How do you write this in Thai?',
          ));
          break;
        case 2:
          queue.add(Exercise(
            type: ExerciseType.listenAndChoose,
            targetWord: word,
            options: _shuffle([word, ...distractors]),
            promptText: 'Select what you hear',
          ));
          break;
        case 3:
          queue.add(Exercise(
            type: ExerciseType.fillInBlank,
            targetWord: word,
            options: _shuffle([word, ...distractors]),
            promptText: 'Fill in the blank',
          ));
          break;
      }

      if (i > 0 && i % 4 == 3 && words.length >= 4) {
        final start = max(0, i - 3);
        final pairWords =
            words.sublist(start, min(start + 4, words.length));
        if (pairWords.length == 4) {
          queue.add(MatchPairExercise(pairs: _shuffle(pairWords)));
        }
      }
    }

    // Final review — 3 random MC questions
    final review = (List<Word>.from(words)..shuffle(_rng)).take(3);
    for (final word in review) {
      final others =
          words.where((w) => w.id != word.id).toList()..shuffle(_rng);
      queue.add(Exercise(
        type: ExerciseType.multipleChoice,
        targetWord: word,
        options: _shuffle([word, ...others.take(3)]),
        promptText: '⭐ Final review',
      ));
    }

    return queue;
  }

  /// Builds an exercise queue from the review word pool.
  /// Only uses multipleChoice, multipleChoiceTh, and matchPairs — no listen.
  List<dynamic> buildReviewQueue(List<Word> words) {
    if (words.isEmpty) return [];
    final shuffled = List<Word>.from(words)..shuffle(_rng);
    final queue = <dynamic>[];

    for (int i = 0; i < shuffled.length; i++) {
      final word = shuffled[i];
      final others = shuffled.where((w) => w.id != word.id).toList()
        ..shuffle(_rng);
      final distractors = others.take(3).toList();
      final options = _shuffle([word, ...distractors]);

      final type = i.isEven
          ? ExerciseType.multipleChoice
          : ExerciseType.multipleChoiceTh;
      queue.add(Exercise(
        type: type,
        targetWord: word,
        options: options,
        promptText: type == ExerciseType.multipleChoice
            ? '📝 What does this mean?'
            : '📝 How do you write this in Thai?',
      ));

      // Insert match pairs every 4 words (requires 4+ words in pool)
      if ((i + 1) % 4 == 0 && shuffled.length >= 4) {
        final start = max(0, i - 3);
        final pairWords =
            shuffled.sublist(start, min(start + 4, shuffled.length));
        if (pairWords.length == 4) {
          queue.add(MatchPairExercise(pairs: _shuffle(pairWords)));
        }
      }
    }

    return queue;
  }

  List<T> _shuffle<T>(List<T> list) {
    final copy = List<T>.from(list);
    copy.shuffle(_rng);
    return copy;
  }
}
