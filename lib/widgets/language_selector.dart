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
          width: screenWidth * 0.9,
          padding: const EdgeInsets.all(20),
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
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select Languages',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Language Selection Row
              Row(
                children: [
                  // From Language
                  Expanded(
                    child: _buildLanguageDropdown(
                      label: 'From',
                      value: provider.fromLang,
                      languages: provider.languages,
                      onChanged: (value) => provider.setFromLang(value!),
                      color: Colors.blue,
                    ),
                  ),
                  
                  // Swap Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GestureDetector(
                      onTap: () => provider.swapLanguages(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.purple.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  
                  // To Language
                  Expanded(
                    child: _buildLanguageDropdown(
                      label: 'To',
                      value: provider.toLang,
                      languages: provider.languages,
                      onChanged: (value) => provider.setToLang(value!),
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Popular Languages
              _buildPopularLanguages(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> languages,
    required Function(String?) onChanged,
    required Color color,
  }) {
    final selectedLanguage = languages.firstWhere(
      (lang) => lang['value'] == value,
      orElse: () => languages.first,
    );

    return Column(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color.lerp(color, Colors.black, 0.2)!,
                size: 16,
              ),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black87,
              ),
              items: languages.take(10).map((lang) {
                return DropdownMenuItem<String>(
                  value: lang['value'],
                  child: Row(
                    children: [
                      Flag.fromString(
                        lang['flag'] ?? 'UN',
                        height: 16,
                        width: 20,
                        borderRadius: 2,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lang['label'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularLanguages(TranslatorProvider provider) {
    final popularLanguages = [
      {'value': 'en', 'label': 'English', 'flag': 'GB'},
      {'value': 'es', 'label': 'Spanish', 'flag': 'ES'},
      {'value': 'fr', 'label': 'French', 'flag': 'FR'},
      {'value': 'de', 'label': 'German', 'flag': 'DE'},
      {'value': 'it', 'label': 'Italian', 'flag': 'IT'},
      {'value': 'pt', 'label': 'Portuguese', 'flag': 'PT'},
      {'value': 'ru', 'label': 'Russian', 'flag': 'RU'},
      {'value': 'ja', 'label': 'Japanese', 'flag': 'JP'},
      {'value': 'ko', 'label': 'Korean', 'flag': 'KR'},
      {'value': 'zh', 'label': 'Chinese', 'flag': 'CN'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Languages',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popularLanguages.map((lang) {
            final isSelected = provider.fromLang == lang['value'] || 
                              provider.toLang == lang['value'];
            
            return GestureDetector(
              onTap: () {
                if (provider.fromLang != lang['value']) {
                  provider.setToLang(lang['value']!);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.blue.shade100 
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.blue.shade300 
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flag.fromString(
                      lang['flag']!,
                      height: 12,
                      width: 16,
                      borderRadius: 1,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      lang['label']!,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected 
                            ? Colors.blue.shade700 
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
