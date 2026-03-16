import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aethera/core/services/haptics_service.dart';
import 'package:aethera/core/theme/aethera_motion.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/features/auth/providers/auth_provider.dart';
import 'package:aethera/features/universe/widgets/cosmic_background.dart';
import 'package:aethera/l10n/l10n_ext.dart';
import 'package:aethera/shared/widgets/aethera_button.dart';
import 'package:aethera/shared/widgets/aethera_glass_panel.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isRegister = false;
  bool _obscurePassword = true;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    HapticsService.secondaryAction();
    ref.read(authProvider.notifier).resetError();
    setState(() => _isRegister = !_isRegister);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticsService.primaryAction();
    final notifier = ref.read(authProvider.notifier);
    if (_isRegister) {
      await notifier.register(
        _emailCtrl.text,
        _passwordCtrl.text,
        _nameCtrl.text,
      );
    } else {
      await notifier.signIn(_emailCtrl.text, _passwordCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AetheraTokens.deepSpace,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CosmicBackground(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [
                    AetheraTokens.nebulaPurple.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  children: [
                    _buildHeader()
                        .animate()
                        .fadeIn(duration: AetheraMotion.emphasized)
                        .slideY(
                          begin: -0.15,
                          end: 0,
                          curve: AetheraMotion.enter,
                        ),
                    const SizedBox(height: 22),
                    _buildModeSwitch().animate().fadeIn(
                      delay: AetheraMotion.stagger,
                      duration: AetheraMotion.emphasized,
                    ),
                    const SizedBox(height: 18),
                    _buildForm(authState)
                        .animate()
                        .fadeIn(
                          delay: AetheraMotion.stagger * 2,
                          duration: AetheraMotion.screen,
                        )
                        .slideY(
                          begin: 0.15,
                          end: 0,
                          curve: AetheraMotion.enter,
                        ),
                    const SizedBox(height: 14),
                    _buildTrustRow().animate().fadeIn(
                      delay: AetheraMotion.stagger * 3,
                      duration: AetheraMotion.screen,
                    ),
                    const SizedBox(height: 22),
                    _buildToggle().animate().fadeIn(
                      delay: AetheraMotion.stagger * 4,
                      duration: AetheraMotion.screen,
                    ),
                    if (!_isRegister) ...[
                      const SizedBox(height: 16),
                      _buildForgotPassword().animate().fadeIn(
                        delay: AetheraMotion.stagger * 5,
                        duration: AetheraMotion.emphasized,
                      ),
                    ],
                  ],
                ),
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
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AetheraTokens.auroraTeal.withValues(alpha: 0.32),
                AetheraTokens.nebulaPurple.withValues(alpha: 0.24),
              ],
            ),
            border: Border.all(
              color: AetheraTokens.auroraTeal.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: AetheraTokens.auroraTeal.withValues(alpha: 0.24),
                blurRadius: 26,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AetheraTokens.starlight,
            size: 34,
          ),
        ),
        const SizedBox(height: 14),
        ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [
                  AetheraTokens.auroraTeal,
                  AetheraTokens.starlight,
                  AetheraTokens.nebulaPurple,
                ],
              ).createShader(bounds),
          child: Text(
            'AETHERA',
            style: AetheraTokens.displayMedium().copyWith(
              color: Colors.white,
              letterSpacing: 8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('acceso emocional privado', 'private emotional access'),
          style: AetheraTokens.bodySmall(
            color: AetheraTokens.moonGlow.withValues(alpha: 0.9),
          ).copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: AetheraMotion.emphasized,
          child: Text(
            _isRegister
                ? context.tr('crea tu universo', 'create your universe')
                : context.tr('bienvenido de vuelta', 'welcome back'),
            key: ValueKey(_isRegister),
            style: AetheraTokens.bodyMedium(
              color: AetheraTokens.moonGlow,
            ).copyWith(letterSpacing: 2.5),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(AsyncValue<void> authState) {
    return AetheraGlassPanel(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isRegister
                  ? context.tr('Crear cuenta', 'Create account')
                  : context.tr('Iniciar sesion', 'Sign in'),
              style: AetheraTokens.labelLarge(color: AetheraTokens.starlight),
            ),
            const SizedBox(height: 4),
            Text(
              _isRegister
                  ? context.tr(
                    'Configura tu acceso para comenzar.',
                    'Set up your access to begin.',
                  )
                  : context.tr(
                    'Ingresa para volver a tu universo.',
                    'Sign in to return to your universe.',
                  ),
              style: AetheraTokens.bodySmall(color: AetheraTokens.moonGlow),
            ),
            const SizedBox(height: 18),
            AnimatedSize(
              duration: AetheraMotion.emphasized,
              curve: AetheraMotion.standard,
              child:
                  _isRegister
                      ? Column(
                        children: [
                          _buildField(
                            controller: _nameCtrl,
                            label: context.tr('Tu nombre', 'Your name'),
                            icon: Icons.person_outline_rounded,
                            validator:
                                (v) =>
                                    (v?.trim().isEmpty ?? true)
                                        ? context.tr(
                                          'Ingresa tu nombre',
                                          'Enter your name',
                                        )
                                        : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                      )
                      : const SizedBox.shrink(),
            ),
            _buildField(
              controller: _emailCtrl,
              label: context.tr('Email', 'Email'),
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v?.trim().isEmpty ?? true) {
                  return context.tr('Ingresa tu email', 'Enter your email');
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v!.trim())) {
                  return context.tr('Email invalido', 'Invalid email');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _passwordCtrl,
              label: context.tr('Contrasena', 'Password'),
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffix: IconButton(
                tooltip:
                    _obscurePassword
                        ? context.tr('Mostrar contrasena', 'Show password')
                        : context.tr('Ocultar contrasena', 'Hide password'),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AetheraTokens.moonGlow,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator:
                  (v) =>
                      (v?.length ?? 0) < 6
                          ? context.tr(
                            'Minimo 6 caracteres',
                            'Minimum 6 characters',
                          )
                          : null,
            ),
            if (authState is AsyncError) ...[
              const SizedBox(height: 16),
              _buildError(
                _parseFirebaseError(authState.error),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
            ],
            const SizedBox(height: 28),
            AetheraButton(
              label:
                  _isRegister
                      ? context.tr('Crear cuenta', 'Create account')
                      : context.tr('Entrar ahora', 'Sign in now'),
              isLoading: authState is AsyncLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModePill(
              selected: !_isRegister,
              label: context.tr('Entrar', 'Sign in'),
              onTap: () {
                if (!_isRegister) return;
                _toggleMode();
              },
            ),
          ),
          Expanded(
            child: _buildModePill(
              selected: _isRegister,
              label: context.tr('Crear cuenta', 'Create account'),
              onTap: () {
                if (_isRegister) return;
                _toggleMode();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModePill({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AetheraMotion.medium,
        curve: AetheraMotion.enter,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color:
              selected
                  ? AetheraTokens.auroraTeal.withValues(alpha: 0.16)
                  : Colors.transparent,
          border:
              selected
                  ? Border.all(
                    color: AetheraTokens.auroraTeal.withValues(alpha: 0.4),
                  )
                  : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AetheraTokens.bodyMedium(
            color: selected ? AetheraTokens.auroraTeal : AetheraTokens.moonGlow,
          ),
        ),
      ),
    );
  }

  Widget _buildTrustRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildTrustChip(
          icon: Icons.verified_user_outlined,
          label: context.tr('Sesion segura', 'Secure session'),
        ),
        _buildTrustChip(
          icon: Icons.lock_outline_rounded,
          label: context.tr('Acceso privado', 'Private access'),
        ),
        _buildTrustChip(
          icon: Icons.favorite_outline_rounded,
          label: context.tr('Solo pareja', 'Couple only'),
        ),
      ],
    );
  }

  Widget _buildTrustChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AetheraTokens.auroraTeal),
          const SizedBox(width: 6),
          Text(
            label,
            style: AetheraTokens.labelSmall(color: AetheraTokens.moonGlow),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: AetheraTokens.bodyLarge(color: AetheraTokens.starlight),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AetheraTokens.bodyMedium(color: AetheraTokens.moonGlow),
        prefixIcon: Icon(icon, color: AetheraTokens.auroraTeal, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.045),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: _inputBorder(AetheraTokens.moonGlow.withValues(alpha: 0.2)),
        enabledBorder: _inputBorder(
          AetheraTokens.moonGlow.withValues(alpha: 0.2),
        ),
        focusedBorder: _inputBorder(
          AetheraTokens.auroraTeal.withValues(alpha: 0.6),
          width: 1.5,
        ),
        errorBorder: _inputBorder(
          AetheraTokens.roseQuartz.withValues(alpha: 0.5),
        ),
        focusedErrorBorder: _inputBorder(
          AetheraTokens.roseQuartz.withValues(alpha: 0.8),
          width: 1.5,
        ),
        errorStyle: AetheraTokens.bodyMedium(color: AetheraTokens.roseQuartz),
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AetheraTokens.roseQuartz.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AetheraTokens.roseQuartz.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AetheraTokens.roseQuartz,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AetheraTokens.bodyMedium(color: AetheraTokens.roseQuartz),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('Ingresa tu email primero', 'Enter your email first'),
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

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Enviamos un enlace a $email',
              'We sent a link to $email',
            ),
            style: AetheraTokens.bodyMedium(),
          ),
          backgroundColor: AetheraTokens.auroraTeal.withValues(alpha: 0.85),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'No pudimos enviar el enlace',
              'We could not send the link',
            ),
            style: AetheraTokens.bodyMedium(),
          ),
          backgroundColor: AetheraTokens.roseQuartz.withValues(alpha: 0.85),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildForgotPassword() {
    return Semantics(
      button: true,
      label: context.tr('Olvide mi contrasena', 'I forgot my password'),
      child: GestureDetector(
        onTap: () {
          HapticsService.secondaryAction();
          _sendPasswordReset();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            context.tr('Olvide mi contrasena', 'I forgot my password'),
            textAlign: TextAlign.center,
            style: AetheraTokens.bodySmall(color: AetheraTokens.dusk).copyWith(
              decoration: TextDecoration.underline,
              decorationColor: AetheraTokens.dusk,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(
          _isRegister
              ? context.tr('Ya tienes universo?', 'Already have a universe?')
              : context.tr('Primera vez en Aethera?', 'First time in Aethera?'),
          style: AetheraTokens.bodyMedium(color: AetheraTokens.moonGlow),
        ),
        Semantics(
          button: true,
          label:
              _isRegister
                  ? context.tr('Inicia sesion', 'Sign in')
                  : context.tr('Crea tu cuenta', 'Create account'),
          child: GestureDetector(
            onTap: _toggleMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: AetheraTokens.auroraTeal.withValues(alpha: 0.12),
                border: Border.all(
                  color: AetheraTokens.auroraTeal.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                _isRegister
                    ? context.tr('Inicia sesion', 'Sign in')
                    : context.tr('Crea tu cuenta', 'Create account'),
                style: AetheraTokens.bodySmall(color: AetheraTokens.auroraTeal),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _parseFirebaseError(Object? error) {
    final msg = error?.toString() ?? '';
    if (msg.contains('user-not-found') ||
        msg.contains('wrong-password') ||
        msg.contains('invalid-credential') ||
        msg.contains('INVALID_LOGIN_CREDENTIALS')) {
      return context.tr(
        'Email o contrasena incorrectos',
        'Wrong email or password',
      );
    }
    if (msg.contains('email-already-in-use')) {
      return context.tr(
        'Este email ya tiene una cuenta',
        'This email is already in use',
      );
    }
    if (msg.contains('weak-password')) {
      return context.tr('La contrasena es muy debil', 'Password is too weak');
    }
    if (msg.contains('network-request-failed')) {
      return context.tr(
        'Sin conexion. Verifica tu internet',
        'No connection. Check your internet',
      );
    }
    if (msg.contains('too-many-requests')) {
      return context.tr(
        'Demasiados intentos. Espera un momento',
        'Too many attempts. Wait a moment',
      );
    }
    return context.tr(
      'Algo salio mal. Intentalo de nuevo',
      'Something went wrong. Try again',
    );
  }
}
