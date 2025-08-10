import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client configuration
/// 
/// Replace these with your actual Supabase project credentials:
/// - Get your URL from: https://app.supabase.com/project/[your-project]/settings/api
/// - Get your anon key from: https://app.supabase.com/project/[your-project]/settings/api
class SupabaseConfig {
  // Your actual Supabase project URL
  static const String supabaseUrl = 'https://ktbrqlaptijcbtkfbxes.supabase.co';
  
  // Your actual Supabase anon/public key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0YnJxbGFwdGlqY2J0a2ZieGVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxMTYwOTcsImV4cCI6MjA2OTY5MjA5N30.Ss9akSXWN8Hcx9cz39pcMjLABoJPEXb5JqO-RMWYUDc';
  
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
