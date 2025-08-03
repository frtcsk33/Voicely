import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class TranslatorProvider with ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  Timer? _debounceTimer;
  Timer? _historyDebounceTimer;
  
  String _inputText = '';
  String _translatedText = '';
  String _fromLang = 'tr';
  String _toLang = 'en';
  bool _isRecording = false;
  bool _isAvailable = false;
  bool _isTranslating = false;
  
  // Favori sistemi için değişkenler
  List<Map<String, dynamic>> _favorites = [];
  bool _isCurrentTranslationFavorited = false;
  
  // Geçmiş sistemi için değişkenler
  List<Map<String, dynamic>> _history = [];
  
  // Uygulama dili için değişkenler
  String _appLanguage = 'tr';
  bool _isLoading = true;

  // Getters
  String get inputText => _inputText;
  String get translatedText => _translatedText;
  String get fromLang => _fromLang;
  String get toLang => _toLang;
  bool get isRecording => _isRecording;
  bool get isAvailable => _isAvailable;
  bool get isTranslating => _isTranslating;
  List<Map<String, dynamic>> get favorites => _favorites;
  bool get isCurrentTranslationFavorited => _isCurrentTranslationFavorited;
  List<Map<String, dynamic>> get history => _history;
  String get appLanguage => _appLanguage;
  bool get isLoading => _isLoading;
  
  List<Map<String, String>> get languages => [
    {'label': 'İngilizce', 'value': 'en'},
    {'label': 'Türkçe', 'value': 'tr'},
    {'label': 'Almanca', 'value': 'de'},
    {'label': 'Fransızca', 'value': 'fr'},
    {'label': 'İspanyolca', 'value': 'es'},
    {'label': 'İtalyanca', 'value': 'it'},
    {'label': 'Portekizce', 'value': 'pt'},
    {'label': 'Rusça', 'value': 'ru'},
    {'label': 'Japonca', 'value': 'ja'},
    {'label': 'Korece', 'value': 'ko'},
    {'label': 'Çince', 'value': 'zh'},
    {'label': 'Arapça', 'value': 'ar'},
  ];

  List<Map<String, String>> get appLanguages => [
    {'label': 'Türkçe', 'value': 'tr'},
    {'label': 'English', 'value': 'en'},
    {'label': 'Deutsch', 'value': 'de'},
    {'label': 'Français', 'value': 'fr'},
    {'label': 'Español', 'value': 'es'},
    {'label': 'Italiano', 'value': 'it'},
    {'label': 'Português', 'value': 'pt'},
    {'label': 'Русский', 'value': 'ru'},
    {'label': '日本語', 'value': 'ja'},
    {'label': '한국어', 'value': 'ko'},
    {'label': '中文', 'value': 'zh'},
    {'label': 'العربية', 'value': 'ar'},
  ];

  TranslatorProvider() {
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      print('Initializing speech recognition...');
      
      _isAvailable = await _speechToText.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          _isAvailable = false;
          notifyListeners();
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isRecording = false;
            notifyListeners();
          }
        },
      );
      print('Speech recognition initialized: $_isAvailable');
      notifyListeners();
    } catch (e) {
      print('Error initializing speech recognition: $e');
      _isAvailable = false;
      notifyListeners();
    }
  }

  Future<void> initializeApp() async {
    await _loadAppLanguage();
    await _initializeSpeech();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAppLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _appLanguage = prefs.getString('appLanguage') ?? 'tr';
    } catch (e) {
      _appLanguage = 'tr';
    }
  }

  Future<void> setAppLanguage(String language) async {
    if (_appLanguage != language) {
      _appLanguage = language;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('appLanguage', language);
      } catch (e) {
        // Hata durumunda sessizce devam et
      }
      // Dil değişikliğinde tüm UI'ı yeniden oluştur
      notifyListeners();
    }
  }

  String getLocalizedText(String key) {
    switch (_appLanguage) {
      case 'tr':
        return _getTurkishText(key);
      case 'en':
        return _getEnglishText(key);
      case 'de':
        return _getGermanText(key);
      case 'fr':
        return _getFrenchText(key);
      case 'es':
        return _getSpanishText(key);
      case 'it':
        return _getItalianText(key);
      case 'pt':
        return _getPortugueseText(key);
      case 'ru':
        return _getRussianText(key);
      case 'ja':
        return _getJapaneseText(key);
      case 'ko':
        return _getKoreanText(key);
      case 'zh':
        return _getChineseText(key);
      case 'ar':
        return _getArabicText(key);
      default:
        return _getTurkishText(key);
    }
  }

  String _getTurkishText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Çevir';
      case 'camera':
        return 'Kamera';
      case 'history':
        return 'Geçmiş';
      case 'favorites':
        return 'Favoriler';
      case 'source_language':
        return 'Kaynak Dil';
      case 'target_language':
        return 'Hedef Dil';
      case 'enter_text':
        return 'Metni girin...';
      case 'translation':
        return 'Çeviri...';
      case 'speak':
        return 'Konuş';
      case 'read':
        return 'Oku';
      case 'add_to_favorites':
        return 'Favorilere Ekle';
      case 'remove_from_favorites':
        return 'Favorilerden Çıkar';
      case 'camera_translation':
        return 'Kamera Çevirisi';
      case 'coming_soon':
        return 'Yakında...';
      case 'text_recognition':
        return 'Metin tanıma ve çeviri özelliği';
      case 'translation_history':
        return 'Çeviri Geçmişi';
      case 'view_recent_translations':
        return 'Son çevirilerinizi görüntüleyin';
      case 'my_favorites':
        return 'Favorilerim';
      case 'no_favorites_yet':
        return 'Henüz Favori Yok';
      case 'add_favorites_description':
        return 'Çevirilerinizi favorilere ekleyerek\ndaha sonra kolayca erişebilirsiniz';
      case 'add_from_translate_page':
        return 'Çeviri sayfasından favori ekleyin';
      case 'clear_history':
        return 'Geçmişi Temizle';
      case 'clear_history_confirm':
        return 'Tüm geçmiş çevirileri silmek istediğinizden emin misiniz?';
      case 'cancel':
        return 'İptal';
      case 'clear':
        return 'Temizle';
      case 'settings':
        return 'Ayarlar';
      case 'app_language':
        return 'Uygulama Dili';
      case 'select_language':
        return 'Dil Seçin';
      case 'take_photo':
        return 'Fotoğraf Çek';
      case 'select_from_gallery':
        return 'Galeriden Seç';
      case 'recognizing_text':
        return 'Metin tanınıyor...';
      case 'text_recognized':
        return 'Metin tanındı';
      case 'translation_complete':
        return 'Çeviri tamamlandı';
      case 'error_occurred':
        return 'Hata oluştu';
      case 'about_app':
        return 'Uygulama Hakkında';
      default:
        return key;
    }
  }

  String _getEnglishText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Translate';
      case 'camera':
        return 'Camera';
      case 'history':
        return 'History';
      case 'favorites':
        return 'Favorites';
      case 'source_language':
        return 'Source Language';
      case 'target_language':
        return 'Target Language';
      case 'enter_text':
        return 'Enter text...';
      case 'translation':
        return 'Translation...';
      case 'speak':
        return 'Speak';
      case 'read':
        return 'Read';
      case 'add_to_favorites':
        return 'Add to Favorites';
      case 'remove_from_favorites':
        return 'Remove from Favorites';
      case 'camera_translation':
        return 'Camera Translation';
      case 'coming_soon':
        return 'Coming soon...';
      case 'text_recognition':
        return 'Text recognition and translation feature';
      case 'translation_history':
        return 'Translation History';
      case 'view_recent_translations':
        return 'View your recent translations';
      case 'my_favorites':
        return 'My Favorites';
      case 'no_favorites_yet':
        return 'No Favorites Yet';
      case 'add_favorites_description':
        return 'Add your translations to favorites\nto access them easily later';
      case 'add_from_translate_page':
        return 'Add favorites from translate page';
      case 'clear_history':
        return 'Clear History';
      case 'clear_history_confirm':
        return 'Are you sure you want to delete all translation history?';
      case 'cancel':
        return 'Cancel';
      case 'clear':
        return 'Clear';
      case 'settings':
        return 'Settings';
      case 'app_language':
        return 'App Language';
      case 'select_language':
        return 'Select Language';
      case 'take_photo':
        return 'Take Photo';
      case 'select_from_gallery':
        return 'Select from Gallery';
      case 'recognizing_text':
        return 'Recognizing text...';
      case 'text_recognized':
        return 'Text recognized';
      case 'translation_complete':
        return 'Translation complete';
      case 'error_occurred':
        return 'An error occurred';
      case 'about_app':
        return 'About App';
      default:
        return key;
    }
  }

  String _getGermanText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Übersetzen';
      case 'camera':
        return 'Kamera';
      case 'history':
        return 'Verlauf';
      case 'favorites':
        return 'Favoriten';
      case 'source_language':
        return 'Quellsprache';
      case 'target_language':
        return 'Zielsprache';
      case 'enter_text':
        return 'Text eingeben...';
      case 'translation':
        return 'Übersetzung...';
      case 'speak':
        return 'Sprechen';
      case 'read':
        return 'Lesen';
      case 'add_to_favorites':
        return 'Zu Favoriten hinzufügen';
      case 'remove_from_favorites':
        return 'Aus Favoriten entfernen';
      case 'camera_translation':
        return 'Kamera-Übersetzung';
      case 'coming_soon':
        return 'Demnächst verfügbar...';
      case 'text_recognition':
        return 'Texterkennung und Übersetzungsfunktion';
      case 'translation_history':
        return 'Übersetzungsverlauf';
      case 'view_recent_translations':
        return 'Ihre letzten Übersetzungen anzeigen';
      case 'my_favorites':
        return 'Meine Favoriten';
      case 'no_favorites_yet':
        return 'Noch keine Favoriten';
      case 'add_favorites_description':
        return 'Fügen Sie Ihre Übersetzungen zu Favoriten hinzu,\num sie später einfach zu finden';
      case 'add_from_translate_page':
        return 'Favoriten von der Übersetzungsseite hinzufügen';
      case 'clear_history':
        return 'Verlauf löschen';
      case 'clear_history_confirm':
        return 'Sind Sie sicher, dass Sie den gesamten Übersetzungsverlauf löschen möchten?';
      case 'cancel':
        return 'Abbrechen';
      case 'clear':
        return 'Löschen';
      case 'settings':
        return 'Einstellungen';
      case 'app_language':
        return 'App-Sprache';
      case 'select_language':
        return 'Sprache auswählen';
      case 'take_photo':
        return 'Foto aufnehmen';
      case 'select_from_gallery':
        return 'Aus Galerie auswählen';
      case 'recognizing_text':
        return 'Text wird erkannt...';
      case 'text_recognized':
        return 'Text erkannt';
      case 'translation_complete':
        return 'Übersetzung abgeschlossen';
      case 'error_occurred':
        return 'Ein Fehler ist aufgetreten';
      case 'about_app':
        return 'Über die App';
      default:
        return key;
    }
  }

  String _getFrenchText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Traduire';
      case 'camera':
        return 'Caméra';
      case 'history':
        return 'Historique';
      case 'favorites':
        return 'Favoris';
      case 'source_language':
        return 'Langue source';
      case 'target_language':
        return 'Langue cible';
      case 'enter_text':
        return 'Entrez le texte...';
      case 'translation':
        return 'Traduction...';
      case 'speak':
        return 'Parler';
      case 'read':
        return 'Lire';
      case 'add_to_favorites':
        return 'Ajouter aux favoris';
      case 'remove_from_favorites':
        return 'Retirer des favoris';
      case 'camera_translation':
        return 'Traduction par caméra';
      case 'coming_soon':
        return 'Bientôt disponible...';
      case 'text_recognition':
        return 'Fonction de reconnaissance et traduction de texte';
      case 'translation_history':
        return 'Historique des traductions';
      case 'view_recent_translations':
        return 'Voir vos traductions récentes';
      case 'my_favorites':
        return 'Mes favoris';
      case 'no_favorites_yet':
        return 'Aucun favori pour le moment';
      case 'add_favorites_description':
        return 'Ajoutez vos traductions aux favoris\npour y accéder facilement plus tard';
      case 'add_from_translate_page':
        return 'Ajouter des favoris depuis la page de traduction';
      case 'clear_history':
        return 'Effacer l\'historique';
      case 'clear_history_confirm':
        return 'Êtes-vous sûr de vouloir supprimer tout l\'historique des traductions ?';
      case 'cancel':
        return 'Annuler';
      case 'clear':
        return 'Effacer';
      case 'settings':
        return 'Paramètres';
      case 'app_language':
        return 'Langue de l\'application';
      case 'select_language':
        return 'Sélectionner la langue';
      case 'take_photo':
        return 'Prendre une photo';
      case 'select_from_gallery':
        return 'Sélectionner depuis la galerie';
      case 'recognizing_text':
        return 'Reconnaissance du texte...';
      case 'text_recognized':
        return 'Texte reconnu';
      case 'translation_complete':
        return 'Traduction terminée';
      case 'error_occurred':
        return 'Une erreur s\'est produite';
      case 'about_app':
        return 'À propos de l\'application';
      default:
        return key;
    }
  }

  String _getSpanishText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Traducir';
      case 'camera':
        return 'Cámara';
      case 'history':
        return 'Historial';
      case 'favorites':
        return 'Favoritos';
      case 'source_language':
        return 'Idioma de origen';
      case 'target_language':
        return 'Idioma de destino';
      case 'enter_text':
        return 'Ingrese el texto...';
      case 'translation':
        return 'Traducción...';
      case 'speak':
        return 'Hablar';
      case 'read':
        return 'Leer';
      case 'add_to_favorites':
        return 'Agregar a favoritos';
      case 'remove_from_favorites':
        return 'Quitar de favoritos';
      case 'camera_translation':
        return 'Traducción por cámara';
      case 'coming_soon':
        return 'Próximamente...';
      case 'text_recognition':
        return 'Función de reconocimiento y traducción de texto';
      case 'translation_history':
        return 'Historial de traducciones';
      case 'view_recent_translations':
        return 'Ver sus traducciones recientes';
      case 'my_favorites':
        return 'Mis favoritos';
      case 'no_favorites_yet':
        return 'Aún no hay favoritos';
      case 'add_favorites_description':
        return 'Agregue sus traducciones a favoritos\npara acceder fácilmente más tarde';
      case 'add_from_translate_page':
        return 'Agregar favoritos desde la página de traducción';
      case 'clear_history':
        return 'Limpiar historial';
      case 'clear_history_confirm':
        return '¿Está seguro de que desea eliminar todo el historial de traducciones?';
      case 'cancel':
        return 'Cancelar';
      case 'clear':
        return 'Limpiar';
      case 'settings':
        return 'Configuración';
      case 'app_language':
        return 'Idioma de la aplicación';
      case 'select_language':
        return 'Seleccionar idioma';
      case 'take_photo':
        return 'Tomar foto';
      case 'select_from_gallery':
        return 'Seleccionar de la galería';
      case 'recognizing_text':
        return 'Reconociendo texto...';
      case 'text_recognized':
        return 'Texto reconocido';
      case 'translation_complete':
        return 'Traducción completada';
      case 'error_occurred':
        return 'Ocurrió un error';
      case 'about_app':
        return 'Acerca de la aplicación';
      default:
        return key;
    }
  }

  String _getItalianText(String key) => _getEnglishText(key);
  String _getPortugueseText(String key) => _getEnglishText(key);
  String _getRussianText(String key) => _getEnglishText(key);
  String _getJapaneseText(String key) => _getEnglishText(key);
  String _getKoreanText(String key) => _getEnglishText(key);
  String _getChineseText(String key) => _getEnglishText(key);
  String _getArabicText(String key) => _getEnglishText(key);

  Future<void> startRecording() async {
    print('startRecording called');
    
    if (!_isAvailable) {
      print('Speech recognition not available, trying to initialize...');
      await _initializeSpeech();
      if (!_isAvailable) {
        print('Speech recognition still not available after initialization');
        return;
      }
    }
    
    if (_isRecording) {
      print('Already recording, stopping first');
      await stopRecording();
      return;
    }
    
    _isRecording = true;
    notifyListeners();
    
    try {
      // Dil kodunu speech-to-text için uygun formata çevir
      String localeId = _getLocaleId(_fromLang);
      print('Starting recording with locale: $localeId');
      
      await _speechToText.listen(
        onResult: (result) {
          print('Speech result: ${result.recognizedWords}');
          if (result.finalResult) {
            _inputText = result.recognizedWords;
            _isRecording = false;
            notifyListeners();
            _debounceTranslate();
          }
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 30), // Daha kısa dinleme süresi
        pauseFor: const Duration(seconds: 3), // Daha kısa duraklama süresi
        partialResults: true,
        onSoundLevelChange: (level) {
          // Ses seviyesi değişikliklerini dinle
          print('Sound level: $level');
        },
        cancelOnError: false, // Hata durumunda iptal etme
        listenMode: ListenMode.dictation, // Dictation modu daha iyi tanıma sağlar
      );
    } catch (e) {
      print('Error starting recording: $e');
      _isRecording = false;
      notifyListeners();
    }
  }

  String _getLocaleId(String langCode) {
    // Dil kodlarını speech-to-text için uygun locale ID'lere çevir
    switch (langCode) {
      case 'tr':
        return 'tr-TR'; // Türkçe için doğru format
      case 'en':
        return 'en-US';
      case 'de':
        return 'de-DE';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'it':
        return 'it-IT';
      case 'pt':
        return 'pt-PT';
      case 'ru':
        return 'ru-RU';
      case 'ja':
        return 'ja-JP';
      case 'ko':
        return 'ko-KR';
      case 'zh':
        return 'zh-CN';
      case 'ar':
        return 'ar-SA';
      default:
        return 'en-US';
    }
  }

  Future<void> stopRecording() async {
    try {
      print('Stopping recording...');
      _isRecording = false;
      await _speechToText.stop();
      print('Recording stopped successfully');
      notifyListeners();
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      notifyListeners();
    }
  }

  void setInputText(String text) {
    _inputText = text;
    _updateFavoriteStatus();
    
    // Yeni metin girildiğinde geçmiş debounce timer'ını iptal et
    _historyDebounceTimer?.cancel();
    
    notifyListeners();
    _debounceTranslate();
  }

  void _debounceTranslate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (_inputText.isNotEmpty) {
        translateText();
      }
    });
  }

  void setFromLang(String lang) {
    _fromLang = lang;
    _updateFavoriteStatus();
    
    // Geçmiş debounce timer'ını iptal et
    _historyDebounceTimer?.cancel();
    
    notifyListeners();
    _debounceTranslate();
  }

  void setToLang(String lang) {
    _toLang = lang;
    _updateFavoriteStatus();
    
    // Geçmiş debounce timer'ını iptal et
    _historyDebounceTimer?.cancel();
    
    notifyListeners();
    _debounceTranslate();
  }

  void swapLanguages() {
    String temp = _fromLang;
    _fromLang = _toLang;
    _toLang = temp;
    _updateFavoriteStatus();
    
    // Geçmiş debounce timer'ını iptal et
    _historyDebounceTimer?.cancel();
    
    notifyListeners();
    _debounceTranslate();
  }

  Future<void> translateText() async {
    if (_inputText.isEmpty) return;
    
    _isTranslating = true;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('https://translate.googleapis.com/translate_a/single'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client': 'gtx',
          'sl': _fromLang,
          'tl': _toLang,
          'dt': 't',
          'q': _inputText,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[0] != null && data[0].isNotEmpty) {
          _translatedText = data[0][0][0];
          _addToHistory();
          _updateFavoriteStatus();
          
          // Çeviri tamamlandığında hedef dilden metni oku
          await speak(_translatedText, _toLang);
        }
      } else {
        _translatedText = 'Çeviri hatası: ${response.statusCode}';
      }
    } catch (e) {
      _translatedText = 'Çeviri hatası: $e';
    }
    
    _isTranslating = false;
    notifyListeners();
  }

  void _addToHistory() {
    if (_inputText.isNotEmpty && _translatedText.isNotEmpty) {
      final translation = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'fromLang': _fromLang,
        'toLang': _toLang,
        'inputText': _inputText,
        'translatedText': _translatedText,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Aynı çeviri zaten varsa ekleme
      bool exists = _history.any((item) =>
          item['inputText'] == _inputText &&
          item['fromLang'] == _fromLang &&
          item['toLang'] == _toLang);
      
      if (!exists) {
        _history.insert(0, translation);
        
        // Geçmişi 100 öğe ile sınırla
        if (_history.length > 100) {
          _history = _history.take(100).toList();
        }
        
        _saveHistory();
      }
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('translation_history', json.encode(_history));
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('translation_history');
      if (historyJson != null) {
        _history = List<Map<String, dynamic>>.from(
          json.decode(historyJson).map((item) => Map<String, dynamic>.from(item))
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  void clearHistory() {
    _history.clear();
    _saveHistory();
    notifyListeners();
  }

  void _updateFavoriteStatus() {
    _isCurrentTranslationFavorited = _favorites.any((favorite) =>
        favorite['inputText'] == _inputText &&
        favorite['fromLang'] == _fromLang &&
        favorite['toLang'] == _toLang);
  }

  void toggleFavorite() {
    if (_inputText.isNotEmpty && _translatedText.isNotEmpty) {
      if (_isCurrentTranslationFavorited) {
        _favorites.removeWhere((favorite) =>
            favorite['inputText'] == _inputText &&
            favorite['fromLang'] == _fromLang &&
            favorite['toLang'] == _toLang);
      } else {
        _favorites.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'fromLang': _fromLang,
          'toLang': _toLang,
          'inputText': _inputText,
          'translatedText': _translatedText,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      
      _isCurrentTranslationFavorited = !_isCurrentTranslationFavorited;
      _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('favorites', json.encode(_favorites));
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString('favorites');
      if (favoritesJson != null) {
        _favorites = List<Map<String, dynamic>>.from(
          json.decode(favoritesJson).map((item) => Map<String, dynamic>.from(item))
        );
        _updateFavoriteStatus();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  void removeFavorite(String id) {
    _favorites.removeWhere((favorite) => favorite['id'] == id);
    _saveFavorites();
    _updateFavoriteStatus();
    notifyListeners();
  }

  void loadFavorite(Map<String, dynamic> favorite) {
    _inputText = favorite['inputText'];
    _translatedText = favorite['translatedText'];
    _fromLang = favorite['fromLang'];
    _toLang = favorite['toLang'];
    
    _updateFavoriteStatus();
    notifyListeners();
  }

  void loadFromHistory(Map<String, dynamic> historyItem) {
    _inputText = historyItem['inputText'];
    _translatedText = historyItem['translatedText'];
    _fromLang = historyItem['fromLang'];
    _toLang = historyItem['toLang'];
    
    _updateFavoriteStatus();
    notifyListeners();
  }

  Future<String> translateTextFromImage(String text, String targetLanguage) async {
    try {
      final response = await http.post(
        Uri.parse('https://translate.googleapis.com/translate_a/single'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client': 'gtx',
          'sl': 'auto',
          'tl': targetLanguage,
          'dt': 't',
          'q': text,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[0] != null && data[0].isNotEmpty) {
          return data[0][0][0];
        } else {
          return 'Çeviri başarısız.';
        }
      } else {
        return 'Çeviri başarısız.';
      }
    } catch (e) {
      return 'Çeviri hatası: $e';
    }
  }

  Future<void> speak(String text, String language) async {
    try {
      await _flutterTts.setLanguage(_getTtsLanguage(language));
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking: $e');
    }
  }

  String _getTtsLanguage(String langCode) {
    switch (langCode) {
      case 'tr':
        return 'tr-TR';
      case 'en':
        return 'en-US';
      case 'de':
        return 'de-DE';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'it':
        return 'it-IT';
      case 'pt':
        return 'pt-PT';
      case 'ru':
        return 'ru-RU';
      case 'ja':
        return 'ja-JP';
      case 'ko':
        return 'ko-KR';
      case 'zh':
        return 'zh-CN';
      case 'ar':
        return 'ar-SA';
      default:
        return 'en-US';
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _historyDebounceTimer?.cancel();
    super.dispose();
  }
} 