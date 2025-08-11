import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';

class LanguageSwitcher extends StatelessWidget {
  final String language1;
  final String language1Name;
  final String language2;  
  final String language2Name;
  final VoidCallback onLanguage1Tap;
  final VoidCallback onLanguage2Tap;
  final VoidCallback onSwapTap;

  const LanguageSwitcher({
    super.key,
    required this.language1,
    required this.language1Name,
    required this.language2,
    required this.language2Name,
    required this.onLanguage1Tap,
    required this.onLanguage2Tap,
    required this.onSwapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
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
      ),
      child: Row(
        children: [
          // Language 1
          Expanded(
            child: _buildLanguageButton(
              context,
              language1,
              language1Name,
              onLanguage1Tap,
              const Color(0xFF3B82F6),
            ),
          ),
          
          // Swap button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: onSwapTap,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade100,
                      Colors.grey.shade200,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.grey.shade700,
                  size: 24,
                ),
              ),
            ),
          ),
          
          // Language 2
          Expanded(
            child: _buildLanguageButton(
              context,
              language2,
              language2Name,
              onLanguage2Tap,
              const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    String languageCode,
    String languageName,
    VoidCallback onTap,
    Color accentColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flag
            Flag.fromString(
              _getFlagCode(languageCode),
              height: 24,
              width: 32,
              borderRadius: 4,
            ),
            
            const SizedBox(height: 8),
            
            // Language name
            Text(
              languageName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Dropdown indicator
            const SizedBox(height: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: accentColor.withOpacity(0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  String _getFlagCode(String languageCode) {
    const Map<String, String> languageToFlag = {
      'tr': 'TR',
      'en': 'GB',
      'es': 'ES',
      'fr': 'FR',
      'de': 'DE',
      'it': 'IT',
      'pt': 'PT',
      'ru': 'RU',
      'ja': 'JP',
      'ko': 'KR',
      'zh': 'CN',
      'ar': 'SA',
      'hi': 'IN',
      'nl': 'NL',
      'sv': 'SE',
      'no': 'NO',
      'da': 'DK',
      'fi': 'FI',
      'pl': 'PL',
      'cs': 'CZ',
      'sk': 'SK',
      'hu': 'HU',
      'ro': 'RO',
      'bg': 'BG',
      'hr': 'HR',
      'sr': 'RS',
      'sl': 'SI',
      'lt': 'LT',
      'lv': 'LV',
      'et': 'EE',
      'el': 'GR',
      'he': 'IL',
      'th': 'TH',
      'vi': 'VN',
      'id': 'ID',
      'ms': 'MY',
      'tl': 'PH',
      'uk': 'UA',
    };
    
    return languageToFlag[languageCode] ?? 'GB';
  }
}