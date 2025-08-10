class BookCategory {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String colorHex;
  final int wordCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.iconName = 'book',
    this.colorHex = '#3B82F6',
    this.wordCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    return BookCategory(
      id: json['id'] as String,
      name: json['name'] as String, // English name
      description: json['description'] as String? ?? '',
      iconName: json['icon'] as String? ?? 'book',
      colorHex: json['color'] as String? ?? '#3B82F6',
      wordCount: json['word_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': iconName,
      'color': colorHex,
      'word_count': wordCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
