import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/translator_provider.dart';
import '../widgets/ai_mic_button.dart';
import '../widgets/translation_card.dart';
import '../widgets/language_selector.dart';
import '../widgets/ai_badge.dart';

class AIHomepage extends StatefulWidget {
  const AIHomepage({super.key});

  @override
  State<AIHomepage> createState() => _AIHomepageState();
}

class _AIHomepageState extends State<AIHomepage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: 20,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // AI Badge
                    const AIBadge(),
                    
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Hero Section
                    _buildHeroSection(context, screenHeight, screenWidth),
                    
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Language Selector
                    const LanguageSelector(),
                    
                    SizedBox(height: screenHeight * 0.03),
                    
                    // Translation Card
                    const TranslationCard(),
                    
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Microphone Button
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: const AIMicButton(),
                        );
                      },
                    ),
                    
                    SizedBox(height: screenHeight * 0.03),
                    
                    // Start Button
                    _buildStartButton(context, screenWidth),
                    
                    SizedBox(height: screenHeight * 0.03),
                    
                    // Features Section
                    _buildFeaturesSection(context, screenWidth),
                    
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, double screenHeight, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.02,
      ),
      child: Column(
        children: [
          // Main Title
          Text(
            'AI Voice Translator',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.08,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [
                    Colors.blue.shade600,
                    Colors.purple.shade600,
                    Colors.pink.shade600,
                  ],
                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: screenHeight * 0.015),
          
          // Subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Break language barriers with real-time AI-powered voice translation',
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.04,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(height: screenHeight * 0.02),
          
          // Feature Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFeaturePill('🎤 Voice Recognition', Colors.blue),
              _buildFeaturePill('🤖 AI Powered', Colors.purple),
              _buildFeaturePill('⚡ Real-time', Colors.orange),
              _buildFeaturePill('🌍 100+ Languages', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color.lerp(color, Colors.black, 0.3)!,
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, double screenWidth) {
    return Container(
      width: screenWidth * 0.8,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.purple.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            // TODO: Navigate to translation screen or start translation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Starting AI Translation...',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.blue.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Start Translating',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Why Choose Voicely?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeatureItem(
                  Icons.speed_rounded,
                  'Lightning Fast',
                  'Instant translations',
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildFeatureItem(
                  Icons.psychology_rounded,
                  'AI Powered',
                  'Smart & accurate',
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildFeatureItem(
                  Icons.offline_bolt_rounded,
                  'Offline Mode',
                  'Works anywhere',
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
