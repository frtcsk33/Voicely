class ChatMessage {
  final String id;
  final String originalText;
  final String translatedText;
  final bool isUser;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime timestamp;
  final bool isFromLeftMic; // true if from left mic (blue), false if from right mic (red)

  ChatMessage({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.isUser,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.timestamp,
    required this.isFromLeftMic,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'isUser': isUser,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isFromLeftMic': isFromLeftMic,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      originalText: json['originalText'],
      translatedText: json['translatedText'],
      isUser: json['isUser'],
      sourceLanguage: json['sourceLanguage'],
      targetLanguage: json['targetLanguage'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      isFromLeftMic: json['isFromLeftMic'] ?? true,
    );
  }
}