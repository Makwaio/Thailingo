import 'dart:math';
import '../models/exercise.dart';
import '../models/lesson.dart';
import '../models/word.dart';
import 'settings_service.dart';

class ExerciseService {
  static final ExerciseService _instance = ExerciseService._internal();
  factory ExerciseService() => _instance;
  ExerciseService._internal();

  final Random _rng = Random();

  static const _conversations = [
    ConversationExercise(
      scenarioTitle: 'At a Street Food Stall',
      lines: [
        ConversationLine(speaker: '🧑‍🍳 Vendor', thai: 'สวัสดีครับ อยากกินอะไร', phonetic: 'sa-wat-dee khrap, yak-gin-a-rai', english: 'Hello! What would you like?', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '🙋 Customer', thai: 'ขอผัดไทยหนึ่งจานครับ', phonetic: 'khor-phat-thai-neung-jaan-khrap', english: 'One Pad Thai please', audioFile: 'food_01.mp3'),
        ConversationLine(speaker: '🧑‍🍳 Vendor', thai: 'เอาเผ็ดไหมครับ', phonetic: 'ao-phet-mai-khrap', english: 'Would you like it spicy?', audioFile: 'food_02.mp3'),
        ConversationLine(speaker: '🙋 Customer', thai: 'ไม่เผ็ดนะครับ ขอบคุณ', phonetic: 'mai-phet-na-khrap, khob-khun', english: 'Not spicy please, thank you', audioFile: 'greet_02.mp3'),
      ],
      questions: [
        ConversationQuestion(question: 'What did the customer order?', options: ['Fried rice', 'Pad Thai', 'Tom Yum soup', 'Som Tam'], correctIndex: 1),
        ConversationQuestion(question: 'Did the customer want it spicy?', options: ['Yes, very spicy', 'Yes, a little', 'No, not spicy', 'No preference'], correctIndex: 2),
      ],
    ),
    ConversationExercise(
      scenarioTitle: 'In a Taxi',
      lines: [
        ConversationLine(speaker: '🚖 Driver', thai: 'ไปไหนครับ', phonetic: 'bpai-nai-khrap', english: 'Where are you going?', audioFile: 'dir_01.mp3'),
        ConversationLine(speaker: '🙋 Passenger', thai: 'ไปสยามครับ', phonetic: 'bpai-siam-khrap', english: 'To Siam please', audioFile: 'dir_02.mp3'),
        ConversationLine(speaker: '🚖 Driver', thai: 'โอเคครับ ประมาณ 15 นาที', phonetic: 'oh-khay-khrap, bpra-maan-sip-ha-naa-tee', english: 'OK about 15 minutes', audioFile: 'dir_03.mp3'),
        ConversationLine(speaker: '🙋 Passenger', thai: 'เท่าไหร่ครับ', phonetic: 'thao-rai-khrap', english: 'How much?', audioFile: 'shop_01.mp3'),
        ConversationLine(speaker: '🚖 Driver', thai: '80 บาทครับ', phonetic: 'paet-sip-baat-khrap', english: '80 baht', audioFile: 'num_01.mp3'),
      ],
      questions: [
        ConversationQuestion(question: 'Where is the passenger going?', options: ['Siam', 'Sukhumvit', 'The airport', 'The hospital'], correctIndex: 0),
        ConversationQuestion(question: 'How much does the ride cost?', options: ['60 baht', '70 baht', '80 baht', '100 baht'], correctIndex: 2),
      ],
    ),
    ConversationExercise(
      scenarioTitle: 'Meeting Someone New',
      lines: [
        ConversationLine(speaker: '👤 Person A', thai: 'สวัสดีครับ คุณชื่ออะไร', phonetic: 'sa-wat-dee-khrap, khun-chue-a-rai', english: 'Hello, what\'s your name?', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '👤 Person B', thai: 'ผมชื่อ Tom ครับ แล้วคุณล่ะ', phonetic: 'pom-chue-Tom-khrap, laeo-khun-la', english: 'My name is Tom, and you?', audioFile: 'greet_09.mp3'),
        ConversationLine(speaker: '👤 Person A', thai: 'ผมชื่อ Max ครับ ยินดีที่รู้จัก', phonetic: 'pom-chue-Max-khrap, yin-dee-tee-ruu-jak', english: 'My name is Max, nice to meet you', audioFile: 'greet_09.mp3'),
        ConversationLine(speaker: '👤 Person B', thai: 'ยินดีที่รู้จักเหมือนกันครับ', phonetic: 'yin-dee-tee-ruu-jak-muean-gan-khrap', english: 'Nice to meet you too', audioFile: 'greet_09.mp3'),
      ],
      questions: [
        ConversationQuestion(question: 'What is Person B\'s name?', options: ['Max', 'Tom', 'Bob', 'John'], correctIndex: 1),
        ConversationQuestion(question: 'What does ยินดีที่รู้จัก mean?', options: ['Goodbye', 'Thank you', 'Nice to meet you', 'How are you?'], correctIndex: 2),
      ],
    ),
  ];

  static const _sentences = [
    SentenceBuilderExercise(
      englishSentence: 'Hello, how are you?',
      thaiChips: ['สวัสดี', 'สบายดี', 'ไหม'],
      audioFile: 'greet_09.mp3',
    ),
    SentenceBuilderExercise(
      englishSentence: 'How much is this?',
      thaiChips: ['นี่', 'ราคา', 'เท่าไหร่'],
      audioFile: 'shop_01.mp3',
    ),
    SentenceBuilderExercise(
      englishSentence: 'Where is the bathroom?',
      thaiChips: ['ห้องน้ำ', 'อยู่', 'ที่ไหน'],
      audioFile: 'greet_09.mp3',
    ),
    SentenceBuilderExercise(
      englishSentence: 'I want fried rice',
      thaiChips: ['ผม', 'อยาก', 'กิน', 'ข้าวผัด'],
      audioFile: 'food_01.mp3',
    ),
    SentenceBuilderExercise(
      englishSentence: 'The weather is very hot',
      thaiChips: ['อากาศ', 'ร้อน', 'มาก'],
      audioFile: 'greet_09.mp3',
    ),
  ];

  List<dynamic> buildQueue(Lesson lesson) {
    final settings = SettingsService();
    final words = List<Word>.from(lesson.words)..shuffle(_rng);
    final queue = <dynamic>[];

    // Build enabled exercise type cycle
    final types = <ExerciseType>[
      ExerciseType.multipleChoice,
      ExerciseType.multipleChoiceTh,
    ];
    if (settings.gtListen) types.add(ExerciseType.listenAndChoose);
    if (settings.gtSpeedTap) types.add(ExerciseType.speedTap);

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final others = words.where((w) => w.id != word.id).toList()..shuffle(_rng);
      final distractors = others.take(3).toList();
      final type = types[i % types.length];

      switch (type) {
        case ExerciseType.speedTap:
          queue.add(Exercise(
            type: ExerciseType.speedTap,
            targetWord: word,
            options: _shuffle([word, ...distractors]),
            promptText: 'Tap the correct answer!',
          ));
        case ExerciseType.listenAndChoose:
          queue.add(Exercise(
            type: ExerciseType.listenAndChoose,
            targetWord: word,
            options: _shuffle([word, ...distractors]),
            promptText: 'Select what you hear',
          ));
        case ExerciseType.multipleChoiceTh:
          queue.add(Exercise(
            type: ExerciseType.multipleChoiceTh,
            targetWord: word,
            options: _shuffle([word, ...distractors]),
            promptText: 'How do you write this in Thai?',
          ));
        default:
          queue.add(Exercise(
            type: ExerciseType.multipleChoice,
            targetWord: word,
            options: _shuffle([word, ...distractors]),
            promptText: 'What does this mean?',
          ));
      }

      // Insert match pairs every 4 words
      if (i > 0 && i % 4 == 3 && words.length >= 4 && settings.gtMatchPairs) {
        final start = max(0, i - 3);
        final pairWords =
            words.sublist(start, min(start + 4, words.length));
        if (pairWords.length == 4) {
          queue.add(MatchPairExercise(pairs: _shuffle(pairWords)));
        }
      }

      // Insert sentence builder every 6 words
      if (i > 0 && i % 6 == 5 && settings.gtSentenceBuilder) {
        queue.add(_sentences[_rng.nextInt(_sentences.length)]);
      }

      // Insert conversation every 8 words
      if (i > 0 && i % 8 == 7 && settings.gtConversation) {
        queue.add(_conversations[_rng.nextInt(_conversations.length)]);
      }

      // Insert typing every 5 words
      if (i > 0 && i % 5 == 4 && settings.gtTyping) {
        queue.add(Exercise(
          type: ExerciseType.typing,
          targetWord: word,
          options: [],
          promptText: 'Type the phonetic spelling',
        ));
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
