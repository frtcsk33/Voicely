import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/translator_provider.dart';

class TranslationCard extends StatelessWidget {
  const TranslationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        // This widget is now simplified and integrated into the main interface
        // It's kept for backward compatibility but not used in the new design
        return const SizedBox.shrink();
      },
    );
  }
}