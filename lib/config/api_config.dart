class ApiConfig {
  // Check if app is in production mode
  static const bool _isProduction = bool.fromEnvironment('dart.vm.product');
  
  // Development IP - Update this with your local IP
  static const String _developmentUrl = 'http://192.168.1.8:3000';
  
  // Production URL - Update when you deploy backend
  static const String _productionUrl = 'https://voicely-translation-api.herokuapp.com';
  
  /// Get the appropriate base URL based on environment
  static String get baseUrl {
    if (_isProduction) {
      return _productionUrl;
    } else {
      return _developmentUrl;
    }
  }
  
  /// Check if app is in debug mode
  static bool get isDebug => !_isProduction;
  
  /// API endpoints
  static String get translateUrl => '$baseUrl/translate';
  static String get ttsUrl => '$baseUrl/tts';
  static String get healthUrl => '$baseUrl/health';
  
  /// Timeout durations
  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration healthCheckTimeout = Duration(seconds: 5);
}