import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:async';

class TranslatorProvider with ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  Timer? _debounceTimer;
  Timer? _historyDebounceTimer;
  Timer? _speakDebounceTimer;
  
  String _inputText = '';
  String _translatedText = '';
  String _fromLang = 'auto';
  String _toLang = 'en';
  String? _detectedLanguage; // Auto detect ile tespit edilen dil
  bool _isRecording = false;
  bool _isAvailable = false;
  bool _isTranslating = false;
  TextEditingController _textController = TextEditingController();
  
  // Favori sistemi için değişkenler
  List<Map<String, dynamic>> _favorites = [];
  bool _isCurrentTranslationFavorited = false;
  
  // Geçmiş sistemi için değişkenler
  List<Map<String, dynamic>> _history = [];
  
  // Uygulama dili için değişkenler
  String _appLanguage = 'tr';
  bool _isLoading = true;
  
  // AI Pro mode için değişkenler
  bool _isProUser = false;  // Simüle edilmiş Pro kullanıcı durumu
  bool _useWhisper = false; // Whisper kullanımı
  String _translationModel = 'standard'; // 'standard' veya 'ai_pro'

  // Getters
  String get inputText => _inputText;
  String get translatedText => _translatedText;
  String get fromLang => _fromLang;
  String get toLang => _toLang;
  String? get detectedLanguage => _detectedLanguage;
  bool get isRecording => _isRecording;
  bool get isAvailable => _isAvailable;
  bool get isTranslating => _isTranslating;
  TextEditingController get textController => _textController;
  List<Map<String, dynamic>> get favorites => _favorites;
  List<Map<String, dynamic>> get history => _history;
  bool get isCurrentTranslationFavorited => _isCurrentTranslationFavorited;
  String get appLanguage => _appLanguage;
  bool get isLoading => _isLoading;
  bool get isProUser => _isProUser;
  bool get useWhisper => _useWhisper;
  String get translationModel => _translationModel;
  
  List<Map<String, String>> get sourceLanguages => [
    {'label': 'Auto Detect', 'value': 'auto', 'flag': 'UN'},
    {'label': 'İngilizce', 'value': 'en', 'flag': 'GB'},
    {'label': 'Türkçe', 'value': 'tr', 'flag': 'TR'},
    {'label': 'Almanca', 'value': 'de', 'flag': 'DE'},
    {'label': 'Fransızca', 'value': 'fr', 'flag': 'FR'},
    {'label': 'İspanyolca', 'value': 'es', 'flag': 'ES'},
    {'label': 'İtalyanca', 'value': 'it', 'flag': 'IT'},
    {'label': 'Portekizce', 'value': 'pt', 'flag': 'PT'},
    {'label': 'Rusça', 'value': 'ru', 'flag': 'RU'},
    {'label': 'Japonca', 'value': 'ja', 'flag': 'JP'},
    {'label': 'Korece', 'value': 'ko', 'flag': 'KR'},
    {'label': 'Çince (Basitleştirilmiş)', 'value': 'zh', 'flag': 'CN'},
    {'label': 'Çince (Geleneksel)', 'value': 'zh-tw', 'flag': 'TW'},
    {'label': 'Arapça', 'value': 'ar', 'flag': 'SA'},
    {'label': 'Hintçe', 'value': 'hi', 'flag': 'IN'},
    {'label': 'Bengalce', 'value': 'bn', 'flag': 'BD'},
    {'label': 'Urduca', 'value': 'ur', 'flag': 'PK'},
    {'label': 'Farsça', 'value': 'fa', 'flag': 'IR'},
    {'label': 'Hollandaca', 'value': 'nl', 'flag': 'NL'},
    {'label': 'İsveççe', 'value': 'sv', 'flag': 'SE'},
    {'label': 'Norveççe', 'value': 'no', 'flag': 'NO'},
    {'label': 'Danca', 'value': 'da', 'flag': 'DK'},
    {'label': 'Fince', 'value': 'fi', 'flag': 'FI'},
    {'label': 'Lehçe', 'value': 'pl', 'flag': 'PL'},
    {'label': 'Çekçe', 'value': 'cs', 'flag': 'CZ'},
    {'label': 'Slovakça', 'value': 'sk', 'flag': 'SK'},
    {'label': 'Macarca', 'value': 'hu', 'flag': 'HU'},
    {'label': 'Rumence', 'value': 'ro', 'flag': 'RO'},
    {'label': 'Bulgarca', 'value': 'bg', 'flag': 'BG'},
    {'label': 'Hırvatça', 'value': 'hr', 'flag': 'HR'},
    {'label': 'Sırpça', 'value': 'sr', 'flag': 'RS'},
    {'label': 'Slovence', 'value': 'sl', 'flag': 'SI'},
    {'label': 'Litvanyaca', 'value': 'lt', 'flag': 'LT'},
    {'label': 'Letonca', 'value': 'lv', 'flag': 'LV'},
    {'label': 'Estonca', 'value': 'et', 'flag': 'EE'},
    {'label': 'Yunanca', 'value': 'el', 'flag': 'GR'},
    {'label': 'İbranice', 'value': 'he', 'flag': 'IL'},
    {'label': 'Tayca', 'value': 'th', 'flag': 'TH'},
    {'label': 'Vietnamca', 'value': 'vi', 'flag': 'VN'},
    {'label': 'Endonezce', 'value': 'id', 'flag': 'ID'},
    {'label': 'Malayca', 'value': 'ms', 'flag': 'MY'},
  ];
  
  List<Map<String, String>> get targetLanguages => [
    {'label': 'İngilizce', 'value': 'en', 'flag': 'GB'},
    {'label': 'Türkçe', 'value': 'tr', 'flag': 'TR'},
    {'label': 'Almanca', 'value': 'de', 'flag': 'DE'},
    {'label': 'Fransızca', 'value': 'fr', 'flag': 'FR'},
    {'label': 'İspanyolca', 'value': 'es', 'flag': 'ES'},
    {'label': 'İtalyanca', 'value': 'it', 'flag': 'IT'},
    {'label': 'Portekizce', 'value': 'pt', 'flag': 'PT'},
    {'label': 'Rusça', 'value': 'ru', 'flag': 'RU'},
    {'label': 'Japonca', 'value': 'ja', 'flag': 'JP'},
    {'label': 'Korece', 'value': 'ko', 'flag': 'KR'},
    {'label': 'Çince (Basitleştirilmiş)', 'value': 'zh', 'flag': 'CN'},
    {'label': 'Çince (Geleneksel)', 'value': 'zh-tw', 'flag': 'TW'},
    {'label': 'Arapça', 'value': 'ar', 'flag': 'SA'},
    {'label': 'Hintçe', 'value': 'hi', 'flag': 'IN'},
    {'label': 'Bengalce', 'value': 'bn', 'flag': 'BD'},
    {'label': 'Urduca', 'value': 'ur', 'flag': 'PK'},
    {'label': 'Farsça', 'value': 'fa', 'flag': 'IR'},
    {'label': 'Hollandaca', 'value': 'nl', 'flag': 'NL'},
    {'label': 'İsveççe', 'value': 'sv', 'flag': 'SE'},
    {'label': 'Norveççe', 'value': 'no', 'flag': 'NO'},
    {'label': 'Danca', 'value': 'da', 'flag': 'DK'},
    {'label': 'Fince', 'value': 'fi', 'flag': 'FI'},
    {'label': 'Lehçe', 'value': 'pl', 'flag': 'PL'},
    {'label': 'Çekçe', 'value': 'cs', 'flag': 'CZ'},
    {'label': 'Slovakça', 'value': 'sk', 'flag': 'SK'},
    {'label': 'Macarca', 'value': 'hu', 'flag': 'HU'},
    {'label': 'Rumence', 'value': 'ro', 'flag': 'RO'},
    {'label': 'Bulgarca', 'value': 'bg', 'flag': 'BG'},
    {'label': 'Hırvatça', 'value': 'hr', 'flag': 'HR'},
    {'label': 'Sırpça', 'value': 'sr', 'flag': 'RS'},
    {'label': 'Slovence', 'value': 'sl', 'flag': 'SI'},
    {'label': 'Litvanyaca', 'value': 'lt', 'flag': 'LT'},
    {'label': 'Letonca', 'value': 'lv', 'flag': 'LV'},
    {'label': 'Estonca', 'value': 'et', 'flag': 'EE'},
    {'label': 'Yunanca', 'value': 'el', 'flag': 'GR'},
    {'label': 'İbranice', 'value': 'he', 'flag': 'IL'},
    {'label': 'Tayca', 'value': 'th', 'flag': 'TH'},
    {'label': 'Vietnamca', 'value': 'vi', 'flag': 'VN'},
    {'label': 'Endonezce', 'value': 'id', 'flag': 'ID'},
    {'label': 'Malayca', 'value': 'ms', 'flag': 'MY'},
    {'label': 'Filipince', 'value': 'tl', 'flag': 'PH'},
    {'label': 'Ukraynaca', 'value': 'uk', 'flag': 'UA'},
    {'label': 'Belarusça', 'value': 'be', 'flag': 'BY'},
    {'label': 'Gürcüce', 'value': 'ka', 'flag': 'GE'},
    {'label': 'Ermenice', 'value': 'hy', 'flag': 'AM'},
    {'label': 'Azerbaycanca', 'value': 'az', 'flag': 'AZ'},
    {'label': 'Kazakça', 'value': 'kk', 'flag': 'KZ'},
    {'label': 'Özbekçe', 'value': 'uz', 'flag': 'UZ'},
    {'label': 'Kırgızca', 'value': 'ky', 'flag': 'KG'},
    {'label': 'Tacikçe', 'value': 'tg', 'flag': 'TJ'},
    {'label': 'Türkmence', 'value': 'tk', 'flag': 'TM'},
    {'label': 'Moğolca', 'value': 'mn', 'flag': 'MN'},
    {'label': 'Amharca', 'value': 'am', 'flag': 'ET'},
    {'label': 'Swahili', 'value': 'sw', 'flag': 'KE'},
    {'label': 'Hausa', 'value': 'ha', 'flag': 'NG'},
    {'label': 'Yoruba', 'value': 'yo', 'flag': 'NG'},
    {'label': 'Igbo', 'value': 'ig', 'flag': 'NG'},
    {'label': 'Zulu', 'value': 'zu', 'flag': 'ZA'},
    {'label': 'Afrikaans', 'value': 'af', 'flag': 'ZA'},
    {'label': 'Katalanca', 'value': 'ca', 'flag': 'ES'},
    {'label': 'Baskça', 'value': 'eu', 'flag': 'ES'},
    {'label': 'Galce', 'value': 'gl', 'flag': 'ES'},
    {'label': 'İrlandaca', 'value': 'ga', 'flag': 'IE'},
    {'label': 'İskoçça', 'value': 'gd', 'flag': 'GB'},
    {'label': 'Galce (Welsh)', 'value': 'cy', 'flag': 'GB'},
    {'label': 'İzlandaca', 'value': 'is', 'flag': 'IS'},
    {'label': 'Maltaca', 'value': 'mt', 'flag': 'MT'},
    {'label': 'Korsikaca', 'value': 'co', 'flag': 'FR'},
    {'label': 'Lüksemburgca', 'value': 'lb', 'flag': 'LU'},
    {'label': 'Esperanto', 'value': 'eo', 'flag': 'UN'},
    {'label': 'Latin', 'value': 'la', 'flag': 'VA'},
  ];

  List<Map<String, String>> get appLanguages => [
    {'label': 'Türkçe', 'value': 'tr', 'flag': 'TR'},
    {'label': 'English', 'value': 'en', 'flag': 'GB'},
    {'label': 'Deutsch', 'value': 'de', 'flag': 'DE'},
    {'label': 'Français', 'value': 'fr', 'flag': 'FR'},
    {'label': 'Español', 'value': 'es', 'flag': 'ES'},
    {'label': 'Italiano', 'value': 'it', 'flag': 'IT'},
    {'label': 'Português', 'value': 'pt', 'flag': 'PT'},
    {'label': 'Русский', 'value': 'ru', 'flag': 'RU'},
    {'label': '日本語', 'value': 'ja', 'flag': 'JP'},
    {'label': '한국어', 'value': 'ko', 'flag': 'KR'},
    {'label': '中文 (简体)', 'value': 'zh', 'flag': 'CN'},
    {'label': '中文 (繁體)', 'value': 'zh-tw', 'flag': 'TW'},
    {'label': 'العربية', 'value': 'ar', 'flag': 'SA'},
    {'label': 'हिन्दी', 'value': 'hi', 'flag': 'IN'},
    {'label': 'বাংলা', 'value': 'bn', 'flag': 'BD'},
    {'label': 'اردو', 'value': 'ur', 'flag': 'PK'},
    {'label': 'فارسی', 'value': 'fa', 'flag': 'IR'},
    {'label': 'Nederlands', 'value': 'nl', 'flag': 'NL'},
    {'label': 'Svenska', 'value': 'sv', 'flag': 'SE'},
    {'label': 'Norsk', 'value': 'no', 'flag': 'NO'},
    {'label': 'Dansk', 'value': 'da', 'flag': 'DK'},
    {'label': 'Suomi', 'value': 'fi', 'flag': 'FI'},
    {'label': 'Polski', 'value': 'pl', 'flag': 'PL'},
    {'label': 'Čeština', 'value': 'cs', 'flag': 'CZ'},
    {'label': 'Slovenčina', 'value': 'sk', 'flag': 'SK'},
    {'label': 'Magyar', 'value': 'hu', 'flag': 'HU'},
    {'label': 'Română', 'value': 'ro', 'flag': 'RO'},
    {'label': 'Български', 'value': 'bg', 'flag': 'BG'},
    {'label': 'Hrvatski', 'value': 'hr', 'flag': 'HR'},
    {'label': 'Српски', 'value': 'sr', 'flag': 'RS'},
    {'label': 'Slovenščina', 'value': 'sl', 'flag': 'SI'},
    {'label': 'Lietuvių', 'value': 'lt', 'flag': 'LT'},
    {'label': 'Latviešu', 'value': 'lv', 'flag': 'LV'},
    {'label': 'Eesti', 'value': 'et', 'flag': 'EE'},
    {'label': 'Ελληνικά', 'value': 'el', 'flag': 'GR'},
    {'label': 'עברית', 'value': 'he', 'flag': 'IL'},
    {'label': 'ไทย', 'value': 'th', 'flag': 'TH'},
    {'label': 'Tiếng Việt', 'value': 'vi', 'flag': 'VN'},
    {'label': 'Bahasa Indonesia', 'value': 'id', 'flag': 'ID'},
    {'label': 'Bahasa Melayu', 'value': 'ms', 'flag': 'MY'},
    {'label': 'Filipino', 'value': 'tl', 'flag': 'PH'},
    {'label': 'Українська', 'value': 'uk', 'flag': 'UA'},
    {'label': 'Беларуская', 'value': 'be', 'flag': 'BY'},
    {'label': 'ქართული', 'value': 'ka', 'flag': 'GE'},
    {'label': 'Հայերեն', 'value': 'hy', 'flag': 'AM'},
    {'label': 'Azərbaycan', 'value': 'az', 'flag': 'AZ'},
    {'label': 'Қазақ', 'value': 'kk', 'flag': 'KZ'},
    {'label': 'O\'zbek', 'value': 'uz', 'flag': 'UZ'},
    {'label': 'Кыргызча', 'value': 'ky', 'flag': 'KG'},
    {'label': 'Тоҷикӣ', 'value': 'tg', 'flag': 'TJ'},
    {'label': 'Türkmençe', 'value': 'tk', 'flag': 'TM'},
    {'label': 'Монгол', 'value': 'mn', 'flag': 'MN'},
    {'label': 'አማርኛ', 'value': 'am', 'flag': 'ET'},
    {'label': 'Kiswahili', 'value': 'sw', 'flag': 'KE'},
    {'label': 'Hausa', 'value': 'ha', 'flag': 'NG'},
    {'label': 'Yorùbá', 'value': 'yo', 'flag': 'NG'},
    {'label': 'Igbo', 'value': 'ig', 'flag': 'NG'},
    {'label': 'isiZulu', 'value': 'zu', 'flag': 'ZA'},
    {'label': 'Afrikaans', 'value': 'af', 'flag': 'ZA'},
    {'label': 'Català', 'value': 'ca', 'flag': 'ES'},
    {'label': 'Euskara', 'value': 'eu', 'flag': 'ES'},
    {'label': 'Galego', 'value': 'gl', 'flag': 'ES'},
    {'label': 'Gaeilge', 'value': 'ga', 'flag': 'IE'},
    {'label': 'Gàidhlig', 'value': 'gd', 'flag': 'GB'},
    {'label': 'Cymraeg', 'value': 'cy', 'flag': 'GB'},
    {'label': 'Íslenska', 'value': 'is', 'flag': 'IS'},
    {'label': 'Malti', 'value': 'mt', 'flag': 'MT'},
    {'label': 'Corsu', 'value': 'co', 'flag': 'FR'},
    {'label': 'Lëtzebuergesch', 'value': 'lb', 'flag': 'LU'},
    {'label': 'Esperanto', 'value': 'eo', 'flag': 'UN'},
    {'label': 'Latina', 'value': 'la', 'flag': 'VA'},
    ];
  
  // Geriye dönük uyumluluk için
  List<Map<String, String>> get languages => targetLanguages;
  
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
      case 'zh-tw':
        return _getChineseTraditionalText(key);
      case 'ar':
        return _getArabicText(key);
      case 'hi':
        return _getHindiText(key);
      case 'bn':
        return _getBengaliText(key);
      case 'ur':
        return _getUrduText(key);
      case 'fa':
        return _getPersianText(key);
      case 'nl':
        return _getDutchText(key);
      case 'sv':
        return _getSwedishText(key);
      case 'no':
        return _getNorwegianText(key);
      case 'da':
        return _getDanishText(key);
      case 'fi':
        return _getFinnishText(key);
      case 'pl':
        return _getPolishText(key);
      case 'cs':
        return _getCzechText(key);
      case 'sk':
        return _getSlovakText(key);
      case 'hu':
        return _getHungarianText(key);
      case 'ro':
        return _getRomanianText(key);
      case 'bg':
        return _getBulgarianText(key);
      case 'hr':
        return _getCroatianText(key);
      case 'sr':
        return _getSerbianText(key);
      case 'sl':
        return _getSlovenianText(key);
      case 'lt':
        return _getLithuanianText(key);
      case 'lv':
        return _getLatvianText(key);
      case 'et':
        return _getEstonianText(key);
      case 'el':
        return _getGreekText(key);
      case 'he':
        return _getHebrewText(key);
      case 'th':
        return _getThaiText(key);
      case 'vi':
        return _getVietnameseText(key);
      case 'id':
        return _getIndonesianText(key);
      case 'ms':
        return _getMalayText(key);
      case 'tl':
        return _getFilipinoText(key);
      case 'uk':
        return _getUkrainianText(key);
      case 'be':
        return _getBelarusianText(key);
      case 'ka':
        return _getGeorgianText(key);
      case 'hy':
        return _getArmenianText(key);
      case 'az':
        return _getAzerbaijaniText(key);
      case 'kk':
        return _getKazakhText(key);
      case 'uz':
        return _getUzbekText(key);
      case 'ky':
        return _getKyrgyzText(key);
      case 'tg':
        return _getTajikText(key);
      case 'tk':
        return _getTurkmenText(key);
      case 'mn':
        return _getMongolianText(key);
      case 'am':
        return _getAmharicText(key);
      case 'sw':
        return _getSwahiliText(key);
      case 'ha':
        return _getHausaText(key);
      case 'yo':
        return _getYorubaText(key);
      case 'ig':
        return _getIgboText(key);
      case 'zu':
        return _getZuluText(key);
      case 'af':
        return _getAfrikaansText(key);
      case 'ca':
        return _getCatalanText(key);
      case 'eu':
        return _getBasqueText(key);
      case 'gl':
        return _getGalicianText(key);
      case 'ga':
        return _getIrishText(key);
      case 'gd':
        return _getScottishText(key);
      case 'cy':
        return _getWelshText(key);
      case 'is':
        return _getIcelandicText(key);
      case 'mt':
        return _getMalteseText(key);
      case 'co':
        return _getCorsicanText(key);
      case 'lb':
        return _getLuxembourgishText(key);
      case 'eo':
        return _getEsperantoText(key);
      case 'la':
        return _getLatinText(key);
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
      case 'no_history_yet':
        return 'Henüz çeviri geçmişi yok';
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
      case 'type_message_hint':
        return 'Mesajınızı buraya yazın veya aşağıdaki mikrofonu kullanın';
      case 'text_pasted':
        return 'Metin yapıştırıldı ve çeviri için hazır';
      case 'no_text_clipboard':
        return 'Panoda metin bulunamadı';
      case 'paste':
        return 'Yapıştır';
      case 'speak_now':
        return 'Çeviri için şimdi konuşun';
      case 'speech_recognition':
        return 'Ses Tanıma';
      case 'stop_recording':
        return 'Kaydı Durdur';
      case 'ai_pro':
        return 'AI Pro';
      case 'translation_copied':
        return 'Çeviri panoya kopyalandı';
      case 'switch_to_standard':
        return 'Standart\'a Geç';
      case 'switch_to_ai_pro':
        return 'AI Pro\'ya Geç';
      case 'voice_translation_app':
        return 'Sesli Çeviri Uygulaması';
      case 'sign_in':
        return 'Giriş Yap';
      case 'access_account':
        return 'Hesabınıza erişin';
      case 'account':
        return 'Hesap';
      case 'manage_account':
        return 'Hesabınızı yönetin';
      case 'change_interface_language':
        return 'Arayüz dilini değiştirin';
      case 'rate_us':
        return 'Bizi Değerlendirin';
      case 'rate_on_playstore':
        return 'Voicely\'yi Play Store\'da değerlendirin';
      case 'share_app':
        return 'Uygulamayı Paylaş';
      case 'share_with_friends':
        return 'Voicely\'yi arkadaşlarınızla paylaşın';
      case 'privacy_policy':
        return 'Gizlilik Politikası';
      case 'view_privacy_policy':
        return 'Gizlilik politikamızı görüntüleyin';
      case 'app_version_info':
        return 'Uygulama versiyonu ve bilgileri';
      case 'report_bug':
        return 'Hata Bildir';
      case 'report_issues':
        return 'Sorunları veya geri bildirimleri bildirin';
      case 'account_options':
        return 'Hesap Seçenekleri';
      case 'account_type':
        return 'Hesap Türü';
      case 'pro':
        return 'Pro';
      case 'free':
        return 'Ücretsiz';
      case 'close':
        return 'Kapat';
      case 'sign_out':
        return 'Çıkış Yap';
      case 'search_languages':
        return 'Dilleri ara...';
      case 'language_changed_to':
        return 'Dil şuna değiştirildi';
      case 'premium_feature':
        return 'Premium Özellik';
      case 'camera_translation_pro_only':
        return 'Kamera çevirisi özelliği sadece Pro üyeler için kullanılabilir';
      case 'photo_translation':
        return 'Fotoğraf Çevirisi';
      case 'translate_photo_text':
        return 'Fotoğraftaki metinleri anında çevir';
      case 'ocr_technology':
        return 'OCR Teknolojisi';
      case 'advanced_text_recognition':
        return 'Gelişmiş metin tanıma sistemi';
      case 'multilang_support':
        return 'Çoklu Dil Desteği';
      case 'text_recognition_50_langs':
        return '50+ dilde metin tanıma';
      case 'upgrade_to_pro':
        return 'Pro\'ya Geçiş Yap';
      case 'later':
        return 'Daha Sonra';
      case 'better_translation':
        return 'Daha İyi Çeviri';
      case 'books':
        return 'Kitaplar';
      case 'expressions':
        return 'İfadeler';
      case 'verbs':
        return 'Fiiller';
      case 'basic':
        return 'Temel';
      case 'culture':
        return 'Kültür';
      case 'travel':
        return 'Seyahat';
      case 'technical':
        return 'Teknik';
      case 'objects':
        return 'Nesneler';
      case 'word_count':
        return 'kelime';
      case 'copy':
        return 'Kopyala';
      case 'share':
        return 'Paylaş';
      case 'word_copied':
        return 'Kelime kopyalandı';
      case 'example':
        return 'Örnek';
      case 'search_words':
        return 'Kelimeleri ara...';
      case 'no_words_found':
        return 'Kelime bulunamadı';
      case 'try_different_search':
        return 'Farklı bir arama deneyin';
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
      case 'type_message_hint':
        return 'Type your message here or use the microphone below';
      case 'text_pasted':
        return 'Text pasted and ready to translate';
      case 'no_text_clipboard':
        return 'No text found in clipboard';
      case 'paste':
        return 'Paste';
      case 'speak_now':
        return 'Speak now for translation';
      case 'speech_recognition':
        return 'Speech Recognition';
      case 'stop_recording':
        return 'Stop Recording';
      case 'ai_pro':
        return 'AI Pro';
      case 'translation_copied':
        return 'Translation copied to clipboard';
      case 'switch_to_standard':
        return 'Switch to Standard';
      case 'switch_to_ai_pro':
        return 'Switch to AI Pro';
      case 'voice_translation_app':
        return 'Voice Translation App';
      case 'sign_in':
        return 'Sign In';
      case 'access_account':
        return 'Access your account';
      case 'account':
        return 'Account';
      case 'manage_account':
        return 'Manage your account';
      case 'change_interface_language':
        return 'Change interface language';
      case 'rate_us':
        return 'Rate Us';
      case 'rate_on_playstore':
        return 'Rate Voicely on Play Store';
      case 'share_app':
        return 'Share App';
      case 'share_with_friends':
        return 'Share Voicely with friends';
      case 'privacy_policy':
        return 'Privacy Policy';
      case 'view_privacy_policy':
        return 'View our privacy policy';
      case 'app_version_info':
        return 'App version and info';
      case 'report_bug':
        return 'Report Bug';
      case 'report_issues':
        return 'Report issues or feedback';
      case 'account_options':
        return 'Account Options';
      case 'account_type':
        return 'Account Type';
      case 'pro':
        return 'Pro';
      case 'free':
        return 'Free';
      case 'close':
        return 'Close';
      case 'sign_out':
        return 'Sign Out';
      case 'search_languages':
        return 'Search languages...';
      case 'language_changed_to':
        return 'Language changed to';
      case 'premium_feature':
        return 'Premium Feature';
      case 'camera_translation_pro_only':
        return 'Camera translation feature is only available for Pro members';
      case 'photo_translation':
        return 'Photo Translation';
      case 'translate_photo_text':
        return 'Instantly translate text in photos';
      case 'ocr_technology':
        return 'OCR Technology';
      case 'advanced_text_recognition':
        return 'Advanced text recognition system';
      case 'multilang_support':
        return 'Multi-language Support';
      case 'text_recognition_50_langs':
        return 'Text recognition in 50+ languages';
      case 'upgrade_to_pro':
        return 'Upgrade to Pro';
      case 'later':
        return 'Later';
      case 'better_translation':
        return 'Better Translation';
      case 'books':
        return 'Books';
      case 'expressions':
        return 'Expressions';
      case 'verbs':
        return 'Verbs';
      case 'basic':
        return 'Basic';
      case 'culture':
        return 'Culture';
      case 'travel':
        return 'Travel';
      case 'technical':
        return 'Technical';
      case 'objects':
        return 'Objects';
      case 'word_count':
        return 'words';
      case 'copy':
        return 'Copy';
      case 'share':
        return 'Share';
      case 'word_copied':
        return 'Word copied';
      case 'example':
        return 'Example';
      case 'search_words':
        return 'Search words...';
      case 'no_words_found':
        return 'No words found';
      case 'try_different_search':
        return 'Try a different search';
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
      case 'type_message_hint':
        return 'Tapez votre message ici ou utilisez le microphone ci-dessous';
      case 'text_pasted':
        return 'Texte collé et prêt à traduire';
      case 'no_text_clipboard':
        return 'Aucun texte trouvé dans le presse-papiers';
      case 'paste':
        return 'Coller';
      case 'speak_now':
        return 'Parlez maintenant pour la traduction';
      case 'speech_recognition':
        return 'Reconnaissance vocale';
      case 'stop_recording':
        return 'Arrêter l\'enregistrement';
      case 'ai_pro':
        return 'IA Pro';
      case 'translation_copied':
        return 'Traduction copiée dans le presse-papiers';
      case 'switch_to_standard':
        return 'Passer au standard';
      case 'switch_to_ai_pro':
        return 'Passer à l\'IA Pro';
      case 'voice_translation_app':
        return 'Application de traduction vocale';
      case 'sign_in':
        return 'Se connecter';
      case 'access_account':
        return 'Accédez à votre compte';
      case 'account':
        return 'Compte';
      case 'manage_account':
        return 'Gérez votre compte';
      case 'change_interface_language':
        return 'Changer la langue de l\'interface';
      case 'rate_us':
        return 'Évaluez-nous';
      case 'rate_on_playstore':
        return 'Évaluez Voicely sur Play Store';
      case 'share_app':
        return 'Partager l\'application';
      case 'share_with_friends':
        return 'Partagez Voicely avec vos amis';
      case 'privacy_policy':
        return 'Politique de confidentialité';
      case 'view_privacy_policy':
        return 'Voir notre politique de confidentialité';
      case 'app_version_info':
        return 'Version et informations de l\'application';
      case 'report_bug':
        return 'Signaler un bug';
      case 'report_issues':
        return 'Signaler des problèmes ou des commentaires';
      case 'account_options':
        return 'Options du compte';
      case 'account_type':
        return 'Type de compte';
      case 'pro':
        return 'Pro';
      case 'free':
        return 'Gratuit';
      case 'close':
        return 'Fermer';
      case 'sign_out':
        return 'Se déconnecter';
      case 'search_languages':
        return 'Rechercher des langues...';
      case 'language_changed_to':
        return 'Langue changée en';
      case 'premium_feature':
        return 'Fonctionnalité premium';
      case 'camera_translation_pro_only':
        return 'La fonction de traduction par caméra n\'est disponible que pour les membres Pro';
      case 'photo_translation':
        return 'Traduction de photos';
      case 'translate_photo_text':
        return 'Traduisez instantanément le texte des photos';
      case 'ocr_technology':
        return 'Technologie OCR';
      case 'advanced_text_recognition':
        return 'Système de reconnaissance de texte avancé';
      case 'multilang_support':
        return 'Support multilingue';
      case 'text_recognition_50_langs':
        return 'Reconnaissance de texte dans plus de 50 langues';
      case 'upgrade_to_pro':
        return 'Passer à Pro';
      case 'later':
        return 'Plus tard';
      case 'better_translation':
        return 'Meilleure traduction';
      case 'books':
        return 'Livres';
      case 'expressions':
        return 'Expressions';
      case 'verbs':
        return 'Verbes';
      case 'basic':
        return 'Basique';
      case 'culture':
        return 'Culture';
      case 'travel':
        return 'Voyage';
      case 'technical':
        return 'Technique';
      case 'objects':
        return 'Objets';
      case 'word_count':
        return 'mots';
      case 'copy':
        return 'Copier';
      case 'share':
        return 'Partager';
      case 'word_copied':
        return 'Mot copié';
      case 'example':
        return 'Exemple';
      case 'search_words':
        return 'Rechercher des mots...';
      case 'no_words_found':
        return 'Aucun mot trouvé';
      case 'try_different_search':
        return 'Essayez une recherche différente';
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

  String _getItalianText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Traduci';
      case 'camera':
        return 'Fotocamera';
      case 'history':
        return 'Cronologia';
      case 'favorites':
        return 'Preferiti';
      case 'source_language':
        return 'Lingua di origine';
      case 'target_language':
        return 'Lingua di destinazione';
      case 'enter_text':
        return 'Inserisci testo...';
      case 'translation':
        return 'Traduzione...';
      case 'speak':
        return 'Parla';
      case 'read':
        return 'Leggi';
      case 'add_to_favorites':
        return 'Aggiungi ai preferiti';
      case 'remove_from_favorites':
        return 'Rimuovi dai preferiti';
      case 'settings':
        return 'Impostazioni';
      case 'app_language':
        return 'Lingua dell\'app';
      case 'select_language':
        return 'Seleziona lingua';
      default:
        return _getEnglishText(key);
    }
  }

  String _getPortugueseText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Traduzir';
      case 'camera':
        return 'Câmera';
      case 'history':
        return 'Histórico';
      case 'favorites':
        return 'Favoritos';
      case 'source_language':
        return 'Idioma de origem';
      case 'target_language':
        return 'Idioma de destino';
      case 'enter_text':
        return 'Digite o texto...';
      case 'translation':
        return 'Tradução...';
      case 'speak':
        return 'Falar';
      case 'read':
        return 'Ler';
      case 'add_to_favorites':
        return 'Adicionar aos favoritos';
      case 'remove_from_favorites':
        return 'Remover dos favoritos';
      case 'settings':
        return 'Configurações';
      case 'app_language':
        return 'Idioma do aplicativo';
      case 'select_language':
        return 'Selecionar idioma';
      default:
        return _getEnglishText(key);
    }
  }

  String _getRussianText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Перевести';
      case 'camera':
        return 'Камера';
      case 'history':
        return 'История';
      case 'favorites':
        return 'Избранное';
      case 'source_language':
        return 'Исходный язык';
      case 'target_language':
        return 'Целевой язык';
      case 'enter_text':
        return 'Введите текст...';
      case 'translation':
        return 'Перевод...';
      case 'speak':
        return 'Говорить';
      case 'read':
        return 'Читать';
      case 'add_to_favorites':
        return 'Добавить в избранное';
      case 'remove_from_favorites':
        return 'Удалить из избранного';
      case 'settings':
        return 'Настройки';
      case 'app_language':
        return 'Язык приложения';
      case 'select_language':
        return 'Выбрать язык';
      default:
        return _getEnglishText(key);
    }
  }

  String _getJapaneseText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return '翻訳';
      case 'camera':
        return 'カメラ';
      case 'history':
        return '履歴';
      case 'favorites':
        return 'お気に入り';
      case 'source_language':
        return '元の言語';
      case 'target_language':
        return '対象言語';
      case 'enter_text':
        return 'テキストを入力...';
      case 'translation':
        return '翻訳...';
      case 'speak':
        return '話す';
      case 'read':
        return '読む';
      case 'add_to_favorites':
        return 'お気に入りに追加';
      case 'remove_from_favorites':
        return 'お気に入りから削除';
      case 'settings':
        return '設定';
      case 'app_language':
        return 'アプリの言語';
      case 'select_language':
        return '言語を選択';
      default:
        return _getEnglishText(key);
    }
  }

  String _getKoreanText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return '번역';
      case 'camera':
        return '카메라';
      case 'history':
        return '기록';
      case 'favorites':
        return '즐겨찾기';
      case 'source_language':
        return '원본 언어';
      case 'target_language':
        return '대상 언어';
      case 'enter_text':
        return '텍스트 입력...';
      case 'translation':
        return '번역...';
      case 'speak':
        return '말하기';
      case 'read':
        return '읽기';
      case 'add_to_favorites':
        return '즐겨찾기에 추가';
      case 'remove_from_favorites':
        return '즐겨찾기에서 제거';
      case 'settings':
        return '설정';
      case 'app_language':
        return '앱 언어';
      case 'select_language':
        return '언어 선택';
      default:
        return _getEnglishText(key);
    }
  }

  String _getChineseText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return '翻译';
      case 'camera':
        return '相机';
      case 'history':
        return '历史';
      case 'favorites':
        return '收藏';
      case 'source_language':
        return '源语言';
      case 'target_language':
        return '目标语言';
      case 'enter_text':
        return '输入文本...';
      case 'translation':
        return '翻译...';
      case 'speak':
        return '说话';
      case 'read':
        return '阅读';
      case 'add_to_favorites':
        return '添加到收藏';
      case 'remove_from_favorites':
        return '从收藏中移除';
      case 'settings':
        return '设置';
      case 'app_language':
        return '应用语言';
      case 'select_language':
        return '选择语言';
      default:
        return _getEnglishText(key);
    }
  }

  String _getChineseTraditionalText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return '翻譯';
      case 'camera':
        return '相機';
      case 'history':
        return '歷史';
      case 'favorites':
        return '收藏';
      case 'source_language':
        return '源語言';
      case 'target_language':
        return '目標語言';
      case 'enter_text':
        return '輸入文本...';
      case 'translation':
        return '翻譯...';
      case 'speak':
        return '說話';
      case 'read':
        return '閱讀';
      case 'add_to_favorites':
        return '添加到收藏';
      case 'remove_from_favorites':
        return '從收藏中移除';
      case 'settings':
        return '設置';
      case 'app_language':
        return '應用語言';
      case 'select_language':
        return '選擇語言';
      default:
        return _getEnglishText(key);
    }
  }

  String _getArabicText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'ترجم';
      case 'camera':
        return 'الكاميرا';
      case 'history':
        return 'التاريخ';
      case 'favorites':
        return 'المفضلة';
      case 'source_language':
        return 'اللغة المصدر';
      case 'target_language':
        return 'اللغة الهدف';
      case 'enter_text':
        return 'أدخل النص...';
      case 'translation':
        return 'الترجمة...';
      case 'speak':
        return 'تحدث';
      case 'read':
        return 'اقرأ';
      case 'add_to_favorites':
        return 'إضافة إلى المفضلة';
      case 'remove_from_favorites':
        return 'إزالة من المفضلة';
      case 'settings':
        return 'الإعدادات';
      case 'app_language':
        return 'لغة التطبيق';
      case 'select_language':
        return 'اختر اللغة';
      default:
        return _getEnglishText(key);
    }
  }

  String _getHindiText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'अनुवाद करें';
      case 'camera':
        return 'कैमरा';
      case 'history':
        return 'इतिहास';
      case 'favorites':
        return 'पसंदीदा';
      case 'source_language':
        return 'स्रोत भाषा';
      case 'target_language':
        return 'लक्ष्य भाषा';
      case 'enter_text':
        return 'टेक्स्ट दर्ज करें...';
      case 'translation':
        return 'अनुवाद...';
      case 'speak':
        return 'बोलें';
      case 'read':
        return 'पढ़ें';
      case 'add_to_favorites':
        return 'पसंदीदा में जोड़ें';
      case 'remove_from_favorites':
        return 'पसंदीदा से हटाएं';
      case 'settings':
        return 'सेटिंग्स';
      case 'app_language':
        return 'ऐप भाषा';
      case 'select_language':
        return 'भाषा चुनें';
      default:
        return _getEnglishText(key);
    }
  }

  String _getDutchText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Vertalen';
      case 'camera':
        return 'Camera';
      case 'history':
        return 'Geschiedenis';
      case 'favorites':
        return 'Favorieten';
      case 'source_language':
        return 'Brontaal';
      case 'target_language':
        return 'Doeltaal';
      case 'enter_text':
        return 'Voer tekst in...';
      case 'translation':
        return 'Vertaling...';
      case 'speak':
        return 'Spreken';
      case 'read':
        return 'Lezen';
      case 'add_to_favorites':
        return 'Toevoegen aan favorieten';
      case 'remove_from_favorites':
        return 'Verwijderen uit favorieten';
      case 'settings':
        return 'Instellingen';
      case 'app_language':
        return 'App-taal';
      case 'select_language':
        return 'Taal selecteren';
      default:
        return _getEnglishText(key);
    }
  }

  String _getPolishText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Tłumacz';
      case 'camera':
        return 'Kamera';
      case 'history':
        return 'Historia';
      case 'favorites':
        return 'Ulubione';
      case 'source_language':
        return 'Język źródłowy';
      case 'target_language':
        return 'Język docelowy';
      case 'enter_text':
        return 'Wprowadź tekst...';
      case 'translation':
        return 'Tłumaczenie...';
      case 'speak':
        return 'Mów';
      case 'read':
        return 'Czytaj';
      case 'add_to_favorites':
        return 'Dodaj do ulubionych';
      case 'remove_from_favorites':
        return 'Usuń z ulubionych';
      case 'settings':
        return 'Ustawienia';
      case 'app_language':
        return 'Język aplikacji';
      case 'select_language':
        return 'Wybierz język';
      default:
        return _getEnglishText(key);
    }
  }

  String _getUkrainianText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Перекласти';
      case 'camera':
        return 'Камера';
      case 'history':
        return 'Історія';
      case 'favorites':
        return 'Обране';
      case 'source_language':
        return 'Мова джерела';
      case 'target_language':
        return 'Цільова мова';
      case 'enter_text':
        return 'Введіть текст...';
      case 'translation':
        return 'Переклад...';
      case 'speak':
        return 'Говорити';
      case 'read':
        return 'Читати';
      case 'add_to_favorites':
        return 'Додати в обране';
      case 'remove_from_favorites':
        return 'Видалити з обраного';
      case 'settings':
        return 'Налаштування';
      case 'app_language':
        return 'Мова додатку';
      case 'select_language':
        return 'Вибрати мову';
      default:
        return _getEnglishText(key);
    }
  }

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
            _textController.text = result.recognizedWords; // Sync with text field
            _isRecording = false;
            notifyListeners();
            _debounceTranslate();
          } else {
            // Show partial results in text field during recording
            _textController.text = result.recognizedWords;
            notifyListeners(); // Update UI to show partial results
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
      case 'zh-tw':
        return 'zh-TW';
      case 'ar':
        return 'ar-SA';
      case 'hi':
        return 'hi-IN';
      case 'bn':
        return 'bn-BD';
      case 'ur':
        return 'ur-PK';
      case 'fa':
        return 'fa-IR';
      case 'nl':
        return 'nl-NL';
      case 'sv':
        return 'sv-SE';
      case 'no':
        return 'no-NO';
      case 'da':
        return 'da-DK';
      case 'fi':
        return 'fi-FI';
      case 'pl':
        return 'pl-PL';
      case 'cs':
        return 'cs-CZ';
      case 'sk':
        return 'sk-SK';
      case 'hu':
        return 'hu-HU';
      case 'ro':
        return 'ro-RO';
      case 'bg':
        return 'bg-BG';
      case 'hr':
        return 'hr-HR';
      case 'sr':
        return 'sr-RS';
      case 'sl':
        return 'sl-SI';
      case 'lt':
        return 'lt-LT';
      case 'lv':
        return 'lv-LV';
      case 'et':
        return 'et-EE';
      case 'el':
        return 'el-GR';
      case 'he':
        return 'he-IL';
      case 'th':
        return 'th-TH';
      case 'vi':
        return 'vi-VN';
      case 'id':
        return 'id-ID';
      case 'ms':
        return 'ms-MY';
      case 'tl':
        return 'tl-PH';
      case 'uk':
        return 'uk-UA';
      case 'be':
        return 'be-BY';
      case 'ka':
        return 'ka-GE';
      case 'hy':
        return 'hy-AM';
      case 'az':
        return 'az-AZ';
      case 'kk':
        return 'kk-KZ';
      case 'uz':
        return 'uz-UZ';
      case 'ky':
        return 'ky-KG';
      case 'tg':
        return 'tg-TJ';
      case 'tk':
        return 'tk-TM';
      case 'mn':
        return 'mn-MN';
      case 'am':
        return 'am-ET';
      case 'sw':
        return 'sw-KE';
      case 'ha':
        return 'ha-NG';
      case 'yo':
        return 'yo-NG';
      case 'ig':
        return 'ig-NG';
      case 'zu':
        return 'zu-ZA';
      case 'af':
        return 'af-ZA';
      case 'ca':
        return 'ca-ES';
      case 'eu':
        return 'eu-ES';
      case 'gl':
        return 'gl-ES';
      case 'ga':
        return 'ga-IE';
      case 'gd':
        return 'gd-GB';
      case 'cy':
        return 'cy-GB';
      case 'is':
        return 'is-IS';
      case 'mt':
        return 'mt-MT';
      case 'co':
        return 'co-FR';
      case 'lb':
        return 'lb-LU';
      case 'eo':
        return 'eo-XX';
      case 'la':
        return 'la-VA';
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
    
    // Eğer metin boşsa çeviriyi de temizle
    if (text.isEmpty) {
      _translatedText = '';
      _isTranslating = false;
    }
    
    notifyListeners();
    _debounceTranslate();
  }

  void _debounceTranslate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (_inputText.isNotEmpty) {
        translateText();
      } else {
        // Metin boşsa çeviriyi temizle
        _translatedText = '';
        _isTranslating = false;
        notifyListeners();
      }
    });
  }

  void setFromLang(String lang) {
    _fromLang = lang;
    if (lang != 'auto') {
      _detectedLanguage = null; // Auto detect değilse temizle
    }
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

  void clearTranslation() {
    _translatedText = '';
    _isTranslating = false;
    notifyListeners();
  }

  Future<void> translateText([String? text]) async {
    final textToTranslate = text ?? _inputText;
    if (textToTranslate.isEmpty) return;
    
    // Update input text if provided
    if (text != null && text != _inputText) {
      _inputText = text;
    }
    
    _isTranslating = true;
    notifyListeners();
    
    try {
      if (_translationModel == 'ai_pro' && _isProUser) {
        // AI Pro çeviri (GPT-4 benzeri)
        await _translateWithAI(textToTranslate);
      } else {
        // Standard çeviri
        await _translateWithStandard(textToTranslate);
      }
    } catch (e) {
      // Fallback olarak MyMemory API kullan
      await _translateWithMyMemory(textToTranslate);
    }
    
    _isTranslating = false;
    
    // Save translation to Supabase if user is authenticated
    await _saveTranslationToSupabase();
    
    notifyListeners();
  }
  
  Future<void> _translateWithStandard(String textToTranslate) async {
    String sourceLanguage = _fromLang;
    
    // Auto detect için dil tespiti yap
    if (_fromLang == 'auto') {
      sourceLanguage = await _detectLanguage(textToTranslate);
      _detectedLanguage = sourceLanguage;
      notifyListeners(); // UI'ı güncelle
    } else {
      _detectedLanguage = null; // Auto detect değilse temizle
    }
    
    // LibreTranslate API kullanımı (ücretsiz)
    final response = await http.post(
      Uri.parse('https://libretranslate.de/translate'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'q': textToTranslate,
        'source': sourceLanguage,
        'target': _toLang,
        'format': 'text',
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['translatedText'] != null) {
        _translatedText = data['translatedText'];
        _addToHistory();
        _updateFavoriteStatus();
        
        // Çeviri tamamlandığında hedef dilden metni oku
        await speak(_translatedText, _toLang);
      } else {
        _translatedText = 'Çeviri bulunamadı';
      }
    } else {
      // Fallback olarak MyMemory API kullan
      await _translateWithMyMemory(textToTranslate);
    }
  }
  
  Future<void> _translateWithAI(String textToTranslate) async {
    // Simüle edilmiş AI çeviri - gerçek uygulamada GPT-4 API kullanılacak
    await Future.delayed(const Duration(milliseconds: 1500)); // AI düşünme simülasyonu
    
    // Daha doğal çeviri örnekleri
    Map<String, Map<String, String>> aiTranslations = {
      'tr': {
        'emin misin': 'Are you sure?',
        'nasılsın': 'How are you doing?',
        'ne yapıyorsun': 'What are you up to?',
        'görüşürüz': 'See you later',
        'iyi geceler': 'Good night',
        'günaydın': 'Good morning',
        'teşekkürler': 'Thank you so much',
        'rica ederim': 'You\'re welcome',
        'özür dilerim': 'I apologize',
        'merhaba': 'Hello there',
      },
      'en': {
        'hello': 'Merhaba',
        'how are you': 'Nasılsın?',
        'thank you': 'Teşekkür ederim',
        'good morning': 'Günaydın',
        'good night': 'İyi geceler',
        'see you later': 'Görüşürüz',
        'are you sure': 'Emin misin?',
        'what are you doing': 'Ne yapıyorsun?',
        'you\'re welcome': 'Rica ederim',
        'i apologize': 'Özür dilerim',
      }
    };
    
    String lowerInput = textToTranslate.toLowerCase();
    String? aiResult;
    
    // AI çeviri arama
    if (aiTranslations.containsKey(_fromLang)) {
      for (String key in aiTranslations[_fromLang]!.keys) {
        if (lowerInput.contains(key)) {
          aiResult = aiTranslations[_fromLang]![key];
          break;
        }
      }
    }
    
    if (aiResult != null) {
      _translatedText = aiResult;
    } else {
      // Fallback to standard translation
      await _translateWithStandard(textToTranslate);
      return;
    }
    
    _addToHistory();
    _updateFavoriteStatus();
    
    // Çeviri tamamlandığında hedef dilden metni oku
    await speak(_translatedText, _toLang);
  }

  /// Basit dil tespiti - gerçek uygulamada Google Translate Detect API kullanılabilir
  Future<String> _detectLanguage(String text) async {
    try {
      // MyMemory API'sı ile dil tespiti
      final response = await http.get(
        Uri.parse('https://api.mymemory.translated.net/get')
            .replace(queryParameters: {
          'q': text,
          'langpair': 'auto|en', // Auto detect to English
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Eğer matches varsa, ilk match'in source language'ini al
        if (data['matches'] != null && data['matches'].isNotEmpty) {
          String? detectedLang = data['matches'][0]['source'];
          if (detectedLang != null && detectedLang.isNotEmpty) {
            return detectedLang;
          }
        }
      }
    } catch (e) {
      print('Language detection error: $e');
    }
    
    // Fallback: Basit karaktere dayalı tahmin
    return _guessLanguageFromText(text);
  }
  
  /// Metin karakterlerine dayalı basit dil tahmini
  String _guessLanguageFromText(String text) {
    final cleanText = text.toLowerCase();
    
    // Türkçe karakterler
    if (cleanText.contains(RegExp(r'[çğıöşüÇĞIİÖŞÜ]'))) {
      return 'tr';
    }
    
    // Arapça karakterler
    if (cleanText.contains(RegExp(r'[\u0600-\u06FF]'))) {
      return 'ar';
    }
    
    // Çince karakterler
    if (cleanText.contains(RegExp(r'[\u4e00-\u9fff]'))) {
      return 'zh';
    }
    
    // Japonca karakterler (Hiragana, Katakana)
    if (cleanText.contains(RegExp(r'[\u3040-\u309f\u30a0-\u30ff]'))) {
      return 'ja';
    }
    
    // Korece karakterler
    if (cleanText.contains(RegExp(r'[\uac00-\ud7af]'))) {
      return 'ko';
    }
    
    // Rusça karakterler
    if (cleanText.contains(RegExp(r'[а-яё]'))) {
      return 'ru';
    }
    
    // Yunanca karakterler
    if (cleanText.contains(RegExp(r'[α-ωάέήίόύώ]'))) {
      return 'el';
    }
    
    // Varsayılan olarak İngilizce
    return 'en';
  }

  Future<void> _translateWithMyMemory([String? text]) async {
    final textToTranslate = text ?? _inputText;
    try {
      String sourceLanguage = _fromLang;
      
      // Auto detect için dil tespiti yap
      if (_fromLang == 'auto') {
        sourceLanguage = await _detectLanguage(textToTranslate);
        _detectedLanguage = sourceLanguage;
        notifyListeners(); // UI'ı güncelle
      } else {
        _detectedLanguage = null; // Auto detect değilse temizle
      }
      
      final response = await http.get(
        Uri.parse('https://api.mymemory.translated.net/get')
            .replace(queryParameters: {
          'q': textToTranslate,
          'langpair': '$sourceLanguage|$_toLang',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['responseData'] != null && data['responseData']['translatedText'] != null) {
          _translatedText = data['responseData']['translatedText'];
          _addToHistory();
          _updateFavoriteStatus();
          
          // Çeviri tamamlandığında hedef dilden metni oku
          await speak(_translatedText, _toLang);
        } else {
          _translatedText = 'Çeviri bulunamadı';
        }
      } else {
        _translatedText = 'Çeviri hatası: ${response.statusCode}';
      }
    } catch (e) {
      _translatedText = 'Çeviri hatası: $e';
    }
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

  /// Save translation to Supabase if user is authenticated
  Future<void> _saveTranslationToSupabase() async {
    try {
      // Check if user is authenticated
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      // Save to translation_history table
      await Supabase.instance.client.from('translation_history').insert({
        'user_id': currentUser.id,
        'source_text': _inputText,
        'translated_text': _translatedText,
        'source_language': _fromLang == 'auto' ? _detectedLanguage ?? 'auto' : _fromLang,
        'target_language': _toLang,
        'translation_model': _translationModel,
        'is_favorite': _isCurrentTranslationFavorited,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save translation to Supabase: $e');
      }
    }
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
    // Önceki speak işlemini iptal et
    _speakDebounceTimer?.cancel();
    
    // 1 saniye bekle ve sonra konuş
    _speakDebounceTimer = Timer(const Duration(seconds: 1), () async {
    try {
      await _flutterTts.setLanguage(_getTtsLanguage(language));
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking: $e');
    }
    });
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
      case 'zh-tw':
        return 'zh-TW';
      case 'ar':
        return 'ar-SA';
      case 'hi':
        return 'hi-IN';
      case 'bn':
        return 'bn-BD';
      case 'ur':
        return 'ur-PK';
      case 'fa':
        return 'fa-IR';
      case 'nl':
        return 'nl-NL';
      case 'sv':
        return 'sv-SE';
      case 'no':
        return 'no-NO';
      case 'da':
        return 'da-DK';
      case 'fi':
        return 'fi-FI';
      case 'pl':
        return 'pl-PL';
      case 'cs':
        return 'cs-CZ';
      case 'sk':
        return 'sk-SK';
      case 'hu':
        return 'hu-HU';
      case 'ro':
        return 'ro-RO';
      case 'bg':
        return 'bg-BG';
      case 'hr':
        return 'hr-HR';
      case 'sr':
        return 'sr-RS';
      case 'sl':
        return 'sl-SI';
      case 'lt':
        return 'lt-LT';
      case 'lv':
        return 'lv-LV';
      case 'et':
        return 'et-EE';
      case 'el':
        return 'el-GR';
      case 'he':
        return 'he-IL';
      case 'th':
        return 'th-TH';
      case 'vi':
        return 'vi-VN';
      case 'id':
        return 'id-ID';
      case 'ms':
        return 'ms-MY';
      case 'tl':
        return 'tl-PH';
      case 'uk':
        return 'uk-UA';
      case 'be':
        return 'be-BY';
      case 'ka':
        return 'ka-GE';
      case 'hy':
        return 'hy-AM';
      case 'az':
        return 'az-AZ';
      case 'kk':
        return 'kk-KZ';
      case 'uz':
        return 'uz-UZ';
      case 'ky':
        return 'ky-KG';
      case 'tg':
        return 'tg-TJ';
      case 'tk':
        return 'tk-TM';
      case 'mn':
        return 'mn-MN';
      case 'am':
        return 'am-ET';
      case 'sw':
        return 'sw-KE';
      case 'ha':
        return 'ha-NG';
      case 'yo':
        return 'yo-NG';
      case 'ig':
        return 'ig-NG';
      case 'zu':
        return 'zu-ZA';
      case 'af':
        return 'af-ZA';
      case 'ca':
        return 'ca-ES';
      case 'eu':
        return 'eu-ES';
      case 'gl':
        return 'gl-ES';
      case 'ga':
        return 'ga-IE';
      case 'gd':
        return 'gd-GB';
      case 'cy':
        return 'cy-GB';
      case 'is':
        return 'is-IS';
      case 'mt':
        return 'mt-MT';
      case 'co':
        return 'co-FR';
      case 'lb':
        return 'lb-LU';
      case 'eo':
        return 'eo-XX';
      case 'la':
        return 'la-VA';
      default:
        return 'en-US';
    }
  }

  // Eksik dil fonksiyonları
  String _getBengaliText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'অনুবাদ';
      case 'camera':
        return 'ক্যামেরা';
      case 'history':
        return 'ইতিহাস';
      case 'favorites':
        return 'প্রিয়';
      case 'source_language':
        return 'উৎস ভাষা';
      case 'target_language':
        return 'লক্ষ্য ভাষা';
      case 'enter_text':
        return 'টেক্সট লিখুন...';
      case 'translation':
        return 'অনুবাদ...';
      case 'speak':
        return 'কথা বলুন';
      case 'read':
        return 'পড়ুন';
      case 'add_to_favorites':
        return 'প্রিয়তে যোগ করুন';
      case 'remove_from_favorites':
        return 'প্রিয় থেকে সরান';
      case 'camera_translation':
        return 'ক্যামেরা অনুবাদ';
      case 'coming_soon':
        return 'শীঘ্রই আসছে...';
      case 'text_recognition':
        return 'টেক্সট স্বীকৃতি এবং অনুবাদ বৈশিষ্ট্য';
      case 'translation_history':
        return 'অনুবাদ ইতিহাস';
      case 'view_recent_translations':
        return 'আপনার সাম্প্রতিক অনুবাদগুলি দেখুন';
      case 'my_favorites':
        return 'আমার প্রিয়';
      case 'no_favorites_yet':
        return 'এখনও কোন প্রিয় নেই';
      case 'add_favorites_description':
        return 'আপনার অনুবাদগুলি প্রিয়তে যোগ করুন\nপরে সহজে অ্যাক্সেস করতে';
      case 'add_from_translate_page':
        return 'অনুবাদ পৃষ্ঠা থেকে প্রিয় যোগ করুন';
      case 'clear_history':
        return 'ইতিহাস মুছুন';
      case 'clear_history_confirm':
        return 'আপনি কি নিশ্চিত যে আপনি সমস্ত ইতিহাস মুছতে চান?';
      case 'cancel':
        return 'বাতিল';
      case 'confirm':
        return 'নিশ্চিত করুন';
      case 'settings':
        return 'সেটিংস';
      case 'language':
        return 'ভাষা';
      case 'app_language':
        return 'অ্যাপ ভাষা';
      case 'select_language':
        return 'ভাষা নির্বাচন করুন';
      case 'about':
        return 'সম্পর্কে';
      case 'version':
        return 'সংস্করণ';
      case 'developed_by':
        return 'দ্বারা বিকশিত';
      case 'privacy_policy':
        return 'গোপনীয়তা নীতি';
      case 'terms_of_service':
        return 'সেবার শর্তাবলী';
      default:
        return _getEnglishText(key);
    }
  }

  String _getUrduText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'ترجمہ';
      case 'camera':
        return 'کیمرا';
      case 'history':
        return 'تاریخ';
      case 'favorites':
        return 'پسندیدہ';
      case 'source_language':
        return 'ماخذ زبان';
      case 'target_language':
        return 'ہدف زبان';
      case 'enter_text':
        return 'ٹیکسٹ درج کریں...';
      case 'translation':
        return 'ترجمہ...';
      case 'speak':
        return 'بولنا';
      case 'read':
        return 'پڑھنا';
      case 'add_to_favorites':
        return 'پسندیدہ میں شامل کریں';
      case 'remove_from_favorites':
        return 'پسندیدہ سے ہٹائیں';
      case 'camera_translation':
        return 'کیمرا ترجمہ';
      case 'coming_soon':
        return 'جلد آ رہا ہے...';
      case 'text_recognition':
        return 'ٹیکسٹ شناخت اور ترجمہ خصوصیت';
      case 'translation_history':
        return 'ترجمہ کی تاریخ';
      case 'view_recent_translations':
        return 'اپنے حالیہ تراجم دیکھیں';
      case 'my_favorites':
        return 'میری پسندیدہ';
      case 'no_favorites_yet':
        return 'ابھی تک کوئی پسندیدہ نہیں';
      case 'add_favorites_description':
        return 'اپنے تراجم کو پسندیدہ میں شامل کریں\nبعد میں آسانی سے رسائی حاصل کرنے کے لیے';
      case 'add_from_translate_page':
        return 'ترجمہ صفحہ سے پسندیدہ شامل کریں';
      case 'clear_history':
        return 'تاریخ صاف کریں';
      case 'clear_history_confirm':
        return 'کیا آپ یقینی ہیں کہ آپ تمام تاریخ صاف کرنا چاہتے ہیں؟';
      case 'cancel':
        return 'منسوخ';
      case 'confirm':
        return 'تصدیق کریں';
      case 'settings':
        return 'ترتیبات';
      case 'language':
        return 'زبان';
      case 'app_language':
        return 'ایپ زبان';
      case 'select_language':
        return 'زبان منتخب کریں';
      case 'about':
        return 'کے بارے میں';
      case 'version':
        return 'ورژن';
      case 'developed_by':
        return 'کی طرف سے تیار';
      case 'privacy_policy':
        return 'رازداری کی پالیسی';
      case 'terms_of_service':
        return 'سروس کی شرائط';
      default:
        return _getEnglishText(key);
    }
  }

  String _getPersianText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'ترجمه';
      case 'camera':
        return 'دوربین';
      case 'history':
        return 'تاریخچه';
      case 'favorites':
        return 'مورد علاقه';
      case 'source_language':
        return 'زبان مبدا';
      case 'target_language':
        return 'زبان مقصد';
      case 'enter_text':
        return 'متن را وارد کنید...';
      case 'translation':
        return 'ترجمه...';
      case 'speak':
        return 'صحبت کردن';
      case 'read':
        return 'خواندن';
      case 'add_to_favorites':
        return 'به مورد علاقه اضافه کنید';
      case 'remove_from_favorites':
        return 'از مورد علاقه حذف کنید';
      case 'camera_translation':
        return 'ترجمه دوربین';
      case 'coming_soon':
        return 'به زودی...';
      case 'text_recognition':
        return 'ویژگی تشخیص متن و ترجمه';
      case 'translation_history':
        return 'تاریخچه ترجمه';
      case 'view_recent_translations':
        return 'ترجمه‌های اخیر خود را مشاهده کنید';
      case 'my_favorites':
        return 'مورد علاقه‌های من';
      case 'no_favorites_yet':
        return 'هنوز مورد علاقه‌ای وجود ندارد';
      case 'add_favorites_description':
        return 'ترجمه‌های خود را به مورد علاقه اضافه کنید\nبرای دسترسی آسان بعداً';
      case 'add_from_translate_page':
        return 'از صفحه ترجمه مورد علاقه اضافه کنید';
      case 'clear_history':
        return 'پاک کردن تاریخچه';
      case 'clear_history_confirm':
        return 'آیا مطمئن هستید که می‌خواهید تمام تاریخچه را پاک کنید؟';
      case 'cancel':
        return 'لغو';
      case 'confirm':
        return 'تایید';
      case 'settings':
        return 'تنظیمات';
      case 'language':
        return 'زبان';
      case 'app_language':
        return 'زبان برنامه';
      case 'select_language':
        return 'زبان را انتخاب کنید';
      case 'about':
        return 'درباره';
      case 'version':
        return 'نسخه';
      case 'developed_by':
        return 'توسعه یافته توسط';
      case 'privacy_policy':
        return 'سیاست حفظ حریم خصوصی';
      case 'terms_of_service':
        return 'شرایط خدمات';
      default:
        return _getEnglishText(key);
    }
  }

  String _getSwedishText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Översätt';
      case 'camera':
        return 'Kamera';
      case 'history':
        return 'Historik';
      case 'favorites':
        return 'Favoriter';
      case 'source_language':
        return 'Källspråk';
      case 'target_language':
        return 'Målspråk';
      case 'enter_text':
        return 'Ange text...';
      case 'translation':
        return 'Översättning...';
      case 'speak':
        return 'Tala';
      case 'read':
        return 'Läs';
      case 'add_to_favorites':
        return 'Lägg till i favoriter';
      case 'remove_from_favorites':
        return 'Ta bort från favoriter';
      case 'camera_translation':
        return 'Kameraöversättning';
      case 'coming_soon':
        return 'Kommer snart...';
      case 'text_recognition':
        return 'Textigenkänning och översättningsfunktion';
      case 'translation_history':
        return 'Översättningshistorik';
      case 'view_recent_translations':
        return 'Visa dina senaste översättningar';
      case 'my_favorites':
        return 'Mina favoriter';
      case 'no_favorites_yet':
        return 'Inga favoriter än';
      case 'add_favorites_description':
        return 'Lägg till dina översättningar i favoriter\nför enkel åtkomst senare';
      case 'add_from_translate_page':
        return 'Lägg till favorit från översättningssidan';
      case 'clear_history':
        return 'Rensa historik';
      case 'clear_history_confirm':
        return 'Är du säker på att du vill rensa all historik?';
      case 'cancel':
        return 'Avbryt';
      case 'confirm':
        return 'Bekräfta';
      case 'settings':
        return 'Inställningar';
      case 'language':
        return 'Språk';
      case 'app_language':
        return 'App-språk';
      case 'select_language':
        return 'Välj språk';
      case 'about':
        return 'Om';
      case 'version':
        return 'Version';
      case 'developed_by':
        return 'Utvecklad av';
      case 'privacy_policy':
        return 'Integritetspolicy';
      case 'terms_of_service':
        return 'Användarvillkor';
      default:
        return _getEnglishText(key);
    }
  }

  String _getNorwegianText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Oversett';
      case 'camera':
        return 'Kamera';
      case 'history':
        return 'Historikk';
      case 'favorites':
        return 'Favoritter';
      case 'source_language':
        return 'Kildespråk';
      case 'target_language':
        return 'Målspråk';
      case 'enter_text':
        return 'Skriv inn tekst...';
      case 'translation':
        return 'Oversettelse...';
      case 'speak':
        return 'Snakk';
      case 'read':
        return 'Les';
      case 'add_to_favorites':
        return 'Legg til i favoritter';
      case 'remove_from_favorites':
        return 'Fjern fra favoritter';
      case 'camera_translation':
        return 'Kameraoversettelse';
      case 'coming_soon':
        return 'Kommer snart...';
      case 'text_recognition':
        return 'Tekstgjenkjenning og oversettelsesfunksjon';
      case 'translation_history':
        return 'Oversettelseshistorikk';
      case 'view_recent_translations':
        return 'Se dine siste oversettelser';
      case 'my_favorites':
        return 'Mine favoritter';
      case 'no_favorites_yet':
        return 'Ingen favoritter ennå';
      case 'add_favorites_description':
        return 'Legg til oversettelsene dine i favoritter\nfor enkel tilgang senere';
      case 'add_from_translate_page':
        return 'Legg til favoritt fra oversettelsessiden';
      case 'clear_history':
        return 'Tøm historikk';
      case 'clear_history_confirm':
        return 'Er du sikker på at du vil tømme all historikk?';
      case 'cancel':
        return 'Avbryt';
      case 'confirm':
        return 'Bekreft';
      case 'settings':
        return 'Innstillinger';
      case 'language':
        return 'Språk';
      case 'app_language':
        return 'App-språk';
      case 'select_language':
        return 'Velg språk';
      case 'about':
        return 'Om';
      case 'version':
        return 'Versjon';
      case 'developed_by':
        return 'Utviklet av';
      case 'privacy_policy':
        return 'Personvernpolicy';
      case 'terms_of_service':
        return 'Brukervilkår';
      default:
        return _getEnglishText(key);
    }
  }

  String _getDanishText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Oversæt';
      case 'camera':
        return 'Kamera';
      case 'history':
        return 'Historik';
      case 'favorites':
        return 'Favoritter';
      case 'source_language':
        return 'Kildesprog';
      case 'target_language':
        return 'Målsprog';
      case 'enter_text':
        return 'Indtast tekst...';
      case 'translation':
        return 'Oversættelse...';
      case 'speak':
        return 'Tal';
      case 'read':
        return 'Læs';
      case 'add_to_favorites':
        return 'Tilføj til favoritter';
      case 'remove_from_favorites':
        return 'Fjern fra favoritter';
      case 'camera_translation':
        return 'Kameraoversættelse';
      case 'coming_soon':
        return 'Kommer snart...';
      case 'text_recognition':
        return 'Tekstgenkendelse og oversættelsesfunktion';
      case 'translation_history':
        return 'Oversættelseshistorik';
      case 'view_recent_translations':
        return 'Se dine seneste oversættelser';
      case 'my_favorites':
        return 'Mine favoritter';
      case 'no_favorites_yet':
        return 'Ingen favoritter endnu';
      case 'add_favorites_description':
        return 'Tilføj dine oversættelser til favoritter\nfor nem adgang senere';
      case 'add_from_translate_page':
        return 'Tilføj favorit fra oversættelsessiden';
      case 'clear_history':
        return 'Ryd historik';
      case 'clear_history_confirm':
        return 'Er du sikker på, at du vil rydde al historik?';
      case 'cancel':
        return 'Annuller';
      case 'confirm':
        return 'Bekræft';
      case 'settings':
        return 'Indstillinger';
      case 'language':
        return 'Sprog';
      case 'app_language':
        return 'App-sprog';
      case 'select_language':
        return 'Vælg sprog';
      case 'about':
        return 'Om';
      case 'version':
        return 'Version';
      case 'developed_by':
        return 'Udviklet af';
      case 'privacy_policy':
        return 'Privatlivspolitik';
      case 'terms_of_service':
        return 'Brugervilkår';
      default:
        return _getEnglishText(key);
    }
  }

  String _getFinnishText(String key) {
    switch (key) {
      case 'app_title':
        return 'Voicely';
      case 'translate':
        return 'Käännä';
      case 'camera':
        return 'Kamera';
      case 'history':
        return 'Historia';
      case 'favorites':
        return 'Suosikit';
      case 'source_language':
        return 'Lähdekieli';
      case 'target_language':
        return 'Kohdekieli';
      case 'enter_text':
        return 'Kirjoita teksti...';
      case 'translation':
        return 'Käännös...';
      case 'speak':
        return 'Puhu';
      case 'read':
        return 'Lue';
      case 'add_to_favorites':
        return 'Lisää suosikkeihin';
      case 'remove_from_favorites':
        return 'Poista suosikeista';
      case 'camera_translation':
        return 'Kamerakäännös';
      case 'coming_soon':
        return 'Tulossa pian...';
      case 'text_recognition':
        return 'Tekstintunnistus ja käännösominaisuus';
      case 'translation_history':
        return 'Käännöshistoria';
      case 'view_recent_translations':
        return 'Katso viimeisimmät käännöksesi';
      case 'my_favorites':
        return 'Suosikkini';
      case 'no_favorites_yet':
        return 'Ei vielä suosikkeja';
      case 'add_favorites_description':
        return 'Lisää käännöksesi suosikkeihin\nhelppoa pääsyä varten myöhemmin';
      case 'add_from_translate_page':
        return 'Lisää suosikki käännössivulta';
      case 'clear_history':
        return 'Tyhjennä historia';
      case 'clear_history_confirm':
        return 'Oletko varma, että haluat tyhjentää kaiken historian?';
      case 'cancel':
        return 'Peruuta';
      case 'confirm':
        return 'Vahvista';
      case 'settings':
        return 'Asetukset';
      case 'language':
        return 'Kieli';
      case 'app_language':
        return 'Sovelluksen kieli';
      case 'select_language':
        return 'Valitse kieli';
      case 'about':
        return 'Tietoja';
      case 'version':
        return 'Versio';
      case 'developed_by':
        return 'Kehittänyt';
      case 'privacy_policy':
        return 'Tietosuojakäytäntö';
      case 'terms_of_service':
        return 'Käyttöehdot';
      default:
        return _getEnglishText(key);
    }
  }

  // Pro mode kontrol fonksiyonları
  void toggleProMode() {
    _isProUser = !_isProUser;
    notifyListeners();
  }
  
  void setTranslationModel(String model) {
    if (_isProUser) {
      _translationModel = model;
      notifyListeners();
    }
  }
  
  void toggleTranslationModel() {
    if (_isProUser) {
      _translationModel = _translationModel == 'standard' ? 'ai_pro' : 'standard';
      notifyListeners();
    }
  }
  
  void setWhisperUsage(bool useWhisper) {
    _useWhisper = useWhisper;
    notifyListeners();
  }
  
  bool canUseAIPro() {
    return _isProUser;
  }
  
  // Diğer eksik diller için placeholder fonksiyonlar
  String _getCzechText(String key) => _getEnglishText(key);
  String _getSlovakText(String key) => _getEnglishText(key);
  String _getHungarianText(String key) => _getEnglishText(key);
  String _getRomanianText(String key) => _getEnglishText(key);
  String _getBulgarianText(String key) => _getEnglishText(key);
  String _getCroatianText(String key) => _getEnglishText(key);
  String _getSerbianText(String key) => _getEnglishText(key);
  String _getSlovenianText(String key) => _getEnglishText(key);
  String _getLithuanianText(String key) => _getEnglishText(key);
  String _getLatvianText(String key) => _getEnglishText(key);
  String _getEstonianText(String key) => _getEnglishText(key);
  String _getGreekText(String key) => _getEnglishText(key);
  String _getHebrewText(String key) => _getEnglishText(key);
  String _getThaiText(String key) => _getEnglishText(key);
  String _getVietnameseText(String key) => _getEnglishText(key);
  String _getIndonesianText(String key) => _getEnglishText(key);
  String _getMalayText(String key) => _getEnglishText(key);
  String _getFilipinoText(String key) => _getEnglishText(key);
  String _getBelarusianText(String key) => _getEnglishText(key);
  String _getGeorgianText(String key) => _getEnglishText(key);
  String _getArmenianText(String key) => _getEnglishText(key);
  String _getAzerbaijaniText(String key) => _getEnglishText(key);
  String _getKazakhText(String key) => _getEnglishText(key);
  String _getUzbekText(String key) => _getEnglishText(key);
  String _getKyrgyzText(String key) => _getEnglishText(key);
  String _getTajikText(String key) => _getEnglishText(key);
  String _getTurkmenText(String key) => _getEnglishText(key);
  String _getMongolianText(String key) => _getEnglishText(key);
  String _getAmharicText(String key) => _getEnglishText(key);
  String _getSwahiliText(String key) => _getEnglishText(key);
  String _getHausaText(String key) => _getEnglishText(key);
  String _getYorubaText(String key) => _getEnglishText(key);
  String _getIgboText(String key) => _getEnglishText(key);
  String _getZuluText(String key) => _getEnglishText(key);
  String _getAfrikaansText(String key) => _getEnglishText(key);
  String _getCatalanText(String key) => _getEnglishText(key);
  String _getBasqueText(String key) => _getEnglishText(key);
  String _getGalicianText(String key) => _getEnglishText(key);
  String _getIrishText(String key) => _getEnglishText(key);
  String _getScottishText(String key) => _getEnglishText(key);
  String _getWelshText(String key) => _getEnglishText(key);
  String _getIcelandicText(String key) => _getEnglishText(key);
  String _getMalteseText(String key) => _getEnglishText(key);
  String _getCorsicanText(String key) => _getEnglishText(key);
  String _getLuxembourgishText(String key) => _getEnglishText(key);
  String _getEsperantoText(String key) => _getEnglishText(key);
  String _getLatinText(String key) => _getEnglishText(key);

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _historyDebounceTimer?.cancel();
    _speakDebounceTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }
} 