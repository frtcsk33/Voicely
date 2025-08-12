import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import '../providers/translator_provider.dart';
import '../widgets/searchable_language_dropdown.dart';
import '../widgets/app_drawer.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({Key? key}) : super(key: key);

  @override
  _TranslatorScreenState createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TranslatorProvider>();
      _inputController.addListener(() {
        provider.setInputText(_inputController.text);
      });
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        // Input controller'ı provider'dan güncelle
        if (provider.inputText != _inputController.text) {
          _inputController.text = provider.inputText;
        }
        
        // Çeviri sonucunu output controller'a set et
        if (provider.translatedText != _outputController.text) {
          _outputController.text = provider.translatedText;
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          drawer: const AppDrawer(),
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
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
                      // Drawer Menu Button
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Source Language Dropdown
                      Expanded(
                        child: SearchableLanguageDropdown(
                          value: provider.fromLang,
                          hint: 'Kaynak Dil',
                          languages: provider.languages,
                          onChanged: (value, name) => provider.setFromLang(value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Swap Button
                      GestureDetector(
                        onTap: () => provider.swapLanguages(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Icon(
                            Icons.swap_horiz,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Target Language Dropdown
                      Expanded(
                        child: SearchableLanguageDropdown(
                          value: provider.toLang,
                          hint: 'Hedef Dil',
                          languages: provider.languages,
                          onChanged: (value, name) => provider.setToLang(value),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Source Language Text Area
                        Container(
                          height: 200,
                          child: _buildTextArea(
                            label: _getLanguageName(provider.fromLang, provider.languages),
                            controller: _inputController,
                            isInput: true,
                            onStopRecord: () => provider.stopRecording(),
                            backgroundColor: Colors.white,
                            borderColor: Colors.grey[300]!,
                            showMicButton: true,
                            context: context,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Target Language Text Area
                        Container(
                          height: 200,
                          child: _buildTextArea(
                            label: _getLanguageName(provider.toLang, provider.languages),
                            controller: _outputController,
                            isInput: false,
                            onStopRecord: null,
                            backgroundColor: Colors.white,
                            borderColor: Colors.grey[300]!,
                            showActionButtons: true,
                            context: context,
                          ),
                        ),
                        
                        // Extra space for keyboard
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  String _getLocalizedLanguageName(String langCode, TranslatorProvider provider) {
    // Basit çözüm: Tüm diller için İngilizce isimleri döndür
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
      default: return 'Unknown';
    }
  }

  Widget _buildTextArea({
    required String label,
    required TextEditingController controller,
    required bool isInput,
    required VoidCallback? onStopRecord,
    required Color backgroundColor,
    required Color borderColor,
    bool showActionButtons = false,
    bool showRecordingButton = false,
    bool showMicButton = false,
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with Flag
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                                 // Flag
                 Flag.fromString(
                   _getFlagCode(label),
                   height: 20,
                   width: 30,
                   borderRadius: 4,
                 ),
                const SizedBox(width: 8),
                // Language name
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          
          // Main text area
          Expanded(
            child: Column(
              children: [
                // TextField
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: controller,
                            maxLines: null,
                            minLines: isInput ? 6 : 5,
                            enabled: isInput,
                            textAlignVertical: TextAlignVertical.top,
                            textInputAction: TextInputAction.newline,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            enableInteractiveSelection: true,
                            autocorrect: true,
                            enableSuggestions: true,
                            smartDashesType: SmartDashesType.enabled,
                            smartQuotesType: SmartQuotesType.enabled,
                            style: TextStyle(
                              fontSize: 16,
                              color: isInput ? Colors.black87 : Colors.grey[700],
                              fontFamily: 'Roboto',
                              height: 1.2,
                            ),
                            decoration: InputDecoration(
                              hintText: isInput ? 'Metin girin...' : 'Çeviri...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Clear button
                      if (isInput && controller.text.isNotEmpty)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            iconSize: 20,
                            color: Colors.grey[600],
                            tooltip: 'Clear text',
                            onPressed: () => controller.clear(),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Buttons
                if (isInput && showMicButton)
                  Container(
                    height: 50,
                    margin: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildRecordingButton(() => Provider.of<TranslatorProvider>(context, listen: false).stopRecording()),
                        if (controller.text.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          _buildFavoriteStar(),
                          const SizedBox(width: 12),
                          _buildReadButton(controller.text),
                        ],
                      ],
                    ),
                  ),
                
                if (showActionButtons)
                  Container(
                    height: 40,
                    margin: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildTranslationActions(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingButton(VoidCallback? onStopRecord) {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: provider.isRecording 
              ? onStopRecord 
              : () => provider.startRecording(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: provider.isRecording 
                  ? LinearGradient(
                      colors: [Colors.red[400]!, Colors.red[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: provider.isRecording 
                      ? Colors.red.withOpacity(0.4)
                      : Colors.blue.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 2,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (provider.isRecording)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    provider.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    key: ValueKey(provider.isRecording),
                    color: Colors.white,
                    size: 24,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTranslationActions() {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        if (provider.translatedText.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  _copyToClipboard(provider.translatedText);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Metin panoya kopyalandı',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.green[600],
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(
                  Icons.copy,
                  color: Colors.blue[600],
                  size: 18,
                ),
                tooltip: 'Kopyala',
              ),
              IconButton(
                onPressed: () => _shareText(provider.translatedText),
                icon: Icon(
                  Icons.share,
                  color: Colors.green[600],
                  size: 18,
                ),
                tooltip: 'Paylaş',
              ),
              IconButton(
                onPressed: () => provider.speak(provider.translatedText, provider.toLang),
                icon: Icon(
                  Icons.volume_up,
                  color: Colors.orange[600],
                  size: 18,
                ),
                tooltip: 'Oku',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadButton(String text) {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => provider.speak(text, provider.fromLang),
            icon: Icon(
              Icons.volume_up,
              color: Colors.orange[600],
              size: 20,
            ),
            tooltip: 'Oku',
          ),
        );
      },
    );
  }

  Widget _buildFavoriteStar() {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              provider.toggleFavorite();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    provider.isCurrentTranslationFavorited
                        ? 'Favorilere eklendi'
                        : 'Favorilerden çıkarıldı',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: provider.isCurrentTranslationFavorited 
                      ? Colors.green[600] 
                      : Colors.orange[600],
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(
              provider.isCurrentTranslationFavorited 
                  ? Icons.star 
                  : Icons.star_border,
              color: provider.isCurrentTranslationFavorited 
                  ? Colors.amber[600] 
                  : Colors.grey[600],
              size: 22,
            ),
            tooltip: 'Favorilere Ekle',
          ),
        );
      },
    );
  }

  String _getLanguageName(String langCode, List<Map<String, String>> languages) {
    final language = languages.firstWhere(
      (lang) => lang['value'] == langCode,
      orElse: () => {'label': 'Bilinmeyen Dil'},
    );
    return language['label'] ?? 'Bilinmeyen Dil';
  }

  String _getFlagCode(String languageName) {
    // Dil adına göre bayrak kodu döndür
    switch (languageName.toLowerCase()) {
      case 'ingilizce':
      case 'english':
        return 'GB';
      case 'türkçe':
      case 'turkish':
        return 'TR';
      case 'italyanca':
      case 'italian':
        return 'IT';
      case 'almanca':
      case 'german':
        return 'DE';
      case 'fransızca':
      case 'french':
        return 'FR';
      case 'ispanyolca':
      case 'spanish':
        return 'ES';
      case 'portekizce':
      case 'portuguese':
        return 'PT';
      case 'rusça':
      case 'russian':
        return 'RU';
      case 'japonca':
      case 'japanese':
        return 'JP';
      case 'korece':
      case 'korean':
        return 'KR';
      case 'çince (basitleştirilmiş)':
      case 'chinese (simplified)':
        return 'CN';
      case 'çince (geleneksel)':
      case 'chinese (traditional)':
        return 'TW';
      case 'arapça':
      case 'arabic':
        return 'SA';
      case 'hintçe':
      case 'hindi':
        return 'IN';
      case 'bengalce':
      case 'bengali':
        return 'BD';
      case 'urduca':
      case 'urdu':
        return 'PK';
      case 'farsça':
      case 'persian':
        return 'IR';
      case 'hollandaca':
      case 'dutch':
        return 'NL';
      case 'isveççe':
      case 'swedish':
        return 'SE';
      case 'norveççe':
      case 'norwegian':
        return 'NO';
      case 'danca':
      case 'danish':
        return 'DK';
      case 'fince':
      case 'finnish':
        return 'FI';
      case 'lehçe':
      case 'polish':
        return 'PL';
      case 'çekçe':
      case 'czech':
        return 'CZ';
      case 'slovakça':
      case 'slovak':
        return 'SK';
      case 'macarca':
      case 'hungarian':
        return 'HU';
      case 'rumence':
      case 'romanian':
        return 'RO';
      case 'bulgarca':
      case 'bulgarian':
        return 'BG';
      case 'hırvatça':
      case 'croatian':
        return 'HR';
      case 'sırpça':
      case 'serbian':
        return 'RS';
      case 'slovence':
      case 'slovenian':
        return 'SI';
      case 'litvanyaca':
      case 'lithuanian':
        return 'LT';
      case 'letonca':
      case 'latvian':
        return 'LV';
      case 'estonca':
      case 'estonian':
        return 'EE';
      case 'yunanca':
      case 'greek':
        return 'GR';
      case 'ibranice':
      case 'hebrew':
        return 'IL';
      case 'tayca':
      case 'thai':
        return 'TH';
      case 'vietnamca':
      case 'vietnamese':
        return 'VN';
      case 'endonezce':
      case 'indonesian':
        return 'ID';
      case 'malayca':
      case 'malay':
        return 'MY';
      case 'filipince':
      case 'filipino':
        return 'PH';
      case 'ukraynaca':
      case 'ukrainian':
        return 'UA';
      case 'belarusça':
      case 'belarusian':
        return 'BY';
      case 'kazakça':
      case 'kazakh':
        return 'KZ';
      case 'özbekçe':
      case 'uzbek':
        return 'UZ';
      case 'kırgızca':
      case 'kyrgyz':
        return 'KG';
      case 'tacikçe':
      case 'tajik':
        return 'TJ';
      case 'türkmence':
      case 'turkmen':
        return 'TM';
      case 'moğolca':
      case 'mongolian':
        return 'MN';
      default:
        return 'UN'; // Unknown flag
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  void _shareText(String text) {
    Share.share(
      text,
      subject: 'Voicely Translate',
    );
  }
} 