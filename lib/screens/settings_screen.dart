import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flag/flag.dart';
import '../providers/translator_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              provider.getLocalizedText('settings'),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: Icon(
                    Icons.language,
                    color: Colors.blue[600],
                    size: 28,
                  ),
                  title: Text(
                    provider.getLocalizedText('app_language'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    provider.appLanguages.firstWhere(
                      (lang) => lang['value'] == provider.appLanguage,
                    )['label']!,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                  onTap: () {
                    _showLanguageDialog(context, provider);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: Icon(
                    Icons.info_outline,
                    color: Colors.orange[600],
                    size: 28,
                  ),
                  title: Text(
                    provider.getLocalizedText('about_app'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Voicely v1.0.0',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, TranslatorProvider provider) {
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Voicely',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sesli ve metin çeviri uygulaması',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Özellikler:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Metin çevirisi\n• Ses çevirisi\n• Kamera çevirisi\n• Favori sistemi\n• Çoklu dil desteği',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tamam',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }
} 