import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/enhanced_speech_service.dart';

class RealTimeConversationProvider extends ChangeNotifier {
  // Services
  final EnhancedSpeechService _speechService = EnhancedSpeechService();
  final FlutterTts _tts = FlutterTts();
  
  // Languages
  String _language1 = 'tr';
  String _language1Name = 'Türkçe';
  String _language2 = 'en';
  String _language2Name = 'English';
  
  // User 1 State (Top user)
  bool _isListeningUser1 = false;
  String _user1OriginalText = '';
  bool _isTranslatingUser1 = false;
  bool _isSpeakingUser1Translation = false;
  
  // User 2 State (Bottom user)
  bool _isListeningUser2 = false;
  String _user2OriginalText = '';
  bool _isTranslatingUser2 = false;
  bool _isSpeakingUser2Translation = false;
  
  // Settings
  bool _autoPlayEnabled = true;
  bool _autoStopEnabled = true;
  bool _fastModeEnabled = false;
  final bool _isConnected = true;
  bool _isInitialized = false;
  String? _errorMessage;

  // Getters
  String get language1 => _language1;
  String get language1Name => _language1Name;
  String get language2 => _language2;
  String get language2Name => _language2Name;
  
  bool get isListeningUser1 => _isListeningUser1;
  String get user1OriginalText => _user1OriginalText;
  bool get isTranslatingUser1 => _isTranslatingUser1;
  bool get isSpeakingUser1Translation => _isSpeakingUser1Translation;
  
  bool get isListeningUser2 => _isListeningUser2;
  String get user2OriginalText => _user2OriginalText;
  bool get isTranslatingUser2 => _isTranslatingUser2;
  bool get isSpeakingUser2Translation => _isSpeakingUser2Translation;
  
  bool get autoPlayEnabled => _autoPlayEnabled;
  bool get autoStopEnabled => _autoStopEnabled;
  bool get fastModeEnabled => _fastModeEnabled;
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize speech service
      final speechInitialized = await _speechService.initialize();
      if (!speechInitialized) {
        _errorMessage = 'Ses tanıma servisi başlatılamadı';
        notifyListeners();
        return;
      }
      
      // Initialize TTS
      await _initializeTTS();
      
      // Set up speech callbacks
      _speechService.setCallbacks(
        onTranscriptionUpdate: _onTranscriptionUpdate,
        onFinalTranscription: _onFinalTranscription,
        onError: _onSpeechError,
      );
      
      _isInitialized = true;
      _errorMessage = null;
      notifyListeners();
      
    } catch (e) {
      _errorMessage = 'Başlatma hatası: $e';
      if (kDebugMode) {
        print('RealTimeConversationProvider initialization error: $e');
      }
      notifyListeners();
    }
  }
  
  Future<void> _initializeTTS() async {
    try {
      await _tts.setSharedInstance(true);
      await _tts.setSpeechRate(0.6);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      
      // Set TTS handlers
      _tts.setStartHandler(() {
        // TTS başladığında hangi kullanıcının çevirisi okunuyorsa o tarafı işaretle
        notifyListeners();
      });
      
      _tts.setCompletionHandler(() {
        _isSpeakingUser1Translation = false;
        _isSpeakingUser2Translation = false;
        notifyListeners();
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('TTS initialization error: $e');
      }
    }
  }

  /// Toggle listening for specified user
  Future<void> toggleListening({required bool isUser1}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (!_isInitialized) {
      _errorMessage = 'Servis başlatılamadı';
      notifyListeners();
      return;
    }

    try {
      // Stop the other user if listening
      if (isUser1 && _isListeningUser2) {
        await _stopListening(isUser1: false);
      } else if (!isUser1 && _isListeningUser1) {
        await _stopListening(isUser1: true);
      }
      
      // Toggle current user
      if ((isUser1 && _isListeningUser1) || (!isUser1 && _isListeningUser2)) {
        await _stopListening(isUser1: isUser1);
      } else {
        await _startListening(isUser1: isUser1);
      }
    } catch (e) {
      _errorMessage = 'Mikrofon hatası: $e';
      if (kDebugMode) {
        print('Toggle listening error: $e');
      }
      notifyListeners();
    }
  }
  
  Future<void> _startListening({required bool isUser1}) async {
    final languageCode = isUser1 ? _language1 : _language2;
    
    // Clear previous text for this user only
    if (isUser1) {
      _user1OriginalText = '';
    } else {
      _user2OriginalText = '';
    }
    
    final success = await _speechService.startListening(
      languageCode: languageCode,
      timeout: _autoStopEnabled ? const Duration(seconds: 30) : null,
    );
    
    if (success) {
      if (isUser1) {
        _isListeningUser1 = true;
      } else {
        _isListeningUser2 = true;
      }
      _errorMessage = null;
    } else {
      _errorMessage = 'Dinleme başlatılamadı';
    }
    
    notifyListeners();
  }
  
  Future<void> _stopListening({required bool isUser1}) async {
    await _speechService.stopListening();
    
    if (isUser1) {
      _isListeningUser1 = false;
    } else {
      _isListeningUser2 = false;
    }
    
    notifyListeners();
  }

  void _onTranscriptionUpdate(String transcription) {
    if (_isListeningUser1) {
      _user1OriginalText = transcription;
    } else if (_isListeningUser2) {
      _user2OriginalText = transcription;
    }
    notifyListeners();
  }
  
  void _onFinalTranscription(String transcription) async {
    if (transcription.trim().isEmpty) return;
    
    final isUser1 = _isListeningUser1;
    
    // Set final transcription
    if (isUser1) {
      _user1OriginalText = transcription;
      _isListeningUser1 = false;
    } else {
      _user2OriginalText = transcription;
      _isListeningUser2 = false;
    }
    
    notifyListeners();
    
    // Start translation
    await _translateText(transcription, isUser1: isUser1);
  }
  
  Future<void> _translateText(String text, {required bool isUser1}) async {
    if (text.trim().isEmpty) return;
    
    try {
      final sourceLanguage = isUser1 ? _language1 : _language2;
      final targetLanguage = isUser1 ? _language2 : _language1;
      
      // Set translating state
      if (isUser1) {
        _isTranslatingUser1 = true;
      } else {
        _isTranslatingUser2 = true;
      }
      notifyListeners();
      
      final translatedText = await EnhancedTranslationService.translateText(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      
      // Update translated text to the OTHER user's area
      if (isUser1) {
        // User1 konuştu, çeviri User2'nin alanında gösterilsin
        _user2OriginalText = translatedText;
        _isTranslatingUser1 = false;
      } else {
        // User2 konuştu, çeviri User1'in alanında gösterilsin  
        _user1OriginalText = translatedText;
        _isTranslatingUser2 = false;
      }
      
      notifyListeners();
      
      // Auto-play translation if enabled
      if (_autoPlayEnabled && translatedText.isNotEmpty) {
        // Çeviri karşı tarafta okunacak çünkü karşı tarafın diline çevrildi
        if (isUser1) {
          // User1 konuştu, çeviri User2 tarafında okunacak
          _isSpeakingUser2Translation = true;
        } else {
          // User2 konuştu, çeviri User1 tarafında okunacak
          _isSpeakingUser1Translation = true;
        }
        notifyListeners();
        await _speakTranslation(translatedText, targetLanguage);
      }
      
    } catch (e) {
      _errorMessage = 'Çeviri hatası: $e';
      if (isUser1) {
        _isTranslatingUser1 = false;
      } else {
        _isTranslatingUser2 = false;
      }
      if (kDebugMode) {
        print('Translation error: $e');
      }
      notifyListeners();
    }
  }

  Future<void> _speakTranslation(String text, String languageCode) async {
    try {
      await _tts.setLanguage(languageCode);
      await _tts.speak(text);
    } catch (e) {
      if (kDebugMode) {
        print('TTS error: $e');
      }
    }
  }
  
  void _onSpeechError(String error) {
    _errorMessage = error;
    _isListeningUser1 = false;
    _isListeningUser2 = false;
    notifyListeners();
  }

  // Public methods for manual actions
  Future<void> playOriginalAudio(String text, String languageCode) async {
    await _speakTranslation(text, languageCode);
  }
  
  Future<void> playTranslatedAudio(String text, String languageCode) async {
    await _speakTranslation(text, languageCode);
  }
  
  void copyToClipboard(String text, BuildContext context) {
    if (text.isEmpty) return;
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Metin panoya kopyalandı'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  // Language management
  void setLanguage1(String code, String name) {
    _language1 = code;
    _language1Name = name;
    notifyListeners();
  }
  
  void setLanguage2(String code, String name) {
    _language2 = code;
    _language2Name = name;
    notifyListeners();
  }
  
  void swapLanguages() {
    final tempCode = _language1;
    final tempName = _language1Name;
    
    _language1 = _language2;
    _language1Name = _language2Name;
    _language2 = tempCode;
    _language2Name = tempName;
    
    // Also swap the texts
    final tempOriginal1 = _user1OriginalText;
    
    _user1OriginalText = _user2OriginalText;
    _user2OriginalText = tempOriginal1;
    
    notifyListeners();
  }

  // Settings
  void setAutoPlay(bool enabled) {
    _autoPlayEnabled = enabled;
    notifyListeners();
  }
  
  void setAutoStop(bool enabled) {
    _autoStopEnabled = enabled;
    notifyListeners();
  }
  
  void setFastMode(bool enabled) {
    _fastModeEnabled = enabled;
    notifyListeners();
  }

  void clearConversation() {
    _user1OriginalText = '';
    _user2OriginalText = '';
    _errorMessage = null;
    
    // Stop any active listening
    if (_isListeningUser1 || _isListeningUser2) {
      _speechService.cancel();
      _isListeningUser1 = false;
      _isListeningUser2 = false;
    }
    
    // Stop TTS
    _tts.stop();
    _isSpeakingUser1Translation = false;
    _isSpeakingUser2Translation = false;
    
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'name': 'Türkçe', 'code': 'tr', 'flag': 'TR'},
      {'name': 'English', 'code': 'en', 'flag': 'GB'},
      {'name': 'Español', 'code': 'es', 'flag': 'ES'},
      {'name': 'Français', 'code': 'fr', 'flag': 'FR'},
      {'name': 'Deutsch', 'code': 'de', 'flag': 'DE'},
      {'name': 'Italiano', 'code': 'it', 'flag': 'IT'},
      {'name': 'Português', 'code': 'pt', 'flag': 'PT'},
      {'name': 'Русский', 'code': 'ru', 'flag': 'RU'},
      {'name': '日本語', 'code': 'ja', 'flag': 'JP'},
      {'name': '한국어', 'code': 'ko', 'flag': 'KR'},
      {'name': '中文', 'code': 'zh', 'flag': 'CN'},
      {'name': 'العربية', 'code': 'ar', 'flag': 'SA'},
      {'name': 'हिन्दी', 'code': 'hi', 'flag': 'IN'},
      {'name': 'Nederlands', 'code': 'nl', 'flag': 'NL'},
      {'name': 'Svenska', 'code': 'sv', 'flag': 'SE'},
    ];
  }

  @override
  void dispose() {
    _speechService.dispose();
    _tts.stop();
    super.dispose();
  }
}