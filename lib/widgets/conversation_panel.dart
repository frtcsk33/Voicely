import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ConversationPanel extends StatefulWidget {
  final bool isTopPanel;
  final String sourceLanguage;
  final String targetLanguage;
  final String sourceLanguageName;
  final String targetLanguageName;
  final bool isListening;
  final String transcribedText;
  final String translatedText;
  final VoidCallback onMicPressed;
  final Color backgroundColor;
  final Color micColor;

  const ConversationPanel({
    super.key,
    required this.isTopPanel,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.sourceLanguageName,
    required this.targetLanguageName,
    required this.isListening,
    required this.transcribedText,
    required this.translatedText,
    required this.onMicPressed,
    required this.backgroundColor,
    required this.micColor,
  });

  @override
  State<ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends State<ConversationPanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Source text section (matching translate screen style)
            Flexible(
              flex: 3,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with language and status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.micColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.sourceLanguageName,
                            style: GoogleFonts.poppins(
                              color: widget.micColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (widget.isListening) 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.micColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'LISTENING',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Transcribed text
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (widget.transcribedText.isEmpty && !widget.isListening)
                                    Text(
                                      'Tap the microphone to speak',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey.shade400,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  else if (widget.isListening && widget.transcribedText.isEmpty)
                                    Text(
                                      'Listening...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: widget.micColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  else
                                    Text(
                                      widget.transcribedText,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: const Color(0xFF1E293B),
                                        height: 1.4,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Microphone button (static version)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: GestureDetector(
                onTap: widget.onMicPressed,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isListening 
                        ? [
                            widget.micColor,
                            widget.micColor.withOpacity(0.8),
                          ]
                        : [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.micColor,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.micColor.withOpacity(widget.isListening ? 0.3 : 0.15),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isListening ? Icons.mic : Icons.mic_none_rounded,
                    color: widget.isListening 
                      ? Colors.white 
                      : widget.micColor,
                    size: 32,
                  ),
                ),
              ),
            ),
            
            // Translation section (matching translate screen style)
            Flexible(
              flex: 3,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Translation header
                    Row(
                      children: [
                        const Icon(
                          Icons.translate_rounded,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.targetLanguageName,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (widget.translatedText.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: widget.translatedText));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Translation copied to clipboard'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  // Note: Speak functionality will be handled by the provider
                                  // This is just a placeholder for the UI
                                },
                                child: Icon(
                                  Icons.volume_up_rounded,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Translated text
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  widget.translatedText.isEmpty 
                                    ? Text(
                                        'Translation will appear here...',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade400,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    : Text(
                                        widget.translatedText,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: const Color(0xFF374151),
                                          height: 1.4,
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Apply rotation to text content if this is bottom panel
    if (!widget.isTopPanel) {
      content = Transform.rotate(
        angle: 3.14159, // 180 degrees to counter the parent rotation
        child: content,
      );
    }

    return content;
  }
}