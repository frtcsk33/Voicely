import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import '../providers/real_time_conversation_provider.dart';
import '../providers/translator_provider.dart';
import '../widgets/conversation_card.dart';
import '../widgets/mic_button.dart';
import '../widgets/language_selector.dart';
import '../widgets/app_drawer.dart';

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
      drawer: const AppDrawer(),
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
                // Modern Language Selector
                RealTimeLanguageSelector(provider: provider),
                
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

class RealTimeLanguageSelector extends StatelessWidget {
  final RealTimeConversationProvider provider;
  
  const RealTimeLanguageSelector({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Consumer<TranslatorProvider>(
      builder: (context, translatorProvider, child) {
        return Container(
          width: screenWidth * 0.95,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // From Language
              Expanded(
                child: _buildLanguageButton(
                  context,
                  provider,
                  translatorProvider,
                  provider.language1,
                  'From',
                  true,
                  translatorProvider.languages,
                ),
              ),
              
              // Swap Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: () => provider.swapLanguages(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ),
              
              // To Language
              Expanded(
                child: _buildLanguageButton(
                  context,
                  provider,
                  translatorProvider,
                  provider.language2,
                  'To',
                  false,
                  translatorProvider.languages,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    RealTimeConversationProvider provider,
    TranslatorProvider translatorProvider,
    String langCode,
    String label,
    bool isFrom,
    List<Map<String, String>> languages,
  ) {
    Map<String, String> language;
    
    try {
      language = languages.firstWhere(
        (lang) => lang['value'] == langCode,
      );
    } catch (e) {
      language = {
        'label': 'Unknown', 
        'value': langCode, 
        'flag': 'GB'
      };
    }

    return GestureDetector(
      onTap: () => _showLanguagePicker(context, provider, translatorProvider, isFrom),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Flag.fromString(
                  language['flag']!,
                  height: 20,
                  width: 28,
                  borderRadius: 4,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    language['label']!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, RealTimeConversationProvider provider, TranslatorProvider translatorProvider, bool isFrom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      enableDrag: true,
      builder: (context) => _RealTimeLanguagePickerModal(
        provider: provider,
        translatorProvider: translatorProvider,
        isFrom: isFrom,
      ),
    );
  }
}

class _RealTimeLanguagePickerModal extends StatefulWidget {
  final RealTimeConversationProvider provider;
  final TranslatorProvider translatorProvider;
  final bool isFrom;

  const _RealTimeLanguagePickerModal({
    required this.provider,
    required this.translatorProvider,
    required this.isFrom,
  });

  @override
  State<_RealTimeLanguagePickerModal> createState() => _RealTimeLanguagePickerModalState();
}

class _RealTimeLanguagePickerModalState extends State<_RealTimeLanguagePickerModal> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final languages = widget.translatorProvider.languages;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    
    // Filter languages based on search query
    final filteredLanguages = languages.where((language) {
      return language['label']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             language['value']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    
    return Container(
      height: screenHeight - topPadding,
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
                Text(
                  widget.isFrom ? 'Select source language' : 'Select target language',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                autofocus: false,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search languages...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Language List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredLanguages.length,
              itemBuilder: (context, index) {
                final language = filteredLanguages[index];
                final isSelected = (widget.isFrom ? widget.provider.language1 : widget.provider.language2) == language['value'];
                
                return GestureDetector(
                  onTap: () {
                    if (widget.isFrom) {
                      widget.provider.setLanguage1(
                        language['value']!,
                        language['label']!,
                      );
                    } else {
                      widget.provider.setLanguage2(
                        language['value']!,
                        language['label']!,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue.shade200 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Flag.fromString(
                          language['flag']!,
                          height: 24,
                          width: 32,
                          borderRadius: 4,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            language['label']!,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_rounded,
                            color: Colors.blue.shade600,
                            size: 20,
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
}