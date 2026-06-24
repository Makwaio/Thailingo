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
    ConversationExercise(
      scenarioTitle: '🏪 Going to 7-Eleven',
      lines: [
        ConversationLine(speaker: '🙋 You', thai: 'ผมจะไป 7-11', phonetic: 'pom-ja-bai-seven', english: "I'm going to 7-Eleven", audioFile: 'out_04.mp3'),
        ConversationLine(speaker: '👤 Partner', thai: 'คุณจะเอาอะไรไหม', phonetic: 'khun-ja-ao-arai-mai', english: 'Do you need anything?', audioFile: 'out_05.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'เอาไอศครีมด้วยได้ไหม', phonetic: 'ao-ai-sa-kreem-duay-dai-mai', english: 'Can you get ice cream too?', audioFile: 'out_06.mp3'),
        ConversationLine(speaker: '👤 Partner', thai: 'ได้ครับ แล้วอะไรอีก', phonetic: 'dai-khrap-laeo-arai-eek', english: 'Sure, anything else?', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'แค่นั้นพอครับ ขอบคุณ', phonetic: 'khae-nan-por-khrap-khob-khun', english: "That's all, thank you", audioFile: 'greet_02.mp3'),
      ],
      questions: [
        ConversationQuestion(question: 'What were you asked to bring back?', options: ['Water', 'Snacks', 'Ice cream', 'Coffee'], correctIndex: 2),
        ConversationQuestion(question: 'Did you want anything else besides ice cream?', options: ['Yes, coffee', 'Yes, snacks', 'Yes, drinks', 'No, just ice cream'], correctIndex: 3),
      ],
    ),
    ConversationExercise(
      scenarioTitle: '🍗 Ordering Kao Man Gai',
      lines: [
        ConversationLine(speaker: '🧑‍🍳 Vendor', thai: 'สวัสดีครับ จะกินอะไร', phonetic: 'sa-wat-dee-khrap, ja-gin-a-rai', english: 'Hello! What would you like?', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'ขอข้าวมันไก่หนึ่งจานครับ', phonetic: 'khor-khao-man-gai-neung-jaan-khrap', english: 'One chicken rice please', audioFile: 'str_03.mp3'),
        ConversationLine(speaker: '🧑‍🍳 Vendor', thai: 'เอาซอสพิเศษไหมครับ', phonetic: 'ao-sot-pi-set-mai-khrap', english: 'Would you like special sauce?', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'เอาครับ ขอบคุณ', phonetic: 'ao-khrap-khob-khun', english: 'Yes please, thank you', audioFile: 'greet_02.mp3'),
        ConversationLine(speaker: '🧑‍🍳 Vendor', thai: 'รอแป๊บนึงนะครับ', phonetic: 'ror-paep-neung-na-khrap', english: 'Wait just a moment', audioFile: 'greet_01.mp3'),
      ],
      questions: [
        ConversationQuestion(question: 'What dish did you order?', options: ['Pad Thai', 'Som Tam', 'Chicken rice', 'Fried rice'], correctIndex: 2),
        ConversationQuestion(question: 'Did you want special sauce?', options: ['No', 'Yes', 'Maybe', 'No sauce at all'], correctIndex: 1),
      ],
    ),
    ConversationExercise(
      scenarioTitle: '🎬 Planning Movie Night',
      lines: [
        ConversationLine(speaker: '🙋 You', thai: 'คืนนี้อยากดูหนังมั้ย', phonetic: 'kheun-nee-yak-duu-nang-mai', english: 'Want to watch a movie tonight?', audioFile: 'out_02.mp3'),
        ConversationLine(speaker: '👤 Partner', thai: 'อยากครับ ดูอะไรดี', phonetic: 'yak-khrap-duu-a-rai-dee', english: 'Yes! What should we watch?', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'แล้วแต่คุณเลย', phonetic: 'laeo-dtae-khun-loei', english: 'Up to you', audioFile: 'greet_02.mp3'),
        ConversationLine(speaker: '👤 Partner', thai: 'โอเค งั้นฉันเลือกเองนะ', phonetic: 'oh-kay-ngan-chan-leuak-eng-na', english: "OK I'll choose then", audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'ใช่ครับ มาดูหนังกันเถอะ', phonetic: 'chai-khrap-maa-duu-nang-gan-ther', english: "Yes let's watch a movie", audioFile: 'out_03.mp3'),
      ],
      questions: [
        ConversationQuestion(question: 'Who decided what movie to watch?', options: ['You chose', 'The partner chose', 'You chose together', 'Nobody decided'], correctIndex: 1),
        ConversationQuestion(question: 'What does แล้วแต่คุณเลย mean?', options: ['I want action', 'Up to you', "Let's go out", 'I choose'], correctIndex: 1),
      ],
    ),
    ConversationExercise(
      scenarioTitle: '📱 Daily Check-in',
      lines: [
        ConversationLine(speaker: '👤 Partner', thai: 'วันนี้ที่ทำงานเป็นยังไงบ้าง', phonetic: 'wan-nee-tee-tam-ngan-pen-yang-ngai-bang', english: 'How was work today?', audioFile: 'dly_05.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'เหนื่อยมากครับ แต่โอเค', phonetic: 'nuay-mak-khrap-dtae-oh-kay', english: 'Very tired but OK', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '👤 Partner', thai: 'คุณจะกลับบ้านกี่โมง', phonetic: 'khun-ja-glap-baan-gee-mong', english: 'What time will you be home?', audioFile: 'dly_11.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'ประมาณสามทุ่มครับ', phonetic: 'bpra-maan-saam-thoom-khrap', english: 'Around 9pm', audioFile: 'dly_12.mp3'),
        ConversationLine(speaker: '👤 Partner', thai: 'โอเค ฉันรอนะ', phonetic: 'oh-kay-chan-ror-na', english: "OK I'll wait for you", audioFile: 'greet_01.mp3'),
      ],
      questions: [
        ConversationQuestion(question: 'How did you feel about work?', options: ['Great', 'Bored', 'Tired but OK', 'Really happy'], correctIndex: 2),
        ConversationQuestion(question: 'What time will you be home?', options: ['8pm', '9pm', '10pm', '11pm'], correctIndex: 1),
      ],
    ),
    ConversationExercise(
      scenarioTitle: '🚗 Getting a Pickup',
      lines: [
        ConversationLine(speaker: '🙋 You', thai: 'ฉันกำลังไปแล้ว', phonetic: 'chan-gam-lang-bai-laeo', english: "I'm on my way", audioFile: 'dly_08.mp3'),
        ConversationLine(speaker: '👤 Friend', thai: 'คุณอยู่ที่ไหน', phonetic: 'khun-yuu-tee-nai', english: 'Where are you?', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'ผมอยู่แถวสยามครับ', phonetic: 'pom-yuu-thaeo-siam-khrap', english: "I'm near Siam", audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '👤 Friend', thai: 'คุณต้องการให้ฉันไปรับไหม', phonetic: 'khun-dtong-gaan-hai-chan-bai-rap-mai', english: 'Do you need me to pick you up?', audioFile: 'dly_09.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'ได้เลยครับ ขอบคุณมาก', phonetic: 'dai-loei-khrap-khob-khun-mak', english: 'Yes please, thank you so much', audioFile: 'greet_02.mp3'),
      ],
      questions: [
        ConversationQuestion(question: 'Where are you waiting?', options: ['Near Sukhumvit', 'Near Siam', 'Near On Nut', 'Near Asok'], correctIndex: 1),
        ConversationQuestion(question: 'Did you accept the ride offer?', options: ['No', 'Maybe later', 'Yes', 'Not needed'], correctIndex: 2),
      ],
    ),
    ConversationExercise(
      scenarioTitle: '🛒 Bargaining at Chatuchak',
      lines: [
        ConversationLine(speaker: '🧑‍🍳 Vendor', thai: 'อันนี้สองร้อยบาทครับ', phonetic: 'an-nee-song-roi-baat-khrap', english: 'This one is 200 baht', audioFile: 'str_04.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'แพงเกินไปครับ ลดได้ไหม', phonetic: 'paeng-gern-bpai-khrap-lot-dai-mai', english: 'Too expensive, can you lower it?', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '🧑‍🍳 Vendor', thai: 'ลดให้ร้อยห้าสิบได้ครับ', phonetic: 'lot-hai-roi-haa-sib-dai-khrap', english: 'I can do 150 baht', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'ร้อยสองสิบได้ไหมครับ', phonetic: 'roi-song-sib-dai-mai-khrap', english: 'How about 120 baht?', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '🧑‍🍳 Vendor', thai: 'โอเคครับ ตกลง', phonetic: 'oh-kay-khrap-dtok-long', english: 'OK deal', audioFile: 'greet_01.mp3'),
      ],
      questions: [
        ConversationQuestion(question: 'What was the original price?', options: ['100 baht', '150 baht', '200 baht', '250 baht'], correctIndex: 2),
        ConversationQuestion(question: 'What was the final agreed price?', options: ['200 baht', '150 baht', '130 baht', '120 baht'], correctIndex: 3),
      ],
    ),
    ConversationExercise(
      scenarioTitle: '🥗 Ordering Som Tam',
      lines: [
        ConversationLine(speaker: '🧑‍🍳 Vendor', thai: 'สวัสดีค่ะ จะสั่งอะไรคะ', phonetic: 'sa-wat-dee-kha-ja-sang-a-rai-kha', english: 'Hello! What would you like to order?', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'ขอส้มตำหนึ่งจานได้ไหมครับ', phonetic: 'khor-som-tam-neung-jaan-dai-mai-khrap', english: 'Can I have one papaya salad please?', audioFile: 'str_02.mp3'),
        ConversationLine(speaker: '🧑‍🍳 Vendor', thai: 'เผ็ดแค่ไหนคะ', phonetic: 'phet-khae-nai-kha', english: 'How spicy?', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '🙋 You', thai: 'ไม่เผ็ดนะครับ', phonetic: 'mai-phet-na-khrap', english: 'Not spicy please', audioFile: 'greet_01.mp3'),
        ConversationLine(speaker: '🧑‍🍳 Vendor', thai: 'โอเคค่ะ รอแป๊บนึงนะคะ', phonetic: 'oh-kay-kha-ror-paep-neung-na-kha', english: 'OK wait just a moment', audioFile: 'greet_01.mp3'),
      ],
      questions: [
        ConversationQuestion(question: 'What did you order?', options: ['Pad Thai', 'Papaya salad', 'Chicken rice', 'Fried rice'], correctIndex: 1),
        ConversationQuestion(question: 'How spicy did you order it?', options: ['Very spicy', 'Medium spicy', 'A little spicy', 'Not spicy'], correctIndex: 3),
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
    final words = lesson.words;
    final isStage1 = lesson.stage == 1;
    const target = 20;

    // Ordered type cycle — MC always first, then enabled extras
    final typeCycle = <ExerciseType>[
      ExerciseType.multipleChoice,
      ExerciseType.multipleChoiceTh,
    ];
    if (settings.gtListen) typeCycle.add(ExerciseType.listenAndChoose);
    if (settings.gtSpeedTap) typeCycle.add(ExerciseType.speedTap);
    if (settings.gtTyping) typeCycle.add(ExerciseType.typing);

    final pool = <dynamic>[];
    int round = 0;

    while (pool.length < target) {
      final type = typeCycle[round % typeCycle.length];
      final shuffledWords = List<Word>.from(words)..shuffle(_rng);

      for (final word in shuffledWords) {
        if (pool.length >= target * 3) break;
        if (type == ExerciseType.typing) {
          pool.add(Exercise(
            type: ExerciseType.typing,
            targetWord: word,
            options: [],
            promptText: 'Type the phonetic spelling',
          ));
        } else {
          final dist = _distractors(word, words);
          pool.add(Exercise(
            type: type,
            targetWord: word,
            options: _shuffle([word, ...dist]),
            promptText: switch (type) {
              ExerciseType.multipleChoiceTh => 'How do you write this in Thai?',
              ExerciseType.listenAndChoose => 'Select what you hear',
              ExerciseType.speedTap => 'Tap the correct answer!',
              _ => 'What does this mean?',
            },
          ));
        }
      }

      // Pairs block after every 2nd word-round
      if (settings.gtMatchPairs && words.length >= 3 && round % 2 == 1) {
        final pairWords = (List<Word>.from(words)..shuffle(_rng))
            .take(min(4, words.length))
            .toList();
        pool.add(MatchPairExercise(pairs: pairWords));
      }

      // Sentence builder after every 3rd word-round
      if (settings.gtSentenceBuilder && round % 3 == 2) {
        pool.add(_sentences[_rng.nextInt(_sentences.length)]);
      }

      // Conversation after every 4th word-round (Stage 2+ only)
      if (!isStage1 && settings.gtConversation && round % 4 == 3) {
        pool.add(_conversations[_rng.nextInt(_conversations.length)]);
      }

      round++;
      if (round > 20) break;
    }

    pool.shuffle(_rng);
    return pool.take(target).toList();
  }

  List<Word> _distractors(Word target, List<Word> pool) {
    final others = List<Word>.from(pool.where((w) => w.id != target.id))
      ..shuffle(_rng);
    if (others.isEmpty) return [target, target, target];
    final result = <Word>[];
    int i = 0;
    while (result.length < 3) {
      result.add(others[i % others.length]);
      i++;
    }
    return result;
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
