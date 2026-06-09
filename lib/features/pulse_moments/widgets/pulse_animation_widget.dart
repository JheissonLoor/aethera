import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/features/pulse_moments/models/pulse_moment.dart';

/// Animated widget that displays incoming pulse moments with haptic feedback.
/// Creates a heartbeat-like visual and tactile experience.
class PulseAnimationWidget extends StatefulWidget {
  final PulseMoment pulse;
  final VoidCallback? onAcknowledge;

  const PulseAnimationWidget({
    super.key,
    required this.pulse,
    this.onAcknowledge,
  });

  @override
  State<PulseAnimationWidget> createState() => _PulseAnimationWidgetState();
}

class _PulseAnimationWidgetState extends State<PulseAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Heartbeat pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticInOut),
    );

    // Scale animation for appearance
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _pulseController.repeat();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Color _emotionColor() {
    return AetheraTokens.colorForEmotion(widget.pulse.emotion);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Center(
        child: GestureDetector(
          onTap: widget.onAcknowledge,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing heartbeat orb
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return Container(
                    width: 100 * _pulseAnimation.value,
                    height: 100 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _emotionColor().withValues(alpha: 0.8),
                          _emotionColor().withValues(alpha: 0.2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _emotionColor().withValues(alpha: 0.6),
                          blurRadius: 30 * _pulseAnimation.value,
                          spreadRadius: 5 * _pulseAnimation.value,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Message or emotion label
              if (widget.pulse.message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.pulse.message!,
                    textAlign: TextAlign.center,
                    style: AetheraTokens.bodyLarge(),
                  ),
                )
              else
                Text(
                  widget.pulse.emotion.toUpperCase(),
                  style: AetheraTokens.displaySmall(color: _emotionColor()),
                ),
              const SizedBox(height: 16),
              // Tap to acknowledge hint
              Text(
                'Tap to acknowledge',
                style: AetheraTokens.bodySmall(color: AetheraTokens.moonGlow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
