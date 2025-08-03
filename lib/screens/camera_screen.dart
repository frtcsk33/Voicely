import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/translator_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  String _recognizedText = '';
  String _translatedText = '';
  bool _isProcessing = false;
  bool _isTranslating = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Kamera Çeviri',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
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
            tooltip: 'Ayarlar',
          ),
        ],
      ),
      body: Consumer<TranslatorProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Dil seçimi
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              'Hedef Dil',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
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
              ),
              
              // Ana içerik
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Fotoğraf seçimi
                      if (_selectedImage == null)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(60),
                                    border: Border.all(color: Colors.blue[200]!, width: 2),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 60,
                                    color: Colors.blue[600],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Fotoğraf Seçin',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Kameradan çekin veya galeriden seçin',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _takePhoto(),
                                      icon: const Icon(Icons.camera_alt),
                                      label: Text(
                                        'Fotoğraf Çek',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[600],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _selectFromGallery(),
                                      icon: const Icon(Icons.photo_library),
                                      label: Text(
                                        'Galeriden Seç',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[600],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Seçilen fotoğraf ve sonuçlar
                      if (_selectedImage != null)
                        Expanded(
                          child: Column(
                            children: [
                              // Fotoğraf
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb
                                      ? Image.network(
                                          _selectedImage!.path,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Tanınan metin
                              if (_recognizedText.isNotEmpty)
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tanınan Metin:',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            child: Text(
                                              _recognizedText,
                                              style: GoogleFonts.poppins(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              
                              // Çeviri
                              if (_translatedText.isNotEmpty)
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Çeviri:',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              onPressed: () => _speakTranslation(),
                                              icon: Icon(
                                                Icons.volume_up,
                                                color: Colors.green[600],
                                              ),
                                              tooltip: 'Oku',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            child: Text(
                                              _translatedText,
                                              style: GoogleFonts.poppins(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              
                              // Butonlar
                              if (_recognizedText.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _isTranslating ? null : () => _translateText(),
                                          icon: _isTranslating
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.translate),
                                          label: Text(
                                            _isTranslating ? 'Çeviriliyor...' : 'Çevir',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[600],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: () => _resetScreen(),
                                        icon: const Icon(Icons.refresh),
                                        label: Text(
                                          'Yeni',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[600],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
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
          );
        },
      ),
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
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          items: languages
              .map((lang) => DropdownMenuItem(
                    value: lang['value'],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        lang['label']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          menuMaxHeight: 300,
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
          _recognizedText = '';
          _translatedText = '';
        });
        await _recognizeText();
      }
    } catch (e) {
      _showErrorDialog('Kamera erişimi hatası: $e');
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _recognizedText = '';
          _translatedText = '';
        });
        await _recognizeText();
      }
    } catch (e) {
      _showErrorDialog('Galeri erişimi hatası: $e');
    }
  }

  Future<void> _recognizeText() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Web'de metin tanıma özelliği henüz desteklenmiyor
      // Bu yüzden placeholder metin gösteriyoruz
      if (kIsWeb) {
        setState(() {
          _recognizedText = 'Web\'de metin tanıma özelliği henüz desteklenmiyor. Lütfen mobil uygulamayı kullanın.';
          _isProcessing = false;
        });
        return;
      }

      // Mobil için gerçek metin tanıma kodu buraya gelecek
      setState(() {
        _recognizedText = 'Metin tanıma özelliği yakında gelecek...';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Metin tanıma hatası: $e');
    }
  }

  Future<void> _translateText() async {
    if (_recognizedText.isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final provider = context.read<TranslatorProvider>();
      final response = await provider.translateTextFromImage(_recognizedText, provider.toLang);
      
      setState(() {
        _translatedText = response;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _isTranslating = false;
      });
      _showErrorDialog('Çeviri hatası: $e');
    }
  }

  Future<void> _speakTranslation() async {
    if (_translatedText.isEmpty) return;

    try {
      final provider = context.read<TranslatorProvider>();
      await provider.speak(_translatedText, provider.toLang);
    } catch (e) {
      _showErrorDialog('Ses çalma hatası: $e');
    }
  }

  void _resetScreen() {
    setState(() {
      _selectedImage = null;
      _recognizedText = '';
      _translatedText = '';
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Hata',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(),
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