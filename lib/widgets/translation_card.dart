import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/translator_provider.dart';

class TranslationCard extends StatefulWidget {
  const TranslationCard({super.key});

  @override
  State<TranslationCard> createState() => _TranslationCardState();
}

class _TranslationCardState extends State<TranslationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        return Container(
          width: screenWidth * 0.9,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.translate_rounded,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Translation',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  if (provider.isTranslating)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Input Section
              _buildTranslationSection(
                title: 'Speaking (${_getLanguageName(provider.fromLang, provider.languages)})',
                content: provider.inputText.isEmpty 
                    ? 'Say something...' 
                    : provider.inputText,
                isInput: true,
                isActive: provider.isRecording,
                isTranslating: provider.isTranslating,
              ),
              
              // Arrow
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
                ),
              ),
              
              // Output Section
              _buildTranslationSection(
                title: 'Translation (${_getLanguageName(provider.toLang, provider.languages)})',
                content: provider.translatedText.isEmpty 
                    ? 'Translation will appear here...' 
                    : provider.translatedText,
                isInput: false,
                isActive: false,
                isTranslating: provider.isTranslating,
              ),
              
              // Action Buttons
              if (provider.translatedText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.volume_up_rounded,
                      label: 'Play',
                      color: Colors.green,
                      onTap: () => provider.speak(provider.translatedText, provider.toLang),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      icon: Icons.copy_rounded,
                      label: 'Copy',
                      color: Colors.blue,
                      onTap: () {
                        // TODO: Copy to clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      icon: Icons.favorite_border_rounded,
                      label: 'Save',
                      color: Colors.pink,
                      onTap: () => provider.toggleFavorite(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTranslationSection({
    required String title,
    required String content,
    required bool isInput,
    required bool isActive,
    required bool isTranslating,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isInput 
                ? (isActive ? Colors.red.shade50 : Colors.grey.shade50)
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isInput 
                  ? (isActive ? Colors.red.shade200 : Colors.grey.shade200)
                  : Colors.blue.shade200,
            ),
          ),
          child: isTranslating && !isInput
              ? AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Text(
                          content,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: content.contains('...') 
                                ? Colors.grey.shade500 
                                : Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                        Positioned.fill(
                          child: ClipRect(
                            child: CustomPaint(
                              painter: ShimmerPainter(_shimmerAnimation.value),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: content.contains('...') 
                        ? Colors.grey.shade500 
                        : Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color.lerp(color, Colors.black, 0.3)!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageName(String langCode, List<Map<String, String>> languages) {
    final language = languages.firstWhere(
      (lang) => lang['value'] == langCode,
      orElse: () => {'label': 'Unknown'},
    );
    return language['label'] ?? 'Unknown';
  }
}

class ShimmerPainter extends CustomPainter {
  final double animationValue;

  ShimmerPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        Colors.white.withOpacity(0.5),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(
          size.width * animationValue - size.width,
          0,
          size.width,
          size.height,
        ),
      );

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(ShimmerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
