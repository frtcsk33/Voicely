import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import '../providers/translator_provider.dart';
import '../services/upload_service.dart';
import '../widgets/app_drawer.dart';
import '../models/upload_result.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with TickerProviderStateMixin {
  File? _selectedFile;
  String? _fileName;
  String? _fileExtension;
  double _fileSize = 0;
  bool _isUploading = false;
  bool _isProcessing = false;
  double _uploadProgress = 0;
  double _processingProgress = 0;
  UploadResult? _result;
  String _selectedOutputFormat = 'txt';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _audioExtensions = ['mp3', 'wav', 'm4a', 'aac'];
  final List<String> _documentExtensions = ['txt', 'pdf', 'docx', 'doc'];
  final List<String> _outputFormats = ['txt', 'pdf', 'docx', 'srt', 'vtt'];

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

  bool get _isAudioFile => _fileExtension != null && _audioExtensions.contains(_fileExtension!.toLowerCase());
  bool get _isDocumentFile => _fileExtension != null && _documentExtensions.contains(_fileExtension!.toLowerCase());

  double get _maxFileSize => _isAudioFile ? 50 : 10; // MB

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'File Upload & Translation',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Upload History Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                _showUploadHistory(context);
              },
              icon: Icon(
                Icons.cloud_done_rounded,
                color: Colors.grey.shade700,
                size: 28,
              ),
              tooltip: 'Upload History',
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<TranslatorProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File Type Selection Cards
                  _buildFileTypeCards(),
                  
                  const SizedBox(height: 24),
                  
                  // Selected File Display
                  if (_selectedFile != null) ...[
                    _buildSelectedFileCard(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Language Selection
                  if (_selectedFile != null) ...[
                    _buildLanguageSelection(provider),
                    const SizedBox(height: 24),
                  ],
                  
                  // Output Format Selection
                  if (_selectedFile != null) ...[
                    _buildOutputFormatSelection(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Progress Indicators
                  if (_isUploading || _isProcessing) ...[
                    _buildProgressSection(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Upload Button
                  if (_selectedFile != null && !_isUploading && !_isProcessing)
                    _buildUploadButton(provider),
                  
                  // Results
                  if (_result != null) ...[
                    const SizedBox(height: 24),
                    _buildResultsSection(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFileTypeCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose File Type',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFileTypeCard(
                icon: Icons.audiotrack_rounded,
                title: 'Audio Files',
                subtitle: 'MP3, WAV, M4A\nMax 50MB',
                color: Colors.purple,
                onTap: () => _pickFile(type: FileType.audio),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFileTypeCard(
                icon: Icons.description_rounded,
                title: 'Documents',
                subtitle: 'PDF, DOCX, TXT\nMax 10MB',
                color: Colors.blue,
                onTap: () => _pickFile(type: FileType.custom, allowedExtensions: _documentExtensions),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                icon,
                size: 30,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileCard() {
    final fileSizeMB = _fileSize / (1024 * 1024);
    final isOverSize = fileSizeMB > _maxFileSize;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverSize ? Colors.red.shade300 : Colors.green.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOverSize ? Colors.red : Colors.green).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isAudioFile ? Colors.purple : Colors.blue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isAudioFile ? Icons.audiotrack_rounded : Icons.description_rounded,
                  color: _isAudioFile ? Colors.purple : Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName ?? 'Unknown file',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fileSizeMB.toStringAsFixed(2)} MB / ${_maxFileSize.toInt()} MB max',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isOverSize ? Colors.red : Colors.grey[600],
                        fontWeight: isOverSize ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedFile = null;
                    _fileName = null;
                    _fileExtension = null;
                    _fileSize = 0;
                    _result = null;
                  });
                },
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          if (isOverSize) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'File size exceeds the maximum limit. Please choose a smaller file.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageSelection(TranslatorProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Translation Settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Auto-detect',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showLanguagePicker(provider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getLanguageName(provider.toLang, provider),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutputFormatSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Output Format',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _getAvailableFormats().map((format) {
              final isSelected = _selectedOutputFormat == format;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedOutputFormat = format;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    format.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isUploading ? 'Uploading File...' : 'Processing File...',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          
          if (_isUploading) ...[
            LinearPercentIndicator(
              width: MediaQuery.of(context).size.width - 80,
              lineHeight: 8.0,
              percent: _uploadProgress / 100,
              backgroundColor: Colors.grey.shade200,
              progressColor: Colors.blue.shade500,
              barRadius: const Radius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload Progress: ${_uploadProgress.toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          
          if (_isProcessing) ...[
            LinearPercentIndicator(
              width: MediaQuery.of(context).size.width - 80,
              lineHeight: 8.0,
              percent: _processingProgress / 100,
              backgroundColor: Colors.grey.shade200,
              progressColor: Colors.green.shade500,
              barRadius: const Radius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              'Processing: ${_processingProgress.toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadButton(TranslatorProvider provider) {
    final fileSizeMB = _fileSize / (1024 * 1024);
    final isOverSize = fileSizeMB > _maxFileSize;
    
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isOverSize ? null : () => _uploadAndProcess(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_rounded,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Upload & Process',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Processing Complete!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Results preview
          if (_result?.originalText != null) ...[
            _buildResultPreview('Original Text', _result!.originalText!),
            const SizedBox(height: 12),
          ],
          
          if (_result?.translatedText != null) ...[
            _buildResultPreview('Translation', _result!.translatedText!),
            const SizedBox(height: 16),
          ],
          
          // Download button
          ElevatedButton(
            onPressed: () => _downloadResult(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.download_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Download ${_selectedOutputFormat.toUpperCase()}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPreview(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content.length > 200 ? '${content.substring(0, 200)}...' : content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // File picking logic
  Future<void> _pickFile({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileExtension = result.files.single.extension;
        final fileSize = await file.length();

        setState(() {
          _selectedFile = file;
          _fileName = fileName;
          _fileExtension = fileExtension;
          _fileSize = fileSize.toDouble();
          _result = null;
        });

        Fluttertoast.showToast(
          msg: 'File selected: $fileName',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error selecting file: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Upload and processing logic
  Future<void> _uploadAndProcess(TranslatorProvider provider) async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _uploadProgress = i.toDouble();
        });
      }

      setState(() {
        _isUploading = false;
        _isProcessing = true;
        _processingProgress = 0;
      });

      // Upload and process file
      final uploadService = UploadService();
      final result = await uploadService.uploadAndProcess(
        file: _selectedFile!,
        targetLanguage: provider.toLang,
        outputFormat: _selectedOutputFormat,
        onProgress: (progress) {
          setState(() {
            _processingProgress = progress;
          });
        },
      );

      setState(() {
        _isProcessing = false;
        _result = result;
      });

      Fluttertoast.showToast(
        msg: 'File processed successfully!',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isProcessing = false;
      });

      Fluttertoast.showToast(
        msg: 'Error: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _downloadResult() async {
    if (_result == null) return;

    try {
      final uploadService = UploadService();
      await uploadService.downloadResult(_result!.downloadUrl!, _selectedOutputFormat);
      
      Fluttertoast.showToast(
        msg: 'File downloaded successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Download error: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  List<String> _getAvailableFormats() {
    if (_isAudioFile) {
      return ['txt', 'pdf', 'docx', 'srt', 'vtt'];
    } else {
      return ['txt', 'pdf', 'docx'];
    }
  }

  String _getLanguageName(String langCode, TranslatorProvider provider) {
    final language = provider.languages.firstWhere(
      (lang) => lang['value'] == langCode,
      orElse: () => {'label': 'Turkish'},
    );
    return language['label'] ?? 'Turkish';
  }

  void _showLanguagePicker(TranslatorProvider provider) {
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
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Target Language',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: provider.targetLanguages.length,
                itemBuilder: (context, index) {
                  final language = provider.targetLanguages[index];
                  final isSelected = provider.toLang == language['value'];
                  
                  return GestureDetector(
                    onTap: () {
                      provider.setToLang(language['value']!);
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

  void _showUploadHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      enableDrag: true,
      builder: (context) => _UploadHistoryModal(),
    );
  }
}

class _UploadHistoryModal extends StatelessWidget {
  // Mock upload history data
  final List<Map<String, dynamic>> _uploadHistory = [
    {
      'id': '1',
      'fileName': 'audio_interview.mp3',
      'fileType': 'audio',
      'originalText': 'Hello, how are you today?',
      'translatedText': 'Merhaba, bugün nasılsın?',
      'sourceLanguage': 'en',
      'targetLanguage': 'tr',
      'outputFormat': 'txt',
      'timestamp': DateTime.now().subtract(Duration(minutes: 15)),
    },
    {
      'id': '2',
      'fileName': 'document.pdf',
      'fileType': 'document',
      'originalText': 'This is a sample document for translation...',
      'translatedText': 'Bu, çeviri için örnek bir belgedir...',
      'sourceLanguage': 'en',
      'targetLanguage': 'tr',
      'outputFormat': 'pdf',
      'timestamp': DateTime.now().subtract(Duration(hours: 2)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.cloud_done_rounded,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Upload History',
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
            child: _uploadHistory.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.green.shade200, width: 2),
                        ),
                        child: Icon(
                          Icons.cloud_off,
                          size: 40,
                          color: Colors.green.shade400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No uploads yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload and process files to see your history here',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _uploadHistory.length,
                  itemBuilder: (context, index) {
                    final item = _uploadHistory[index];
                    final isAudio = item['fileType'] == 'audio';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isAudio ? Colors.purple.shade100 : Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isAudio ? Icons.audiotrack_rounded : Icons.description_rounded,
                                        color: isAudio ? Colors.purple.shade600 : Colors.blue.shade600,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['outputFormat'].toString().toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: isAudio ? Colors.purple.shade600 : Colors.blue.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTime(item['timestamp']),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // File name
                            Text(
                              item['fileName'],
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Content preview
                            if (item['originalText'] != null) ...[
                              Text(
                                item['originalText'].length > 100 
                                  ? '${item['originalText'].substring(0, 100)}...'
                                  : item['originalText'],
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            // Language indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item['sourceLanguage'].toUpperCase()} → ${item['targetLanguage'].toUpperCase()}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
          
          // Bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}