import 'dart:math';
import 'package:flutter/material.dart';
import 'package:aethera/core/constants/app_constants.dart';

/// Immutable star data — computed once, reused every frame.
class _Star {
  final double x;
  final double y;
  final double radius;
  final double twinkleOffset; // phase offset for unique twinkling per star
  final double twinkleSpeed;

  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.twinkleOffset,
    required this.twinkleSpeed,
  });
}

/// Animated star field using a CustomPainter.
/// Renders [AppConstants.starCount] stars with individual twinkling.
class CosmicBackground extends StatefulWidget {
  const CosmicBackground({super.key});

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    final rng = Random(42); // seed for deterministic layout
    _stars = List.generate(
      AppConstants.starCount,
      (_) => _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 0.5 + rng.nextDouble() * 1.5,
        twinkleOffset: rng.nextDouble() * 2 * pi,
        twinkleSpeed: 0.4 + rng.nextDouble() * 0.8,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _StarFieldPainter(
          stars: _stars,
          progress: _controller.value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress;

  _StarFieldPainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final t = progress * 2 * pi;

    for (final star in stars) {
      // Each star has unique twinkling phase and speed
      final brightness = 0.5 + 0.5 * sin(t * star.twinkleSpeed + star.twinkleOffset);
      final alpha = (0.3 + 0.7 * brightness).clamp(0.0, 1.0);

      paint.color = Color.fromRGBO(232, 244, 253, alpha); // AetheraTokens.starlight

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius * (0.8 + 0.2 * brightness),
        paint,
      );

      // Glow halo for brighter stars
      if (star.radius > 1.2 && brightness > 0.7) {
        paint.color = Color.fromRGBO(100, 255, 218, alpha * 0.15); // auroraTeal faint
        canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height),
          star.radius * 3,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) => old.progress != progress;
}
