import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flag/flag.dart';
import '../providers/translator_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        return Container(
          width: screenWidth * 0.95,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // From Language
              Expanded(
                child: _buildLanguageButton(
                  context,
                  provider,
                  provider.fromLang,
                  'From',
                  true,
                ),
              ),
              
              // Swap Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: provider.swapLanguages,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ),
              
              // To Language
              Expanded(
                child: _buildLanguageButton(
                  context,
                  provider,
                  provider.toLang,
                  'To',
                  false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    TranslatorProvider provider,
    String langCode,
    String label,
    bool isFrom,
  ) {
    final language = provider.languages.firstWhere(
      (lang) => lang['value'] == langCode,
      orElse: () => {'label': 'Unknown', 'value': langCode, 'flag': 'GB'},
    );

    return GestureDetector(
      onTap: () => _showLanguagePicker(context, provider, isFrom),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Flag.fromString(
                  language['flag']!,
                  height: 20,
                  width: 28,
                  borderRadius: 4,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    language['label']!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, TranslatorProvider provider, bool isFrom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                  Text(
                    isFrom ? 'Select source language' : 'Select target language',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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
            
            // Language List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: provider.languages.length,
                itemBuilder: (context, index) {
                  final language = provider.languages[index];
                  final isSelected = (isFrom ? provider.fromLang : provider.toLang) == language['value'];
                  
                  return GestureDetector(
                    onTap: () {
                      if (isFrom) {
                        provider.setFromLang(language['value']!);
                      } else {
                        provider.setToLang(language['value']!);
                      }
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade200 : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Flag.fromString(
                            language['flag']!,
                            height: 24,
                            width: 32,
                            borderRadius: 4,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              language['label']!,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              color: Colors.blue.shade600,
                              size: 20,
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
    );
  }
}