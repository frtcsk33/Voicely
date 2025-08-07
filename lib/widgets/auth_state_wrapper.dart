import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../main.dart';

/// AuthStateWrapper handles the authentication state and navigation
/// 
/// This widget automatically shows:
/// - LoginScreen if user is not authenticated
/// - HomePage if user is authenticated
/// - Loading screen during authentication checks
class AuthStateWrapper extends StatelessWidget {
  const AuthStateWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Show loading screen during authentication operations
        if (authService.isLoading) {
          return const AuthLoadingScreen();
        }

        // Always show home page - users can access login from settings if needed
        // This provides better UX by not forcing authentication
        return const MainScreen();
      },
    );
  }
}

/// Loading screen shown during authentication operations
class AuthLoadingScreen extends StatefulWidget {
  const AuthLoadingScreen({super.key});

  @override
  State<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends State<AuthLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            AnimatedBuilder(
              animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade500,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.record_voice_over_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // App Name
            Text(
              'Voicely',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [Colors.blue.shade600, Colors.purple.shade600],
                  ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Loading indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue.shade500,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Loading text
            Text(
              'Setting up your account...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper widget that provides AuthService to the entire app
class AuthProvider extends StatelessWidget {
  final Widget child;
  
  const AuthProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: child,
    );
  }
}

/// Helper widget for showing auth errors
class AuthErrorDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const AuthErrorDialog({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Authentication Error',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade600,
          height: 1.4,
        ),
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade600,
              ),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'OK',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Show auth error dialog
  static void show(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AuthErrorDialog(
        message: message,
        onRetry: onRetry,
      ),
    );
  }
}

/// Helper widget for logout confirmation
class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.logout_rounded,
            color: Colors.orange.shade600,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Sign Out',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to sign out of your account?',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade600,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Sign Out',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Show logout confirmation dialog
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const LogoutConfirmationDialog(),
    );
    return result ?? false;
  }
}
