import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/core/router/app_router.dart';
import 'package:aethera/core/constants/app_constants.dart';
import 'package:aethera/features/universe/providers/universe_provider.dart';
import 'package:aethera/features/universe/widgets/cosmic_background.dart';
import 'package:aethera/shared/widgets/aethera_glass_panel.dart';
import 'package:aethera/shared/widgets/aethera_button.dart';
import 'package:aethera/shared/widgets/emotion_orb.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringCtrl;
  bool _codeCopied = false;
  final _joinCodeCtrl = TextEditingController();
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _joinCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(universeProvider);
    final couple = state.couple;
    final myUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isUser1 = couple?.user1Id == myUserId;

    final myMood = isUser1
        ? couple?.user1Emotion?.mood ?? 'neutral'
        : couple?.user2Emotion?.mood ?? 'neutral';
    final partnerMood = isUser1
        ? couple?.user2Emotion?.mood ?? 'neutral'
        : couple?.user1Emotion?.mood ?? 'neutral';

    final daysTogether = couple != null
        ? DateTime.now().difference(couple.createdAt).inDays
        : 0;

    final memoryCount = state.memories.length;
    final goalsCompleted = state.goals.where((g) => g.isCompleted).length;
    final goalsTotal = state.goals.length;

    return Scaffold(
      backgroundColor: AetheraTokens.deepSpace,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CosmicBackground(),

          // Subtle gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AetheraTokens.nebulaPurple.withValues(alpha: 0.08),
                  Colors.transparent,
                  AetheraTokens.deepSpace.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Top bar ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Icon(Icons.arrow_back_rounded,
                                color: AetheraTokens.moonGlow, size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text('Tu universo', style: AetheraTokens.displaySmall()),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 16),

                  // ── Connection ring ───────────────────────────────────
                  Center(
                    child: AnimatedBuilder(
                      animation: _ringCtrl,
                      builder: (_, __) {
                        final progress = Curves.easeOutCubic
                            .transform(_ringCtrl.value);
                        return _ConnectionRing(
                          strength: state.connectionStrength,
                          level: state.universeLevel,
                          animatedProgress: progress,
                          myMood: myMood,
                          partnerMood: partnerMood,
                          partnerOnline: state.partnerOnline,
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 150.ms).scale(
                      begin: const Offset(0.85, 0.85),
                      curve: Curves.easeOutBack),

                  const SizedBox(height: 28),

                  // ── Days together ─────────────────────────────────────
                  AetheraGlassPanel(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🌙', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Text(
                          '$daysTogether días creando su universo',
                          style: AetheraTokens.bodyMedium(
                              color: AetheraTokens.starlight),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 16),

                  // ── Stats grid ────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          emoji: '✦',
                          value: '$memoryCount',
                          label: 'Memorias',
                          color: AetheraTokens.auroraTeal,
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          emoji: '🎯',
                          value: '$goalsCompleted/$goalsTotal',
                          label: 'Metas',
                          color: AetheraTokens.goldenDawn,
                        ).animate().fadeIn(delay: 480.ms).slideY(begin: 0.1, end: 0),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          emoji: '⭐',
                          value: '${state.universeLevel}',
                          label: 'Nivel',
                          color: AetheraTokens.nebulaPurple,
                        ).animate().fadeIn(delay: 560.ms).slideY(begin: 0.1, end: 0),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Universe level progress ───────────────────────────
                  _LevelProgressCard(
                    connectionStrength: state.connectionStrength,
                    level: state.universeLevel,
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 16),

                  // ── Invite code ───────────────────────────────────────
                  if (couple?.inviteCode != null) ...[
                    _InviteCodeCard(
                      code: couple!.inviteCode,
                      copied: _codeCopied,
                      onCopy: () async {
                        await Clipboard.setData(
                            ClipboardData(text: couple.inviteCode));
                        setState(() => _codeCopied = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _codeCopied = false);
                        });
                      },
                    ).animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: 16),
                  ],

                  // ── Connect with partner (solo mode) ──────────────────
                  if (couple?.isSolo == true) ...[
                    _ConnectPartnerCard(
                      codeCtrl: _joinCodeCtrl,
                      isLoading: _isJoining,
                      onJoin: () async {
                        final code = _joinCodeCtrl.text.trim();
                        if (code.isEmpty) return;
                        setState(() => _isJoining = true);
                        final messenger = ScaffoldMessenger.of(context);
                        final error = await ref
                            .read(universeProvider.notifier)
                            .joinPartner(code);
                        if (!mounted) return;
                        setState(() => _isJoining = false);
                        if (error != null) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: AetheraTokens.roseQuartz,
                            ),
                          );
                        } else {
                          _joinCodeCtrl.clear();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  '¡Conectados! Vuestro universo compartido está listo 💕'),
                            ),
                          );
                        }
                      },
                    ).animate().fadeIn(delay: 750.ms),
                    const SizedBox(height: 16),
                  ],

                  // ── Sign out ──────────────────────────────────────────
                  AetheraButton(
                    label: 'Cerrar sesión',
                    variant: AetheraButtonVariant.outlined,
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) context.go(AetheraRoutes.auth);
                    },
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Connection Ring ──────────────────────────────────────────────────────────

class _ConnectionRing extends StatelessWidget {
  final int strength;
  final int level;
  final double animatedProgress;
  final String myMood;
  final String partnerMood;
  final bool partnerOnline;

  const _ConnectionRing({
    required this.strength,
    required this.level,
    required this.animatedProgress,
    required this.myMood,
    required this.partnerMood,
    required this.partnerOnline,
  });

  static Color _emotionColor(String mood) {
    switch (mood) {
      case 'joy': return AetheraTokens.goldenDawn;
      case 'love': return AetheraTokens.roseQuartz;
      case 'peace': return AetheraTokens.auroraTeal;
      case 'longing': return AetheraTokens.nebulaPurple;
      case 'melancholy': return AetheraTokens.dusk;
      case 'anxious': return AetheraTokens.emotionAnxious;
      default: return AetheraTokens.moonGlow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayProgress = (strength / AppConstants.maxConnectionStrength)
        .clamp(0.0, 1.0) * animatedProgress;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring
          CustomPaint(
            size: const Size(220, 220),
            painter: _RingPainter(
              progress: displayProgress,
              myColor: _emotionColor(myMood),
              partnerColor: _emotionColor(partnerMood),
            ),
          ),

          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emotion orbs
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EmotionOrb(mood: myMood, size: 40, animated: false),
                  const SizedBox(width: 8),
                  Text('✦',
                      style: TextStyle(
                          color: AetheraTokens.moonGlow.withValues(alpha: 0.4),
                          fontSize: 12)),
                  const SizedBox(width: 8),
                  EmotionOrb(mood: partnerMood, size: 40, animated: false),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$strength%',
                style: AetheraTokens.displayMedium().copyWith(fontSize: 32),
              ),
              Text(
                'Conexión',
                style: AetheraTokens.bodySmall(color: AetheraTokens.moonGlow),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AetheraTokens.nebulaPurple.withValues(alpha: 0.2),
                  border: Border.all(
                      color: AetheraTokens.nebulaPurple.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Nivel $level',
                  style: AetheraTokens.labelSmall(
                      color: AetheraTokens.nebulaPurple),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color myColor;
  final Color partnerColor;

  const _RingPainter({
    required this.progress,
    required this.myColor,
    required this.partnerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const strokeWidth = 12.0;
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = AetheraTokens.moonGlow.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc with gradient
    if (progress > 0) {
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: -pi / 2 + 2 * pi * progress,
          colors: [myColor, partnerColor],
          stops: const [0.0, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        paint,
      );

      // Glow on the progress tip
      final tipAngle = -pi / 2 + 2 * pi * progress;
      final tipX = cx + radius * cos(tipAngle);
      final tipY = cy + radius * sin(tipAngle);
      canvas.drawCircle(
        Offset(tipX, tipY),
        6,
        Paint()
          ..color = partnerColor.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.myColor != myColor ||
      old.partnerColor != partnerColor;
}

// ─── Level Progress Card ──────────────────────────────────────────────────────

class _LevelProgressCard extends StatelessWidget {
  final int connectionStrength;
  final int level;

  const _LevelProgressCard(
      {required this.connectionStrength, required this.level});

  static const _levelNames = {
    1: 'Nebulosa Naciente',
    2: 'Estrella Emergente',
    3: 'Aurora Compartida',
    4: 'Cosmos Entrelazado',
    5: 'Universo Eterno',
  };

  static const _levelEmojis = {
    1: '🌌',
    2: '⭐',
    3: '🌠',
    4: '✨',
    5: '🌟',
  };

  @override
  Widget build(BuildContext context) {
    final currentThreshold = (level - 1) * 20;
    final nextThreshold = level * 20;
    final progressInLevel =
        ((connectionStrength - currentThreshold) / (nextThreshold - currentThreshold))
            .clamp(0.0, 1.0);

    return AetheraGlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_levelEmojis[level] ?? '✨',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_levelNames[level] ?? 'Nivel $level',
                        style: AetheraTokens.bodyLarge()),
                    if (level < 5)
                      Text(
                        'Próximo nivel a $nextThreshold% conexión',
                        style: AetheraTokens.bodySmall(
                            color: AetheraTokens.moonGlow),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (level < 5) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressInLevel,
                minHeight: 4,
                backgroundColor:
                    AetheraTokens.moonGlow.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AetheraTokens.auroraTeal),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '¡Has alcanzado el nivel máximo! 🌟',
              style: AetheraTokens.bodySmall(
                  color: AetheraTokens.goldenDawn),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AetheraGlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(value,
              style: AetheraTokens.displaySmall().copyWith(
                color: color,
                fontSize: 22,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: AetheraTokens.labelSmall(color: AetheraTokens.moonGlow)),
        ],
      ),
    );
  }
}

// ─── Connect Partner Card ─────────────────────────────────────────────────────

class _ConnectPartnerCard extends StatelessWidget {
  final TextEditingController codeCtrl;
  final bool isLoading;
  final VoidCallback onJoin;

  const _ConnectPartnerCard({
    required this.codeCtrl,
    required this.isLoading,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return AetheraGlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AetheraTokens.auroraTeal.withValues(alpha: 0.3),
                    AetheraTokens.nebulaPurple.withValues(alpha: 0.1),
                  ]),
                ),
                child: const Text('💫', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Conectar con tu pareja',
                        style: AetheraTokens.bodyLarge()),
                    Text(
                      'Tu pareja creó un universo? Ingresa su código',
                      style:
                          AetheraTokens.bodySmall(color: AetheraTokens.moonGlow),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: AetheraTokens.bodyLarge().copyWith(
                    letterSpacing: 4,
                    color: AetheraTokens.starlight,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'CÓDIGO',
                    hintStyle: AetheraTokens.bodyLarge().copyWith(
                      letterSpacing: 4,
                      color: AetheraTokens.moonGlow.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AetheraTokens.moonGlow.withValues(alpha: 0.15)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AetheraTokens.moonGlow.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AetheraTokens.auroraTeal.withValues(alpha: 0.5)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: isLoading ? null : onJoin,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: isLoading
                        ? null
                        : LinearGradient(
                            colors: [
                              AetheraTokens.auroraTeal,
                              AetheraTokens.nebulaPurple,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isLoading
                        ? AetheraTokens.moonGlow.withValues(alpha: 0.2)
                        : null,
                  ),
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Invite Code Card ─────────────────────────────────────────────────────────

class _InviteCodeCard extends StatelessWidget {
  final String code;
  final bool copied;
  final VoidCallback onCopy;

  const _InviteCodeCard({
    required this.code,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return AetheraGlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Código de invitación',
              style: AetheraTokens.labelLarge(color: AetheraTokens.moonGlow)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                        color: AetheraTokens.moonGlow.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    code,
                    style: AetheraTokens.displaySmall().copyWith(
                      letterSpacing: 6,
                      color: AetheraTokens.auroraTeal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onCopy,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: copied
                        ? AetheraTokens.auroraTeal.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: copied
                          ? AetheraTokens.auroraTeal.withValues(alpha: 0.4)
                          : AetheraTokens.moonGlow.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Icon(
                    copied ? Icons.check_rounded : Icons.copy_rounded,
                    color: copied
                        ? AetheraTokens.auroraTeal
                        : AetheraTokens.moonGlow,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Comparte este código para que tu pareja se una',
            style: AetheraTokens.bodySmall(color: AetheraTokens.dusk),
          ),
        ],
      ),
    );
  }
}
