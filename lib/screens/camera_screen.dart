import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flag/flag.dart';
import 'dart:io';
import '../providers/translator_provider.dart';
import '../widgets/app_drawer.dart';
import 'pro_subscription_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  String _recognizedText = '';
  String _translatedText = '';
  bool _isProcessing = false;
  bool _isTranslating = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          context.read<TranslatorProvider>().getLocalizedText('camera_translation'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          // OCR History Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                _showOCRHistory(context);
              },
              icon: Icon(
                Icons.image_search_rounded,
                color: Colors.grey.shade700,
                size: 28,
              ),
              tooltip: 'OCR History',
            ),
          ),
        ],
      ),
      body: Consumer<TranslatorProvider>(
        builder: (context, provider, child) {
          // Pro olmayan kullanıcılar için paywall göster
          if (!provider.isProUser) {
            return _buildProPaywall(context);
          }
          
          return Column(
            children: [
              // Dil seçimi
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                                                         child: Text(
                               context.read<TranslatorProvider>().getLocalizedText('target_language'),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                                                     _buildLanguageDropdown(
                             context,
                             context.read<TranslatorProvider>().getLocalizedText('target_language'),
                            provider.toLang,
                            (value) => provider.setToLang(value!),
                            provider.languages,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Ana içerik
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Fotoğraf seçimi
                      if (_selectedImage == null)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(60),
                                    border: Border.all(color: Colors.blue[200]!, width: 2),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 60,
                                    color: Colors.blue[600],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Fotoğraf Seçin',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Kameradan çekin veya galeriden seçin',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _takePhoto(),
                                      icon: const Icon(Icons.camera_alt),
                                      label: Text(
                                        'Fotoğraf Çek',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[600],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _selectFromGallery(),
                                      icon: const Icon(Icons.photo_library),
                                      label: Text(
                                        'Galeriden Seç',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[600],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Seçilen fotoğraf ve sonuçlar
                      if (_selectedImage != null)
                        Expanded(
                          child: Column(
                            children: [
                              // Fotoğraf
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb
                                      ? Image.network(
                                          _selectedImage!.path,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Tanınan metin
                              if (_recognizedText.isNotEmpty)
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tanınan Metin:',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            child: Text(
                                              _recognizedText,
                                              style: GoogleFonts.poppins(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              
                              // Çeviri
                              if (_translatedText.isNotEmpty)
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Çeviri:',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              onPressed: () => _speakTranslation(),
                                              icon: Icon(
                                                Icons.volume_up,
                                                color: Colors.green[600],
                                              ),
                                              tooltip: 'Oku',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            child: Text(
                                              _translatedText,
                                              style: GoogleFonts.poppins(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              
                              // Butonlar
                              if (_recognizedText.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _isTranslating ? null : () => _translateText(),
                                          icon: _isTranslating
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.translate),
                                          label: Text(
                                            _isTranslating ? 'Çeviriliyor...' : 'Çevir',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[600],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: () => _resetScreen(),
                                        icon: const Icon(Icons.refresh),
                                        label: Text(
                                          'Yeni',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[600],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageDropdown(
    BuildContext context,
    String label,
    String value,
    Function(String?) onChanged,
    List<Map<String, String>> languages,
  ) {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              items: languages
                  .map((lang) => DropdownMenuItem(
                        value: lang['value'],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Flag.fromString(
                                lang['flag'] ?? 'UN',
                                height: 18,
                                width: 28,
                                borderRadius: 3,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getLocalizedLanguageName(lang['value']!, provider),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
              dropdownColor: Colors.white,
              menuMaxHeight: 300,
            ),
          ),
        );
      },
    );
  }

  String _getLocalizedLanguageName(String langCode, TranslatorProvider provider) {
    // Uygulama diline göre dil isimlerini döndür
    switch (provider.appLanguage) {
      case 'tr':
        return _getTurkishLanguageName(langCode);
      case 'en':
        return _getEnglishLanguageName(langCode);
      default:
        return _getEnglishLanguageName(langCode); // Varsayılan olarak İngilizce
    }
  }

  String _getTurkishLanguageName(String langCode) {
    switch (langCode) {
      case 'tr': return 'Türkçe';
      case 'en': return 'İngilizce';
      case 'de': return 'Almanca';
      case 'fr': return 'Fransızca';
      case 'es': return 'İspanyolca';
      case 'it': return 'İtalyanca';
      case 'pt': return 'Portekizce';
      case 'ru': return 'Rusça';
      case 'ja': return 'Japonca';
      case 'ko': return 'Korece';
      case 'zh': return 'Çince (Basitleştirilmiş)';
      case 'zh-tw': return 'Çince (Geleneksel)';
      case 'ar': return 'Arapça';
      case 'hi': return 'Hintçe';
      case 'nl': return 'Hollandaca';
      case 'sv': return 'İsveççe';
      case 'no': return 'Norveççe';
      case 'da': return 'Danca';
      case 'fi': return 'Fince';
      case 'pl': return 'Lehçe';
      case 'cs': return 'Çekçe';
      case 'sk': return 'Slovakça';
      case 'hu': return 'Macarca';
      case 'ro': return 'Rumence';
      case 'bg': return 'Bulgarca';
      case 'hr': return 'Hırvatça';
      case 'sr': return 'Sırpça';
      case 'sl': return 'Slovence';
      case 'lt': return 'Litvanyaca';
      case 'lv': return 'Letonca';
      case 'et': return 'Estonca';
      case 'el': return 'Yunanca';
      case 'he': return 'İbranice';
      case 'th': return 'Tayca';
      case 'vi': return 'Vietnamca';
      case 'id': return 'Endonezce';
      case 'ms': return 'Malayca';
      case 'fil': return 'Filipince';
      case 'bn': return 'Bengalce';
      case 'ur': return 'Urduca';
      case 'fa': return 'Farsça';
      case 'uk': return 'Ukraynaca';
      case 'be': return 'Belarusça';
      case 'kk': return 'Kazakça';
      case 'uz': return 'Özbekçe';
      case 'ky': return 'Kırgızca';
      case 'tg': return 'Tacikçe';
      case 'tk': return 'Türkmence';
      case 'mn': return 'Moğolca';
      case 'am': return 'Amharca';
      case 'sw': return 'Svahili';
      case 'ha': return 'Hausa';
      case 'yo': return 'Yoruba';
      case 'ig': return 'İgbo';
      case 'zu': return 'Zulu';
      case 'af': return 'Afrikaanca';
      case 'ca': return 'Katalanca';
      case 'eu': return 'Baskça';
      case 'gl': return 'Galiçyaca';
      case 'ga': return 'İrlandaca';
      case 'gd': return 'İskoç Galcesi';
      case 'cy': return 'Galce';
      case 'is': return 'İzlandaca';
      case 'mt': return 'Maltaca';
      case 'co': return 'Korsikaca';
      case 'lb': return 'Lüksemburgca';
      case 'eo': return 'Esperanto';
      case 'la': return 'Latince';
      default: return 'Bilinmeyen Dil';
    }
  }

  String _getEnglishLanguageName(String langCode) {
    switch (langCode) {
      case 'tr': return 'Turkish';
      case 'en': return 'English';
      case 'de': return 'German';
      case 'fr': return 'French';
      case 'es': return 'Spanish';
      case 'it': return 'Italian';
      case 'pt': return 'Portuguese';
      case 'ru': return 'Russian';
      case 'ja': return 'Japanese';
      case 'ko': return 'Korean';
      case 'zh': return 'Chinese (Simplified)';
      case 'zh-tw': return 'Chinese (Traditional)';
      case 'ar': return 'Arabic';
      case 'hi': return 'Hindi';
      case 'nl': return 'Dutch';
      case 'sv': return 'Swedish';
      case 'no': return 'Norwegian';
      case 'da': return 'Danish';
      case 'fi': return 'Finnish';
      case 'pl': return 'Polish';
      case 'cs': return 'Czech';
      case 'sk': return 'Slovak';
      case 'hu': return 'Hungarian';
      case 'ro': return 'Romanian';
      case 'bg': return 'Bulgarian';
      case 'hr': return 'Croatian';
      case 'sr': return 'Serbian';
      case 'sl': return 'Slovenian';
      case 'lt': return 'Lithuanian';
      case 'lv': return 'Latvian';
      case 'et': return 'Estonian';
      case 'el': return 'Greek';
      case 'he': return 'Hebrew';
      case 'th': return 'Thai';
      case 'vi': return 'Vietnamese';
      case 'id': return 'Indonesian';
      case 'ms': return 'Malay';
      case 'fil': return 'Filipino';
      case 'bn': return 'Bengali';
      case 'ur': return 'Urdu';
      case 'fa': return 'Persian';
      case 'uk': return 'Ukrainian';
      case 'be': return 'Belarusian';
      case 'kk': return 'Kazakh';
      case 'uz': return 'Uzbek';
      case 'ky': return 'Kyrgyz';
      case 'tg': return 'Tajik';
      case 'tk': return 'Turkmen';
      case 'mn': return 'Mongolian';
      case 'am': return 'Amharic';
      case 'sw': return 'Swahili';
      case 'ha': return 'Hausa';
      case 'yo': return 'Yoruba';
      case 'ig': return 'Igbo';
      case 'zu': return 'Zulu';
      case 'af': return 'Afrikaans';
      case 'ca': return 'Catalan';
      case 'eu': return 'Basque';
      case 'gl': return 'Galician';
      case 'ga': return 'Irish';
      case 'gd': return 'Scottish Gaelic';
      case 'cy': return 'Welsh';
      case 'is': return 'Icelandic';
      case 'mt': return 'Maltese';
      case 'co': return 'Corsican';
      case 'lb': return 'Luxembourgish';
      case 'eo': return 'Esperanto';
      case 'la': return 'Latin';
      default: return 'Unknown Language';
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
          _recognizedText = '';
          _translatedText = '';
        });
        await _recognizeText();
      }
    } catch (e) {
      _showErrorDialog('Kamera erişimi hatası: $e');
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _recognizedText = '';
          _translatedText = '';
        });
        await _recognizeText();
      }
    } catch (e) {
      _showErrorDialog('Galeri erişimi hatası: $e');
    }
  }

  Future<void> _recognizeText() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Web'de metin tanıma özelliği henüz desteklenmiyor
      // Bu yüzden placeholder metin gösteriyoruz
      if (kIsWeb) {
        setState(() {
          _recognizedText = 'Web\'de metin tanıma özelliği henüz desteklenmiyor. Lütfen mobil uygulamayı kullanın.';
          _isProcessing = false;
        });
        return;
      }

      // Mobil için gerçek metin tanıma kodu buraya gelecek
      setState(() {
        _recognizedText = 'Metin tanıma özelliği yakında gelecek...';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Metin tanıma hatası: $e');
    }
  }

  Future<void> _translateText() async {
    if (_recognizedText.isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final provider = context.read<TranslatorProvider>();
      final response = await provider.translateTextFromImage(_recognizedText, provider.toLang);
      
      setState(() {
        _translatedText = response;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _isTranslating = false;
      });
      _showErrorDialog('Çeviri hatası: $e');
    }
  }

  Future<void> _speakTranslation() async {
    if (_translatedText.isEmpty) return;

    try {
      final provider = context.read<TranslatorProvider>();
      await provider.speak(_translatedText, provider.toLang);
    } catch (e) {
      _showErrorDialog('Ses çalma hatası: $e');
    }
  }

  void _resetScreen() {
    setState(() {
      _selectedImage = null;
      _recognizedText = '';
      _translatedText = '';
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Hata',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tamam',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProPaywall(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue[50]!,
            Colors.white,
            Colors.purple[50]!,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                     MediaQuery.of(context).padding.top - 
                     kToolbarHeight,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          // Premium Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.purple[400]!],
              ),
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 60,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            context.read<TranslatorProvider>().getLocalizedText('premium_feature'),
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              context.read<TranslatorProvider>().getLocalizedText('camera_translation_pro_only'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Features List
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildFeatureItem(
                  icon: Icons.camera_alt,
                  title: context.read<TranslatorProvider>().getLocalizedText('photo_translation'),
                  description: context.read<TranslatorProvider>().getLocalizedText('translate_photo_text'),
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  icon: Icons.text_fields,
                  title: context.read<TranslatorProvider>().getLocalizedText('ocr_technology'),
                  description: context.read<TranslatorProvider>().getLocalizedText('advanced_text_recognition'),
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  icon: Icons.language,
                  title: context.read<TranslatorProvider>().getLocalizedText('multilang_support'),
                  description: context.read<TranslatorProvider>().getLocalizedText('text_recognition_50_langs'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Upgrade Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProSubscriptionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch),
                  const SizedBox(width: 12),
                  Text(
                    context.read<TranslatorProvider>().getLocalizedText('upgrade_to_pro'),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Skip Button
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              context.read<TranslatorProvider>().getLocalizedText('later'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.blue[600],
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showOCRHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      enableDrag: true,
      builder: (context) => _OCRHistoryModal(),
    );
  }
}

class _OCRHistoryModal extends StatefulWidget {
  @override
  State<_OCRHistoryModal> createState() => _OCRHistoryModalState();
}

class _OCRHistoryModalState extends State<_OCRHistoryModal> {
  // Mock OCR history data - in a real app, this would come from a provider or database
  final List<Map<String, dynamic>> _ocrHistory = [
    {
      'id': '1',
      'recognizedText': 'Hello World',
      'translatedText': 'Merhaba Dünya',
      'sourceLanguage': 'en',
      'targetLanguage': 'tr',
      'timestamp': DateTime.now().subtract(Duration(minutes: 5)),
      'imagePath': null,
    },
    {
      'id': '2',
      'recognizedText': 'Welcome to our restaurant',
      'translatedText': 'Restaurantımıza hoş geldiniz',
      'sourceLanguage': 'en',
      'targetLanguage': 'tr',
      'timestamp': DateTime.now().subtract(Duration(hours: 2)),
      'imagePath': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.image_search_rounded,
                    color: Colors.orange.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'OCR Translation History',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // History List
          Expanded(
            child: _ocrHistory.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.orange.shade200, width: 2),
                        ),
                        child: Icon(
                          Icons.image_search,
                          size: 40,
                          color: Colors.orange.shade400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No OCR translations yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Translate images to see your OCR history here',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _ocrHistory.length,
                  itemBuilder: (context, index) {
                    final item = _ocrHistory[index];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with OCR indicator
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        color: Colors.orange.shade600,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'OCR',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.orange.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTime(item['timestamp']),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Recognized text
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.text_fields_rounded,
                                        color: Colors.grey.shade600,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Recognized Text',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['recognizedText'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Translated text
                            if (item['translatedText'].isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.translate_rounded,
                                          color: Colors.blue.shade600,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Translation',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.blue.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['translatedText'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 8),
                            
                            // Language indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item['sourceLanguage'].toUpperCase()} → ${item['targetLanguage'].toUpperCase()}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
} 