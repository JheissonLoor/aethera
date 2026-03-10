import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/features/auth/providers/auth_provider.dart';
import 'package:aethera/features/universe/widgets/cosmic_background.dart';
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
    ref.read(authProvider.notifier).resetError();
    setState(() => _isRegister = !_isRegister);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(authProvider.notifier);
    if (_isRegister) {
      await notifier.register(
          _emailCtrl.text, _passwordCtrl.text, _nameCtrl.text);
    } else {
      await notifier.signIn(_emailCtrl.text, _passwordCtrl.text);
    }
    // GoRouter redirect handles navigation automatically
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
          // Cosmic background
          const CosmicBackground(),

          // Subtle top glow
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: Column(
                  children: [
                    // ── Logo ──────────────────────────────────────────
                    _buildHeader()
                        .animate()
                        .fadeIn(duration: 700.ms)
                        .slideY(begin: -0.15, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: 48),

                    // ── Form ──────────────────────────────────────────
                    _buildForm(authState)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: 28),

                    // ── Toggle ────────────────────────────────────────
                    _buildToggle()
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 500.ms),

                    // ── Forgot password (login mode only) ─────────────
                    if (!_isRegister) ...[
                      const SizedBox(height: 16),
                      _buildForgotPassword()
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 400.ms),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Dismiss keyboard on scroll (covered by GestureDetector above)
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
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
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: Text(
            _isRegister ? 'crea tu universo' : 'bienvenido de vuelta',
            key: ValueKey(_isRegister),
            style: AetheraTokens.bodyMedium(color: AetheraTokens.moonGlow)
                .copyWith(letterSpacing: 2.5),
          ),
        ),
      ],
    );
  }

  // ── Form panel ──────────────────────────────────────────────────────────

  Widget _buildForm(AsyncValue<void> authState) {
    return AetheraGlassPanel(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display name — register only
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              child: _isRegister
                  ? Column(
                      children: [
                        _buildField(
                          controller: _nameCtrl,
                          label: 'Tu nombre',
                          icon: Icons.person_outline_rounded,
                          validator: (v) =>
                              (v?.trim().isEmpty ?? true) ? 'Ingresa tu nombre' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Email
            _buildField(
              controller: _emailCtrl,
              label: 'Email',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v?.trim().isEmpty ?? true) return 'Ingresa tu email';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v!.trim())) {
                  return 'Email inválido';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Password
            _buildField(
              controller: _passwordCtrl,
              label: 'Contraseña',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AetheraTokens.moonGlow,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) =>
                  (v?.length ?? 0) < 6 ? 'Mínimo 6 caracteres' : null,
            ),

            // Error message
            if (authState is AsyncError) ...[
              const SizedBox(height: 16),
              _buildError(_parseFirebaseError(authState.error))
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: -0.1, end: 0),
            ],

            const SizedBox(height: 28),

            // Submit button
            AetheraButton(
              label: _isRegister ? 'Crear universo' : 'Entrar',
              isLoading: authState is AsyncLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  // ── Text field ──────────────────────────────────────────────────────────

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
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: _inputBorder(AetheraTokens.moonGlow.withValues(alpha: 0.2)),
        enabledBorder:
            _inputBorder(AetheraTokens.moonGlow.withValues(alpha: 0.2)),
        focusedBorder:
            _inputBorder(AetheraTokens.auroraTeal.withValues(alpha: 0.6),
                width: 1.5),
        errorBorder:
            _inputBorder(AetheraTokens.roseQuartz.withValues(alpha: 0.5)),
        focusedErrorBorder:
            _inputBorder(AetheraTokens.roseQuartz.withValues(alpha: 0.8),
                width: 1.5),
        errorStyle:
            AetheraTokens.bodyMedium(color: AetheraTokens.roseQuartz),
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1.0}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  // ── Error banner ────────────────────────────────────────────────────────

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AetheraTokens.roseQuartz.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AetheraTokens.roseQuartz.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AetheraTokens.roseQuartz, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style:
                    AetheraTokens.bodyMedium(color: AetheraTokens.roseQuartz)),
          ),
        ],
      ),
    );
  }

  // ── Forgot password ─────────────────────────────────────────────────────

  Future<void> _sendPasswordReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ingresa tu email primero', style: AetheraTokens.bodyMedium()),
        backgroundColor: AetheraTokens.roseQuartz.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enviamos un enlace a $email', style: AetheraTokens.bodyMedium()),
        backgroundColor: AetheraTokens.auroraTeal.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No pudimos enviar el enlace', style: AetheraTokens.bodyMedium()),
        backgroundColor: AetheraTokens.roseQuartz.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Widget _buildForgotPassword() {
    return GestureDetector(
      onTap: _sendPasswordReset,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'Olvidé mi contraseña',
          textAlign: TextAlign.center,
          style: AetheraTokens.bodySmall(color: AetheraTokens.dusk).copyWith(
            decoration: TextDecoration.underline,
            decorationColor: AetheraTokens.dusk,
          ),
        ),
      ),
    );
  }

  // ── Toggle login ↔ register ─────────────────────────────────────────────

  Widget _buildToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isRegister ? '¿Ya tienes universo?  ' : '¿Primera vez?  ',
          style: AetheraTokens.bodyMedium(color: AetheraTokens.moonGlow),
        ),
        GestureDetector(
          onTap: _toggleMode,
          child: Text(
            _isRegister ? 'Inicia sesión' : 'Crea tu cuenta',
            style: AetheraTokens.bodyMedium(
                    color: AetheraTokens.auroraTeal)
                .copyWith(
              decoration: TextDecoration.underline,
              decorationColor: AetheraTokens.auroraTeal,
            ),
          ),
        ),
      ],
    );
  }

  // ── Firebase error parser ───────────────────────────────────────────────

  String _parseFirebaseError(Object? error) {
    final msg = error?.toString() ?? '';
    if (msg.contains('user-not-found') ||
        msg.contains('wrong-password') ||
        msg.contains('invalid-credential') ||
        msg.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'Email o contraseña incorrectos';
    }
    if (msg.contains('email-already-in-use')) {
      return 'Este email ya tiene una cuenta';
    }
    if (msg.contains('weak-password')) {
      return 'La contraseña es muy débil';
    }
    if (msg.contains('network-request-failed')) {
      return 'Sin conexión. Verifica tu internet';
    }
    if (msg.contains('too-many-requests')) {
      return 'Demasiados intentos. Espera un momento';
    }
    return 'Algo salió mal. Inténtalo de nuevo';
  }
}
