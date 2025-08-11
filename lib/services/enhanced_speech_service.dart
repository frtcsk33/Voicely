import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

/// Enhanced speech service for real-time transcription
/// Supports both local speech-to-text and cloud-based services
class EnhancedSpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  
  // Callbacks
  Function(String)? onTranscriptionUpdate;
  Function(String)? onFinalTranscription;
  Function(String)? onError;
  
  // Current transcription
  String _currentTranscription = '';
  String _finalTranscription = '';
  
  // Auto-stop timer
  Timer? _autoStopTimer;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get currentTranscription => _currentTranscription;
  String get finalTranscription => _finalTranscription;

  /// Initialize the speech service
  Future<bool> initialize() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          if (kDebugMode) {
            print('Speech recognition error: $error');
          }
          onError?.call(error.errorMsg);
          _isListening = false;
        },
        onStatus: (status) {
          if (kDebugMode) {
            print('Speech recognition status: $status');
          }
          
          if (status == 'notListening') {
            _isListening = false;
            _autoStopTimer?.cancel();
          } else if (status == 'listening') {
            _isListening = true;
          }
        },
      );
      
      if (kDebugMode) {
        print('Speech service initialized: $_isInitialized');
      }
      
      return _isInitialized;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize speech service: $e');
      }
      onError?.call('Failed to initialize speech recognition');
      return false;
    }
  }

  /// Start listening for speech in the specified language
  Future<bool> startListening({
    required String languageCode,
    Duration? timeout,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (!_isInitialized) {
      onError?.call('Speech recognition not available');
      return false;
    }
    
    if (_isListening) {
      await stopListening();
    }
    
    try {
      _currentTranscription = '';
      _finalTranscription = '';
      
      // Start listening with continuous recognition
      await _speech.listen(
        onResult: (result) {
          _currentTranscription = result.recognizedWords;
          onTranscriptionUpdate?.call(_currentTranscription);
          
          // If the result is final, trigger final transcription
          if (result.finalResult) {
            _finalTranscription = result.recognizedWords;
            onFinalTranscription?.call(_finalTranscription);
            _isListening = false;
          }
        },
        listenFor: timeout ?? const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: _mapLanguageCode(languageCode),
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
      
      _isListening = true;
      
      // Set auto-stop timer
      if (timeout != null) {
        _autoStopTimer = Timer(timeout, () {
          stopListening();
        });
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting speech recognition: $e');
      }
      onError?.call('Failed to start listening');
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      _autoStopTimer?.cancel();
      
      // If we have current transcription, make it final
      if (_currentTranscription.isNotEmpty && _finalTranscription.isEmpty) {
        _finalTranscription = _currentTranscription;
        onFinalTranscription?.call(_finalTranscription);
      }
    }
  }

  /// Cancel current listening session
  Future<void> cancel() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
      _autoStopTimer?.cancel();
      _currentTranscription = '';
      _finalTranscription = '';
    }
  }

  /// Map language codes to speech recognition locale IDs
  String _mapLanguageCode(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return 'en_US';
      case 'es':
        return 'es_ES';
      case 'fr':
        return 'fr_FR';
      case 'de':
        return 'de_DE';
      case 'it':
        return 'it_IT';
      case 'pt':
        return 'pt_BR';
      case 'ru':
        return 'ru_RU';
      case 'ja':
        return 'ja_JP';
      case 'ko':
        return 'ko_KR';
      case 'zh':
        return 'zh_CN';
      case 'ar':
        return 'ar_SA';
      case 'hi':
        return 'hi_IN';
      case 'tr':
        return 'tr_TR';
      case 'nl':
        return 'nl_NL';
      case 'sv':
        return 'sv_SE';
      case 'no':
        return 'nb_NO';
      case 'da':
        return 'da_DK';
      case 'fi':
        return 'fi_FI';
      case 'pl':
        return 'pl_PL';
      case 'cs':
        return 'cs_CZ';
      case 'hu':
        return 'hu_HU';
      case 'ro':
        return 'ro_RO';
      case 'bg':
        return 'bg_BG';
      case 'hr':
        return 'hr_HR';
      case 'sk':
        return 'sk_SK';
      case 'sl':
        return 'sl_SI';
      case 'et':
        return 'et_EE';
      case 'lv':
        return 'lv_LV';
      case 'lt':
        return 'lt_LT';
      case 'el':
        return 'el_GR';
      case 'he':
        return 'he_IL';
      case 'th':
        return 'th_TH';
      case 'vi':
        return 'vi_VN';
      case 'id':
        return 'id_ID';
      case 'ms':
        return 'ms_MY';
      case 'uk':
        return 'uk_UA';
      default:
        return 'en_US'; // Fallback to English
    }
  }

  /// Get available locales for speech recognition
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (!_isInitialized) {
      return [];
    }
    
    try {
      final locales = await _speech.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available locales: $e');
      }
      return [];
    }
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    try {
      return await _speech.hasPermission;
    } catch (e) {
      return false;
    }
  }

  /// Set callbacks for transcription events
  void setCallbacks({
    Function(String)? onTranscriptionUpdate,
    Function(String)? onFinalTranscription,
    Function(String)? onError,
  }) {
    this.onTranscriptionUpdate = onTranscriptionUpdate;
    this.onFinalTranscription = onFinalTranscription;
    this.onError = onError;
  }

  /// Dispose of the service
  void dispose() {
    _autoStopTimer?.cancel();
    if (_isListening) {
      _speech.stop();
    }
  }
}

/// Enhanced translation service with better error handling
class EnhancedTranslationService {
  static const String _libreTranslateUrl = 'https://libretranslate.com/translate';
  static const String _backupTranslateUrl = 'https://translate.astian.org/translate';
  static const String _thirdTranslateUrl = 'https://translate.terraprint.co/translate';
  
  /// Translate text from source language to target language
  static Future<String> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (text.trim().isEmpty) {
      return '';
    }
    
    // Try primary translation service
    try {
      final result = await _tryTranslation(
        url: _libreTranslateUrl,
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      
      if (result.isNotEmpty) {
        return result;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Primary translation failed: $e');
      }
    }
    
    // Try backup translation service
    try {
      final result = await _tryTranslation(
        url: _backupTranslateUrl,
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      
      if (result.isNotEmpty) {
        return result;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Backup translation failed: $e');
      }
    }

    // Try third translation service
    try {
      final result = await _tryTranslation(
        url: _thirdTranslateUrl,
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      
      if (result.isNotEmpty) {
        return result;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Third translation failed: $e');
      }
    }
    
    // If all services fail, try a simple mock translation for demo
    if (sourceLanguage == 'tr' && targetLanguage == 'en') {
      return _getMockTranslation(text, 'en');
    } else if (sourceLanguage == 'en' && targetLanguage == 'tr') {
      return _getMockTranslation(text, 'tr');
    }
    
    // If both services fail, return original text with error indicator
    return '$text (Translation unavailable)';
  }
  
  static Future<String> _tryTranslation({
    required String url,
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'q': text,
        'source': sourceLanguage,
        'target': targetLanguage,
        'format': 'text',
      }),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['translatedText'] ?? '';
    } else {
      throw Exception('Translation service returned ${response.statusCode}');
    }
  }

  /// Fallback mock translation for demo purposes
  static String _getMockTranslation(String text, String targetLanguage) {
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
    final translations = mockTranslations[targetLanguage];
    
    if (translations != null) {
      for (final entry in translations.entries) {
        if (lowerText.contains(entry.key.toLowerCase())) {
          return entry.value;
        }
      }
    }
    
    // Return a generic translated message if no match found
    return targetLanguage == 'tr' 
      ? '[Türkçe çeviri: $text]'
      : '[English translation: $text]';
  }
}