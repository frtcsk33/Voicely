import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/translator_provider.dart';

class AIMicButton extends StatefulWidget {
  const AIMicButton({super.key});

  @override
  State<AIMicButton> createState() => _AIMicButtonState();
}

class _AIMicButtonState extends State<AIMicButton>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _glowController;
  late Animation<double> _waveAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    final provider = context.read<TranslatorProvider>();
    if (provider.isRecording) {
      provider.stopRecording();
      _waveController.stop();
      _waveController.reset();
    } else {
      provider.startRecording();
      _waveController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: _toggleRecording,
          child: Container(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow effect
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 120 * _glowAnimation.value,
                      height: 120 * _glowAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (provider.isRecording ? Colors.red : Colors.blue)
                                .withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                // Sound waves (when recording)
                if (provider.isRecording) ...[
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(120, 120),
                        painter: SoundWavePainter(_waveAnimation.value),
                      );
                    },
                  ),
                ],
                
                // Main button
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: provider.isRecording
                          ? [Colors.red.shade400, Colors.red.shade600]
                          : [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (provider.isRecording ? Colors.red : Colors.blue)
                            .withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    provider.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                
                // Status text
                Positioned(
                  bottom: -30,
                  child: Text(
                    provider.isRecording ? 'Recording...' : 'Tap to speak',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SoundWavePainter extends CustomPainter {
  final double animationValue;

  SoundWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw multiple concentric circles with different opacities
    for (int i = 1; i <= 3; i++) {
      final radius = (size.width / 2 - 10) * animationValue * i / 3;
      final opacity = (1.0 - animationValue) * (4 - i) / 3;
      
      paint.color = Colors.red.withOpacity(opacity * 0.5);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(SoundWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
