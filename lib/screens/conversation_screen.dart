import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import '../providers/conversation_provider.dart';
import '../providers/translator_provider.dart';
import '../widgets/conversation_panel.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Conversation Mode',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ConversationProvider>().clearConversation();
            },
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: Consumer2<ConversationProvider, TranslatorProvider>(
        builder: (context, conversationProvider, translatorProvider, child) {
          return SafeArea(
            child: Column(
              children: [
                // Header (same style as translator_screen)
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
                      // Source Language Dropdown
                      Expanded(
                        child: _buildLanguageDropdown(
                          context,
                          'Kaynak Dil',
                          conversationProvider.language1,
                          (value) => conversationProvider.setLanguage1(value!, _getLanguageName(value!, translatorProvider.languages)),
                          translatorProvider.languages,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Swap Button
                      GestureDetector(
                        onTap: () => conversationProvider.swapLanguages(),
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
                        child: _buildLanguageDropdown(
                          context,
                          'Hedef Dil',
                          conversationProvider.language2,
                          (value) => conversationProvider.setLanguage2(value!, _getLanguageName(value!, translatorProvider.languages)),
                          translatorProvider.languages,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Conversation panels with flexible height
                Expanded(
                  child: Column(
                    children: [
                      // Top panel (Language 1 -> Language 2)
                      Flexible(
                        flex: 1,
                        child: ConversationPanel(
                          isTopPanel: true,
                          sourceLanguage: conversationProvider.language1,
                          targetLanguage: conversationProvider.language2,
                          sourceLanguageName: conversationProvider.language1Name,
                          targetLanguageName: conversationProvider.language2Name,
                          isListening: conversationProvider.isListeningTop,
                          transcribedText: conversationProvider.topTranscribedText,
                          translatedText: conversationProvider.topTranslatedText,
                          onMicPressed: () => conversationProvider.toggleListening(true),
                          backgroundColor: const Color(0xFFF1F5F9),
                          micColor: const Color(0xFF3B82F6),
                        ),
                      ),
                      
                      // Divider
                      Container(
                        height: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      
                      // Bottom panel (Language 2 -> Language 1)  
                      Flexible(
                        flex: 1,
                        child: Transform.rotate(
                          angle: 3.14159, // 180 degrees
                          child: ConversationPanel(
                            isTopPanel: false,
                            sourceLanguage: conversationProvider.language2,
                            targetLanguage: conversationProvider.language1,
                            sourceLanguageName: conversationProvider.language2Name,
                            targetLanguageName: conversationProvider.language1Name,
                            isListening: conversationProvider.isListeningBottom,
                            transcribedText: conversationProvider.bottomTranscribedText,
                            translatedText: conversationProvider.bottomTranslatedText,
                            onMicPressed: () => conversationProvider.toggleListening(false),
                            backgroundColor: const Color(0xFFFEF7F0),
                            micColor: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 18),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              items: languages
                  .map((lang) => DropdownMenuItem(
                        value: lang['value'],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Flag.fromString(
                                lang['flag'] ?? 'UN',
                                height: 16,
                                width: 24,
                                borderRadius: 2,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getLocalizedLanguageName(lang['value']!, provider),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
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

  String _getLanguageName(String langCode, List<Map<String, String>> languages) {
    final language = languages.firstWhere(
      (lang) => lang['value'] == langCode,
      orElse: () => {'label': 'Bilinmeyen Dil'},
    );
    return language['label'] ?? 'Bilinmeyen Dil';
  }

}