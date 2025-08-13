import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Backend translation service that communicates with our Node.js server
class BackendTranslationService {
  static String get _baseUrl => ApiConfig.baseUrl;
  static Duration get _timeout => ApiConfig.requestTimeout;

  /// Translate text using our backend (DeepL -> Google fallback)
  static Future<String> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    String? provider, // 'deepl' or 'google' to force specific provider
  }) async {
    if (text.trim().isEmpty) {
      return '';
    }

    try {
      final requestBody = {
        'text': text.trim(),
        'target': _convertLanguageCode(targetLanguage),
      };

      // Only add source if it's not auto detection
      if (sourceLanguage.toLowerCase() != 'auto') {
        requestBody['source'] = _convertLanguageCode(sourceLanguage);
      }

      if (provider != null) {
        requestBody['provider'] = provider.toLowerCase();
      }

      if (kDebugMode) {
        print('Backend Translation Request: $requestBody');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/translate'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'VoicelyApp/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(_timeout);

      if (kDebugMode) {
        print('Backend Translation Response: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final translatedText = data['translatedText'] ?? '';
          final usedProvider = data['provider'] ?? 'unknown';
          
          if (kDebugMode) {
            print('Translation successful using $usedProvider: $translatedText');
          }
          
          return translatedText;
        } else {
          throw Exception(data['error'] ?? 'Translation failed');
        }
      } else {
        throw Exception('Backend server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Backend translation error: $e');
      }
      
      // Fallback to a user-friendly error message
      return _getFallbackTranslation(text, sourceLanguage, targetLanguage);
    }
  }

  /// Get Text-to-Speech audio as base64
  static Future<String> textToSpeech({
    required String text,
    required String languageCode,
    String? voiceName,
    double speakingRate = 1.0,
    double pitch = 0.0,
  }) async {
    if (text.trim().isEmpty) {
      return '';
    }

    try {
      final requestBody = {
        'text': text.trim(),
        'languageCode': languageCode,
        'speakingRate': speakingRate,
        'pitch': pitch,
      };

      if (voiceName != null) {
        requestBody['voiceName'] = voiceName;
      }

      if (kDebugMode) {
        print('Backend TTS Request: $requestBody');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/tts'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'VoicelyApp/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(_timeout);

      if (kDebugMode) {
        print('Backend TTS Response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return data['audioBase64'] ?? '';
        } else {
          throw Exception(data['error'] ?? 'TTS failed');
        }
      } else {
        throw Exception('Backend TTS error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Backend TTS error: $e');
      }
      throw Exception('Text-to-speech failed: $e');
    }
  }

  /// Get available TTS voices
  static Future<Map<String, List<Map<String, dynamic>>>> getAvailableVoices() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tts/voices'),
        headers: {
          'User-Agent': 'VoicelyApp/1.0',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final voices = data['voices'] as Map<String, dynamic>? ?? {};
          return voices.map((key, value) => 
            MapEntry(key, List<Map<String, dynamic>>.from(value))
          );
        }
      }
      
      return {};
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get voices: $e');
      }
      return {};
    }
  }

  /// Check if backend server is healthy
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {
          'User-Agent': 'VoicelyApp/1.0',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'OK';
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Health check failed: $e');
      }
      return false;
    }
  }

  /// Convert language code to proper format for our backend
  static String _convertLanguageCode(String languageCode) {
    // Handle auto detection
    if (languageCode.toLowerCase() == 'auto') {
      return 'auto';
    }
    
    // Convert from our app format to backend format
    final Map<String, String> languageMap = {
      'en': 'EN',
      'tr': 'TR', 
      'es': 'ES',
      'fr': 'FR',
      'de': 'DE',
      'it': 'IT',
      'pt': 'PT',
      'ru': 'RU',
      'ja': 'JA',
      'ko': 'KO',
      'zh': 'ZH',
      'ar': 'AR',
      'nl': 'NL',
      'pl': 'PL',
      'sv': 'SV',
      'da': 'DA',
      'fi': 'FI',
      'el': 'EL',
      'cs': 'CS',
      'et': 'ET',
      'hu': 'HU',
      'lv': 'LV',
      'lt': 'LT',
      'sk': 'SK',
      'sl': 'SL',
      'bg': 'BG',
      'ro': 'RO',
      'uk': 'UK',
    };
    
    return languageMap[languageCode.toLowerCase()] ?? languageCode.toUpperCase();
  }

  /// Convert language code to TTS format
  static String convertToTTSLanguageCode(String languageCode) {
    final Map<String, String> ttsLanguageMap = {
      'en': 'en-US',
      'tr': 'tr-TR',
      'es': 'es-ES', 
      'fr': 'fr-FR',
      'de': 'de-DE',
      'it': 'it-IT',
      'pt': 'pt-PT',
      'ru': 'ru-RU',
      'ja': 'ja-JP',
      'ko': 'ko-KR',
      'zh': 'zh-CN',
      'ar': 'ar-XA',
      'nl': 'nl-NL',
      'pl': 'pl-PL',
      'sv': 'sv-SE',
      'da': 'da-DK',
      'fi': 'fi-FI',
      'el': 'el-GR',
      'cs': 'cs-CZ',
      'et': 'et-EE',
      'hu': 'hu-HU',
      'lv': 'lv-LV',
      'lt': 'lt-LT',
      'sk': 'sk-SK',
      'sl': 'sl-SI',
      'bg': 'bg-BG',
      'ro': 'ro-RO',
      'uk': 'uk-UA',
    };
    
    return ttsLanguageMap[languageCode.toLowerCase()] ?? 'en-US';
  }

  /// Fallback translation when backend is not available
  static String _getFallbackTranslation(String text, String sourceLanguage, String targetLanguage) {
    // Simple mock translations for common phrases
    final Map<String, Map<String, String>> mockTranslations = {
      'tr': {
        'hello': 'merhaba',
        'good morning': 'günaydın',
        'good evening': 'iyi akşamlar',
        'how are you': 'nasılsın',
        'thank you': 'teşekkürler',
        'goodbye': 'hoşçakal',
        'yes': 'evet',
        'no': 'hayır',
        'please': 'lütfen',
        'excuse me': 'afedersin',
      },
      'en': {
        'merhaba': 'hello',
        'günaydın': 'good morning',
        'iyi akşamlar': 'good evening',
        'nasılsın': 'how are you',
        'teşekkürler': 'thank you',
        'hoşçakal': 'goodbye',
        'evet': 'yes',
        'hayır': 'no',
        'lütfen': 'please',
        'afedersin': 'excuse me',
      },
    };

    final lowerText = text.toLowerCase().trim();
    final translations = mockTranslations[targetLanguage.toLowerCase()];
    
    if (translations != null) {
      for (final entry in translations.entries) {
        if (lowerText.contains(entry.key.toLowerCase())) {
          return entry.value;
        }
      }
    }
    
    // Return a formatted fallback
    final targetLanguageName = _getLanguageName(targetLanguage);
    return '[$targetLanguageName: $text]';
  }

  /// Get language name for fallback display
  static String _getLanguageName(String languageCode) {
    final Map<String, String> languageNames = {
      'tr': 'Turkish',
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'ar': 'Arabic',
    };
    
    return languageNames[languageCode.toLowerCase()] ?? languageCode.toUpperCase();
  }
}