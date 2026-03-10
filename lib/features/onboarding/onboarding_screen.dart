import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/core/router/app_router.dart';
import 'package:aethera/core/providers/app_state_notifier.dart';
import 'package:aethera/shared/widgets/aethera_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  late AnimationController _bgCtrl;
  late AnimationController _particleCtrl;

  static const _totalPages = 5;

  static const _pages = [
    _OnboardingPageData(
      emoji: '✦',
      title: 'Tu universo privado',
      subtitle:
          'Un espacio digital que solo existe entre tú y tu pareja. Invisible para el mundo. Infinito para ustedes.',
      accentColor: AetheraTokens.auroraTeal,
      bgColors: [Color(0xFF001A14), Color(0xFF070B14)],
    ),
    _OnboardingPageData(
      emoji: '🌊',
      title: 'El cielo cambia contigo',
      subtitle:
          'Cada emoción que compartes transforma los colores de tu cosmos. Alegría, amor, paz, añoranza — todas tienen su lugar aquí.',
      accentColor: AetheraTokens.nebulaPurple,
      bgColors: [Color(0xFF0E0018), Color(0xFF070B14)],
    ),
    _OnboardingPageData(
      emoji: '⭐',
      title: 'Tus recuerdos flotan en las estrellas',
      subtitle:
          'Cada momento especial se convierte en un objeto que habita tu universo. Constellaciones, faros, árboles — cada recuerdo tiene su forma.',
      accentColor: AetheraTokens.goldenDawn,
      bgColors: [Color(0xFF1A1200), Color(0xFF070B14)],
    ),
    _OnboardingPageData(
      emoji: '🏰',
      title: 'Sus sueños construyen el horizonte',
      subtitle:
          'Las metas que comparten se materializan en el horizonte de su universo. Cuanto más cerca estén de cumplirlas, más grandes aparecen.',
      accentColor: AetheraTokens.starlightBlue,
      bgColors: [Color(0xFF001020), Color(0xFF070B14)],
    ),
    _OnboardingPageData(
      emoji: '💕',
      title: 'Conectados a través del cosmos',
      subtitle:
          'Un ritual semanal, latidos de presencia, una conexión que crece con cada interacción. La distancia no existe aquí.',
      accentColor: AetheraTokens.roseQuartz,
      bgColors: [Color(0xFF1A0010), Color(0xFF070B14)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bgCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await appStateNotifier.completeOnboarding();
    if (mounted) context.go(AetheraRoutes.auth);
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic);
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: AetheraTokens.deepSpace,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated background gradient ─────────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.3 + _bgCtrl.value * 0.15),
                    radius: 1.2 + _bgCtrl.value * 0.2,
                    colors: [
                      page.accentColor.withValues(alpha: 0.12 + _bgCtrl.value * 0.06),
                      AetheraTokens.deepSpace,
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Floating ambient particles ────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _AmbientParticlePainter(
                progress: _particleCtrl.value,
                accentColor: page.accentColor,
              ),
            ),
          ),

          // ── Pages ─────────────────────────────────────────────────────
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (p) => setState(() => _currentPage = p),
            itemCount: _totalPages,
            itemBuilder: (_, i) => _OnboardingPage(
              data: _pages[i],
              isActive: i == _currentPage,
              isLast: i == _totalPages - 1,
              onNext: _next,
            ),
          ),

          // ── Page dots ─────────────────────────────────────────────────
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 28 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isActive
                        ? _pages[i].accentColor
                        : AetheraTokens.moonGlow.withValues(alpha: 0.25),
                  ),
                );
              }),
            ),
          ),

          // ── Skip button ───────────────────────────────────────────────
          if (_currentPage < _totalPages - 1)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: _complete,
                    child: Text(
                      'Omitir',
                      style: AetheraTokens.bodySmall(
                          color: AetheraTokens.dusk),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Single onboarding page ───────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final bool isActive;
  final bool isLast;
  final VoidCallback onNext;

  const _OnboardingPage({
    required this.data,
    required this.isActive,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Hero emoji with glow ───────────────────────────────────
            if (isActive)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: data.accentColor.withValues(alpha: 0.3),
                      blurRadius: 48,
                      spreadRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: data.emoji == '✦'
                      ? ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              AetheraTokens.auroraTeal,
                              AetheraTokens.nebulaPurple,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            data.emoji,
                            style: const TextStyle(
                                fontSize: 72, color: Colors.white),
                          ),
                        )
                      : Text(
                          data.emoji,
                          style: const TextStyle(fontSize: 72),
                        ),
                ),
              )
                  .animate(key: ValueKey('emoji_$isActive'))
                  .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms)
            else
              const SizedBox(height: 120),

            const SizedBox(height: 48),

            // ── Title ─────────────────────────────────────────────────
            if (isActive)
              Text(
                data.title,
                style: AetheraTokens.displayMedium().copyWith(
                  fontSize: 30,
                  height: 1.25,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              )
                  .animate(key: ValueKey('title_$isActive'))
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

            const SizedBox(height: 20),

            // ── Accent line ────────────────────────────────────────────
            if (isActive)
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: data.accentColor,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [
                    BoxShadow(
                      color: data.accentColor.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              )
                  .animate(key: ValueKey('line_$isActive'))
                  .fadeIn(delay: 400.ms)
                  .scaleX(begin: 0, end: 1, delay: 400.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Subtitle ──────────────────────────────────────────────
            if (isActive)
              Text(
                data.subtitle,
                style: AetheraTokens.bodyLarge(
                    color: AetheraTokens.moonGlow),
                textAlign: TextAlign.center,
              )
                  .animate(key: ValueKey('sub_$isActive'))
                  .fadeIn(delay: 400.ms, duration: 700.ms)
                  .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 52),

            // ── CTA button (last page only) ───────────────────────────
            if (isLast && isActive)
              AetheraButton(
                label: 'Comenzar mi universo  ✦',
                onPressed: onNext,
              )
                  .animate(key: const ValueKey('cta'))
                  .fadeIn(delay: 700.ms)
                  .slideY(begin: 0.2, end: 0),

            // ── Tap anywhere hint (not last) ──────────────────────────
            if (!isLast && isActive)
              GestureDetector(
                onTap: onNext,
                behavior: HitTestBehavior.translucent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Siguiente',
                        style: AetheraTokens.bodyMedium(
                            color: data.accentColor),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded,
                          color: data.accentColor, size: 16),
                    ],
                  ),
                ),
              ).animate(key: ValueKey('next_$isActive')).fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}

// ─── Page data model ──────────────────────────────────────────────────────────

class _OnboardingPageData {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<Color> bgColors;

  const _OnboardingPageData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.bgColors,
  });
}

// ─── Ambient floating particles ───────────────────────────────────────────────

class _AmbientParticlePainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  const _AmbientParticlePainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7);
    for (int i = 0; i < 25; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.02 + rng.nextDouble() * 0.04;
      final phase = rng.nextDouble();
      final amp = 12 + rng.nextDouble() * 20;

      final t = (progress + phase) % 1.0;
      final x = baseX + sin(t * 2 * pi) * amp;
      final y = baseY - t * size.height * speed * 10 % size.height;
      final alpha = sin(t * pi) * 0.5;
      final radius = 1.0 + rng.nextDouble() * 1.5;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = (i % 3 == 0
                  ? accentColor
                  : i % 3 == 1
                      ? AetheraTokens.starlight
                      : AetheraTokens.moonGlow)
              .withValues(alpha: alpha.clamp(0.0, 0.5)),
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientParticlePainter old) =>
      old.progress != progress || old.accentColor != accentColor;
}
