import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BetterTranslationButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isProUser;

  const BetterTranslationButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.isProUser = false,
  });

  @override
  State<BetterTranslationButton> createState() => _BetterTranslationButtonState();
}

class _BetterTranslationButtonState extends State<BetterTranslationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Start shimmer animation for non-pro users
    if (!widget.isProUser) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isProUser ? 1.0 : _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: widget.isProUser
                    ? LinearGradient(
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade600,
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.purple.shade400.withOpacity(0.8 + 0.2 * _shimmerAnimation.value),
                          Colors.blue.shade500.withOpacity(0.8 + 0.2 * _shimmerAnimation.value),
                          Colors.cyan.shade400.withOpacity(0.8 + 0.2 * _shimmerAnimation.value),
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.isProUser 
                        ? Colors.green.withOpacity(0.3)
                        : Colors.purple.withOpacity(0.3 + 0.2 * _shimmerAnimation.value),
                    blurRadius: 8 + 4 * _shimmerAnimation.value,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Icon(
                      widget.isProUser 
                          ? Icons.auto_awesome_rounded
                          : Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.isLoading 
                        ? 'AI Translating...'
                        : widget.isProUser 
                            ? 'AI Pro Translation'
                            : 'Better Translation',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (!widget.isProUser && !widget.isLoading) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PRO',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
