import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/core/router/app_router.dart';

/// Full cinematic splash screen — 3.5 seconds animated sequence.
///
/// Sequence:
///   0ms     — Deep space background fades in
///   200ms   — Star field stagger appears
///   800ms   — Two orbital particles converge to center
///   1200ms  — "AETHERA" scales + fades in with letter-spacing expand
///   1800ms  — Subtitle fades in
///   2800ms  — Brief glow pulse
///   3200ms  — Full fade-out → AuthScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // ── Derived animations ─────────────────────────────────────────────
  late final Animation<double> _bgFade;
  late final Animation<double> _starsFade;
  late final Animation<double> _titleScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleSpacing;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _orbitalProgress;
  late final Animation<double> _exitFade;
  late final Animation<double> _glowPulse;

  static const _total = Duration(milliseconds: 3600);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _total);

    // Helpers
    Animation<double> interval(double start, double end, {Curve curve = Curves.easeInOut}) =>
        CurvedAnimation(parent: _ctrl, curve: Interval(start, end, curve: curve));

    _bgFade = interval(0.0, 0.17);
    _starsFade = interval(0.06, 0.42);
    _orbitalProgress = interval(0.22, 0.50, curve: Curves.easeInOutCubic);
    _titleFade = interval(0.33, 0.61);
    _titleScale = Tween(begin: 0.85, end: 1.0).animate(interval(0.33, 0.61, curve: Curves.easeOutBack));
    _titleSpacing = Tween(begin: 2.0, end: 8.0).animate(interval(0.33, 0.67));
    _subtitleFade = interval(0.50, 0.78);
    _glowPulse = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.78, 0.89, curve: Curves.easeInOut)),
    );
    _exitFade = Tween(begin: 1.0, end: 0.0).animate(interval(0.89, 1.0));

    _ctrl.forward();
    Future.delayed(_total, _navigate);
  }

  void _navigate() {
    if (mounted) context.go(AetheraRoutes.auth);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return FadeTransition(
            opacity: _exitFade,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Background gradient ─────────────────────────────
                FadeTransition(
                  opacity: _bgFade,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.3),
                        radius: 1.4,
                        colors: [
                          Color(0xFF0D1B2A),
                          Color(0xFF070B14),
                          Colors.black,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── Star field ──────────────────────────────────────
                FadeTransition(
                  opacity: _starsFade,
                  child: const _SplashStarField(),
                ),

                // ── Orbital particles ───────────────────────────────
                _OrbitalParticles(progress: _orbitalProgress.value),

                // ── Glow halo at center ─────────────────────────────
                Center(
                  child: Opacity(
                    opacity: _glowPulse.value * 0.5,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AetheraTokens.auroraTeal.withValues(alpha: 0.4),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                          BoxShadow(
                            color: AetheraTokens.roseQuartz.withValues(alpha: 0.3),
                            blurRadius: 80,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Title + subtitle ────────────────────────────────
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // AETHERA
                      FadeTransition(
                        opacity: _titleFade,
                        child: ScaleTransition(
                          scale: _titleScale,
                          child: Text(
                            'AETHERA',
                            style: AetheraTokens.displayLarge().copyWith(
                              letterSpacing: _titleSpacing.value,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [
                                    AetheraTokens.auroraTeal,
                                    AetheraTokens.starlight,
                                    AetheraTokens.nebulaPurple,
                                  ],
                                ).createShader(
                                  const Rect.fromLTWH(0, 0, 300, 80),
                                ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Subtitle
                      FadeTransition(
                        opacity: _subtitleFade,
                        child: Text(
                          'tu universo, juntos',
                          style: AetheraTokens.bodyMedium(
                            color: AetheraTokens.moonGlow,
                          ).copyWith(letterSpacing: 2.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Static splash star field (lighter than universe, no twinkling yet) ────────

class _SplashStarField extends StatelessWidget {
  const _SplashStarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SplashStarPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _SplashStarPainter extends CustomPainter {
  final List<(double, double, double)> _stars;

  _SplashStarPainter() : _stars = _generateStars();

  static List<(double, double, double)> _generateStars() {
    final rng = Random(99);
    return List.generate(
      120,
      (_) => (rng.nextDouble(), rng.nextDouble(), 0.4 + rng.nextDouble() * 1.4),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final (x, y, r) in _stars) {
      paint.color = Color.fromRGBO(232, 244, 253, 0.5 + r * 0.3);
      canvas.drawCircle(Offset(x * size.width, y * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(_SplashStarPainter _) => false;
}

// ─── Orbital particles converging to center ─────────────────────────────────────

class _OrbitalParticles extends StatelessWidget {
  final double progress; // 0.0 → 1.0

  const _OrbitalParticles({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cx = constraints.maxWidth / 2;
      final cy = constraints.maxHeight / 2;

      // Start positions (top-left and bottom-right quadrants)
      final startOffset1 = Offset(cx * 0.2, cy * 0.3);
      final startOffset2 = Offset(cx * 1.8, cy * 1.7);
      final end = Offset(cx, cy);

      final pos1 = Offset.lerp(startOffset1, end, Curves.easeInOutCubic.transform(progress))!;
      final pos2 = Offset.lerp(startOffset2, end, Curves.easeInOutCubic.transform(progress))!;
      final alpha = (1.0 - progress * 0.3).clamp(0.0, 1.0);

      return CustomPaint(
        painter: _OrbitalPainter(
          pos1: pos1,
          pos2: pos2,
          alpha: alpha,
          progress: progress,
        ),
      );
    });
  }
}

class _OrbitalPainter extends CustomPainter {
  final Offset pos1;
  final Offset pos2;
  final double alpha;
  final double progress;

  const _OrbitalPainter({
    required this.pos1,
    required this.pos2,
    required this.alpha,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Particle 1 — teal
    _drawParticle(canvas, pos1, const Color(0xFF64FFDA), alpha);
    // Particle 2 — rose
    _drawParticle(canvas, pos2, const Color(0xFFFF6B8A), alpha);

    // Trail lines when close to center
    if (progress > 0.6) {
      final trailAlpha = ((progress - 0.6) / 0.4 * alpha * 0.4).clamp(0.0, 1.0);
      _drawTrail(canvas, pos1, size, const Color(0xFF64FFDA), trailAlpha);
      _drawTrail(canvas, pos2, size, const Color(0xFFFF6B8A), trailAlpha);
    }
  }

  void _drawParticle(Canvas canvas, Offset pos, Color color, double alpha) {
    // Glow
    canvas.drawCircle(
      pos,
      18,
      Paint()..color = color.withValues(alpha: 0.12 * alpha),
    );
    // Core
    canvas.drawCircle(
      pos,
      5,
      Paint()..color = color.withValues(alpha: alpha),
    );
  }

  void _drawTrail(Canvas canvas, Offset pos, Size size, Color color, double alpha) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(pos, center, paint);
  }

  @override
  bool shouldRepaint(_OrbitalPainter old) =>
      old.pos1 != pos1 || old.pos2 != pos2 || old.alpha != alpha;
}
