import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';

/// Animated heartbeat pulse — activates when both users are online simultaneously.
class HeartbeatOverlay extends StatelessWidget {
  final bool isActive;

  const HeartbeatOverlay({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();

    return IgnorePointer(
      child: Center(
        child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring 1
          _PulseRing(
            color: AetheraTokens.roseQuartz,
            size: 180,
            delay: 0,
          ),
          // Outer ring 2
          _PulseRing(
            color: AetheraTokens.auroraTeal,
            size: 140,
            delay: 300,
          ),
          // Inner heart icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AetheraTokens.roseQuartz.withValues(alpha: 0.15),
              boxShadow: AetheraTokens.roseGlow(intensity: 0.8),
            ),
            child: const Center(
              child: Text('💕', style: TextStyle(fontSize: 28)),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.15, 1.15),
                duration: 800.ms,
                curve: Curves.easeInOut,
              ),
        ],
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final Color color;
  final double size;
  final int delay;

  const _PulseRing({
    required this.color,
    required this.size,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.4, 1.4),
          duration: 2000.ms,
          delay: Duration(milliseconds: delay),
          curve: Curves.easeOut,
        )
        .fadeOut(
          begin: 1.0,
          duration: 2000.ms,
          delay: Duration(milliseconds: delay),
          curve: Curves.easeIn,
        );
  }
}
