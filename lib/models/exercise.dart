import 'word.dart';

enum ExerciseType {
  multipleChoice,
  multipleChoiceTh,
  matchPairs,
  listenAndChoose,
  fillInBlank,
}

class Exercise {
  final ExerciseType type;
  final Word targetWord;
  final List<Word> options;
  final String? promptText;

  const Exercise({
    required this.type,
    required this.targetWord,
    required this.options,
    this.promptText,
  });
}

class MatchPairExercise {
  final List<Word> pairs;
  const MatchPairExercise({required this.pairs});
}
