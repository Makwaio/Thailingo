import 'word.dart';

class Lesson {
  final int id;
  final String title;
  final String subtitle;
  final String icon;
  final String colorHex;
  final int xpReward;
  final List<Word> words;

  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorHex,
    required this.xpReward,
    required this.words,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as int,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        icon: json['icon'] as String? ?? '',
        colorHex: json['color'] as String? ?? '#1565C0',
        xpReward: json['xpReward'] as int? ?? 20,
        words: (json['words'] as List<dynamic>)
            .map((w) => Word.fromJson(w as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'icon': icon,
        'color': colorHex,
        'xpReward': xpReward,
        'words': words.map((w) => w.toJson()).toList(),
      };
}
