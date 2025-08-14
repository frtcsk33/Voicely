import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import '../providers/conversation_provider.dart';
import '../providers/translator_provider.dart';
import '../widgets/app_drawer.dart';
import '../models/chat_message.dart';

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
      body: Consumer2<ConversationProvider, TranslatorProvider>(
        builder: (context, conversationProvider, translatorProvider, child) {
          return SafeArea(
            child: Stack(
              children: [
                _buildSplitScreenLayout(conversationProvider, translatorProvider),
                
                // Floating History Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => _showConversationHistory(context, conversationProvider),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _buildSplitScreenLayout(ConversationProvider conversationProvider, TranslatorProvider translatorProvider) {
    return Column(
      children: [
        // User A Area (Top) - Rotated 180 degrees
        Expanded(
          child: Transform.rotate(
            angle: 3.14159, // 180 degrees in radians
            child: _buildUserArea(
              conversationProvider,
              translatorProvider,
              isUserA: true,
              messages: conversationProvider.chatMessages.where((msg) => msg.isFromLeftMic).toList(),
              backgroundColor: const Color(0xFFEF4444).withOpacity(0.05),
              accentColor: const Color(0xFFEF4444),
              isListening: conversationProvider.isListeningTop,
            ),
          ),
        ),
        
        // Divider
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFEF4444).withOpacity(0.3),
                const Color(0xFF3B82F6).withOpacity(0.3),
              ],
            ),
          ),
        ),
        
        // User B Area (Bottom) - Normal orientation
        Expanded(
          child: _buildUserArea(
            conversationProvider,
            translatorProvider,
            isUserA: false,
            messages: conversationProvider.chatMessages.where((msg) => !msg.isFromLeftMic).toList(),
            backgroundColor: const Color(0xFF3B82F6).withOpacity(0.05),
            accentColor: const Color(0xFF3B82F6),
            isListening: conversationProvider.isListeningBottom,
          ),
        ),
      ],
    );
  }

  Widget _buildUserArea(
    ConversationProvider conversationProvider,
    TranslatorProvider translatorProvider, {
    required bool isUserA,
    required List<ChatMessage> messages,
    required Color backgroundColor,
    required Color accentColor,
    required bool isListening,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Stack(
        children: [
          // Messages Area
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Language Selector
                  _buildLanguageSelector(
                    conversationProvider,
                    translatorProvider,
                    isUserA,
                    accentColor,
                  ),
                  const SizedBox(height: 12),
                  
                  // Status Indicator
                  _buildStatusIndicator(isListening, accentColor, isUserA),
                  const SizedBox(height: 8),
                  
                  // Messages
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        return _buildSplitChatBubble(message, accentColor, isUserA, conversationProvider);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Floating Microphone Button (Bottom Right)
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildFloatingMicButton(
              conversationProvider,
              isUserA,
              accentColor,
              isListening,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
    ConversationProvider conversationProvider,
    TranslatorProvider translatorProvider,
    bool isUserA,
    Color accentColor,
  ) {
    final currentLanguage = isUserA ? conversationProvider.language1 : conversationProvider.language2;
    final currentLanguageName = isUserA ? conversationProvider.language1Name : conversationProvider.language2Name;
    
    // Dil listesinden flag bilgisini al
    final language = translatorProvider.languages.firstWhere(
      (lang) => lang['value'] == currentLanguage,
      orElse: () => {'label': currentLanguageName, 'value': currentLanguage, 'flag': 'GB'},
    );
    
    return GestureDetector(
      onTap: () => _showConversationLanguagePicker(
        conversationProvider,
        translatorProvider,
        isUserA,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flag.fromString(
              language['flag']!,
              height: 18,
              width: 24,
              borderRadius: 3,
            ),
            const SizedBox(width: 8),
            Text(
              currentLanguageName,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: accentColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showConversationLanguagePicker(
    ConversationProvider conversationProvider,
    TranslatorProvider translatorProvider,
    bool isUserA,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      enableDrag: true,
      builder: (context) => _ConversationLanguagePickerModal(
        conversationProvider: conversationProvider,
        translatorProvider: translatorProvider,
        isUserA: isUserA,
      ),
    );
  }

  Widget _buildStatusIndicator(bool isListening, Color accentColor, bool isUserA) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isListening ? accentColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isListening ? Colors.white : accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isListening ? 'Listening...' : 'Tap to speak',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isListening ? Colors.white : accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitChatBubble(ChatMessage message, Color accentColor, bool isUserA, ConversationProvider conversationProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Original Text (User's own text - normal orientation)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.originalText,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          
          if (message.translatedText.isNotEmpty) ...[
            const SizedBox(height: 8),
            
            // Translated Text (For other user - mirrored if needed)
            Transform.rotate(
              angle: isUserA ? 3.14159 : 0, // Mirror for User A
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.translatedText,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        conversationProvider.speakText(
                          message.translatedText,
                          message.targetLanguage,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 16,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingMicButton(
    ConversationProvider conversationProvider,
    bool isUserA,
    Color accentColor,
    bool isListening,
  ) {
    return GestureDetector(
      onTap: () => conversationProvider.toggleListening(isUserA),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isListening ? accentColor : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: accentColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(isListening ? 0.4 : 0.2),
              blurRadius: 16,
              spreadRadius: isListening ? 4 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none_rounded,
          color: isListening ? Colors.white : accentColor,
          size: 28,
        ),
      ),
    );
  }

  void _showConversationHistory(BuildContext context, ConversationProvider conversationProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      enableDrag: true,
      builder: (context) => _ConversationHistoryModal(
        conversationProvider: conversationProvider,
      ),
    );
  }
}

class _ConversationLanguagePickerModal extends StatefulWidget {
  final ConversationProvider conversationProvider;
  final TranslatorProvider translatorProvider;
  final bool isUserA;

  const _ConversationLanguagePickerModal({
    required this.conversationProvider,
    required this.translatorProvider,
    required this.isUserA,
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
                  'Select ${widget.isUserA ? "User A" : "User B"} language',
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
                final currentLanguage = widget.isUserA 
                    ? widget.conversationProvider.language1 
                    : widget.conversationProvider.language2;
                final isSelected = currentLanguage == language['value'];
                
                return GestureDetector(
                  onTap: () {
                    if (widget.isUserA) {
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

class _ConversationHistoryModal extends StatefulWidget {
  final ConversationProvider conversationProvider;

  const _ConversationHistoryModal({
    required this.conversationProvider,
  });

  @override
  State<_ConversationHistoryModal> createState() => _ConversationHistoryModalState();
}

class _ConversationHistoryModalState extends State<_ConversationHistoryModal> {
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Conversation History',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                // Clear conversation button
                if (widget.conversationProvider.chatMessages.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () {
                      _showClearConversationDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
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
          
          // Conversation Messages
          Expanded(
            child: Consumer<ConversationProvider>(
              builder: (context, provider, child) {
                if (provider.chatMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.grey.shade200, width: 2),
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a conversation to see messages here',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  reverse: true,
                  itemCount: provider.chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = provider.chatMessages[provider.chatMessages.length - 1 - index];
                    final isFromLeft = message.isFromLeftMic;
                    final messageColor = isFromLeft ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: messageColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: messageColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: messageColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isFromLeft ? 'User A' : 'User B',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: messageColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Message bubble
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Original text
                                Text(
                                  message.originalText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                
                                if (message.translatedText.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  
                                  // Translated text
                                  Text(
                                    message.translatedText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 8),
                                
                                // Language indicator and timestamp
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: messageColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${message.sourceLanguage} → ${message.targetLanguage}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: messageColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatTime(message.timestamp),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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

  void _showClearConversationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Clear Conversation',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to clear the entire conversation history? This action cannot be undone.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(),
              ),
            ),
            TextButton(
              onPressed: () {
                widget.conversationProvider.clearConversation();
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the history modal too
              },
              child: Text(
                'Clear',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
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

