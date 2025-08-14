import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flag/flag.dart';
import '../providers/translator_provider.dart';
import '../widgets/language_selector.dart';
import '../widgets/better_translation_button.dart';
import '../widgets/upgrade_to_pro_dialog.dart';
import '../widgets/app_drawer.dart';
import 'pro_subscription_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'auth/login_screen.dart';

class AIHomepage extends StatefulWidget {
  const AIHomepage({super.key});

  @override
  State<AIHomepage> createState() => _AIHomepageState();
}

class _AIHomepageState extends State<AIHomepage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  AnimationController? _waveController;
  List<Animation<double>>? _waveAnimations;
  AnimationController? _pulseController;
  late Animation<double> _pulseAnimation;
  AnimationController? _scaleController;
  late Animation<double> _scaleAnimation;
  bool _controllersInitialized = false;
  


  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    // Wave animation controller
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Scale animation controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Create wave animations with different delays
    _waveAnimations = List.generate(12, (index) {
      final delay = (index * 0.08).clamp(0.0, 0.8); // Ensure delay doesn't exceed 0.8
      return Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _waveController!,
          curve: Interval(delay, 1.0, curve: Curves.easeInOut),
        ),
      );
    });
    
    // Pulse animation for microphone
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(
      CurvedAnimation(
        parent: _pulseController!,
        curve: Curves.easeInOut,
      ),
    );
    
    // Scale animation for interactions
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _scaleController!,
        curve: Curves.easeInOut,
      ),
    );
    
    _controllersInitialized = true;
    _fadeController.forward();
    

  }

  @override
  void dispose() {
    _fadeController.dispose();
    _waveController?.dispose();
    _pulseController?.dispose();
    _scaleController?.dispose();
    super.dispose();
  }
  

  


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final translatorProvider = context.watch<TranslatorProvider>();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: Colors.grey.shade700,
              size: 28,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Translation History Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                _showTranslationHistory(context);
              },
              icon: Icon(
                Icons.history_rounded,
                color: Colors.grey.shade700,
                size: 28,
              ),
              tooltip: 'Translation History',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.translate_rounded,
              color: Colors.blue.shade500,
              size: 28,
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.grey.shade50,
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
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Language Selector
                    const LanguageSelector(),
                    
                    SizedBox(height: screenHeight * 0.02),
                    
                    SizedBox(height: screenHeight * 0.01),
                    
                    // Main Translation Interface
                    _buildTranslationInterface(context, screenWidth, screenHeight, translatorProvider),
                    
                    SizedBox(height: screenHeight * 0.04),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranslationInterface(BuildContext context, double screenWidth, double screenHeight, TranslatorProvider provider) {
    return Container(
      width: screenWidth * 0.95,
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
        children: [
          // Input Section
          _buildInputSection(context, provider, screenWidth),
          
          // Translation Output
          _buildOutputSection(context, provider, screenWidth),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context, TranslatorProvider provider, double screenWidth) {
    // Show AI Assistant UI when recording
    if (provider.isRecording) {
      return _buildAIAssistantUI(context, provider);
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Label
          Text(
            'Type or speak to translate:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Unified Input Area
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Text Input Field
                Stack(
                  children: [
                    TextField(
                      controller: provider.textController,
                      maxLines: null,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: provider.getLocalizedText('type_message_hint'),
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                      onChanged: (text) {
                        // setState is called implicitly by provider
                        provider.setInputText(text);
                      },
                    ),
                    if (provider.textController.text.isNotEmpty)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          iconSize: 20,
                          color: Colors.grey.shade600,
                          tooltip: 'Clear text',
                          onPressed: () {
                            provider.clearInput();
                          },
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Paste Button
                    GestureDetector(
                      onTap: () async {
                        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                        if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
                          provider.textController.text = clipboardData.text!;
                          provider.setInputText(clipboardData.text!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(provider.getLocalizedText('text_pasted')),
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.green.shade600,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(provider.getLocalizedText('no_text_clipboard')),
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.orange.shade600,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.paste_rounded,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              provider.getLocalizedText('paste'),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Voice Input Button
                    GestureDetector(
                      onTap: () {
                        provider.startRecording();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade500,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mic_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ],
                        ),
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
  }

  Widget _buildAIAssistantUI(BuildContext context, TranslatorProvider provider) {
    // Start animations when this UI is shown
    if (_controllersInitialized) {
      if (_waveController != null && !_waveController!.isAnimating) {
        _waveController!.repeat(reverse: true);
      }
      if (_pulseController != null && !_pulseController!.isAnimating) {
        _pulseController!.repeat(reverse: true);
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          
          // Animated Microphone with Sound Waves
          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sound Waves Background
                ..._buildAnimatedSoundWaves(),
                
                // Central Microphone Button
                AnimatedBuilder(
                  animation: _controllersInitialized && _pulseController != null ? _pulseAnimation : 
                    const AlwaysStoppedAnimation(1.0),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _controllersInitialized ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                              Colors.blue.shade800,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 25,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Clean Status Text
          Text(
            provider.getLocalizedText('speak_now'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 25),
          
          // Live Speech Results - Clean Design
          if (provider.textController.text.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.record_voice_over_rounded,
                        color: Colors.blue.shade500,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.getLocalizedText('speech_recognition'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.textController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          
          // Action Buttons Row - Simplified
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop Recording Button
              ElevatedButton.icon(
                onPressed: () {
                  if (_controllersInitialized) {
                    _waveController?.stop();
                    _waveController?.reset();
                    _pulseController?.stop();
                    _pulseController?.reset();
                  }
                  provider.stopRecording();
                },
                icon: const Icon(Icons.stop_rounded, size: 20),
                label: Text(
                  provider.getLocalizedText('stop_recording'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnimatedSoundWaves() {
    if (!_controllersInitialized || _waveAnimations == null) {
      return [];
    }
    
    return [
      // Clean ripple waves
      ...List.generate(3, (ringIndex) {
        final animationIndex = ringIndex % _waveAnimations!.length;
        return AnimatedBuilder(
          animation: _waveAnimations![animationIndex],
          builder: (context, child) {
            final progress = _waveAnimations![animationIndex].value;
            final scale = 1.0 + (progress * 0.8);
            final opacity = (1.0 - progress) * 0.6;
            
            return Positioned.fill(
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 100.0 + (ringIndex * 30.0),
                    height: 100.0 + (ringIndex * 30.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue.shade400.withOpacity(opacity),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
      
      // Audio bars in circular pattern
      ...List.generate(16, (index) {
        final angle = (index * 22.5) * (pi / 180);
        final animationIndex = index % _waveAnimations!.length;
        
        return AnimatedBuilder(
          animation: _waveAnimations![animationIndex],
          builder: (context, child) {
            final progress = _waveAnimations![animationIndex].value;
            final height = 15.0 + (progress * 20.0);
            final opacity = 0.6 + (progress * 0.4);
            
            return Positioned.fill(
              child: Center(
                child: Transform.rotate(
                  angle: angle,
                  child: Transform.translate(
                    offset: const Offset(0, -60),
                    child: Container(
                      width: 3,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.blue.shade600.withOpacity(opacity),
                            Colors.blue.shade400.withOpacity(opacity * 0.8),
                            Colors.blue.shade200.withOpacity(opacity * 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
      
      // Subtle floating dots
      ...List.generate(6, (index) {
        final angle = (index * 60.0) * (pi / 180);
        final animationIndex = index % _waveAnimations!.length;
        
        return AnimatedBuilder(
          animation: _waveAnimations![animationIndex],
          builder: (context, child) {
            final progress = _waveAnimations![animationIndex].value;
            final distance = 80.0 + (sin(progress * pi * 2) * 10.0);
            final size = 4.0 + (progress * 2.0);
            final opacity = 0.4 + (progress * 0.4);
            
            return Positioned(
              left: 150 + cos(angle) * distance - size/2,
              top: 60 + sin(angle) * distance - size/2,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.blue.shade300.withOpacity(opacity),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(opacity * 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    ];
  }

  Widget _buildOutputSection(BuildContext context, TranslatorProvider provider, double screenWidth) {
    if (provider.inputText.isEmpty && !provider.isTranslating) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Translation Header - Made flexible to prevent overflow
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row: Translation badge and action buttons
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: provider.translationModel == 'ai_pro' && provider.isProUser
                          ? Colors.purple.shade500
                          : Colors.blue.shade500,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          provider.translationModel == 'ai_pro' && provider.isProUser
                              ? Icons.auto_awesome_rounded
                              : Icons.translate_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.translationModel == 'ai_pro' && provider.isProUser
                              ? provider.getLocalizedText('ai_pro')
                              : provider.getLocalizedText('translation'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  if (provider.translatedText.isNotEmpty && !provider.isTranslating)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Copy Button
                        GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: provider.translatedText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(provider.getLocalizedText('translation_copied')),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green.shade600,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.copy_rounded,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Share Button
                    GestureDetector(
                      onTap: () {
                        Share.share(
                          provider.translatedText,
                          subject: 'Translation from Voicely',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.share_rounded,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Audio Button
                    GestureDetector(
                      onTap: () => provider.speak(provider.translatedText, provider.toLang),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              ),
              
              // Second row: Better Translation Button or Model Toggle
              if (provider.translatedText.isNotEmpty && !provider.isTranslating) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!provider.isProUser) 
                      // Non-Pro: Show upgrade button
                      BetterTranslationButton(
                        isProUser: provider.isProUser,
                        isLoading: provider.isTranslating,
                        onPressed: () => _handleBetterTranslation(context, provider),
                      )
                    else
                      // Pro: Show model toggle
                      GestureDetector(
                        onTap: () {
                          provider.toggleTranslationModel();
                          // Re-translate with new model
                          provider.translateText();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: provider.translationModel == 'ai_pro'
                                  ? [Colors.purple.shade400, Colors.purple.shade600]
                                  : [Colors.blue.shade400, Colors.blue.shade600],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (provider.translationModel == 'ai_pro' 
                                    ? Colors.purple 
                                    : Colors.blue).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                provider.translationModel == 'ai_pro'
                                    ? Icons.auto_awesome_rounded
                                    : Icons.translate_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                provider.translationModel == 'ai_pro'
                                    ? 'Switch to Standard'
                                    : 'Switch to AI Pro',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Translation Content
          if (provider.isTranslating)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue.shade500,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Translating...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          else if (provider.translatedText.isNotEmpty)
            Text(
              provider.translatedText,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            )
          else
            Text(
              'Translation will appear here...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  void _handleBetterTranslation(BuildContext context, TranslatorProvider provider) {
    if (provider.isProUser) {
      // User is Pro - use AI translation
      provider.setTranslationModel('ai_pro');
      provider.translateText();
    } else {
      // User is not Pro - show upgrade dialog
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => UpgradeToProDialog(
          onGoPro: () {
            Navigator.pop(context); // Close dialog
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProSubscriptionScreen(),
              ),
            );
          },
          onCancel: () {
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  void _showTranslationHistory(BuildContext context) {
    final translatorProvider = context.read<TranslatorProvider>();
    
    // Load history if not already loaded
    translatorProvider.loadHistory();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      enableDrag: true,
      builder: (context) => _TranslationHistoryModal(
        translatorProvider: translatorProvider,
      ),
    );
  }

}

class _TranslationHistoryModal extends StatefulWidget {
  final TranslatorProvider translatorProvider;

  const _TranslationHistoryModal({
    required this.translatorProvider,
  });

  @override
  State<_TranslationHistoryModal> createState() => _TranslationHistoryModalState();
}

class _TranslationHistoryModalState extends State<_TranslationHistoryModal> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    
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
                Icon(
                  Icons.history_rounded,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Translation History',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
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
          
          // History List
          Expanded(
            child: Consumer<TranslatorProvider>(
              builder: (context, provider, child) {
                if (provider.history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.blue.shade200, width: 2),
                          ),
                          child: Icon(
                            Icons.history,
                            size: 40,
                            color: Colors.blue.shade400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No translations yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your translation history will appear here',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: provider.history.length,
                  itemBuilder: (context, index) {
                    final historyItem = provider.history[index];
                    final fromLang = provider.languages.firstWhere(
                      (lang) => lang['value'] == historyItem['fromLang'],
                      orElse: () => {'label': historyItem['fromLang']},
                    )['label'];
                    final toLang = provider.languages.firstWhere(
                      (lang) => lang['value'] == historyItem['toLang'],
                      orElse: () => {'label': historyItem['toLang']},
                    )['label'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              historyItem['inputText'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              historyItem['translatedText'],
                              style: GoogleFonts.poppins(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$fromLang → $toLang',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.blue.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTimestamp(historyItem['timestamp']),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          provider.loadFromHistory(historyItem);
                          Navigator.pop(context);
                        },
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

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Az önce';
      }
    } catch (e) {
      return 'Bilinmeyen';
    }
  }
}
