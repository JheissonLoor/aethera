import 'dart:math';
import 'package:flutter/material.dart';

/// Renders an animated aurora borealis effect.
/// Visible when both users are online simultaneously (or at high connection levels).
class AuroraEffect extends StatefulWidget {
  final double opacity;

  const AuroraEffect({super.key, this.opacity = 1.0});

  @override
  State<AuroraEffect> createState() => _AuroraEffectState();
}

class _AuroraEffectState extends State<AuroraEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.opacity,
      duration: const Duration(seconds: 2),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _AuroraPainter(progress: _controller.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double progress;

  _AuroraPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * pi;
    final paint = Paint()..style = PaintingStyle.fill;

    // Aurora band 1 — teal
    _drawAuroraBand(
      canvas,
      size,
      paint,
      color: const Color(0xFF64FFDA),
      yCenter: size.height * 0.25,
      amplitude: size.height * 0.04,
      phaseShift: t,
      alphaBase: 0.08,
    );

    // Aurora band 2 — purple
    _drawAuroraBand(
      canvas,
      size,
      paint,
      color: const Color(0xFF9B72CF),
      yCenter: size.height * 0.22,
      amplitude: size.height * 0.06,
      phaseShift: t + 1.2,
      alphaBase: 0.06,
    );

    // Aurora band 3 — rose
    _drawAuroraBand(
      canvas,
      size,
      paint,
      color: const Color(0xFFFF6B8A),
      yCenter: size.height * 0.28,
      amplitude: size.height * 0.03,
      phaseShift: t + 2.4,
      alphaBase: 0.04,
    );
  }

  void _drawAuroraBand(
    Canvas canvas,
    Size size,
    Paint paint, {
    required Color color,
    required double yCenter,
    required double amplitude,
    required double phaseShift,
    required double alphaBase,
  }) {
    const bandHeight = 80.0;
    final path = Path();
    final steps = 60;

    path.moveTo(0, yCenter);
    for (int i = 0; i <= steps; i++) {
      final x = (i / steps) * size.width;
      final y = yCenter + amplitude * sin((i / steps) * 2 * pi + phaseShift);
      if (i == 0) {
        path.moveTo(x, y - bandHeight / 2);
      } else {
        path.lineTo(x, y - bandHeight / 2);
      }
    }
    for (int i = steps; i >= 0; i--) {
      final x = (i / steps) * size.width;
      final y = yCenter + amplitude * sin((i / steps) * 2 * pi + phaseShift);
      path.lineTo(x, y + bandHeight / 2);
    }
    path.close();

    paint.shader = LinearGradient(
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: alphaBase * 1.5),
        color.withValues(alpha: alphaBase),
        color.withValues(alpha: 0.0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, yCenter - bandHeight, size.width, bandHeight * 2));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.progress != progress;
}
