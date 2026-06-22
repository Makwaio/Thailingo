class Word {
  final String id;
  final String thai;
  final String phonetic;
  final String english;
  final String image;
  final String audio;
  final String example;

  const Word({
    required this.id,
    required this.thai,
    required this.phonetic,
    required this.english,
    required this.image,
    required this.audio,
    required this.example,
  });

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        id: json['id'] as String,
        thai: json['thai'] as String,
        phonetic: json['phonetic'] as String,
        english: json['english'] as String,
        image: json['image'] as String? ?? '',
        audio: json['audio'] as String? ?? '',
        example: json['example'] as String? ?? '',
      );
}
