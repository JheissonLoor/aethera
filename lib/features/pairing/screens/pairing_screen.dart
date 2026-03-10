import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/core/router/app_router.dart';
import 'package:aethera/features/pairing/providers/pairing_provider.dart';
import 'package:aethera/features/universe/widgets/cosmic_background.dart';
import 'package:aethera/shared/widgets/aethera_button.dart';
import 'package:aethera/shared/widgets/aethera_glass_panel.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  bool _isJoinMode = false;
  bool _codeCopied = false;
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _generateCode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await ref.read(pairingProvider.notifier).createCouple(uid);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _codeCopied = true);
    Future.delayed(
        const Duration(seconds: 2),
        () {
          if (mounted) setState(() => _codeCopied = false);
        });
  }

  Future<void> _joinCouple() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El código tiene 6 caracteres',
              style: AetheraTokens.bodyMedium()),
          backgroundColor: AetheraTokens.roseQuartz.withValues(alpha: 0.85),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    final ok = await ref.read(pairingProvider.notifier).joinCouple(code, uid);
    if (ok && mounted) context.go(AetheraRoutes.universe);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pairingProvider);

    return Scaffold(
      backgroundColor: AetheraTokens.deepSpace,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CosmicBackground(),

          // Subtle bottom glow
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomCenter,
                  radius: 1.2,
                  colors: [
                    AetheraTokens.auroraTeal.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                children: [
                  _buildHeader()
                      .animate()
                      .fadeIn(duration: 700.ms)
                      .slideY(begin: -0.1, end: 0, curve: Curves.easeOut),

                  const SizedBox(height: 36),

                  _buildTabSelector()
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms),

                  const SizedBox(height: 28),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(_isJoinMode ? 0.08 : -0.08, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOut)),
                          child: child,
                        ),
                      ),
                      child: _isJoinMode
                          ? _JoinContent(
                              key: const ValueKey('join'),
                              controller: _codeCtrl,
                              state: state,
                              onJoin: _joinCouple,
                            )
                          : _CreateContent(
                              key: const ValueKey('create'),
                              state: state,
                              codeCopied: _codeCopied,
                              onCopy: _copyCode,
                              onGenerate: _generateCode,
                              onEnterSolo: () =>
                                  ref.read(pairingProvider.notifier).enterSolo(),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AetheraTokens.auroraTeal, AetheraTokens.nebulaPurple],
          ).createShader(bounds),
          child: const Icon(Icons.hub_outlined, size: 52, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'Tu universo',
          style: AetheraTokens.displayMedium().copyWith(letterSpacing: 4),
        ),
        const SizedBox(height: 8),
        Text(
          'conecta con quien importa',
          style: AetheraTokens.bodyMedium(color: AetheraTokens.moonGlow)
              .copyWith(letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return AetheraGlassPanel(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _TabChip(
            label: 'Crear universo',
            isActive: !_isJoinMode,
            onTap: () => setState(() => _isJoinMode = false),
          ),
          _TabChip(
            label: 'Unirse',
            isActive: _isJoinMode,
            onTap: () => setState(() => _isJoinMode = true),
          ),
        ],
      ),
    );
  }
}

// ── Tab chip ─────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(colors: [
                    AetheraTokens.auroraTeal.withValues(alpha: 0.18),
                    AetheraTokens.nebulaPurple.withValues(alpha: 0.12),
                  ])
                : null,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(
                    color: AetheraTokens.auroraTeal.withValues(alpha: 0.3))
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AetheraTokens.bodyMedium(
              color: isActive
                  ? AetheraTokens.auroraTeal
                  : AetheraTokens.moonGlow,
            ).copyWith(
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal),
          ),
        ),
      ),
    );
  }
}

// ── Create tab ───────────────────────────────────────────────────────────────

class _CreateContent extends StatelessWidget {
  final PairingState state;
  final bool codeCopied;
  final void Function(String) onCopy;
  final VoidCallback onEnterSolo;
  final VoidCallback onGenerate;

  const _CreateContent({
    super.key,
    required this.state,
    required this.codeCopied,
    required this.onCopy,
    required this.onEnterSolo,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final code = state.couple?.inviteCode;
    final isGenerating = state.isLoading;
    final hasCode = code != null && code.isNotEmpty;

    if (!hasCode && !isGenerating) {
      // Initial state — user hasn't generated a code yet
      return Column(
        children: [
          AetheraGlassPanel(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AetheraTokens.auroraTeal, AetheraTokens.nebulaPurple],
                  ).createShader(bounds),
                  child: const Text('✦', style: TextStyle(fontSize: 52, color: Colors.white)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Crea tu universo',
                  style: AetheraTokens.displaySmall(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Genera un código único para invitar\na tu pareja a este espacio.',
                  textAlign: TextAlign.center,
                  style: AetheraTokens.bodyMedium(color: AetheraTokens.moonGlow),
                ),
                const SizedBox(height: 32),
                AetheraButton(
                  label: 'Generar mi código  ✦',
                  onPressed: onGenerate,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

          const Spacer(),

          Text(
            '¿Tienes el código de tu pareja? Cambia a la pestaña "Unirse"',
            textAlign: TextAlign.center,
            style: AetheraTokens.bodyMedium(
                color: AetheraTokens.moonGlow.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    if (isGenerating) {
      return const Center(
        child: CircularProgressIndicator(
          color: AetheraTokens.auroraTeal,
          strokeWidth: 2,
        ),
      );
    }

    // Code has been generated
    final safeCode = code ?? '';
    return Column(
      children: [
        AetheraGlassPanel(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
          child: Column(
            children: [
              Text(
                'Comparte este código con tu pareja',
                textAlign: TextAlign.center,
                style: AetheraTokens.bodyLarge(color: AetheraTokens.moonGlow),
              ),
              const SizedBox(height: 28),

              // Code display
              GestureDetector(
                onTap: () => onCopy(safeCode),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AetheraTokens.auroraTeal.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AetheraTokens.auroraTeal.withValues(alpha: 0.08),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    safeCode,
                    style: AetheraTokens.displayMedium().copyWith(
                      letterSpacing: 14,
                      color: AetheraTokens.auroraTeal,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),

              const SizedBox(height: 14),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Row(
                  key: ValueKey(codeCopied),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      codeCopied ? Icons.check_circle_outline_rounded : Icons.copy_outlined,
                      size: 14,
                      color: codeCopied ? AetheraTokens.auroraTeal : AetheraTokens.moonGlow,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      codeCopied ? '¡Copiado!' : 'Toca para copiar',
                      style: AetheraTokens.bodyMedium(
                        color: codeCopied ? AetheraTokens.auroraTeal : AetheraTokens.moonGlow,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Tu pareja debe ir a "Unirse" e ingresar este código',
                textAlign: TextAlign.center,
                style: AetheraTokens.bodyMedium(
                    color: AetheraTokens.moonGlow.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),

        const Spacer(),

        AetheraButton(
          label: 'Entrar solo por ahora',
          variant: AetheraButtonVariant.outlined,
          onPressed: onEnterSolo,
        ),

        const SizedBox(height: 12),

        Text(
          'El código permanece activo — tu pareja puede unirse después',
          textAlign: TextAlign.center,
          style: AetheraTokens.bodyMedium(
              color: AetheraTokens.moonGlow.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Join tab ─────────────────────────────────────────────────────────────────

class _JoinContent extends StatelessWidget {
  final TextEditingController controller;
  final PairingState state;
  final VoidCallback onJoin;

  const _JoinContent({
    super.key,
    required this.controller,
    required this.state,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AetheraGlassPanel(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ingresa el código de invitación',
                textAlign: TextAlign.center,
                style:
                    AetheraTokens.bodyLarge(color: AetheraTokens.moonGlow),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: AetheraTokens.displayMedium().copyWith(
                  letterSpacing: 12,
                  color: AetheraTokens.auroraTeal,
                ),
                decoration: InputDecoration(
                  hintText: 'XXXXXX',
                  hintStyle: AetheraTokens.displayMedium().copyWith(
                    letterSpacing: 12,
                    color: AetheraTokens.moonGlow.withValues(alpha: 0.25),
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            AetheraTokens.moonGlow.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            AetheraTokens.moonGlow.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          AetheraTokens.auroraTeal.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              if (state.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AetheraTokens.roseQuartz.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AetheraTokens.roseQuartz
                            .withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: AetheraTokens.bodyMedium(
                        color: AetheraTokens.roseQuartz),
                  ),
                ).animate().fadeIn(duration: 300.ms),
              ],

              const SizedBox(height: 24),

              AetheraButton(
                label: 'Unirse al universo',
                isLoading: state.isLoading,
                onPressed: onJoin,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

        const Spacer(),

        Text(
          'Pide el código a tu pareja desde la pestaña "Crear universo"',
          textAlign: TextAlign.center,
          style: AetheraTokens.bodyMedium(
              color: AetheraTokens.moonGlow.withValues(alpha: 0.45)),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}
