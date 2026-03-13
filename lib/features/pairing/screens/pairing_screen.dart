import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aethera/core/router/app_router.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/features/auth/providers/auth_provider.dart';
import 'package:aethera/features/pairing/providers/pairing_provider.dart';
import 'package:aethera/features/universe/widgets/cosmic_background.dart';
import 'package:aethera/l10n/l10n_ext.dart';
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

  Future<void> _generateCode() async {
    final uid = ref.read(authServiceProvider).currentUserId;
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
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  Future<void> _joinCouple() async {
    final uid = ref.read(authServiceProvider).currentUserId;
    if (uid == null) return;
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('El codigo tiene 6 caracteres', 'Code has 6 characters'),
            style: AetheraTokens.bodyMedium(),
          ),
          backgroundColor: AetheraTokens.roseQuartz.withValues(alpha: 0.85),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                children: [
                  _buildHeader()
                      .animate()
                      .fadeIn(duration: 700.ms)
                      .slideY(begin: -0.1, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 36),
                  _buildTabSelector().animate().fadeIn(
                    delay: 200.ms,
                    duration: 500.ms,
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder:
                          (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(_isJoinMode ? 0.08 : -0.08, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOut,
                                ),
                              ),
                              child: child,
                            ),
                          ),
                      child:
                          _isJoinMode
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
                                onEnterSolo:
                                    () =>
                                        ref
                                            .read(pairingProvider.notifier)
                                            .enterSolo(),
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
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [AetheraTokens.auroraTeal, AetheraTokens.nebulaPurple],
              ).createShader(bounds),
          child: const Icon(Icons.hub_outlined, size: 52, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('Tu universo', 'Your universe'),
          style: AetheraTokens.displayMedium().copyWith(letterSpacing: 4),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('conecta con quien importa', 'connect with who matters'),
          style: AetheraTokens.bodyMedium(
            color: AetheraTokens.moonGlow,
          ).copyWith(letterSpacing: 2),
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
            label: context.tr('Crear universo', 'Create universe'),
            isActive: !_isJoinMode,
            onTap: () => setState(() => _isJoinMode = false),
          ),
          _TabChip(
            label: context.tr('Unirse', 'Join'),
            isActive: _isJoinMode,
            onTap: () => setState(() => _isJoinMode = true),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient:
                  isActive
                      ? LinearGradient(
                        colors: [
                          AetheraTokens.auroraTeal.withValues(alpha: 0.18),
                          AetheraTokens.nebulaPurple.withValues(alpha: 0.12),
                        ],
                      )
                      : null,
              borderRadius: BorderRadius.circular(8),
              border:
                  isActive
                      ? Border.all(
                        color: AetheraTokens.auroraTeal.withValues(alpha: 0.3),
                      )
                      : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AetheraTokens.bodyMedium(
                color:
                    isActive
                        ? AetheraTokens.auroraTeal
                        : AetheraTokens.moonGlow,
              ).copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
      return Column(
        children: [
          AetheraGlassPanel(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback:
                      (bounds) => const LinearGradient(
                        colors: [
                          AetheraTokens.auroraTeal,
                          AetheraTokens.nebulaPurple,
                        ],
                      ).createShader(bounds),
                  child: const Text(
                    '✦',
                    style: TextStyle(fontSize: 52, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('Crea tu universo', 'Create your universe'),
                  style: AetheraTokens.displaySmall(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr(
                    'Genera un codigo unico para invitar a tu pareja a este espacio.',
                    'Generate a unique code to invite your partner to this space.',
                  ),
                  textAlign: TextAlign.center,
                  style: AetheraTokens.bodyMedium(
                    color: AetheraTokens.moonGlow,
                  ),
                ),
                const SizedBox(height: 32),
                AetheraButton(
                  label: context.tr(
                    'Generar mi codigo  ✦',
                    'Generate my code  ✦',
                  ),
                  onPressed: onGenerate,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
          const Spacer(),
          Text(
            context.tr(
              'Tienes el codigo de tu pareja? Cambia a la pestana Unirse',
              'Do you have your partner code? Switch to Join tab',
            ),
            textAlign: TextAlign.center,
            style: AetheraTokens.bodyMedium(
              color: AetheraTokens.moonGlow.withValues(alpha: 0.45),
            ),
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

    final safeCode = code ?? '';
    return Column(
      children: [
        AetheraGlassPanel(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
          child: Column(
            children: [
              Text(
                context.tr(
                  'Comparte este codigo con tu pareja',
                  'Share this code with your partner',
                ),
                textAlign: TextAlign.center,
                style: AetheraTokens.bodyLarge(color: AetheraTokens.moonGlow),
              ),
              const SizedBox(height: 28),
              Semantics(
                button: true,
                label: context.tr('Copiar codigo', 'Copy code'),
                child: GestureDetector(
                      onTap: () => onCopy(safeCode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AetheraTokens.auroraTeal.withValues(
                              alpha: 0.4,
                            ),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AetheraTokens.auroraTeal.withValues(
                                alpha: 0.08,
                              ),
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
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      curve: Curves.easeOutBack,
                    ),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Row(
                  key: ValueKey(codeCopied),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      codeCopied
                          ? Icons.check_circle_outline_rounded
                          : Icons.copy_outlined,
                      size: 14,
                      color:
                          codeCopied
                              ? AetheraTokens.auroraTeal
                              : AetheraTokens.moonGlow,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      codeCopied
                          ? context.tr('Copiado', 'Copied')
                          : context.tr('Toca para copiar', 'Tap to copy'),
                      style: AetheraTokens.bodyMedium(
                        color:
                            codeCopied
                                ? AetheraTokens.auroraTeal
                                : AetheraTokens.moonGlow,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr(
                  'Tu pareja debe ir a Unirse e ingresar este codigo',
                  'Your partner should open Join and enter this code',
                ),
                textAlign: TextAlign.center,
                style: AetheraTokens.bodyMedium(
                  color: AetheraTokens.moonGlow.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        AetheraButton(
          label: context.tr('Entrar solo por ahora', 'Enter solo for now'),
          variant: AetheraButtonVariant.outlined,
          onPressed: onEnterSolo,
        ),
        const SizedBox(height: 12),
        Text(
          context.tr(
            'El codigo permanece activo y tu pareja puede unirse despues',
            'The code stays active and your partner can join later',
          ),
          textAlign: TextAlign.center,
          style: AetheraTokens.bodyMedium(
            color: AetheraTokens.moonGlow.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

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
                context.tr(
                  'Ingresa el codigo de invitacion',
                  'Enter invite code',
                ),
                textAlign: TextAlign.center,
                style: AetheraTokens.bodyLarge(color: AetheraTokens.moonGlow),
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
                  hintText: context.tr('XXXXXX', 'XXXXXX'),
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
                      color: AetheraTokens.moonGlow.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AetheraTokens.moonGlow.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AetheraTokens.auroraTeal.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AetheraTokens.roseQuartz.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AetheraTokens.roseQuartz.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: AetheraTokens.bodyMedium(
                      color: AetheraTokens.roseQuartz,
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms),
              ],
              const SizedBox(height: 24),
              AetheraButton(
                label: context.tr('Unirse al universo', 'Join universe'),
                isLoading: state.isLoading,
                onPressed: onJoin,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
        const Spacer(),
        Text(
          context.tr(
            'Pide el codigo a tu pareja desde Crear universo',
            'Ask your partner for the code from Create universe',
          ),
          textAlign: TextAlign.center,
          style: AetheraTokens.bodyMedium(
            color: AetheraTokens.moonGlow.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
