import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/enhanced_speech_service.dart';
import '../services/backend_translation_service.dart';
import '../services/user_service.dart';
import '../models/chat_message.dart';

class ConversationProvider extends ChangeNotifier {
  // Speech services
  final EnhancedSpeechService _speechService = EnhancedSpeechService();
  final FlutterTts _tts = FlutterTts();
  
  // User service for tracking translations
  UserService? _userService;
  
  // Language settings
  String _language1 = 'en';
  String _language1Name = 'English';
  String _language2 = 'es';
  String _language2Name = 'Spanish';
  
  // Listening states
  bool _isListeningTop = false;
  bool _isListeningBottom = false;
  
  // Transcription states
  String _topTranscribedText = '';
  String _topTranslatedText = '';
  String _bottomTranscribedText = '';
  String _bottomTranslatedText = '';
  
  // Settings
  bool _autoPlayEnabled = true;
  bool _autoStopEnabled = true;
  
  // Error handling
  String? _errorMessage;
  bool _isInitialized = false;
  
  // Chat messages
  final List<ChatMessage> _chatMessages = [];
  
  // Getters
  String get language1 => _language1;
  String get language1Name => _language1Name;
  String get language2 => _language2;
  String get language2Name => _language2Name;
  
  bool get isListeningTop => _isListeningTop;
  bool get isListeningBottom => _isListeningBottom;
  
  String get topTranscribedText => _topTranscribedText;
  String get topTranslatedText => _topTranslatedText;
  String get bottomTranscribedText => _bottomTranscribedText;
  String get bottomTranslatedText => _bottomTranslatedText;
  
  bool get autoPlayEnabled => _autoPlayEnabled;
  bool get autoStopEnabled => _autoStopEnabled;
  
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  
  /// Set user service for translation tracking
  void setUserService(UserService userService) {
    _userService = userService;
  }
  
  /// Initialize the conversation provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize speech service
      final speechInitialized = await _speechService.initialize();
      if (!speechInitialized) {
        _errorMessage = 'Speech recognition not available';
        notifyListeners();
        return;
      }
      
      // Initialize TTS
      await _initializeTTS();
      
      // Set up speech service callbacks
      _speechService.setCallbacks(
        onTranscriptionUpdate: _onTranscriptionUpdate,
        onFinalTranscription: _onFinalTranscription,
        onError: _onSpeechError,
      );
      
      _isInitialized = true;
      _errorMessage = null;
      notifyListeners();
      
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      if (kDebugMode) {
        print('Conversation provider initialization error: $e');
      }
      notifyListeners();
    }
  }
  
  /// Initialize Text-to-Speech
  Future<void> _initializeTTS() async {
    try {
      await _tts.setSharedInstance(true);
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      if (kDebugMode) {
        print('TTS initialization error: $e');
      }
    }
  }
  
  /// Toggle listening for specified panel
  Future<void> toggleListening(bool isTopPanel) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (!_isInitialized) {
      _errorMessage = 'Service not initialized';
      notifyListeners();
      return;
    }
    
    try {
      // Stop the other panel if it's listening
      if (isTopPanel && _isListeningBottom) {
        await _stopListening(false);
      } else if (!isTopPanel && _isListeningTop) {
        await _stopListening(true);
      }
      
      // Toggle current panel
      if ((isTopPanel && _isListeningTop) || (!isTopPanel && _isListeningBottom)) {
        await _stopListening(isTopPanel);
      } else {
        await _startListening(isTopPanel);
      }
    } catch (e) {
      _errorMessage = 'Error toggling microphone: $e';
      if (kDebugMode) {
        print('Toggle listening error: $e');
      }
      notifyListeners();
    }
  }
  
  /// Start listening for specified panel
  Future<void> _startListening(bool isTopPanel) async {
    final languageCode = isTopPanel ? _language1 : _language2;
    
    // Clear previous text for this panel
    if (isTopPanel) {
      _topTranscribedText = '';
      _topTranslatedText = '';
    } else {
      _bottomTranscribedText = '';
      _bottomTranslatedText = '';
    }
    
    final success = await _speechService.startListening(
      languageCode: languageCode,
      timeout: _autoStopEnabled ? const Duration(seconds: 30) : null,
    );
    
    if (success) {
      if (isTopPanel) {
        _isListeningTop = true;
      } else {
        _isListeningBottom = true;
      }
      _errorMessage = null;
    } else {
      _errorMessage = 'Failed to start listening';
    }
    
    notifyListeners();
  }
  
  /// Stop listening for specified panel
  Future<void> _stopListening(bool isTopPanel) async {
    await _speechService.stopListening();
    
    if (isTopPanel) {
      _isListeningTop = false;
    } else {
      _isListeningBottom = false;
    }
    
    notifyListeners();
  }
  
  /// Handle transcription updates
  void _onTranscriptionUpdate(String transcription) {
    if (_isListeningTop) {
      _topTranscribedText = transcription;
    } else if (_isListeningBottom) {
      _bottomTranscribedText = transcription;
    }
    notifyListeners();
  }
  
  /// Handle final transcription and trigger translation
  void _onFinalTranscription(String transcription) async {
    if (transcription.trim().isEmpty) return;
    
    final isTopPanel = _isListeningTop;
    
    // Set final transcription
    if (isTopPanel) {
      _topTranscribedText = transcription;
      _isListeningTop = false;
    } else {
      _bottomTranscribedText = transcription;
      _isListeningBottom = false;
    }
    
    notifyListeners();
    
    // Translate the text
    await _translateText(transcription, isTopPanel);
    
    // Track translation usage
    _trackTranslationUsage();
  }
  
  /// Translate text and update UI
  Future<void> _translateText(String text, bool isTopPanel) async {
    if (text.trim().isEmpty) return;
    
    try {
      final sourceLanguage = isTopPanel ? _language1 : _language2;
      final targetLanguage = isTopPanel ? _language2 : _language1;
      
      final translatedText = await BackendTranslationService.translateText(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      
      // Update translated text
      if (isTopPanel) {
        _topTranslatedText = translatedText;
      } else {
        _bottomTranslatedText = translatedText;
      }
      
      // Add message to chat
      _addChatMessage(
        originalText: text,
        translatedText: translatedText,
        isUser: !isTopPanel,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        isFromLeftMic: isTopPanel,
      );
      
      notifyListeners();
      
      // Auto-play translation if enabled
      if (_autoPlayEnabled && translatedText.isNotEmpty) {
        await _speakTranslation(translatedText, targetLanguage);
      }
      
    } catch (e) {
      // Even if translation fails, add the original text to chat
      final sourceLanguage = isTopPanel ? _language1 : _language2;
      final targetLanguage = isTopPanel ? _language2 : _language1;
      
      _addChatMessage(
        originalText: text,
        translatedText: 'Translation service temporarily unavailable',
        isUser: !isTopPanel,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        isFromLeftMic: isTopPanel,
      );
      
      _errorMessage = 'Translation temporarily unavailable';
      if (kDebugMode) {
        print('Translation error: $e');
      }
      notifyListeners();
    }
  }
  
  /// Speak the translated text
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
  
  /// Handle speech recognition errors
  void _onSpeechError(String error) {
    _errorMessage = error;
    _isListeningTop = false;
    _isListeningBottom = false;
    notifyListeners();
  }
  
  /// Track translation usage
  void _trackTranslationUsage() {
    _userService?.incrementTranslationCount();
  }
  
  /// Add a new chat message
  void _addChatMessage({
    required String originalText,
    required String translatedText,
    required bool isUser,
    required String sourceLanguage,
    required String targetLanguage,
    required bool isFromLeftMic,
  }) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalText: originalText,
      translatedText: translatedText,
      isUser: isUser,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      timestamp: DateTime.now(),
      isFromLeftMic: isFromLeftMic,
    );
    
    _chatMessages.add(message);
  }
  
  /// Set language 1
  void setLanguage1(String languageCode, String languageName) {
    _language1 = languageCode;
    _language1Name = languageName;
    notifyListeners();
  }
  
  /// Set language 2
  void setLanguage2(String languageCode, String languageName) {
    _language2 = languageCode;
    _language2Name = languageName;
    notifyListeners();
  }
  
  /// Swap languages
  void swapLanguages() {
    final tempCode = _language1;
    final tempName = _language1Name;
    
    _language1 = _language2;
    _language1Name = _language2Name;
    _language2 = tempCode;
    _language2Name = tempName;
    
    // Also swap the text content
    final tempTranscribed = _topTranscribedText;
    final tempTranslated = _topTranslatedText;
    
    _topTranscribedText = _bottomTranscribedText;
    _topTranslatedText = _bottomTranslatedText;
    _bottomTranscribedText = tempTranscribed;
    _bottomTranslatedText = tempTranslated;
    
    notifyListeners();
  }
  
  /// Set auto-play setting
  void setAutoPlay(bool enabled) {
    _autoPlayEnabled = enabled;
    notifyListeners();
  }
  
  /// Set auto-stop setting
  void setAutoStop(bool enabled) {
    _autoStopEnabled = enabled;
    notifyListeners();
  }
  
  /// Clear conversation
  void clearConversation() {
    _topTranscribedText = '';
    _topTranslatedText = '';
    _bottomTranscribedText = '';
    _bottomTranslatedText = '';
    _errorMessage = null;
    _chatMessages.clear();
    
    // Stop any active listening
    if (_isListeningTop || _isListeningBottom) {
      _speechService.cancel();
      _isListeningTop = false;
      _isListeningBottom = false;
    }
    
    notifyListeners();
  }
  
  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Manually speak text
  Future<void> speakText(String text, String languageCode) async {
    await _speakTranslation(text, languageCode);
  }
  
  /// Check if can translate (for usage limits)
  bool canTranslate() {
    return _userService?.canTranslate ?? true;
  }
  
  /// Get remaining translations for free users
  int getRemainingTranslations() {
    return _userService?.translationsRemaining ?? 50;
  }
  
  @override
  void dispose() {
    _speechService.dispose();
    _tts.stop();
    super.dispose();
  }
}