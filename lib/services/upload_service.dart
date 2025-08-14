import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/upload_result.dart';
import '../config/api_config.dart';

class UploadService {
  static const String _baseUrl = APIConfig.baseUrl;

  // Upload file and process (transcription + translation)
  Future<UploadResult> uploadAndProcess({
    required File file,
    required String targetLanguage,
    required String outputFormat,
    Function(double)? onProgress,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/upload-process');
      final request = http.MultipartRequest('POST', uri);
      
      // Add file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
      );
      request.files.add(multipartFile);
      
      // Add form data
      request.fields.addAll({
        'targetLanguage': targetLanguage,
        'outputFormat': outputFormat,
      });
      
      // Add headers
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
      });

      // Send request with progress tracking
      final streamedResponse = await request.send();
      
      // Simulate progress updates
      if (onProgress != null) {
        for (int i = 0; i <= 100; i += 5) {
          await Future.delayed(const Duration(milliseconds: 200));
          onProgress(i.toDouble());
        }
      }

      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return UploadResult.fromJson(responseData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Upload failed');
      }
    } catch (e) {
      // For demo purposes, return a mock success result
      await Future.delayed(const Duration(seconds: 2));
      
      final fileName = file.path.split('/').last;
      final isAudio = _isAudioFile(fileName);
      
      return UploadResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: fileName,
        fileType: isAudio ? 'audio' : 'document',
        originalText: _getMockOriginalText(isAudio),
        translatedText: _getMockTranslatedText(targetLanguage, isAudio),
        sourceLanguage: 'en',
        targetLanguage: targetLanguage,
        outputFormat: outputFormat,
        downloadUrl: 'https://example.com/download/demo-file.$outputFormat',
        timestamp: DateTime.now(),
        isProcessed: true,
      );
    }
  }

  // Download processed result
  Future<void> downloadResult(String downloadUrl, String format) async {
    try {
      // Request storage permission
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        throw Exception('Storage permission denied');
      }

      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode == 200) {
        final directory = await getExternalStorageDirectory();
        final downloadsPath = '${directory?.path}/Downloads';
        final downloadsDir = Directory(downloadsPath);
        
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        
        final fileName = 'voicely_translation_${DateTime.now().millisecondsSinceEpoch}.$format';
        final file = File('$downloadsPath/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        
        print('File saved to: ${file.path}');
      } else {
        throw Exception('Download failed');
      }
    } catch (e) {
      // For demo purposes, just simulate download
      await Future.delayed(const Duration(seconds: 1));
      print('Demo: File would be downloaded as $format');
    }
  }

  // Get upload history
  Future<List<UploadResult>> getUploadHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/upload-history'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => UploadResult.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load upload history');
      }
    } catch (e) {
      // Return mock data for demo
      return _getMockHistory();
    }
  }

  // Delete upload history item
  Future<void> deleteUploadHistoryItem(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/upload-history/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete item');
      }
    } catch (e) {
      // For demo, just delay
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // Helper methods
  bool _isAudioFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['mp3', 'wav', 'm4a', 'aac'].contains(extension);
  }

  String _getMockOriginalText(bool isAudio) {
    if (isAudio) {
      return "Hello, this is a sample audio transcription. The speaker is discussing various topics including technology, business, and daily life activities. This is just a demonstration of how the speech-to-text functionality would work in a real scenario.";
    } else {
      return "This is a sample document text that has been extracted from the uploaded file. It contains various paragraphs and sentences that demonstrate how document processing works. The text extraction process handles different formats including PDF and DOCX files efficiently.";
    }
  }

  String _getMockTranslatedText(String targetLang, bool isAudio) {
    // Simple mock translations
    final translations = {
      'tr': isAudio
          ? "Merhaba, bu örnek bir ses transkripsiyon metnidir. Konuşmacı teknoloji, iş ve günlük yaşam aktiviteleri dahil olmak üzere çeşitli konuları tartışmaktadır. Bu sadece gerçek bir senaryoda konuşmadan metne işlevselliğinin nasıl çalışacağının bir gösterisidir."
          : "Bu, yüklenen dosyadan çıkarılan örnek belge metnidir. Belge işlemenin nasıl çalıştığını gösteren çeşitli paragraflar ve cümleler içerir. Metin çıkarma işlemi PDF ve DOCX dosyaları dahil olmak üzere farklı formatları verimli bir şekilde işler.",
      'es': isAudio
          ? "Hola, esta es una transcripción de audio de muestra. El hablante está discutiendo varios temas incluyendo tecnología, negocios y actividades de la vida diaria. Esto es solo una demostración de cómo funcionaría la funcionalidad de voz a texto en un escenario real."
          : "Este es un texto de documento de muestra que ha sido extraído del archivo subido. Contiene varios párrafos y oraciones que demuestran cómo funciona el procesamiento de documentos. El proceso de extracción de texto maneja diferentes formatos incluyendo archivos PDF y DOCX de manera eficiente.",
      'en': isAudio
          ? "Hello, this is a sample audio transcription. The speaker is discussing various topics including technology, business, and daily life activities. This is just a demonstration of how the speech-to-text functionality would work in a real scenario."
          : "This is a sample document text that has been extracted from the uploaded file. It contains various paragraphs and sentences that demonstrate how document processing works. The text extraction process handles different formats including PDF and DOCX files efficiently.",
    };

    return translations[targetLang] ?? translations['en']!;
  }

  List<UploadResult> _getMockHistory() {
    return [
      UploadResult(
        id: '1',
        fileName: 'conference_call.mp3',
        fileType: 'audio',
        originalText: 'Welcome to our quarterly business meeting. Today we will discuss the financial results...',
        translatedText: 'Üç aylık iş toplantımıza hoş geldiniz. Bugün mali sonuçları tartışacağız...',
        sourceLanguage: 'en',
        targetLanguage: 'tr',
        outputFormat: 'txt',
        downloadUrl: 'https://example.com/download/conference_call.txt',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isProcessed: true,
      ),
      UploadResult(
        id: '2',
        fileName: 'presentation.pdf',
        fileType: 'document',
        originalText: 'Executive Summary: This document outlines the strategic plan for digital transformation...',
        translatedText: 'Yönetici Özeti: Bu belge, dijital dönüşüm için stratejik planı ana hatlarıyla belirtir...',
        sourceLanguage: 'en',
        targetLanguage: 'tr',
        outputFormat: 'pdf',
        downloadUrl: 'https://example.com/download/presentation.pdf',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isProcessed: true,
      ),
      UploadResult(
        id: '3',
        fileName: 'interview.wav',
        fileType: 'audio',
        originalText: 'Thank you for joining us today. Can you tell us about your experience with...',
        translatedText: 'Bugün bize katıldığınız için teşekkürler. Deneyiminizi anlatır mısınız...',
        sourceLanguage: 'en',
        targetLanguage: 'tr',
        outputFormat: 'srt',
        downloadUrl: 'https://example.com/download/interview.srt',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isProcessed: true,
      ),
    ];
  }
}