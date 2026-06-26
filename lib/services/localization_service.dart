import 'settings_service.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const _labels = <String, Map<String, String>>{
    'continue':       {'en': 'Continue',         'th': 'ต่อไป'},
    'correct':        {'en': 'Correct!',          'th': 'ถูกต้อง!'},
    'wrong':          {'en': 'Wrong!',            'th': 'ผิด!'},
    'lesson_complete':{'en': 'Lesson Complete!',  'th': 'เรียนจบแล้ว!'},
    'review':         {'en': 'Review',            'th': 'ทบทวน'},
    'settings':       {'en': 'Settings',          'th': 'การตั้งค่า'},
    'home':           {'en': 'Home',              'th': 'หน้าหลัก'},
    'streak':         {'en': 'Streak',            'th': 'ความต่อเนื่อง'},
    'level':          {'en': 'Level',             'th': 'ระดับ'},
    'score':          {'en': 'Score',             'th': 'คะแนน'},
    'next':           {'en': 'Next',              'th': 'ถัดไป'},
    'skip':           {'en': 'Skip',              'th': 'ข้าม'},
    'hint':           {'en': 'Hint',              'th': 'คำใบ้'},
    'choose_answer':  {'en': 'CHOOSE THE ANSWER', 'th': 'เลือกคำตอบ'},
    'tap_thai':       {'en': 'TAP THE THAI WORD', 'th': 'แตะคำภาษาไทย'},
    'tap_english':    {'en': 'TAP THE ENGLISH WORD', 'th': 'แตะคำภาษาอังกฤษ'},
    'what_english':   {'en': 'What does this mean in English?', 'th': 'นี่แปลว่าอะไรในภาษาอังกฤษ?'},
    'what_thai':      {'en': 'How do you say this in Thai?',    'th': 'พูดเป็นภาษาไทยว่าอย่างไร?'},
    'type_answer':    {'en': 'Type the answer',  'th': 'พิมพ์คำตอบ'},
    'listen_choose':  {'en': 'Listen and choose','th': 'ฟังแล้วเลือก'},
  };

  bool get _isThai =>
      SettingsService().learningDirection == LearningDirection.thaiToEnglish;

  String get(String key) {
    final map = _labels[key];
    if (map == null) return key;
    return _isThai ? (map['th'] ?? key) : (map['en'] ?? key);
  }

  String directionBadge() {
    switch (SettingsService().learningDirection) {
      case LearningDirection.englishToThai:
        return '🇬🇧→🇹🇭';
      case LearningDirection.thaiToEnglish:
        return '🇹🇭→🇬🇧';
      case LearningDirection.mixed:
        return '🔀';
    }
  }
}
