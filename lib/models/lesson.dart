import 'word.dart';

class Lesson {
  final int id;
  final String title;
  final String thaiTitle;
  final String subtitle;
  final String icon;
  final String colorHex;
  final int xpReward;
  final List<Word> words;

  const Lesson({
    required this.id,
    required this.title,
    this.thaiTitle = '',
    required this.subtitle,
    required this.icon,
    required this.colorHex,
    required this.xpReward,
    required this.words,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as int,
        title: json['title'] as String,
        thaiTitle: json['thaiTitle'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        icon: json['icon'] as String? ?? '',
        colorHex: json['color'] as String? ?? '#1565C0',
        xpReward: json['xpReward'] as int? ?? 20,
        words: (json['words'] as List<dynamic>)
            .map((w) => Word.fromJson(w as Map<String, dynamic>))
            .toList(),
      );

  int get stage {
    const s1 = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,29,30,31,32,33};
    const s2 = {23,24,25,26,34,35,36,37,38,39,40,41,42,43,44,45,52,53,54,55,56,57,58,59,60,64};
    const s3 = {46,47,48,49,50,51,61,62,63,65,66};
    if (s1.contains(id)) return 1;
    if (s2.contains(id)) return 2;
    if (s3.contains(id)) return 3;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thaiTitle': thaiTitle,
        'subtitle': subtitle,
        'icon': icon,
        'color': colorHex,
        'xpReward': xpReward,
        'words': words.map((w) => w.toJson()).toList(),
      };
}
