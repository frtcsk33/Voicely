import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/book_category.dart';
import '../models/word.dart';
import '../services/books_service.dart';
import '../providers/translator_provider.dart';

class WordListScreen extends StatefulWidget {
  final BookCategory category;

  const WordListScreen({
    super.key,
    required this.category,
  });

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  List<Word> _filteredWords = [];
  bool _showFavoritesOnly = false;

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
    
    // Load words for this category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BooksService>().loadWordsByCategory(widget.category.id);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterWords(List<Word> words) {
    setState(() {
      if (_showFavoritesOnly) {
        _filteredWords = words.where((word) => word.isFavorite).toList();
      } else {
        _filteredWords = words;
      }

      if (_searchController.text.isNotEmpty) {
        _filteredWords = _filteredWords.where((word) =>
          word.word.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          word.meaning.toLowerCase().contains(_searchController.text.toLowerCase())
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.category.colorHex);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.category.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: categoryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
            },
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            tooltip: _showFavoritesOnly ? 'Tümünü Göster' : 'Sadece Favoriler',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<BooksService>(
          builder: (context, booksService, child) {
            // Update filtered words when data changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _filterWords(booksService.words);
            });

            if (booksService.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (booksService.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kelimeler yüklenemedi',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => booksService.loadWordsByCategory(widget.category.id),
                      child: Text(
                        'Tekrar Dene',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Search and Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => _filterWords(booksService.words),
                          style: GoogleFonts.poppins(),
                          decoration: InputDecoration(
                            hintText: 'Kelime ara...',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[500],
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[500],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Stats
                      Row(
                        children: [
                          Icon(
                            Icons.book,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_filteredWords.length} kelime',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (_showFavoritesOnly)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Favoriler',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Words List
                Expanded(
                  child: _filteredWords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showFavoritesOnly ? Icons.favorite_border : Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _showFavoritesOnly 
                                    ? 'Henüz favori kelime yok'
                                    : _searchController.text.isNotEmpty
                                        ? 'Kelime bulunamadı'
                                        : 'Kelime listesi boş',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredWords.length,
                          itemBuilder: (context, index) {
                            final word = _filteredWords[index];
                            return _buildWordCard(word, categoryColor);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWordCard(Word word, Color categoryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Word and Favorite
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            word.word,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            word.pronunciation,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.read<BooksService>().toggleFavorite(word.id),
                      icon: Icon(
                        word.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: word.isFavorite ? Colors.red[400] : Colors.grey[400],
                      ),
                      tooltip: word.isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Meaning
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: categoryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    word.meaning,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Example Sentence
                if (word.exampleSentence != null && word.exampleSentence!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Örnek:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          word.exampleSentence!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (word.exampleTranslation != null && word.exampleTranslation!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            word.exampleTranslation!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Action Buttons
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _speakWord(word),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.volume_up,
                            color: categoryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dinle',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _copyWord(word),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.copy,
                            color: Colors.grey[600],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kopyala',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _shareWord(word),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.share,
                            color: Colors.grey[600],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Paylaş',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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

  Color _getCategoryColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  void _speakWord(Word word) async {
    try {
      final provider = context.read<TranslatorProvider>();
      await provider.speak(word.word, word.languageFrom);
    } catch (e) {
      _showSnackBar('Ses çalınamadı: $e', isError: true);
    }
  }

  void _copyWord(Word word) {
    Clipboard.setData(ClipboardData(text: '${word.word} - ${word.meaning}'));
    _showSnackBar('Kelime kopyalandı');
  }

  void _shareWord(Word word) {
    String shareText = '${word.word} - ${word.meaning}';
    if (word.exampleSentence != null && word.exampleSentence!.isNotEmpty) {
      shareText += '\n\nÖrnek: ${word.exampleSentence}';
      if (word.exampleTranslation != null && word.exampleTranslation!.isNotEmpty) {
        shareText += '\n${word.exampleTranslation}';
      }
    }
    shareText += '\n\nVoicely uygulamasından paylaşıldı';
    Share.share(shareText);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
