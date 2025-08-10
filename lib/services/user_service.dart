import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import 'supabase_client.dart';

/// Service for managing user profiles and user-related operations
/// 
/// This service handles:
/// - User profile CRUD operations
/// - User statistics tracking
/// - Subscription management
/// - User preferences
class UserService extends ChangeNotifier {
  UserProfile? _currentUserProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserProfile? get currentUserProfile => _currentUserProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // User profile getters
  String? get displayName => _currentUserProfile?.displayName;
  bool get isPro => _currentUserProfile?.isPro ?? false;
  bool get canTranslate => _currentUserProfile?.canTranslate ?? true;
  int get translationsRemaining => _currentUserProfile?.translationsRemaining ?? 50;
  int get dailyTranslations => _currentUserProfile?.dailyTranslations ?? 0;
  int get totalTranslations => _currentUserProfile?.totalTranslations ?? 0;
  int get streakDays => _currentUserProfile?.streakDays ?? 0;
  List<String> get learningLanguages => _currentUserProfile?.learningLanguages ?? [];

  /// Load user profile by user ID
  Future<bool> loadUserProfile(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      // Demo mode - create mock profile
      if (SupabaseConfig.supabaseUrl.contains('your-project-ref')) {
        await Future.delayed(const Duration(milliseconds: 500));
        _currentUserProfile = UserProfile(
          id: userId,
          email: 'demo@example.com',
          fullName: 'Demo User',
          lastDailyReset: DateTime.now(),
          lastActivityAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        notifyListeners();
        return true;
      }

      // Load from Supabase
      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      if (response != null) {
        _currentUserProfile = UserProfile.fromJson(response);
        notifyListeners();
        return true;
      } else {
        _setError('User profile not found');
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user profile: $e');
      }
      _setError('Failed to load user profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Create or update user profile
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      _setLoading(true);
      _clearError();

      // Demo mode - just update local profile
      if (SupabaseConfig.supabaseUrl.contains('your-project-ref')) {
        await Future.delayed(const Duration(milliseconds: 300));
        _currentUserProfile = profile;
        notifyListeners();
        return true;
      }

      // Save to Supabase
      final response = await supabase
          .from('users')
          .upsert(profile.toJson())
          .select()
          .single();

      if (response != null) {
        _currentUserProfile = UserProfile.fromJson(response);
        notifyListeners();
        return true;
      } else {
        _setError('Failed to save user profile');
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user profile: $e');
      }
      _setError('Failed to save user profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user's last activity timestamp
  Future<void> updateLastActivity() async {
    if (_currentUserProfile == null) return;

    try {
      final updatedProfile = _currentUserProfile!.copyWith(
        lastActivityAt: DateTime.now(),
      );
      await saveUserProfile(updatedProfile);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating last activity: $e');
      }
    }
  }

  /// Increment translation count
  Future<bool> incrementTranslationCount() async {
    if (_currentUserProfile == null) return false;

    try {
      // Check if user can translate
      if (!_currentUserProfile!.canTranslate) {
        _setError('Translation limit reached for today');
        return false;
      }

      final now = DateTime.now();
      final updatedProfile = _currentUserProfile!.copyWith(
        totalTranslations: _currentUserProfile!.totalTranslations + 1,
        dailyTranslations: _currentUserProfile!.dailyTranslations + 1,
        lastActivityAt: now,
        updatedAt: now,
      );

      return await saveUserProfile(updatedProfile);
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing translation count: $e');
      }
      _setError('Failed to update translation count');
      return false;
    }
  }

  /// Update user's learning languages
  Future<bool> updateLearningLanguages(List<String> languages) async {
    if (_currentUserProfile == null) return false;

    try {
      final updatedProfile = _currentUserProfile!.copyWith(
        learningLanguages: languages,
        updatedAt: DateTime.now(),
      );

      return await saveUserProfile(updatedProfile);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating learning languages: $e');
      }
      _setError('Failed to update learning languages');
      return false;
    }
  }

  /// Update user's preferred language
  Future<bool> updatePreferredLanguage(String languageCode) async {
    if (_currentUserProfile == null) return false;

    try {
      final updatedProfile = _currentUserProfile!.copyWith(
        preferredLanguage: languageCode,
        updatedAt: DateTime.now(),
      );

      return await saveUserProfile(updatedProfile);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating preferred language: $e');
      }
      _setError('Failed to update preferred language');
      return false;
    }
  }

  /// Update user's full name
  Future<bool> updateFullName(String fullName) async {
    if (_currentUserProfile == null) return false;

    try {
      final updatedProfile = _currentUserProfile!.copyWith(
        fullName: fullName,
        updatedAt: DateTime.now(),
      );

      return await saveUserProfile(updatedProfile);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating full name: $e');
      }
      _setError('Failed to update full name');
      return false;
    }
  }

  /// Update user settings
  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    if (_currentUserProfile == null) return false;

    try {
      final currentSettings = Map<String, dynamic>.from(_currentUserProfile!.settings);
      currentSettings.addAll(settings);

      final updatedProfile = _currentUserProfile!.copyWith(
        settings: currentSettings,
        updatedAt: DateTime.now(),
      );

      return await saveUserProfile(updatedProfile);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user settings: $e');
      }
      _setError('Failed to update user settings');
      return false;
    }
  }

  /// Check and update streak days
  Future<void> updateStreakDays() async {
    if (_currentUserProfile == null) return;

    try {
      final now = DateTime.now();
      final lastActivity = _currentUserProfile!.lastActivityAt;
      final daysSinceLastActivity = now.difference(lastActivity).inDays;

      int newStreakDays = _currentUserProfile!.streakDays;

      if (daysSinceLastActivity == 1) {
        // Continue streak
        newStreakDays += 1;
      } else if (daysSinceLastActivity > 1) {
        // Reset streak
        newStreakDays = 1;
      }
      // If same day, keep current streak

      if (newStreakDays != _currentUserProfile!.streakDays) {
        final updatedProfile = _currentUserProfile!.copyWith(
          streakDays: newStreakDays,
          lastActivityAt: now,
          updatedAt: now,
        );
        await saveUserProfile(updatedProfile);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating streak days: $e');
      }
    }
  }

  /// Reset daily translation count (called daily)
  Future<void> resetDailyTranslations() async {
    if (_currentUserProfile == null) return;

    try {
      final now = DateTime.now();
      final lastReset = _currentUserProfile!.lastDailyReset;

      // Check if we need to reset (different day)
      if (now.day != lastReset.day || 
          now.month != lastReset.month || 
          now.year != lastReset.year) {
        
        final updatedProfile = _currentUserProfile!.copyWith(
          dailyTranslations: 0,
          lastDailyReset: now,
          updatedAt: now,
        );
        await saveUserProfile(updatedProfile);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting daily translations: $e');
      }
    }
  }

  /// Clear current user profile (for logout)
  void clearUserProfile() {
    _currentUserProfile = null;
    _clearError();
    notifyListeners();
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

  /// Clear error message (public method)
  void clearError() {
    _clearError();
    notifyListeners();
  }
}