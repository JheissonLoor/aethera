import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:aethera/core/providers/app_state_notifier.dart';
import 'package:aethera/core/router/app_router.dart';
import 'package:aethera/core/services/haptics_service.dart';
import 'package:aethera/core/theme/aethera_motion.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/l10n/l10n_ext.dart';
import 'package:aethera/shared/widgets/aethera_button.dart';
import 'package:aethera/shared/widgets/aethera_glass_panel.dart';

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

  static const int _totalPages = 5;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: AetheraMotion.long)
      ..repeat(reverse: true);
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bgCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    HapticsService.affirmation();
    await appStateNotifier.completeOnboarding();
    if (mounted) context.go(AetheraRoutes.auth);
  }

  void _next() {
    HapticsService.secondaryAction();
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: AetheraMotion.screen,
        curve: AetheraMotion.standard,
      );
    } else {
      _complete();
    }
  }

  List<_OnboardingPageData> _pages(BuildContext context) {
    return [
      _OnboardingPageData(
        icon: Icons.auto_awesome_rounded,
        title: context.tr('Tu universo privado', 'Your private universe'),
        subtitle: context.tr(
          'Un espacio digital que solo existe entre tu y tu pareja. Invisible para el mundo. Infinito para ustedes.',
          'A digital space that exists only between you and your partner. Invisible to the world. Infinite for you both.',
        ),
        accentColor: AetheraTokens.auroraTeal,
        bgColors: const [Color(0xFF001A14), Color(0xFF070B14)],
      ),
      _OnboardingPageData(
        icon: Icons.water_drop_rounded,
        title: context.tr(
          'El cielo cambia contigo',
          'The sky changes with you',
        ),
        subtitle: context.tr(
          'Cada emocion que compartes transforma los colores de tu cosmos. Alegria, amor, paz y anoranza.',
          'Every emotion you share transforms the colors of your cosmos. Joy, love, peace and longing.',
        ),
        accentColor: AetheraTokens.nebulaPurple,
        bgColors: const [Color(0xFF0E0018), Color(0xFF070B14)],
      ),
      _OnboardingPageData(
        icon: Icons.star_rounded,
        title: context.tr(
          'Tus recuerdos flotan en las estrellas',
          'Your memories float among the stars',
        ),
        subtitle: context.tr(
          'Cada momento especial se convierte en un objeto que habita tu universo.',
          'Every special moment becomes an object that lives in your universe.',
        ),
        accentColor: AetheraTokens.goldenDawn,
        bgColors: const [Color(0xFF1A1200), Color(0xFF070B14)],
      ),
      _OnboardingPageData(
        icon: Icons.castle_rounded,
        title: context.tr(
          'Sus suenos construyen el horizonte',
          'Your shared dreams build the horizon',
        ),
        subtitle: context.tr(
          'Las metas compartidas se materializan en su universo y crecen con ustedes.',
          'Shared goals materialize in your universe and grow with you.',
        ),
        accentColor: AetheraTokens.starlightBlue,
        bgColors: const [Color(0xFF001020), Color(0xFF070B14)],
      ),
      _OnboardingPageData(
        icon: Icons.favorite_rounded,
        title: context.tr(
          'Conectados a traves del cosmos',
          'Connected through the cosmos',
        ),
        subtitle: context.tr(
          'Un ritual semanal y una conexion que crece con cada interaccion.',
          'A weekly ritual and a connection that grows with every interaction.',
        ),
        accentColor: AetheraTokens.roseQuartz,
        bgColors: const [Color(0xFF1A0010), Color(0xFF070B14)],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages(context);
    final page = pages[_currentPage];

    return Scaffold(
      backgroundColor: AetheraTokens.deepSpace,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.3 + _bgCtrl.value * 0.15),
                    radius: 1.2 + _bgCtrl.value * 0.2,
                    colors: [
                      page.accentColor.withValues(
                        alpha: 0.12 + _bgCtrl.value * 0.06,
                      ),
                      AetheraTokens.deepSpace,
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _particleCtrl,
            builder:
                (_, __) => CustomPaint(
                  painter: _AmbientParticlePainter(
                    progress: _particleCtrl.value,
                    accentColor: page.accentColor,
                  ),
                ),
          ),
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (p) => setState(() => _currentPage = p),
            itemCount: _totalPages,
            itemBuilder:
                (_, i) => _OnboardingPage(
                  data: pages[i],
                  index: i,
                  total: _totalPages,
                  isActive: i == _currentPage,
                  isLast: i == _totalPages - 1,
                  onNext: _next,
                ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: AetheraMotion.emphasized,
                  curve: AetheraMotion.standard,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 28 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color:
                        isActive
                            ? pages[i].accentColor
                            : AetheraTokens.moonGlow.withValues(alpha: 0.25),
                  ),
                );
              }),
            ),
          ),
          if (_currentPage < _totalPages - 1)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Semantics(
                    button: true,
                    label: context.tr('Omitir onboarding', 'Skip onboarding'),
                    child: GestureDetector(
                      onTap: () {
                        HapticsService.secondaryAction();
                        _complete();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.white.withValues(alpha: 0.06),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Text(
                          context.tr('Omitir', 'Skip'),
                          style: AetheraTokens.bodySmall(
                            color: AetheraTokens.moonGlow,
                          ),
                        ),
                      ),
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

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final int index;
  final int total;
  final bool isActive;
  final bool isLast;
  final VoidCallback onNext;

  const _OnboardingPage({
    required this.data,
    required this.index,
    required this.total,
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
            if (isActive)
              _StepChip(index: index + 1, total: total, color: data.accentColor)
                  .animate()
                  .fadeIn(duration: AetheraMotion.emphasized)
                  .slideY(begin: -0.15, end: 0, curve: AetheraMotion.enter),
            const SizedBox(height: 20),
            if (isActive)
              Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          data.accentColor.withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: data.accentColor.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: data.accentColor.withValues(alpha: 0.35),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      data.icon,
                      size: 56,
                      color: AetheraTokens.starlight,
                    ),
                  )
                  .animate(key: ValueKey('emoji_$isActive'))
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    duration: AetheraMotion.screen,
                    curve: AetheraMotion.emphasis,
                  )
                  .fadeIn(duration: AetheraMotion.emphasized)
            else
              const SizedBox(height: 120),
            const SizedBox(height: 34),
            if (isActive)
              AetheraGlassPanel(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    child: Column(
                      children: [
                        Text(
                          data.title,
                          style: AetheraTokens.displayMedium().copyWith(
                            fontSize: 30,
                            height: 1.25,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: 44,
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
                        ),
                        const SizedBox(height: 14),
                        Text(
                          data.subtitle,
                          style: AetheraTokens.bodyLarge(
                            color: AetheraTokens.moonGlow,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  .animate(key: ValueKey('title_$isActive'))
                  .fadeIn(
                    delay: AetheraMotion.stagger * 2,
                    duration: AetheraMotion.screen,
                  )
                  .slideY(begin: 0.15, end: 0, curve: AetheraMotion.enter),
            const SizedBox(height: 30),
            if (isLast && isActive)
              AetheraButton(
                    label: context.tr(
                      'Comenzar mi universo',
                      'Start my universe',
                    ),
                    onPressed: onNext,
                  )
                  .animate(key: const ValueKey('cta'))
                  .fadeIn(delay: AetheraMotion.screen)
                  .slideY(begin: 0.2, end: 0),
            if (!isLast && isActive)
              Semantics(
                    button: true,
                    label: context.tr('Siguiente pagina', 'Next page'),
                    child: GestureDetector(
                      onTap: onNext,
                      behavior: HitTestBehavior.translucent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.tr('Siguiente', 'Next'),
                              style: AetheraTokens.bodyMedium(
                                color: data.accentColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: data.accentColor,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .animate(key: ValueKey('next_$isActive'))
                  .fadeIn(delay: AetheraMotion.screenSlow),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<Color> bgColors;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.bgColors,
  });
}

class _StepChip extends StatelessWidget {
  final int index;
  final int total;
  final Color color;

  const _StepChip({
    required this.index,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        context.tr('Paso $index de $total', 'Step $index of $total'),
        style: AetheraTokens.labelSmall(color: color),
      ),
    );
  }
}

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
  bool shouldRepaint(_AmbientParticlePainter old) {
    return old.progress != progress || old.accentColor != accentColor;
  }
}
