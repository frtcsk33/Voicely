import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_category.dart';
import '../models/word.dart';
import 'supabase_client.dart';

class BooksService extends ChangeNotifier {
  List<BookCategory> _categories = [];
  List<Word> _words = [];
  List<Word> _favoriteWords = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<BookCategory> get categories => _categories;
  List<Word> get words => _words;
  List<Word> get favoriteWords => _favoriteWords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  BooksService() {
    _initializeDemoData();
  }

  /// Initialize with demo data when Supabase is not available
  void _initializeDemoData() {
    try {
      // Check if we're in demo mode
      if (SupabaseConfig.supabaseUrl.contains('your-project-ref')) {
        _loadDemoData();
      } else {
        // Try to load from Supabase
        loadCategories();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Books service running in demo mode: $e');
      }
      _loadDemoData();
    }
  }

  void _loadDemoData() {
    _categories = [
      BookCategory(
        id: '1',
        name: 'İfadeler',
        description: 'Günlük kullanılan ifadeler',
        iconName: 'chat',
        colorHex: '#FF6B6B',
        wordCount: 25,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      BookCategory(
        id: '2',
        name: 'Fiiller',
        description: 'Temel fiiller ve kullanımları',
        iconName: 'directions_run',
        colorHex: '#4ECDC4',
        wordCount: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      BookCategory(
        id: '3',
        name: 'Temel',
        description: 'Temel kelimeler',
        iconName: 'school',
        colorHex: '#45B7D1',
        wordCount: 40,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      BookCategory(
        id: '4',
        name: 'Kültür',
        description: 'Kültürel kelimeler',
        iconName: 'public',
        colorHex: '#96CEB4',
        wordCount: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      BookCategory(
        id: '5',
        name: 'Seyahat',
        description: 'Seyahat ile ilgili kelimeler',
        iconName: 'flight',
        colorHex: '#FFEAA7',
        wordCount: 35,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      BookCategory(
        id: '6',
        name: 'Teknik',
        description: 'Teknik terimler',
        iconName: 'computer',
        colorHex: '#DDA0DD',
        wordCount: 28,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      BookCategory(
        id: '7',
        name: 'Objects',
        description: 'Günlük nesneler',
        iconName: 'category',
        colorHex: '#FFB347',
        wordCount: 45,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Demo words for "İfadeler" category
    _words = [
      Word(
        id: '1',
        word: 'Hello',
        meaning: 'Merhaba',
        pronunciation: '/həˈloʊ/',
        categoryId: '1',
        languageFrom: 'en',
        languageTo: 'tr',
        exampleSentence: 'Hello, how are you?',
        exampleTranslation: 'Merhaba, nasılsın?',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Word(
        id: '2',
        word: 'Thank you',
        meaning: 'Teşekkür ederim',
        pronunciation: '/θæŋk juː/',
        categoryId: '1',
        languageFrom: 'en',
        languageTo: 'tr',
        exampleSentence: 'Thank you for your help.',
        exampleTranslation: 'Yardımın için teşekkür ederim.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Word(
        id: '3',
        word: 'Excuse me',
        meaning: 'Affedersiniz',
        pronunciation: '/ɪkˈskjuːz miː/',
        categoryId: '1',
        languageFrom: 'en',
        languageTo: 'tr',
        exampleSentence: 'Excuse me, where is the bathroom?',
        exampleTranslation: 'Affedersiniz, banyo nerede?',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Word(
        id: '4',
        word: 'Please',
        meaning: 'Lütfen',
        pronunciation: '/pliːz/',
        categoryId: '1',
        languageFrom: 'en',
        languageTo: 'tr',
        exampleSentence: 'Please help me.',
        exampleTranslation: 'Lütfen bana yardım et.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Word(
        id: '5',
        word: 'I\'m sorry',
        meaning: 'Özür dilerim',
        pronunciation: '/aɪm ˈsɔːri/',
        categoryId: '1',
        languageFrom: 'en',
        languageTo: 'tr',
        exampleSentence: 'I\'m sorry for being late.',
        exampleTranslation: 'Geç kaldığım için özür dilerim.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    notifyListeners();
  }

  /// Load categories from Supabase
  Future<void> loadCategories() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await supabase
          .from('book_categories')
          .select('*')
          .order('created_at', ascending: true);

      _categories = (response as List)
          .map((json) => BookCategory.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load categories: $e');
      if (kDebugMode) {
        print('Error loading categories: $e');
      }
      // Fallback to demo data
      _loadDemoData();
    } finally {
      _setLoading(false);
    }
  }

  /// Load words by category
  Future<void> loadWordsByCategory(String categoryId) async {
    try {
      _setLoading(true);
      _clearError();

      // Demo mode - filter demo words
      if (SupabaseConfig.supabaseUrl.contains('your-project-ref')) {
        _words = _words.where((word) => word.categoryId == categoryId).toList();
        notifyListeners();
        return;
      }

      final response = await supabase
          .from('words')
          .select('*')
          .eq('category_id', categoryId)
          .order('created_at', ascending: true);

      _words = (response as List)
          .map((json) => Word.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load words: $e');
      if (kDebugMode) {
        print('Error loading words: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Search words
  List<Word> searchWords(String query) {
    if (query.isEmpty) return _words;
    
    return _words.where((word) =>
        word.word.toLowerCase().contains(query.toLowerCase()) ||
        word.meaning.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String wordId) async {
    try {
      final wordIndex = _words.indexWhere((word) => word.id == wordId);
      if (wordIndex == -1) return;

      final word = _words[wordIndex];
      final updatedWord = word.copyWith(isFavorite: !word.isFavorite);

      // Demo mode - just update local state
      if (SupabaseConfig.supabaseUrl.contains('your-project-ref')) {
        _words[wordIndex] = updatedWord;
        _updateFavoritesList();
        notifyListeners();
        return;
      }

      // Update in Supabase
      await supabase
          .from('words')
          .update({'is_favorite': updatedWord.isFavorite})
          .eq('id', wordId);

      _words[wordIndex] = updatedWord;
      _updateFavoritesList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update favorite: $e');
      if (kDebugMode) {
        print('Error updating favorite: $e');
      }
    }
  }

  /// Load favorite words
  Future<void> loadFavoriteWords() async {
    try {
      _setLoading(true);
      _clearError();

      // Demo mode - filter from current words
      if (SupabaseConfig.supabaseUrl.contains('your-project-ref')) {
        _favoriteWords = _words.where((word) => word.isFavorite).toList();
        notifyListeners();
        return;
      }

      final response = await supabase
          .from('words')
          .select('*')
          .eq('is_favorite', true)
          .order('created_at', ascending: true);

      _favoriteWords = (response as List)
          .map((json) => Word.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load favorites: $e');
      if (kDebugMode) {
        print('Error loading favorites: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  void _updateFavoritesList() {
    _favoriteWords = _words.where((word) => word.isFavorite).toList();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
