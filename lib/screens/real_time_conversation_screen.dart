import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import '../providers/real_time_conversation_provider.dart';
import '../providers/translator_provider.dart';
import '../widgets/conversation_card.dart';
import '../widgets/mic_button.dart';
import '../widgets/searchable_language_dropdown.dart';

class RealTimeConversationScreen extends StatefulWidget {
  const RealTimeConversationScreen({super.key});

  @override
  State<RealTimeConversationScreen> createState() => _RealTimeConversationScreenState();
}

class _RealTimeConversationScreenState extends State<RealTimeConversationScreen>
    with TickerProviderStateMixin {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RealTimeConversationProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'İki Taraflı Çeviri',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context),
            tooltip: 'Ayarlar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              context.read<RealTimeConversationProvider>().clearConversation();
            },
            tooltip: 'Temizle',
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer2<RealTimeConversationProvider, TranslatorProvider>(
          builder: (context, provider, translatorProvider, child) {
            return Column(
              children: [
                // Dil Değiştirici (Translator style)
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
                        child: SearchableLanguageDropdown(
                          value: provider.language1,
                          hint: 'Kaynak Dil',
                          languages: translatorProvider.languages,
                          onChanged: (langCode, langName) {
                            provider.setLanguage1(langCode, langName);
                          },
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
                          value: provider.language2,
                          hint: 'Hedef Dil',
                          languages: translatorProvider.languages,
                          onChanged: (langCode, langName) {
                            provider.setLanguage2(langCode, langName);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Ana Konuşma Alanı
                Expanded(
                  child: Column(
                    children: [
                      // Kullanıcı A Bölümü (Üst)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          child: _buildUserSection(
                            context,
                            provider,
                            isTopUser: true,
                            userLanguage: provider.language1,
                            userLanguageName: provider.language1Name,
                            targetLanguage: provider.language2,
                            targetLanguageName: provider.language2Name,
                            isListening: provider.isListeningUser1,
                            userText: provider.user1OriginalText,
                            isTranslating: provider.isTranslatingUser1,
                            isSpeaking: provider.isSpeakingUser1Translation,
                            onMicPressed: () => provider.toggleListening(isUser1: true),
                            accentColor: const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                      
                      // Simple divider
                      Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      
                      // Kullanıcı B Bölümü (Alt - 180° çevrilmiş)
                      Expanded(
                        child: Transform.rotate(
                          angle: 3.14159, // 180 degrees
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            child: _buildUserSection(
                              context,
                              provider,
                              isTopUser: false,
                              userLanguage: provider.language2,
                              userLanguageName: provider.language2Name,
                              targetLanguage: provider.language1,
                              targetLanguageName: provider.language1Name,
                              isListening: provider.isListeningUser2,
                              userText: provider.user2OriginalText,
                              isTranslating: provider.isTranslatingUser2,
                              isSpeaking: provider.isSpeakingUser2Translation,
                              onMicPressed: () => provider.toggleListening(isUser1: false),
                              accentColor: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserSection(
    BuildContext context,
    RealTimeConversationProvider provider, {
    required bool isTopUser,
    required String userLanguage,
    required String userLanguageName,
    required String targetLanguage,
    required String targetLanguageName,
    required bool isListening,
    required String userText,
    required bool isTranslating,
    required bool isSpeaking,
    required VoidCallback onMicPressed,
    required Color accentColor,
  }) {
    // Basit tek kart layout
    Widget content = Column(
      children: [
        // Sadece kullanıcının konuşma kartı
        Expanded(
          child: ConversationCard(
            title: userLanguageName,
            text: userText.isEmpty 
              ? (isListening ? 'Dinliyorum...' : 'Konuşmak için mikrofona basın')
              : userText,
            isPlaceholder: userText.isEmpty,
            isListening: isListening,
            accentColor: accentColor,
            showPlayButton: userText.isNotEmpty,
            onPlayPressed: () => provider.playOriginalAudio(userText, userLanguage),
            onCopyPressed: () => provider.copyToClipboard(userText, context),
            listenWaveColor: accentColor,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Mikrofon Butonu - Sabit boyut
        MicButton(
          isListening: isListening,
          accentColor: accentColor,
          onPressed: onMicPressed,
          size: 80,
        ),
        
        const SizedBox(height: 16),
      ],
    );

    // Alt kullanıcı için içeriği ters çevir
    if (!isTopUser) {
      content = Transform.rotate(
        angle: 3.14159,
        child: content,
      );
    }

    return content;
  }



  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konuşma Ayarları',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Consumer<RealTimeConversationProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Otomatik çeviri okuma'),
                  subtitle: const Text('Çeviriler otomatik sesli okunur'),
                  value: provider.autoPlayEnabled,
                  onChanged: (value) => provider.setAutoPlay(value),
                ),
                SwitchListTile(
                  title: const Text('Otomatik durdurma'),
                  subtitle: const Text('30 saniye sonra kaydı durdur'),
                  value: provider.autoStopEnabled,
                  onChanged: (value) => provider.setAutoStop(value),
                ),
                SwitchListTile(
                  title: const Text('Hızlı çeviri'),
                  subtitle: const Text('Daha hızlı ama daha az doğru'),
                  value: provider.fastModeEnabled,
                  onChanged: (value) => provider.setFastMode(value),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}