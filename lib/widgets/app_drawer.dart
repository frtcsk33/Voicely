import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../providers/translator_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/pro_subscription_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import 'package:flag/flag.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<TranslatorProvider, AuthService, UserService>(
      builder: (context, translatorProvider, authService, userService, child) {
        return Drawer(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFE2E8F0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Modern Header
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.translate_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voicely',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                translatorProvider.getLocalizedText('voice_translator'),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Modern Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // User Section
                      if (authService.isAuthenticated) ...[
                        _buildUserCard(authService, userService, translatorProvider, context),
                        const SizedBox(height: 20),
                      ],
                      
                      if (!authService.isAuthenticated) ...[
                        _buildModernMenuItem(
                          icon: Icons.login_rounded,
                          title: translatorProvider.getLocalizedText('sign_in'),
                          subtitle: translatorProvider.getLocalizedText('access_account'),
                          onTap: () => _navigateToSignIn(context),
                          color: Colors.green,
                          isImportant: true,
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Main Menu Items
                      _buildModernMenuItem(
                        icon: Icons.language_rounded,
                        title: translatorProvider.getLocalizedText('app_language'),
                        subtitle: translatorProvider.getLocalizedText('change_interface_language'),
                        onTap: () => _showLanguageDialog(context, translatorProvider),
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildModernMenuItem(
                        icon: Icons.star_rounded,
                        title: translatorProvider.getLocalizedText('rate_us'),
                        subtitle: translatorProvider.getLocalizedText('rate_on_playstore'),
                        onTap: () => _rateApp(),
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildModernMenuItem(
                        icon: Icons.share_rounded,
                        title: translatorProvider.getLocalizedText('share_app'),
                        subtitle: translatorProvider.getLocalizedText('share_with_friends'),
                        onTap: () => _shareApp(translatorProvider),
                        color: Colors.cyan,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildModernMenuItem(
                        icon: Icons.info_rounded,
                        title: translatorProvider.getLocalizedText('about'),
                        subtitle: translatorProvider.getLocalizedText('app_info'),
                        onTap: () => _showAbout(context, translatorProvider),
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildModernMenuItem(
                        icon: Icons.privacy_tip_rounded,
                        title: translatorProvider.getLocalizedText('privacy_policy'),
                        subtitle: translatorProvider.getLocalizedText('privacy_info'),
                        onTap: () => _showPrivacyPolicy(translatorProvider),
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 12),
                      
                      if (authService.isAuthenticated) ...[
                        _buildModernMenuItem(
                          icon: Icons.diamond_rounded,
                          title: translatorProvider.getLocalizedText('premium'),
                          subtitle: translatorProvider.getLocalizedText('unlock_features'),
                          onTap: () => _navigateToPro(context),
                          color: Colors.orange,
                          isImportant: !userService.isPro,
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      if (authService.isAuthenticated) ...[
                        _buildModernMenuItem(
                          icon: Icons.settings_rounded,
                          title: translatorProvider.getLocalizedText('settings'),
                          subtitle: translatorProvider.getLocalizedText('app_preferences'),
                          onTap: () => _navigateToSettings(context),
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(height: 12),
                        
                        _buildModernMenuItem(
                          icon: Icons.logout_rounded,
                          title: translatorProvider.getLocalizedText('sign_out'),
                          subtitle: translatorProvider.getLocalizedText('logout_account'),
                          onTap: () => _signOut(context, authService, translatorProvider),
                          color: Colors.red,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Modern Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Made with',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'by Voicely Team',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserCard(AuthService authService, UserService userService, TranslatorProvider translatorProvider, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditProfileScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue.shade100,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.account_circle_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userService.displayName ?? 'User',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  translatorProvider.getLocalizedText('manage_account'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required MaterialColor color,
    bool isImportant = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isImportant ? color.shade200 : Colors.grey.shade200,
              width: isImportant ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isImportant ? color.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                blurRadius: isImportant ? 15 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isImportant 
                        ? [color.shade400, color.shade600]
                        : [color.shade100, color.shade200],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isImportant ? Colors.white : color.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSignIn(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToPro(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProSubscriptionScreen()),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _showLanguageDialog(BuildContext context, TranslatorProvider provider) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            provider.getLocalizedText('select_language'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.appLanguages.length,
              itemBuilder: (context, index) {
                final language = provider.appLanguages[index];
                final isSelected = language['value'] == provider.appLanguage;
                
                return ListTile(
                  leading: Flag.fromString(
                    language['flag'] ?? 'UN',
                    height: 20,
                    width: 30,
                    borderRadius: 3,
                  ),
                  title: Text(
                    language['label']!,
                    style: GoogleFonts.poppins(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.blue[600],
                        )
                      : null,
                  onTap: () {
                    provider.setAppLanguage(language['value']!);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                provider.getLocalizedText('cancel'),
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _rateApp() async {
    const url = 'https://play.google.com/store/apps/details?id=com.voicely.app';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _shareApp(TranslatorProvider provider) {
    Share.share(
      provider.getLocalizedText('share_message') + '\n\nhttps://play.google.com/store/apps/details?id=com.voicely.app',
      subject: provider.getLocalizedText('share_subject'),
    );
  }

  void _showPrivacyPolicy(TranslatorProvider provider) async {
    const url = 'https://voicely.app/privacy-policy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _showAbout(BuildContext context, TranslatorProvider provider) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          provider.getLocalizedText('about'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voicely v1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(provider.getLocalizedText('app_description')),
            const SizedBox(height: 16),
            Text(
              '© 2024 Voicely Team',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(provider.getLocalizedText('close')),
          ),
        ],
      ),
    );
  }


  void _signOut(BuildContext context, AuthService authService, TranslatorProvider provider) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          provider.getLocalizedText('sign_out'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(provider.getLocalizedText('confirm_sign_out')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(provider.getLocalizedText('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authService.signOut();
            },
            child: Text(
              provider.getLocalizedText('sign_out'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}