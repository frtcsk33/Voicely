import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Mock user class for demo mode
class MockUser implements User {
  @override
  final String id;
  
  @override
  final String? email;
  
  @override
  final Map<String, dynamic>? userMetadata;
  
  MockUser({
    required this.id,
    this.email,
    this.userMetadata,
  });
  
  // Implement all required User interface methods
  @override
  String? get phone => null;
  
  @override
  String? get emailConfirmedAt => DateTime.now().toIso8601String();
  
  @override
  String? get phoneConfirmedAt => null;
  
  @override
  String? get confirmedAt => DateTime.now().toIso8601String();
  
  @override
  String? get lastSignInAt => DateTime.now().toIso8601String();
  
  @override
  String get createdAt => DateTime.now().toIso8601String();
  
  @override
  String? get updatedAt => DateTime.now().toIso8601String();
  
  @override
  Map<String, dynamic> get appMetadata => {};
  
  @override
  String get aud => 'authenticated';
  
  @override
  String? get role => 'authenticated';
  
  @override
  List<UserIdentity>? get identities => null;
  
  @override
  List<Factor>? get factors => null;
  
  // Additional required fields
  @override
  String? get actionLink => null;
  
  @override
  String? get confirmationSentAt => null;
  
  @override
  String? get emailChangeSentAt => null;
  
  @override
  String? get invitedAt => null;
  
  @override
  bool get isAnonymous => false;
  
  @override
  String? get newEmail => null;
  
  @override
  String? get recoverySentAt => null;
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'user_metadata': userMetadata,
      'app_metadata': appMetadata,
      'aud': aud,
      'role': role,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'email_confirmed_at': emailConfirmedAt,
      'phone_confirmed_at': phoneConfirmedAt,
      'confirmed_at': confirmedAt,
      'last_sign_in_at': lastSignInAt,
      'phone': phone,
      'is_anonymous': isAnonymous,
    };
  }
}

/// Authentication service that handles all auth operations
/// 
/// This service provides methods for:
/// - Sign up with email/password
/// - Sign in with email/password  
/// - Sign out
/// - Password reset
/// - Demo mode for testing without Supabase
/// 
/// The service automatically detects if it's running in demo mode
/// (when using placeholder Supabase keys) and simulates auth operations
class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    _initialize();
  }

  /// Initialize the auth service and listen to auth state changes
  void _initialize() {
    try {
      // Get current user if any
      _currentUser = supabase.auth.currentUser;
      
      // Listen to auth state changes
      supabase.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        
        if (kDebugMode) {
          print('Auth state changed: $event');
        }
        
        switch (event) {
          case AuthChangeEvent.signedIn:
            _currentUser = session?.user;
            _clearError();
            break;
          case AuthChangeEvent.signedOut:
            _currentUser = null;
            _clearError();
            break;
          case AuthChangeEvent.userUpdated:
            _currentUser = session?.user;
            break;
          default:
            break;
        }
        
        notifyListeners();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Auth service running in demo mode: $e');
      }
    }
  }

  /// Sign up a new user with email and password
  /// 
  /// Returns true if successful, false otherwise
  /// In demo mode, simulates successful signup
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Demo mode - simulate successful signup
      if (SupabaseConfig.supabaseUrl.contains('your-project-ref')) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        
        // Create a mock user for demo
        _currentUser = MockUser(
          id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          userMetadata: {
            'full_name': fullName ?? email.split('@').first,
          },
        );
        
        notifyListeners();
        return true;
      }

      // Real Supabase signup
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user != null) {
        _currentUser = response.user;
        notifyListeners();
        return true;
      } else {
        _setError('Sign up failed. Please try again.');
        return false;
      }
    } catch (e) {
      // If it's a demo mode error, handle gracefully
      if (SupabaseConfig.supabaseUrl.contains('your-project-ref')) {
        _currentUser = MockUser(
          id: 'demo-user-${email.hashCode}',
          email: email,
          userMetadata: {'full_name': fullName ?? email.split('@').first},
        );
        notifyListeners();
        return true;
      }
      
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in user with email and password
  /// 
  /// Returns true if successful, false otherwise
  /// In demo mode, simulates successful signin
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Demo mode - simulate successful signin
      if (SupabaseConfig.supabaseUrl.contains('your-project-ref')) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        
        // Create a mock user for demo
        _currentUser = MockUser(
          id: 'demo-user-${email.hashCode}',
          email: email,
          userMetadata: {
            'full_name': email.split('@').first,
          },
        );
        
        notifyListeners();
        return true;
      }

      // Real Supabase signin
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;
        notifyListeners();
        return true;
      } else {
        _setError('Sign in failed. Please check your credentials.');
        return false;
      }
    } catch (e) {
      // If it's a demo mode error, handle gracefully
      if (SupabaseConfig.supabaseUrl.contains('your-project-ref')) {
        _currentUser = MockUser(
          id: 'demo-user-${email.hashCode}',
          email: email,
          userMetadata: {'full_name': email.split('@').first},
        );
        notifyListeners();
        return true;
      }
      
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out the current user
  /// 
  /// Returns true if successful, false otherwise
  /// In demo mode, simulates successful signout
  Future<bool> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      // Demo mode - simulate successful signout
      if (SupabaseConfig.supabaseUrl.contains('your-project-ref') || _currentUser is MockUser) {
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
        _currentUser = null;
        notifyListeners();
        return true;
      }

      // Real Supabase signout
      await supabase.auth.signOut();
      _currentUser = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password for the given email
  /// 
  /// Returns true if successful, false otherwise
  /// In demo mode, simulates successful password reset
  Future<bool> resetPassword({required String email}) async {
    try {
      _setLoading(true);
      _clearError();

      // Demo mode - simulate successful password reset
      if (SupabaseConfig.supabaseUrl.contains('your-project-ref') || _currentUser is MockUser) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        return true;
      }

      // Real Supabase password reset
      await supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
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

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message.toLowerCase()) {
        case 'invalid login credentials':
          return 'Invalid email or password. Please try again.';
        case 'email not confirmed':
          return 'Please check your email and confirm your account.';
        case 'user already registered':
          return 'An account with this email already exists.';
        case 'password should be at least 6 characters':
          return 'Password must be at least 6 characters long.';
        default:
          return error.message;
      }
    }
    
    return error.toString();
  }
}