import 'package:flutter/material.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/features/sentiment_constellation/models/constellation.dart';

/// Custom painter for rendering the emotional constellation as connected stars.
class ConstellationPainter extends CustomPainter {
  final SentimentConstellation constellation;

  ConstellationPainter(this.constellation);

  @override
  void paint(Canvas canvas, Size size) {
    if (constellation.points.isEmpty) return;

    // Draw connecting lines between points
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final pathPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Convert normalized coordinates to canvas coordinates
    final canvasPoints = constellation.points
        .map((p) => Offset(
              (p.x / 100) * size.width,
              (p.y / 100) * size.height,
            ))
        .toList();

    // Draw path connecting all points
    if (canvasPoints.length > 1) {
      for (int i = 0; i < canvasPoints.length - 1; i++) {
        canvas.drawLine(canvasPoints[i], canvasPoints[i + 1], pathPaint);
      }
    }

    // Draw stars (points)
    for (int i = 0; i < constellation.points.length; i++) {
      final point = constellation.points[i];
      final position = canvasPoints[i];
      final color = AetheraTokens.colorForEmotion(point.emotion);

      // Star glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(position, 12, glowPaint);

      // Star core
      final starPaint = Paint()..color = color;
      canvas.drawCircle(position, 5, starPaint);

      // Star outline
      final outlinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(position, 5, outlinePaint);
    }

    // Draw connection between first and last point (circle)
    if (canvasPoints.length > 2) {
      final circlePathPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        canvasPoints.last,
        canvasPoints.first,
        circlePathPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ConstellationPainter oldDelegate) {
    return oldDelegate.constellation != constellation;
  }
}
