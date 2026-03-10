import 'package:flutter/material.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';

/// Animates the sky gradient when the combined emotional state changes.
class EmotionalSky extends StatelessWidget {
  final String combinedMood;

  const EmotionalSky({super.key, required this.combinedMood});

  @override
  Widget build(BuildContext context) {
    final colors = AetheraTokens.emotionSkyGradients[combinedMood] ??
        AetheraTokens.emotionSkyGradients['neutral']!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return AnimatedContainer(
          duration: const Duration(seconds: 3),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
