import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/translator_provider.dart';
import '../widgets/language_selector.dart';

class AIHomepage extends StatefulWidget {
  const AIHomepage({super.key});

  @override
  State<AIHomepage> createState() => _AIHomepageState();
}

class _AIHomepageState extends State<AIHomepage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
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
      drawer: _buildDrawer(context),
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
                    
                    SizedBox(height: screenHeight * 0.03),
                    
                    // Main Translation Interface
                    _buildTranslationInterface(context, screenWidth, screenHeight),
                    
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

  Widget _buildTranslationInterface(BuildContext context, double screenWidth, double screenHeight) {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
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
      },
    );
  }

  Widget _buildInputSection(BuildContext context, TranslatorProvider provider, double screenWidth) {
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
                TextField(
                  controller: provider.textController,
                  maxLines: null,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: provider.isRecording 
                        ? null 
                        : 'Type your message here or use the microphone below',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: provider.isRecording ? Colors.red.shade600 : Colors.grey.shade800,
                    fontStyle: provider.isRecording ? FontStyle.italic : FontStyle.normal,
                  ),
                  onChanged: (text) {
                    if (!provider.isRecording) {
                      provider.setInputText(text);
                    }
                  },
                  readOnly: provider.isRecording,
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Paste Button (hidden during recording)
                    if (!provider.isRecording) ...[
                      GestureDetector(
                        onTap: () async {
                          final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                          if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
                            provider.textController.text = clipboardData.text!;
                            provider.setInputText(clipboardData.text!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Text pasted and ready to translate'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.green.shade600,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('No text found in clipboard'),
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
                                'Paste',
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
                    ],
                    
                    // Voice Input Button
                    GestureDetector(
                      onTap: () {
                        if (provider.isRecording) {
                          provider.stopRecording();
                        } else {
                          provider.startRecording();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: provider.isRecording ? Colors.red.shade500 : Colors.blue.shade500,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: (provider.isRecording ? Colors.red : Colors.blue).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              provider.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            if (provider.isRecording) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Stop Recording',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Recording Status
                if (provider.isRecording) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red.shade500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recording... Speak now',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
          // Translation Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade500,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Translation',
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
                  children: [
                    // Copy Button
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: provider.translatedText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Translation copied to clipboard'),
                            duration: Duration(seconds: 2),
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade500, Colors.blue.shade600],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.translate_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voicely',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Voice Translation App',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(
                    icon: Icons.language_rounded,
                    title: 'App Language',
                    subtitle: 'Change interface language',
                    onTap: () => _showLanguageDialog(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.star_rounded,
                    title: 'Rate Us',
                    subtitle: 'Rate Voicely on Play Store',
                    onTap: () => _rateApp(),
                  ),
                  _buildMenuItem(
                    icon: Icons.share_rounded,
                    title: 'Share App',
                    subtitle: 'Share Voicely with friends',
                    onTap: () => _shareApp(),
                  ),
                  _buildMenuItem(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    subtitle: 'View our privacy policy',
                    onTap: () => _openPrivacyPolicy(),
                  ),
                  _buildMenuItem(
                    icon: Icons.info_rounded,
                    title: 'About',
                    subtitle: 'App version and info',
                    onTap: () => _showAboutDialog(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.bug_report_rounded,
                    title: 'Report Bug',
                    subtitle: 'Report issues or feedback',
                    onTap: () => _reportBug(),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Made with ❤️ for translation',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.blue.shade600,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.grey.shade400,
        size: 16,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'App Language',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Text('🇺🇸'),
              title: Text('English'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: Text('🇹🇷'),
              title: Text('Türkçe'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _rateApp() {
    Navigator.of(context).pop(); // Close drawer
    // Open Play Store rating
    launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.example.voicely'));
  }

  void _shareApp() {
    Navigator.of(context).pop(); // Close drawer
    Share.share(
      'Check out Voicely - the best voice translation app! Download it from: https://play.google.com/store/apps/details?id=com.example.voicely',
      subject: 'Voicely - Voice Translation App',
    );
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).pop(); // Close drawer
    launchUrl(Uri.parse('https://your-website.com/privacy-policy'));
  }

  void _reportBug() {
    Navigator.of(context).pop(); // Close drawer
    launchUrl(Uri.parse('mailto:support@voicely.app?subject=Bug Report&body=Describe the issue:'));
  }

  void _showAboutDialog(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer
    showAboutDialog(
      context: context,
      applicationName: 'Voicely',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade500,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.translate_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        Text(
          'A powerful voice translation app that helps you communicate across languages with ease.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }
}