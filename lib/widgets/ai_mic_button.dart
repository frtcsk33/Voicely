import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/translator_provider.dart';

class AIMicButton extends StatefulWidget {
  const AIMicButton({super.key});

  @override
  State<AIMicButton> createState() => _AIMicButtonState();
}

class _AIMicButtonState extends State<AIMicButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    final provider = context.read<TranslatorProvider>();
    if (provider.isRecording) {
      provider.stopRecording();
      _pulseController.stop();
      _pulseController.reset();
    } else {
      provider.startRecording();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedBuilder(
                animation: provider.isRecording ? _pulseAnimation : 
                    AlwaysStoppedAnimation(1.0),
                builder: (context, child) {
                  return Transform.scale(
                    scale: provider.isRecording ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: provider.isRecording
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (provider.isRecording ? Colors.red : Colors.blue)
                                .withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        provider.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Status text
            Text(
              provider.isRecording 
                  ? 'Listening...' 
                  : provider.isTranslating 
                      ? 'Translating...'
                      : 'Tap to speak',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: provider.isRecording 
                    ? Colors.red.shade600
                    : provider.isTranslating
                        ? Colors.blue.shade600
                        : Colors.grey.shade600,
              ),
            ),
          ],
        );
      },
    );
  }
}