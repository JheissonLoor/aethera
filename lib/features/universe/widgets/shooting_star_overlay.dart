import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Periodically spawns animated shooting stars across the universe background.
/// Purely visual — does not intercept touches.
class ShootingStarOverlay extends StatefulWidget {
  const ShootingStarOverlay({super.key});

  @override
  State<ShootingStarOverlay> createState() => _ShootingStarOverlayState();
}

class _StarData {
  final Key key;
  final double startX;
  final double startY;
  final double angleDeg;
  final double trailFraction;

  const _StarData({
    required this.key,
    required this.startX,
    required this.startY,
    required this.angleDeg,
    required this.trailFraction,
  });
}

class _ShootingStarOverlayState extends State<ShootingStarOverlay> {
  final _rng = Random();
  final List<_StarData> _stars = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Initial delay so it doesn't fire immediately on screen load
    _timer = Timer(const Duration(seconds: 6), _scheduleLoop);
  }

  void _scheduleLoop() {
    if (!mounted) return;
    _spawnStar();
    final delay = 9 + _rng.nextInt(14); // 9–23 seconds
    _timer = Timer(Duration(seconds: delay), _scheduleLoop);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _spawnStar() {
    final star = _StarData(
      key: UniqueKey(),
      startX: 0.05 + _rng.nextDouble() * 0.55,
      startY: 0.04 + _rng.nextDouble() * 0.32,
      angleDeg: 22 + _rng.nextDouble() * 28,
      trailFraction: 0.22 + _rng.nextDouble() * 0.18,
    );
    setState(() => _stars.add(star));
  }

  void _removeStar(Key key) {
    if (mounted) setState(() => _stars.removeWhere((s) => s.key == key));
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (ctx, constraints) => Stack(
          children: _stars
              .map((s) => _ShootingStarWidget(
                    key: s.key,
                    startX: s.startX * constraints.maxWidth,
                    startY: s.startY * constraints.maxHeight,
                    angleDeg: s.angleDeg,
                    trailLength: s.trailFraction * constraints.maxWidth,
                    onComplete: () => _removeStar(s.key),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ─── Individual shooting star ─────────────────────────────────────────────────

class _ShootingStarWidget extends StatefulWidget {
  final double startX;
  final double startY;
  final double angleDeg;
  final double trailLength;
  final VoidCallback onComplete;

  const _ShootingStarWidget({
    super.key,
    required this.startX,
    required this.startY,
    required this.angleDeg,
    required this.trailLength,
    required this.onComplete,
  });

  @override
  State<_ShootingStarWidget> createState() => _ShootingStarWidgetState();
}

class _ShootingStarWidgetState extends State<_ShootingStarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _position;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _position = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 33),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final angleRad = widget.angleDeg * pi / 180.0;
    final dx = cos(angleRad) * widget.trailLength;
    final dy = sin(angleRad) * widget.trailLength;
    const tailRatio = 0.38;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final p = _position.value;
        final alpha = _opacity.value;
        final headX = widget.startX + dx * p;
        final headY = widget.startY + dy * p;
        final tailX = headX - cos(angleRad) * widget.trailLength * tailRatio;
        final tailY = headY - sin(angleRad) * widget.trailLength * tailRatio;

        return CustomPaint(
          painter: _ShootingStarPainter(
            head: Offset(headX, headY),
            tail: Offset(tailX, tailY),
            alpha: alpha,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ShootingStarPainter extends CustomPainter {
  final Offset head;
  final Offset tail;
  final double alpha;

  const _ShootingStarPainter({
    required this.head,
    required this.tail,
    required this.alpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (alpha <= 0.01) return;

    // Trail gradient: tail (transparent) → head (bright white)
    final linePaint = Paint()
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..shader = LinearGradient(
        colors: [
          const Color(0x00E8F4FD),
          Color.fromRGBO(232, 244, 253, alpha * 0.85),
        ],
      ).createShader(Rect.fromPoints(tail, head));

    canvas.drawLine(tail, head, linePaint);

    // Head: bright core dot
    canvas.drawCircle(
      head,
      1.6,
      Paint()
        ..color = Color.fromRGBO(232, 244, 253, alpha)
        ..style = PaintingStyle.fill,
    );

    // Head: teal glow halo
    canvas.drawCircle(
      head,
      4.5,
      Paint()
        ..color = Color.fromRGBO(100, 255, 218, alpha * 0.35)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_ShootingStarPainter old) =>
      old.head != head || old.alpha != alpha;
}
