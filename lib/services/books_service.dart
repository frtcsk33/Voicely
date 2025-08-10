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
    if (kDebugMode) {
      _testDatabaseConnection();
    }
    loadCategories();
  }

  /// Test database connection and table access
  Future<void> _testDatabaseConnection() async {
    if (kDebugMode) {
      print('=== BooksService: TESTING DATABASE CONNECTION ===');
      print('BooksService: Supabase URL: ${SupabaseConfig.supabaseUrl}');
      print('BooksService: Supabase Key: ${SupabaseConfig.supabaseAnonKey.substring(0, 20)}...');
      
      try {
        // Test the most basic query possible
        print('BooksService: Testing basic SELECT query...');
        final basicTest = await supabase
            .from('categories')
            .select('*')
            .limit(1);
        print('BooksService: Basic query result: $basicTest');
        print('BooksService: Basic query success! Found ${basicTest?.length ?? 0} records');

        // Test if we can get all categories without any constraints
        print('BooksService: Testing full categories query...');
        final allCategories = await supabase
            .from('categories')
            .select('*');
        print('BooksService: All categories result: $allCategories');
        print('BooksService: Total categories found: ${allCategories?.length ?? 0}');
        
        if (allCategories != null && allCategories.isNotEmpty) {
          print('BooksService: First category sample: ${allCategories[0]}');
          print('BooksService: Available columns: ${allCategories[0].keys.toList()}');
        }
        
      } catch (e, stackTrace) {
        print('BooksService: ❌ DATABASE CONNECTION FAILED!');
        print('BooksService: Error: $e');
        print('BooksService: Stack trace: $stackTrace');
      }
      print('=== BooksService: CONNECTION TEST COMPLETE ===');
    }
  }

  /// Load categories from Supabase
  Future<void> loadCategories() async {
    try {
      _setLoading(true);
      _clearError();

      if (kDebugMode) {
        print('BooksService: Starting to load categories from database...');
        print('BooksService: Supabase URL: ${SupabaseConfig.supabaseUrl}');
        print('BooksService: Using table: categories');
        print('BooksService: Supabase client status: ${supabase.toString()}');
      }

      // First try a simple limited query to test connection
      if (kDebugMode) {
        try {
          final testResponse = await supabase
              .from('categories')
              .select('id, name')
              .limit(5);
          print('BooksService: Categories table test response: $testResponse');
          print('BooksService: Test response length: ${testResponse?.length ?? 'null'}');
        } catch (e) {
          print('BooksService: Error getting test data: $e');
        }
      }

      final response = await supabase
          .from('categories')
          .select('*');

      if (kDebugMode) {
        print('BooksService: Response type: ${response.runtimeType}');
        print('BooksService: Response length: ${response?.length ?? 'null'}');
        print('BooksService: Full response: $response');
      }

      if (response != null && response is List) {
        if (response.isEmpty) {
          _categories = [];
          _setError('Database connected but categories table is empty. Please add categories to your Supabase database.');
          if (kDebugMode) {
            print('BooksService: ⚠️ Categories table is empty!');
          }
        } else {
          _categories = response.map((json) {
            if (kDebugMode) {
              print('BooksService: Processing category JSON: $json');
              print('BooksService: JSON keys: ${json.keys.toList()}');
            }
            try {
              return BookCategory.fromJson(json);
            } catch (e) {
              if (kDebugMode) {
                print('BooksService: Error parsing category JSON: $e');
                print('BooksService: Problematic JSON: $json');
              }
              rethrow;
            }
          }).toList();
          
          if (kDebugMode) {
            print('BooksService: ✅ Successfully loaded ${_categories.length} categories from database');
            for (final category in _categories) {
              print('BooksService: Category - ID: ${category.id}, Name: ${category.name}, WordCount: ${category.wordCount}');
            }
          }
        }
      } else {
        _categories = [];
        _setError('Database connection failed or categories table does not exist. Response: $response');
        if (kDebugMode) {
          print('BooksService: ❌ Invalid response from database - response is null or not a List');
          print('BooksService: Response type: ${response.runtimeType}');
          print('BooksService: Response value: $response');
        }
      }

      notifyListeners();
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to load categories: $e';
      _setError(errorMsg);
      if (kDebugMode) {
        print('BooksService Error: $errorMsg');
        print('Exception type: ${e.runtimeType}');
        print('Stack trace: $stackTrace');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Check if Supabase is properly configured
  bool _isSupabaseConfigured() {
    try {
      // Check if URLs are still placeholder values from SupabaseConfig
      return !SupabaseConfig.supabaseUrl.contains('https://ktbrqlaptijcbtkfbxes.supabase.co') && 
             !SupabaseConfig.supabaseAnonKey.contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0YnJxbGFwdGlqY2J0a2ZieGVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMTYwOTcsImV4cCI6MjA2OTY5MjA5N30.Ss9akSXWN8Hcx9cz39pcMjLABoJPEXb5JqO-RMWYUDc') &&
             SupabaseConfig.supabaseUrl.isNotEmpty && 
             SupabaseConfig.supabaseAnonKey.isNotEmpty;
    } catch (e) {
      return false; 
    }
  }

  /// Load demo categories for testing
  void _loadDemoCategories() {
    final now = DateTime.now();
    _categories = [
      BookCategory(
        id: '1',
        name: 'Daily Conversation',
        description: 'Common phrases for everyday conversations',
        iconName: 'chat',
        colorHex: '#3B82F6',
        wordCount: 50,
        createdAt: now,
        updatedAt: now,
      ),
      BookCategory(
        id: '2',
        name: 'Travel',
        description: 'Essential words and phrases for travelers',
        iconName: 'flight',
        colorHex: '#10B981',
        wordCount: 75,
        createdAt: now,
        updatedAt: now,
      ),
      BookCategory(
        id: '3',
        name: 'Food & Dining',
        description: 'Food-related vocabulary and restaurant phrases',
        iconName: 'restaurant',
        colorHex: '#F59E0B',
        wordCount: 60,
        createdAt: now,
        updatedAt: now,
      ),
      BookCategory(
        id: '4',
        name: 'Business',
        description: 'Professional and business vocabulary',
        iconName: 'business_center',
        colorHex: '#6366F1',
        wordCount: 40,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    
    if (kDebugMode) {
      print('BooksService: Loaded ${_categories.length} demo categories');
    }
    notifyListeners();
  }

  /// Load demo words for a specific category
  void _loadDemoWords(String categoryId) {
    final now = DateTime.now();
    
    switch (categoryId) {
      case '1': // Daily Conversation
        _words = [
          Word(
            id: 'w1',
            word: 'Hello',
            meaning: 'Merhaba',
            pronunciation: '/həˈloʊ/',
            languageFrom: 'en',
            languageTo: 'tr',
            exampleSentence: 'Hello, how are you?',
            exampleTranslation: 'Merhaba, nasılsın?',
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
          ),
          Word(
            id: 'w2',
            word: 'Goodbye',
            meaning: 'Hoşçakal',
            pronunciation: '/ɡʊdˈbaɪ/',
            languageFrom: 'en',
            languageTo: 'tr',
            exampleSentence: 'Goodbye, see you later!',
            exampleTranslation: 'Hoşçakal, sonra görüşürüz!',
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
          ),
          Word(
            id: 'w3',
            word: 'Please',
            meaning: 'Lütfen',
            pronunciation: '/pliːz/',
            languageFrom: 'en',
            languageTo: 'tr',
            exampleSentence: 'Please help me.',
            exampleTranslation: 'Lütfen bana yardım et.',
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
          ),
          Word(
            id: 'w4',
            word: 'Thank you',
            meaning: 'Teşekkür ederim',
            pronunciation: '/θæŋk juː/',
            languageFrom: 'en',
            languageTo: 'tr',
            exampleSentence: 'Thank you for your help.',
            exampleTranslation: 'Yardımın için teşekkür ederim.',
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
          ),
        ];
        break;
      
      case '2': // Travel
        _words = [
          Word(
            id: 'w5',
            word: 'Airport',
            meaning: 'Havaalanı',
            pronunciation: '/ˈeəpɔːt/',
            languageFrom: 'en',
            languageTo: 'tr',
            exampleSentence: 'I need to go to the airport.',
            exampleTranslation: 'Havaalanına gitmem gerekiyor.',
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
          ),
          Word(
            id: 'w6',
            word: 'Hotel',
            meaning: 'Otel',
            pronunciation: '/hoʊˈtɛl/',
            languageFrom: 'en',
            languageTo: 'tr',
            exampleSentence: 'Where is the nearest hotel?',
            exampleTranslation: 'En yakın otel nerede?',
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
          ),
          Word(
            id: 'w7',
            word: 'Ticket',
            meaning: 'Bilet',
            pronunciation: '/ˈtɪkɪt/',
            languageFrom: 'en',
            languageTo: 'tr',
            exampleSentence: 'I need to buy a ticket.',
            exampleTranslation: 'Bilet satın almam gerekiyor.',
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
          ),
        ];
        break;
      
      case '3': // Food & Dining
        _words = [
          Word(
            id: 'w8',
            word: 'Restaurant',
            meaning: 'Restoran',
            pronunciation: '/ˈrɛstərənt/',
            languageFrom: 'en',
            languageTo: 'tr',
            exampleSentence: 'Let\'s go to a restaurant.',
            exampleTranslation: 'Hadi bir restorana gidelim.',
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
          ),
          Word(
            id: 'w9',
            word: 'Menu',
            meaning: 'Menü',
            pronunciation: '/ˈmɛnjuː/',
            languageFrom: 'en',
            languageTo: 'tr',
            exampleSentence: 'Can I see the menu please?',
            exampleTranslation: 'Menüyü görebilir miyim lütfen?',
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
          ),
          Word(
            id: 'w10',
            word: 'Water',
            meaning: 'Su',
            pronunciation: '/ˈwɔːtər/',
            languageFrom: 'en',
            languageTo: 'tr',
            exampleSentence: 'I would like some water.',
            exampleTranslation: 'Biraz su istiyorum.',
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
          ),
        ];
        break;
      
      case '4': // Business
        _words = [
          Word(
            id: 'w11',
            word: 'Meeting',
            meaning: 'Toplantı',
            pronunciation: '/ˈmiːtɪŋ/',
            languageFrom: 'en',
            languageTo: 'tr',
            exampleSentence: 'I have a meeting at 3 PM.',
            exampleTranslation: 'Saat 15:00\'te toplantım var.',
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
          ),
          Word(
            id: 'w12',
            word: 'Contract',
            meaning: 'Sözleşme',
            pronunciation: '/ˈkɒntrækt/',
            languageFrom: 'en',
            languageTo: 'tr',
            exampleSentence: 'Please review the contract.',
            exampleTranslation: 'Lütfen sözleşmeyi gözden geçirin.',
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
          ),
          Word(
            id: 'w13',
            word: 'Project',
            meaning: 'Proje',
            pronunciation: '/ˈprɒdʒekt/',
            languageFrom: 'en',
            languageTo: 'tr',
            exampleSentence: 'We need to finish this project.',
            exampleTranslation: 'Bu projeyi bitirmemiz gerekiyor.',
            categoryId: categoryId,
            createdAt: now,
            updatedAt: now,
          ),
        ];
        break;
      
      default:
        _words = [];
    }
    
    if (kDebugMode) {
      print('BooksService: Loaded ${_words.length} demo words for category $categoryId');
    }
    notifyListeners();
  }

  /// Load words by category
  Future<void> loadWordsByCategory(String categoryId) async {
    try {
      _setLoading(true);
      _clearError();

      if (kDebugMode) {
        print('BooksService: Loading words for category: $categoryId from database...');
        print('BooksService: Using table: words');
        print('BooksService: Query: SELECT * FROM words WHERE category_id = $categoryId');
      }

      // First try a simple limited query to test connection
      if (kDebugMode) {
        try {
          final testResponse = await supabase
              .from('words')
              .select('id, word')
              .eq('category_id', categoryId)
              .limit(5);
          print('BooksService: Words table test response for category $categoryId: $testResponse');
          print('BooksService: Test words response length: ${testResponse?.length ?? 'null'}');
        } catch (e) {
          print('BooksService: Error getting test words data: $e');
        }
      }

      final response = await supabase
          .from('words')
          .select('*')
          .eq('category_id', categoryId);

      if (kDebugMode) {
        print('BooksService: Words response type: ${response.runtimeType}');
        print('BooksService: Words response length: ${response?.length ?? 'null'}');
        print('BooksService: Full words response: $response');
      }

      if (response != null && response is List) {
        _words = response.map((json) {
          if (kDebugMode) {
            print('BooksService: Processing word JSON: $json');
            print('BooksService: JSON keys: ${json.keys.toList()}');
          }
          try {
            return Word.fromJson(json);
          } catch (e) {
            if (kDebugMode) {
              print('BooksService: Error parsing word JSON: $e');
              print('BooksService: Problematic JSON: $json');
            }
            rethrow;
          }
        }).toList();
        
        if (kDebugMode) {
          print('BooksService: Successfully loaded ${_words.length} words from database for category $categoryId');
          for (final word in _words) {
            print('BooksService: Word - ID: ${word.id}, Word: ${word.word}, Meaning: ${word.meaning}');
          }
        }
      } else {
        _words = [];
        _setError('No words found for this category');
        if (kDebugMode) {
          print('BooksService: No words found for category $categoryId - response is null or not a List');
        }
      }

      notifyListeners();
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to load words: $e';
      _setError(errorMsg);
      if (kDebugMode) {
        print('BooksService Error loading words: $errorMsg');
        print('Exception type: ${e.runtimeType}');
        print('Stack trace: $stackTrace');
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

      final response = await supabase
          .from('words')
          .select('*')
          .eq('is_favorite', true)
          .order('created_at', ascending: true);

      if (response != null && response is List) {
        _favoriteWords = response.map((json) => Word.fromJson(json)).toList();
        if (kDebugMode) {
          print('BooksService: Successfully loaded ${_favoriteWords.length} favorite words from database');
        }
      } else {
        _favoriteWords = [];
        if (kDebugMode) {
          print('BooksService: No favorite words found in database');
        }
      }

      notifyListeners();
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to load favorites: $e';
      _setError(errorMsg);
      if (kDebugMode) {
        print('BooksService Error loading favorites: $errorMsg');
        print('Stack trace: $stackTrace');
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
