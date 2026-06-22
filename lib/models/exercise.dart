import 'word.dart';

enum ExerciseType {
  multipleChoice,
  multipleChoiceTh,
  matchPairs,
  listenAndChoose,
  fillInBlank,
  speedTap,
  sentenceBuilder,
  conversation,
  typing,
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

class SentenceBuilderExercise {
  final String englishSentence;
  final List<String> thaiChips;
  final String audioFile;

  const SentenceBuilderExercise({
    required this.englishSentence,
    required this.thaiChips,
    required this.audioFile,
  });
}

class ConversationExercise {
  final String scenarioTitle;
  final List<ConversationLine> lines;
  final List<ConversationQuestion> questions;

  const ConversationExercise({
    required this.scenarioTitle,
    required this.lines,
    required this.questions,
  });
}

class ConversationLine {
  final String speaker;
  final String thai;
  final String phonetic;
  final String english;
  final String audioFile;

  const ConversationLine({
    required this.speaker,
    required this.thai,
    required this.phonetic,
    required this.english,
    required this.audioFile,
  });
}

class ConversationQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const ConversationQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}
