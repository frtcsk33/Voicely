import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import '../providers/conversation_provider.dart';
import '../providers/translator_provider.dart';
import '../widgets/conversation_panel.dart';
import '../widgets/language_selector.dart';
import '../widgets/app_drawer.dart';

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
      drawer: const AppDrawer(),
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
                // Language Selector
                const ConversationLanguageSelector(),
                
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

}

class ConversationLanguageSelector extends StatelessWidget {
  const ConversationLanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Consumer2<ConversationProvider, TranslatorProvider>(
      builder: (context, conversationProvider, translatorProvider, child) {
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
                  conversationProvider,
                  translatorProvider,
                  conversationProvider.language1,
                  'From',
                  true,
                  translatorProvider.languages,
                ),
              ),
              
              // Swap Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: () => conversationProvider.swapLanguages(),
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
                  conversationProvider,
                  translatorProvider,
                  conversationProvider.language2,
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
    ConversationProvider conversationProvider,
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
      onTap: () => _showLanguagePicker(context, conversationProvider, translatorProvider, isFrom),
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

  void _showLanguagePicker(BuildContext context, ConversationProvider conversationProvider, TranslatorProvider translatorProvider, bool isFrom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      enableDrag: true,
      builder: (context) => _ConversationLanguagePickerModal(
        conversationProvider: conversationProvider,
        translatorProvider: translatorProvider,
        isFrom: isFrom,
      ),
    );
  }
}

class _ConversationLanguagePickerModal extends StatefulWidget {
  final ConversationProvider conversationProvider;
  final TranslatorProvider translatorProvider;
  final bool isFrom;

  const _ConversationLanguagePickerModal({
    required this.conversationProvider,
    required this.translatorProvider,
    required this.isFrom,
  });

  @override
  State<_ConversationLanguagePickerModal> createState() => _ConversationLanguagePickerModalState();
}

class _ConversationLanguagePickerModalState extends State<_ConversationLanguagePickerModal> {
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
                final isSelected = (widget.isFrom ? widget.conversationProvider.language1 : widget.conversationProvider.language2) == language['value'];
                
                return GestureDetector(
                  onTap: () {
                    if (widget.isFrom) {
                      widget.conversationProvider.setLanguage1(
                        language['value']!,
                        language['label']!,
                      );
                    } else {
                      widget.conversationProvider.setLanguage2(
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