import 'package:flutter/material.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final Color accentColor;
  final VoidCallback onPressed;
  final double size;

  const MicButton({
    super.key,
    required this.isListening,
    required this.accentColor,
    required this.onPressed,
    this.size = 80,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Ripple animation for the outer circle
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
      _rippleController.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.reset();
      _rippleController.stop();
      _rippleController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple effect (outer circle)
          if (widget.isListening)
            AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return Container(
                  width: widget.size * 2 * _rippleAnimation.value,
                  height: widget.size * 2 * _rippleAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.accentColor.withOpacity(
                        0.3 * (1 - _rippleAnimation.value)
                      ),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          
          // Main button with pulse effect
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    gradient: widget.isListening 
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.accentColor,
                            widget.accentColor.withOpacity(0.8),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                        ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.accentColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withOpacity(
                          widget.isListening ? 0.4 : 0.2
                        ),
                        blurRadius: widget.isListening ? 25 : 15,
                        spreadRadius: widget.isListening ? 5 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isListening ? Icons.mic : Icons.mic_none_rounded,
                    color: widget.isListening 
                      ? Colors.white 
                      : widget.accentColor,
                    size: widget.size * 0.4,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}