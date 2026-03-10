import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/core/constants/app_constants.dart';

class EmotionOrb extends StatelessWidget {
  final String mood;
  final double size;
  final bool animated;
  final VoidCallback? onTap;

  const EmotionOrb({
    super.key,
    required this.mood,
    this.size = 48,
    this.animated = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AetheraTokens.colorForEmotion(mood);
    final emoji = AppConstants.emotionEmojis[mood] ?? '✦';

    Widget orb = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.08),
            ],
            stops: const [0.3, 1.0],
          ),
          border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: size * 0.42),
          ),
        ),
      ),
    );

    if (animated) {
      orb = orb
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.08, 1.08),
            duration: 2000.ms,
            curve: Curves.easeInOut,
          )
          .then()
          .shimmer(
            color: color.withValues(alpha: 0.3),
            duration: 1500.ms,
          );
    }

    return orb;
  }
}
