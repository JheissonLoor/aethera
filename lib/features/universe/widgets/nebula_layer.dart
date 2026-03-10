import 'dart:math';
import 'package:flutter/material.dart';

/// Soft, pulsing nebula clouds that give depth to the universe.
/// Opacity scales with universe level: invisible at level 1, full at level 4+.
class NebulaLayer extends StatefulWidget {
  final int universeLevel;

  const NebulaLayer({super.key, required this.universeLevel});

  @override
  State<NebulaLayer> createState() => _NebulaLayerState();
}

class _NebulaBlob {
  final double x;
  final double y;
  final double radius; // fraction of screen width
  final Color color;
  final double phaseOffset;
  final double pulseSpeed;

  const _NebulaBlob({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.phaseOffset,
    required this.pulseSpeed,
  });
}

class _NebulaLayerState extends State<NebulaLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_NebulaBlob> _blobs;

  static const _colors = [
    Color(0xFF9B72CF), // nebulaPurple
    Color(0xFF64FFDA), // auroraTeal
    Color(0xFFFF6B8A), // roseQuartz
    Color(0xFF4FC3F7), // starlightBlue
    Color(0xFF9B72CF),
    Color(0xFF4FC3F7),
    Color(0xFF64FFDA),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    final rng = Random(77); // fixed seed for deterministic layout
    _blobs = List.generate(7, (i) => _NebulaBlob(
      x: 0.05 + rng.nextDouble() * 0.9,
      y: 0.05 + rng.nextDouble() * 0.65,
      radius: 0.14 + rng.nextDouble() * 0.18,
      color: _colors[i],
      phaseOffset: rng.nextDouble() * 2 * pi,
      pulseSpeed: 0.3 + rng.nextDouble() * 0.5,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _targetOpacity {
    switch (widget.universeLevel) {
      case 1: return 0.0;
      case 2: return 0.45;
      case 3: return 0.70;
      default: return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _targetOpacity,
      duration: const Duration(seconds: 4),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _NebulaPainter(blobs: _blobs, progress: _ctrl.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _NebulaPainter extends CustomPainter {
  final List<_NebulaBlob> blobs;
  final double progress;

  const _NebulaPainter({required this.blobs, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * pi;
    for (final blob in blobs) {
      final pulse = 0.88 + 0.12 * sin(t * blob.pulseSpeed + blob.phaseOffset);
      final radius = blob.radius * size.width * pulse;
      final cx = blob.x * size.width;
      final cy = blob.y * size.height;

      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              blob.color.withValues(alpha: 0.09),
              blob.color.withValues(alpha: 0.03),
              blob.color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_NebulaPainter old) => old.progress != progress;
}
