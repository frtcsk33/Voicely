import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

/// Modern and responsive sign up screen
/// 
/// Features:
/// - Clean Material 3 design
/// - Form validation with password confirmation
/// - Password strength indicator
/// - Password visibility toggle
/// - Loading states
/// - Error handling
/// - Responsive layout
/// - Accessibility support
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _fullNameFocusNode = FocusNode();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _fullNameFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.grey.shade700,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 80,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildSignUpForm(),
                    const Spacer(),
                    _buildLoginPrompt(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade400,
                Colors.blue.shade500,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Title
        Text(
          'Create Account',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          'Join Voicely and start translating\nwith the power of AI',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full Name Field
                _buildFullNameField(),
                
                const SizedBox(height: 20),
                
                // Email Field
                _buildEmailField(),
                
                const SizedBox(height: 20),
                
                // Password Field
                _buildPasswordField(),
                
                const SizedBox(height: 20),
                
                // Confirm Password Field
                _buildConfirmPasswordField(),
                
                const SizedBox(height: 16),
                
                // Password Strength Indicator
                _buildPasswordStrengthIndicator(),
                
                const SizedBox(height: 20),
                
                // Terms and Conditions
                _buildTermsCheckbox(),
                
                const SizedBox(height: 24),
                
                // Error Message
                if (authService.errorMessage != null) ...[
                  _buildErrorMessage(authService.errorMessage!),
                  const SizedBox(height: 16),
                ],
                
                // Sign Up Button
                _buildSignUpButton(authService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullNameField() {
    return TextFormField(
      controller: _fullNameController,
      focusNode: _fullNameFocusNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: 'Enter your full name',
        prefixIcon: Icon(
          Icons.person_outline,
          color: Colors.grey.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.purple.shade500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      ),
      style: GoogleFonts.poppins(),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your full name';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email',
        prefixIcon: Icon(
          Icons.email_outlined,
          color: Colors.grey.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.purple.shade500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      ),
      style: GoogleFonts.poppins(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!EmailValidator.validate(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
      onChanged: (_) => setState(() {}), // Trigger password strength update
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Create a strong password',
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.grey.shade600,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade600,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.purple.shade500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      ),
      style: GoogleFonts.poppins(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocusNode,
      obscureText: !_isConfirmPasswordVisible,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleSignUp(),
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        hintText: 'Re-enter your password',
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.grey.shade600,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade600,
          ),
          onPressed: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.purple.shade500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      ),
      style: GoogleFonts.poppins(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    final strength = _calculatePasswordStrength(password);
    
    if (password.isEmpty) return const SizedBox.shrink();
    
    Color strengthColor;
    String strengthText;
    
    switch (strength) {
      case 0:
      case 1:
        strengthColor = Colors.red;
        strengthText = 'Weak';
        break;
      case 2:
        strengthColor = Colors.orange;
        strengthText = 'Fair';
        break;
      case 3:
        strengthColor = Colors.yellow.shade700;
        strengthText = 'Good';
        break;
      case 4:
        strengthColor = Colors.green;
        strengthText = 'Strong';
        break;
      default:
        strengthColor = Colors.grey;
        strengthText = 'Unknown';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Strength',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              strengthText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: strengthColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: strength / 4,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _acceptTerms,
            onChanged: (value) {
              setState(() {
                _acceptTerms = value ?? false;
              });
            },
            activeColor: Colors.purple.shade500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: Colors.purple.shade600,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: Colors.purple.shade600,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton(AuthService authService) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: (authService.isLoading || !_acceptTerms) ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: authService.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Create Account',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Sign In',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.purple.shade600,
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    
    int strength = 0;
    
    // Length check
    if (password.length >= 6) strength++;
    if (password.length >= 10) strength++;
    
    // Contains lowercase
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    
    // Contains uppercase
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    
    // Contains numbers
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    
    // Contains special characters
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    
    return strength > 4 ? 4 : strength;
  }

  // Event handlers
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please accept the Terms of Service and Privacy Policy',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final authService = context.read<AuthService>();
    authService.clearError();

    final success = await authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created successfully! Welcome to Voicely!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      
      // Navigation will be handled by AuthStateWrapper
      Navigator.of(context).pop();
    }
  }
}
