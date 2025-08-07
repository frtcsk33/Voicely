import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client configuration
/// 
/// Replace these with your actual Supabase project credentials:
/// - Get your URL from: https://app.supabase.com/project/[your-project]/settings/api
/// - Get your anon key from: https://app.supabase.com/project/[your-project]/settings/api
class SupabaseConfig {
  // TODO: Replace with your actual Supabase project URL
  static const String supabaseUrl = 'https://your-project-ref.supabase.co';
  
  // TODO: Replace with your actual Supabase anon/public key
  static const String supabaseAnonKey = 'your-anon-key-here';
  
  /// Initialize Supabase client
  /// Call this in main() before runApp()
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 10,
        ),
      );
    } catch (e) {
      // If Supabase initialization fails, we'll continue without it
      // This allows the app to work in demo mode
      print('Supabase initialization failed: $e');
      print('App will run in demo mode without authentication');
    }
  }
}

/// Global Supabase client instance
/// Use this throughout your app to access Supabase services
final supabase = Supabase.instance.client;
