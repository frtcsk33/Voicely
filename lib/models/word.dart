class Word {
  final String id;
  final String word;
  final String meaning;
  final String pronunciation;
  final String? audioUrl;
  final String categoryId;
  final String languageFrom;
  final String languageTo;
  final bool isFavorite;
  final String? exampleSentence;
  final String? exampleTranslation;
  final DateTime createdAt;
  final DateTime updatedAt;

  Word({
    required this.id,
    required this.word,
    this.meaning = '',
    this.pronunciation = '',
    this.audioUrl,
    required this.categoryId,
    this.languageFrom = 'en',
    this.languageTo = 'tr',
    this.isFavorite = false,
    this.exampleSentence,
    this.exampleTranslation,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      word: json['word'] as String,
      meaning: json['translation'] as String? ?? '',
      pronunciation: json['phonetic'] as String? ?? '',
      audioUrl: json['audio_url'] as String?,
      categoryId: json['category_id'] as String,
      languageFrom: 'en', // Default since your DB doesn't have this column
      languageTo: 'tr', // Default since your DB doesn't have this column  
      isFavorite: false, // Default since your DB doesn't have this column
      exampleSentence: json['example_sentence'] as String?,
      exampleTranslation: null, // Your DB doesn't have this column
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'translation': meaning,
      'phonetic': pronunciation,
      'audio_url': audioUrl,
      'category_id': categoryId,
      'language_from': languageFrom,
      'language_to': languageTo,
      'is_favorite': isFavorite,
      'example_sentence': exampleSentence,
      'example_translation': exampleTranslation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Word copyWith({
    String? id,
    String? word,
    String? meaning,
    String? pronunciation,
    String? audioUrl,
    String? categoryId,
    String? languageFrom,
    String? languageTo,
    bool? isFavorite,
    String? exampleSentence,
    String? exampleTranslation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Word(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      pronunciation: pronunciation ?? this.pronunciation,
      audioUrl: audioUrl ?? this.audioUrl,
      categoryId: categoryId ?? this.categoryId,
      languageFrom: languageFrom ?? this.languageFrom,
      languageTo: languageTo ?? this.languageTo,
      isFavorite: isFavorite ?? this.isFavorite,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
