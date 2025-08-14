class UploadResult {
  final String id;
  final String fileName;
  final String fileType;
  final String? originalText;
  final String? translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final String outputFormat;
  final String? downloadUrl;
  final DateTime timestamp;
  final bool isProcessed;
  final double? processingProgress;
  final String? errorMessage;

  UploadResult({
    required this.id,
    required this.fileName,
    required this.fileType,
    this.originalText,
    this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.outputFormat,
    this.downloadUrl,
    required this.timestamp,
    this.isProcessed = false,
    this.processingProgress,
    this.errorMessage,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      id: json['id'],
      fileName: json['fileName'],
      fileType: json['fileType'],
      originalText: json['originalText'],
      translatedText: json['translatedText'],
      sourceLanguage: json['sourceLanguage'],
      targetLanguage: json['targetLanguage'],
      outputFormat: json['outputFormat'],
      downloadUrl: json['downloadUrl'],
      timestamp: DateTime.parse(json['timestamp']),
      isProcessed: json['isProcessed'] ?? false,
      processingProgress: json['processingProgress']?.toDouble(),
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileType': fileType,
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'outputFormat': outputFormat,
      'downloadUrl': downloadUrl,
      'timestamp': timestamp.toIso8601String(),
      'isProcessed': isProcessed,
      'processingProgress': processingProgress,
      'errorMessage': errorMessage,
    };
  }

  UploadResult copyWith({
    String? id,
    String? fileName,
    String? fileType,
    String? originalText,
    String? translatedText,
    String? sourceLanguage,
    String? targetLanguage,
    String? outputFormat,
    String? downloadUrl,
    DateTime? timestamp,
    bool? isProcessed,
    double? processingProgress,
    String? errorMessage,
  }) {
    return UploadResult(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      outputFormat: outputFormat ?? this.outputFormat,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      timestamp: timestamp ?? this.timestamp,
      isProcessed: isProcessed ?? this.isProcessed,
      processingProgress: processingProgress ?? this.processingProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}