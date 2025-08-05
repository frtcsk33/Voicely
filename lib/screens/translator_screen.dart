import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flag/flag.dart';
import '../providers/translator_provider.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  late TextEditingController _inputController;
  late TextEditingController _outputController;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _outputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        // Controller'ları güncelle
        if (_inputController.text != provider.inputText) {
          _inputController.text = provider.inputText;
        }
        if (_outputController.text != provider.translatedText) {
          _outputController.text = provider.translatedText;
        }

        return Container(
          color: Colors.grey[50],
          child: Column(
            children: [
              // AppBar
              Container(
                color: Colors.white,
                child: AppBar(
                  title: const Text(''),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  centerTitle: true,
                  actions: [
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                      icon: const Icon(Icons.settings),
                      tooltip: provider.getLocalizedText('settings'),
                    ),
                  ],
                ),
              ),
              // Ana içerik
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Language Selection
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Dil seçimi satırı
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                                        child: Text(
                                          provider.getLocalizedText('source_language'),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                      _buildLanguageDropdown(
                                        context,
                                        'Kaynak Dil',
                                        provider.fromLang,
                                        (value) => provider.setFromLang(value!),
                                        provider.languages,
                                      ),
                                    ],
                                  ),
                                ),
                                // Ortalanmış dil değiştirme butonu
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 30),
                                      child: GestureDetector(
                                        onTap: () => provider.swapLanguages(),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.blue[200]!),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.blue.withOpacity(0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.swap_horiz,
                                            color: Colors.blue[600],
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                                        child: Text(
                                          provider.getLocalizedText('target_language'),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                      _buildLanguageDropdown(
                                        context,
                                        'Hedef Dil',
                                        provider.toLang,
                                        (value) => provider.setToLang(value!),
                                        provider.languages,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Favori butonu kısmını kaldır
                      
                      // Translation Area - sabit yükseklik
                      Container(
                        height: MediaQuery.of(context).size.height * 0.65,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Source Language Text Area
                            Container(
                              height: (MediaQuery.of(context).size.height * 0.65 - 40 - 90) / 2, // (total - padding - button) / 2
                              child: _buildTextArea(
                                label: _getLanguageName(provider.fromLang, provider.languages),
                                controller: _inputController,
                                onChanged: (text) => provider.setInputText(text),
                                isInput: true,
                                onStopRecord: () => provider.stopRecording(),
                                backgroundColor: Colors.white,
                                borderColor: Colors.grey[300]!,
                              ),
                            ),
                            
                            // Ses butonu - metin kutucuğunun altında ortalanmış
                            Container(
                              height: 90,
                              alignment: Alignment.center,
                              child: Consumer<TranslatorProvider>(
                                builder: (context, provider, child) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: Colors.blue[200]!),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _buildRecordingButton(() => provider.stopRecording()),
                                  );
                                },
                              ),
                            ),
                            
                            // Target Language Text Area
                            Container(
                              height: (MediaQuery.of(context).size.height * 0.65 - 40 - 90) / 2, // (total - padding - button) / 2
                              child: _buildTextArea(
                                label: _getLanguageName(provider.toLang, provider.languages),
                                controller: _outputController,
                                onChanged: (text) {}, // Read-only
                                isInput: false,
                                onStopRecord: null,
                                backgroundColor: Colors.white,
                                borderColor: Colors.grey[300]!,
                                showActionButtons: true, // Sağ alt köşede butonlar
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageDropdown(
    BuildContext context,
    String label,
    String value,
    Function(String?) onChanged,
    List<Map<String, String>> languages,
  ) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 18),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          items: languages
              .map((lang) => DropdownMenuItem(
                    value: lang['value'],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Flag.fromString(
                            lang['flag'] ?? 'UN',
                            height: 16,
                            width: 24,
                            borderRadius: 2,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lang['label']!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextArea({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    required bool isInput,
    required VoidCallback? onStopRecord,
    required Color backgroundColor,
    required Color borderColor,
    bool showActionButtons = false,
    bool showRecordingButton = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 140, // Sabit yükseklik
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                TextField(
                  controller: controller,
                  onChanged: onChanged,
                  maxLines: 6,
                  minLines: 1,
                  enabled: isInput,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontSize: 16,
                    color: isInput ? Colors.black87 : Colors.grey[700],
                  ),
                  decoration: InputDecoration(
                    hintText: isInput ? 'Metni girin...' : 'Çeviri...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                // Sağ alt köşede butonlar
                if (showActionButtons)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _buildTranslationActions(),
                  ),
                // Sağ alt köşede oku butonu (sadece input için)
                if (isInput && controller.text.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFavoriteStar(),
                        const SizedBox(width: 8),
                        _buildReadButton(controller.text),
                      ],
                    ),
                  ),
                // Sağ üst köşede temizle (x) butonu (sadece input için)
                if (isInput && controller.text.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        controller.clear();
                        Provider.of<TranslatorProvider>(context, listen: false).setInputText('');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingButton(VoidCallback? onStopRecord) {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: provider.isRecording
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: IconButton(
                      key: const ValueKey('recording'),
                      onPressed: onStopRecord,
                      alignment: Alignment.center,
                      icon: Icon(
                        Icons.stop,
                        color: Colors.red[600],
                        size: 28,
                      ),
                      tooltip: 'Kaydı Durdur',
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    key: const ValueKey('not_recording'),
                    onPressed: () => provider.startRecording(),
                    icon: Icon(
                      Icons.mic,
                      color: Colors.blue[600],
                      size: 28,
                    ),
                    tooltip: 'Konuş',
                  ),
                ),
        );
      },
    );
  }

  Widget _buildTranslationActions() {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        if (provider.translatedText.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  _copyToClipboard(provider.translatedText);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Metin panoya kopyalandı',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.green[600],
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(
                  Icons.copy,
                  color: Colors.blue[600],
                  size: 18,
                ),
                tooltip: 'Kopyala',
              ),
              IconButton(
                onPressed: () => _shareText(provider.translatedText),
                icon: Icon(
                  Icons.share,
                  color: Colors.green[600],
                  size: 18,
                ),
                tooltip: 'Paylaş',
              ),
              IconButton(
                onPressed: () => provider.speak(provider.translatedText, provider.toLang),
                icon: Icon(
                  Icons.volume_up,
                  color: Colors.orange[600],
                  size: 18,
                ),
                tooltip: 'Oku',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadButton(String text) {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => provider.speak(text, provider.fromLang),
            icon: Icon(
              Icons.volume_up,
              color: Colors.orange[600],
              size: 20,
            ),
            tooltip: 'Oku',
          ),
        );
      },
    );
  }

  Widget _buildFavoriteStar() {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              provider.toggleFavorite();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    provider.isCurrentTranslationFavorited
                        ? 'Bu çeviriyi favorilerinize eklediniz'
                        : 'Bu çeviriyi favorilerinizden çıkardınız',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: provider.isCurrentTranslationFavorited 
                      ? Colors.green[600] 
                      : Colors.orange[600],
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(
              provider.isCurrentTranslationFavorited 
                  ? Icons.star 
                  : Icons.star_border,
              color: provider.isCurrentTranslationFavorited 
                  ? Colors.amber[600] 
                  : Colors.grey[600],
              size: 22,
            ),
            tooltip: 'Favorilere Ekle',
          ),
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  void _shareText(String text) {
    Share.share(
      text,
      subject: 'Voicely Çeviri',
    );
  }

  String _getLanguageName(String langCode, List<Map<String, String>> languages) {
    final language = languages.firstWhere(
      (lang) => lang['value'] == langCode,
      orElse: () => {'label': 'Bilinmeyen Dil'},
    );
    return language['label'] ?? 'Bilinmeyen Dil';
  }
} 