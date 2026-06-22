class UserProgress {
  int totalXp;
  int streak;
  int longestStreak;
  int maxCombo;
  int totalWordsReviewed;
  String? lastPlayedDate;
  Map<int, LessonProgress> lessonProgress;
  Map<String, String> achievementsUnlocked;

  UserProgress({
    this.totalXp = 0,
    this.streak = 0,
    this.longestStreak = 0,
    this.maxCombo = 0,
    this.totalWordsReviewed = 0,
    this.lastPlayedDate,
    Map<int, LessonProgress>? lessonProgress,
    Map<String, String>? achievementsUnlocked,
  })  : lessonProgress = lessonProgress ?? {},
        achievementsUnlocked = achievementsUnlocked ?? {};

  int get level => (totalXp / 200).floor() + 1;
  int get xpInLevel => totalXp % 200;

  bool isLessonUnlocked(int lessonId) {
    if (lessonId == 1) return true;
    // Lesson 23 (first Stage 2 lesson) requires ALL Stage 1 lessons complete
    if (lessonId == 23) {
      return List.generate(22, (i) => i + 1)
          .every((id) => (lessonProgress[id]?.stars ?? 0) >= 3);
    }
    // Alphabet lessons (101-105) unlock sequentially, no 3-star requirement
    if (lessonId >= 101 && lessonId <= 105) {
      if (lessonId == 101) return true;
      return lessonProgress[lessonId - 1]?.completed ?? false;
    }
    return (lessonProgress[lessonId - 1]?.stars ?? 0) >= 3;
  }

  bool isLessonCompleted(int lessonId) =>
      lessonProgress[lessonId]?.completed ?? false;

  int lessonStars(int lessonId) => lessonProgress[lessonId]?.stars ?? 0;

  bool get allStage1Complete =>
      List.generate(22, (i) => i + 1)
          .every((id) => (lessonProgress[id]?.stars ?? 0) >= 3);

  bool get allStage2Complete =>
      List.generate(15, (i) => i + 23)
          .every((id) => (lessonProgress[id]?.stars ?? 0) >= 3);

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        totalXp: json['totalXp'] as int? ?? 0,
        streak: json['streak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        maxCombo: json['maxCombo'] as int? ?? 0,
        totalWordsReviewed: json['totalWordsReviewed'] as int? ?? 0,
        lastPlayedDate: json['lastPlayedDate'] as String?,
        lessonProgress:
            (json['lessonProgress'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
            int.parse(k),
            LessonProgress.fromJson(v as Map<String, dynamic>),
          ),
        ),
        achievementsUnlocked:
            (json['achievementsUnlocked'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, v as String),
        ),
      );

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'streak': streak,
        'longestStreak': longestStreak,
        'maxCombo': maxCombo,
        'totalWordsReviewed': totalWordsReviewed,
        'lastPlayedDate': lastPlayedDate,
        'lessonProgress':
            lessonProgress.map((k, v) => MapEntry(k.toString(), v.toJson())),
        'achievementsUnlocked': achievementsUnlocked,
      };
}

class LessonProgress {
  bool completed;
  int stars;
  int bestScore;
  int bestAccuracy;
  int timesPlayed;
  int bestTimeSeconds;
  String? lastPlayedDate;

  LessonProgress({
    this.completed = false,
    this.stars = 0,
    this.bestScore = 0,
    this.bestAccuracy = 0,
    this.timesPlayed = 0,
    this.bestTimeSeconds = 0,
    this.lastPlayedDate,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) => LessonProgress(
        completed: json['completed'] as bool? ?? false,
        stars: json['stars'] as int? ?? 0,
        bestScore: json['bestScore'] as int? ?? 0,
        bestAccuracy: json['bestAccuracy'] as int? ?? 0,
        timesPlayed: json['timesPlayed'] as int? ?? 0,
        bestTimeSeconds: json['bestTimeSeconds'] as int? ?? 0,
        lastPlayedDate: json['lastPlayedDate'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'completed': completed,
        'stars': stars,
        'bestScore': bestScore,
        'bestAccuracy': bestAccuracy,
        'timesPlayed': timesPlayed,
        'bestTimeSeconds': bestTimeSeconds,
        'lastPlayedDate': lastPlayedDate,
      };
}

class AchievementDef {
  final String id;
  final String emoji;
  final String title;
  final String description;

  const AchievementDef(this.id, this.emoji, this.title, this.description);
}

const kAchievements = [
  AchievementDef('first_step', '🌟', 'First Step', 'Complete your first lesson'),
  AchievementDef('on_fire', '🔥', 'On Fire', 'Reach a 3 day streak'),
  AchievementDef('perfectionist', '💯', 'Perfectionist', 'Get 100% on any lesson'),
  AchievementDef('speed_demon', '⚡', 'Speed Demon', 'Finish a lesson in under 60 seconds'),
  AchievementDef('stage_master', '🏆', 'Stage Master', 'Complete a whole stage with 3 stars'),
  AchievementDef('word_collector', '📚', 'Word Collector', 'Learn 50+ words'),
  AchievementDef('sharp_shooter', '🎯', 'Sharp Shooter', 'Hit a 10× combo in a lesson'),
  AchievementDef('diamond', '💎', 'Diamond', 'Reach level 10 (2 000 XP)'),
  AchievementDef('stage1_master', '🇹🇭', 'Thai Foundation', 'Complete all 22 Stage 1 lessons with 3 stars'),
  AchievementDef('stage2_master', '🏙️', 'Survival Thai', 'Complete all 15 Stage 2 lessons with 3 stars'),
];

const kStageLessonIds = [
  [1, 2, 3, 4],
  [5, 6, 7, 8],
  [9, 10, 11, 12],
  [13, 14, 15, 16, 17, 18, 19, 20, 21, 22],
  [23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37],
];

bool isAchievementUnlocked(
  String id,
  UserProgress p,
  int totalWordsLearned,
) {
  switch (id) {
    case 'first_step':
      return p.lessonProgress.values.any((lp) => lp.completed);
    case 'on_fire':
      return p.longestStreak >= 3 || p.streak >= 3;
    case 'perfectionist':
      return p.lessonProgress.values.any((lp) => lp.bestAccuracy == 100);
    case 'speed_demon':
      return p.lessonProgress.values
          .any((lp) => lp.bestTimeSeconds > 0 && lp.bestTimeSeconds < 60);
    case 'stage_master':
      return kStageLessonIds
          .any((ids) => ids.every((id) => (p.lessonProgress[id]?.stars ?? 0) >= 3));
    case 'word_collector':
      return totalWordsLearned >= 50;
    case 'sharp_shooter':
      return p.maxCombo >= 10;
    case 'diamond':
      return p.totalXp >= 2000;
    case 'stage1_master':
      return p.allStage1Complete;
    case 'stage2_master':
      return p.allStage2Complete;
    default:
      return false;
  }
}
