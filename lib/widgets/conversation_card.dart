import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConversationCard extends StatefulWidget {
  final String title;
  final String text;
  final bool isPlaceholder;
  final bool isListening;
  final bool isTranslating;
  final bool isSpeaking;
  final Color accentColor;
  final bool showPlayButton;
  final VoidCallback? onPlayPressed;
  final VoidCallback? onCopyPressed;
  final Color? listenWaveColor;
  final bool isTranslationCard;

  const ConversationCard({
    super.key,
    required this.title,
    required this.text,
    this.isPlaceholder = false,
    this.isListening = false,
    this.isTranslating = false,
    this.isSpeaking = false,
    required this.accentColor,
    this.showPlayButton = false,
    this.onPlayPressed,
    this.onCopyPressed,
    this.listenWaveColor,
    this.isTranslationCard = false,
  });

  @override
  State<ConversationCard> createState() => _ConversationCardState();
}

class _ConversationCardState extends State<ConversationCard>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late List<Animation<double>> _waveAnimations;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Wave animation for listening
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _waveAnimations = List.generate(5, (index) {
      return Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _waveController,
          curve: Interval((index * 0.15).clamp(0.0, 1.0), 1.0, curve: Curves.easeInOut),
        ),
      );
    });

    // Pulse animation for translating/speaking
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(ConversationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isListening && !oldWidget.isListening) {
      _waveController.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _waveController.stop();
      _waveController.reset();
    }
    
    if ((widget.isTranslating || widget.isSpeaking) && 
        !(oldWidget.isTranslating || oldWidget.isSpeaking)) {
      _pulseController.repeat(reverse: true);
    } else if (!(widget.isTranslating || widget.isSpeaking) && 
               (oldWidget.isTranslating || oldWidget.isSpeaking)) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: widget.isListening || widget.isTranslating || widget.isSpeaking
            ? Border.all(
                color: widget.accentColor.withOpacity(0.3),
                width: 2,
              )
            : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Fixed height
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    // Title
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          color: widget.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Status indicators - Fixed container
                    if (widget.isListening && widget.listenWaveColor != null)
                      SizedBox(
                        width: 50,
                        height: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return AnimatedBuilder(
                              animation: _waveAnimations[index],
                              builder: (context, child) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  height: 16 * _waveAnimations[index].value,
                                  width: 3,
                                  decoration: BoxDecoration(
                                    color: widget.listenWaveColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      )
                    else if (widget.isTranslating)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade400,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.sync,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else if (widget.isSpeaking)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade400,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.volume_up_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Text content - Scrollable with overflow protection
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isTranslationCard) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.translate_rounded,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Çeviri',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      Text(
                        widget.text,
                        style: GoogleFonts.poppins(
                          fontSize: widget.isPlaceholder ? 14 : 16,
                          color: widget.isPlaceholder 
                            ? Colors.grey.shade400 
                            : const Color(0xFF1E293B),
                          fontStyle: widget.isPlaceholder ? FontStyle.italic : FontStyle.normal,
                          fontWeight: widget.isPlaceholder ? FontWeight.w400 : FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action buttons - Fixed height
              if (widget.showPlayButton && !widget.isPlaceholder) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        // Play button
                        if (widget.onPlayPressed != null)
                          GestureDetector(
                            onTap: widget.onPlayPressed,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    size: 16,
                                    color: widget.accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Dinle',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: widget.accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        const SizedBox(width: 8),
                        
                        // Copy button
                        if (widget.onCopyPressed != null)
                          GestureDetector(
                            onTap: widget.onCopyPressed,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Kopyala',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }
}