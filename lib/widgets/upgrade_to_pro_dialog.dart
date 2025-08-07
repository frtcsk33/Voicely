import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpgradeToProDialog extends StatefulWidget {
  final VoidCallback onGoPro;
  final VoidCallback onCancel;

  const UpgradeToProDialog({
    super.key,
    required this.onGoPro,
    required this.onCancel,
  });

  @override
  State<UpgradeToProDialog> createState() => _UpgradeToProDialogState();
}

class _UpgradeToProDialogState extends State<UpgradeToProDialog>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    _shimmerController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: screenWidth * 0.9,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.purple.shade50,
              Colors.blue.shade50,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with animated background
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade600,
                        Colors.blue.shade500,
                        Colors.cyan.shade400,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Animated Premium Icon
                      AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3 + 0.2 * _shimmerAnimation.value),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 20 + 10 * _shimmerAnimation.value,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 50,
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Title with gradient text effect
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.white, Colors.white.withOpacity(0.8)],
                        ).createShader(bounds),
                        child: Text(
                          'Unlock AI Pro',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Experience the future of translation',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Comparison section
                      _buildComparisonSection(),
                      
                      const SizedBox(height: 24),
                      
                      // CTA Section
                      _buildCTASection(),
                      
                      const SizedBox(height: 16),
                      
                      // Buttons
                      _buildButtons(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Text(
                  'Free',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade500, Colors.blue.shade500],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'AI Pro',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Comparison items
          _buildComparisonItem(
            'Translation Quality',
            'Basic',
            'AI-Powered',
            Colors.orange.shade500,
          ),
          _buildComparisonItem(
            'Speech Recognition',
            'Standard',
            'Whisper AI',
            Colors.blue.shade500,
          ),
          _buildComparisonItem(
            'Processing Speed',
            'Normal',
            'Priority',
            Colors.green.shade500,
          ),
          _buildComparisonItem(
            'Context Understanding',
            '❌',
            '✅',
            Colors.purple.shade500,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(String feature, String free, String pro, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  feature,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              free,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              pro,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.trending_up_rounded,
            color: Colors.purple.shade500,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            '3x Better Translation Accuracy',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Join thousands of users who upgraded to AI Pro for professional-grade translations.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        // Go Pro Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade500,
                Colors.blue.shade500,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onGoPro,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Upgrade to Pro',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Maybe Later Button
        TextButton(
          onPressed: widget.onCancel,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          child: Text(
            'Maybe Later',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Trust indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security_rounded,
              color: Colors.grey.shade500,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Secure • No Ads • Cancel Anytime',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}