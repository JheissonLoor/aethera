import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/core/router/app_router.dart';
import 'package:aethera/shared/widgets/aethera_glass_panel.dart';
import 'package:aethera/shared/widgets/aethera_button.dart';
import 'package:aethera/shared/widgets/emotion_orb.dart';
import 'package:aethera/features/universe/providers/universe_provider.dart';
import 'package:aethera/features/universe/widgets/cosmic_background.dart';
import 'package:aethera/features/universe/widgets/emotional_sky.dart';
import 'package:aethera/features/universe/widgets/aurora_effect.dart';
import 'package:aethera/features/universe/widgets/memory_object.dart';
import 'package:aethera/features/universe/widgets/goal_horizon.dart';
import 'package:aethera/features/universe/widgets/heartbeat_overlay.dart';
import 'package:aethera/features/universe/widgets/nebula_layer.dart';
import 'package:aethera/features/universe/widgets/shooting_star_overlay.dart';
import 'package:aethera/core/constants/app_constants.dart';
import 'package:aethera/shared/models/goal_model.dart';
import 'package:aethera/shared/models/time_capsule_model.dart';
import 'package:aethera/core/services/music_service.dart';

String _formatDateTimeLabel(BuildContext context, DateTime dateTime) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatCompactDate(dateTime);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(dateTime),
    alwaysUse24HourFormat: true,
  );
  return '$date $time';
}

class UniverseScreen extends ConsumerStatefulWidget {
  const UniverseScreen({super.key});

  @override
  ConsumerState<UniverseScreen> createState() => _UniverseScreenState();
}

class _UniverseScreenState extends ConsumerState<UniverseScreen> {
  String? _lastMood;
  String? _lastCutsceneMemoryId;
  Timer? _cosmicCutsceneTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MusicService.instance.play();
    });
  }

  @override
  void dispose() {
    _cosmicCutsceneTimer?.cancel();
    MusicService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(universeProvider);

    if (state.cosmicEventMemoryId != null &&
        _lastCutsceneMemoryId != state.cosmicEventMemoryId) {
      _lastCutsceneMemoryId = state.cosmicEventMemoryId;
      _cosmicCutsceneTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cosmicCutsceneTimer = Timer(const Duration(milliseconds: 4600), () {
          if (mounted) {
            ref.read(universeProvider.notifier).dismissCosmicEventCutscene();
          }
        });
      });
    }

    // Update music volume when emotion changes
    final currentMood = state.combinedMood;
    if (currentMood != _lastMood) {
      _lastMood = currentMood;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        MusicService.instance.onEmotionChanged(currentMood);
      });
    }

    return Scaffold(
      backgroundColor: AetheraTokens.deepSpace,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // â”€â”€ Layer 1: Emotional sky gradient â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          EmotionalSky(combinedMood: state.combinedMood),

          // â”€â”€ Layer 1.5: Nebula clouds (appear at level 2+) â”€â”€â”€â”€â”€â”€â”€â”€
          NebulaLayer(universeLevel: state.universeLevel),

          // â”€â”€ Layer 2: Star field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const CosmicBackground(),

          // â”€â”€ Layer 2.5: Shooting stars â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const ShootingStarOverlay(),

          // â”€â”€ Layer 3: Aurora (when partner online / high connection)
          AuroraEffect(opacity: state.showAurora ? 1.0 : 0.0),

          // â”€â”€ Layer 4: Horizon + goals â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Positioned(
            left: 0,
            right: 0,
            bottom: 140,
            height: 120,
            child: _HorizonLayer(
              state: state,
              onGoalTap: (goal) => _showGoalDetail(context, ref, goal),
            ),
          ),

          // â”€â”€ Layer 5: Memory objects â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          ..._buildMemoryObjects(context, state),

          // â”€â”€ Layer 6: Heartbeat (partner online or received pulse) â”€â”€
          HeartbeatOverlay(
            isActive: state.partnerOnline || state.receivedPulse,
          ),

          if (state.dailyQuestion != null || state.capsules.isNotEmpty)
            Positioned(
              top: 108,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.dailyQuestion != null)
                    _DailyQuestionPanel(
                      state: state,
                      onAnswer: () => _showDailyQuestionAnswerSheet(state),
                    ),
                  if (state.dailyQuestion != null && state.capsules.isNotEmpty)
                    const SizedBox(height: 8),
                  if (state.capsules.isNotEmpty)
                    _TimeCapsuleStatusPanel(
                      capsules: state.capsules,
                      currentUserId: state.currentUserId,
                      onOpenCapsule: _openCapsule,
                    ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15, end: 0),
            ),

          // â”€â”€ Layer 7.5: New memory notification toast â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (state.newMemoryFromPartner)
            Positioned(
              top:
                  (state.dailyQuestion != null || state.capsules.isNotEmpty)
                      ? 266
                      : 160,
              left: 24,
              right: 24,
              child: _NewMemoryToast()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.4, end: 0),
            ),

          // â”€â”€ Emotion feedback overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (state.emotionFeedback != null)
            Positioned.fill(
              child: _EmotionRippleOverlay(
                mood: state.emotionFeedback!,
              ).animate().fadeIn(duration: 300.ms),
            ),

          // â”€â”€ Incoming wish overlay (shooting star from partner) â”€â”€â”€â”€â”€â”€â”€â”€
          if (state.incomingWish != null)
            Positioned.fill(
              child: _IncomingWishOverlay(
                wish: state.incomingWish!,
                onSeen:
                    () => ref.read(universeProvider.notifier).markWishSeen(),
              ).animate().fadeIn(duration: 400.ms),
            ),

          // Cosmic event cutscene overlay
          if (state.cosmicEventName != null)
            Positioned.fill(
              child: _CosmicEventCutsceneOverlay(
                eventName: state.cosmicEventName!,
                onSkip: () {
                  _cosmicCutsceneTimer?.cancel();
                  ref
                      .read(universeProvider.notifier)
                      .dismissCosmicEventCutscene();
                },
              ),
            ),

          // â”€â”€ Solo mode invite banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (state.couple?.isSolo == true)
            Positioned(
              left: 20,
              right: 20,
              bottom: 110,
              child: _SoloBanner(inviteCode: state.couple!.inviteCode)
                  .animate()
                  .fadeIn(delay: 1200.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),
            ),

          // â”€â”€ Layer 7: UI Overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _TopBar(
                  state: state,
                ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2),
                const Spacer(),
                // Bottom action bar
                _BottomBar(state: state, onOpenCapsule: _openCapsule)
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 200.ms)
                    .slideY(begin: 0.2),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMemoryObjects(
    BuildContext context,
    UniverseAppState state,
  ) {
    final size = MediaQuery.of(context).size;
    return state.memories.indexed.map((entry) {
      final (index, memory) = entry;
      return Positioned(
        left: memory.posX * size.width - 26,
        top: memory.posY * size.height,
        child: MemoryObjectWidget(
          memory: memory,
          animationIndex: index,
          onTap:
              () =>
                  _showMemoryDetail(context, memory.title, memory.description),
        ),
      );
    }).toList();
  }

  void _showMemoryDetail(
    BuildContext context,
    String title,
    String description,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _MemoryDetailSheet(title: title, description: description),
    );
  }

  void _showGoalDetail(BuildContext context, WidgetRef ref, GoalModel goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _GoalDetailSheet(
            goal: goal,
            onUpdateProgress: (progress) async {
              await ref
                  .read(universeProvider.notifier)
                  .updateGoalProgress(goal.id, progress);
            },
          ),
    );
  }

  void _showDailyQuestionAnswerSheet(UniverseAppState state) {
    final dailyQuestion = state.dailyQuestion;
    if (dailyQuestion == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _DailyQuestionAnswerSheet(
            question: dailyQuestion.question,
            initialAnswer: state.myDailyQuestionAnswer,
            onSubmit: (answer) async {
              Navigator.of(context).pop();
              await ref
                  .read(universeProvider.notifier)
                  .submitDailyQuestionAnswer(answer);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Respuesta guardada.')),
                );
              }
            },
          ),
    );
  }

  Future<void> _openCapsule(TimeCapsuleModel capsule) async {
    final opened = await ref
        .read(universeProvider.notifier)
        .openTimeCapsule(capsule.id);
    if (!mounted) return;
    if (opened == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta capsula aun no se puede abrir.')),
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _OpenedCapsuleSheet(capsule: opened),
    );
  }
}

// â”€â”€â”€ Top Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TopBar extends ConsumerWidget {
  final UniverseAppState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AetheraGlassPanel(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Title + streak badge + compact icon controls
            Row(
              children: [
                Text('Tu Universo', style: AetheraTokens.displaySmall()),
                if (state.streakDays >= 2) ...[
                  const SizedBox(width: 8),
                  _StreakBadge(days: state.streakDays),
                ],
                const Spacer(),
                _MusicToggleButton(),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.push(AetheraRoutes.profile),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: AetheraTokens.moonGlow,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Row 2: User orb â”€â”€ connection bar â”€â”€ partner orb + status dot
            Row(
              children: [
                EmotionOrb(
                  mood: state.couple?.user1Emotion?.mood ?? 'neutral',
                  size: 34,
                  animated: false,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ConnectionBar(
                    strength: state.connectionStrength,
                    level: state.universeLevel,
                  ),
                ),
                const SizedBox(width: 10),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    EmotionOrb(
                      mood: state.couple?.user2Emotion?.mood ?? 'neutral',
                      size: 34,
                      animated: false,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              state.receivedPulse
                                  ? AetheraTokens.roseQuartz
                                  : state.partnerOnline
                                  ? AetheraTokens.auroraTeal
                                  : AetheraTokens.dusk,
                          border: Border.all(
                            color: AetheraTokens.deepSpace,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBar extends StatelessWidget {
  final int strength;
  final int level;
  const _ConnectionBar({required this.strength, required this.level});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nivel $level',
              style: AetheraTokens.labelSmall(color: AetheraTokens.auroraTeal),
            ),
            Text(
              '$strength%',
              style: AetheraTokens.labelSmall(color: AetheraTokens.moonGlow),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (strength / 100.0).clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AetheraTokens.auroraTeal,
            ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€ Horizon Layer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HorizonLayer extends StatelessWidget {
  final UniverseAppState state;
  final void Function(GoalModel)? onGoalTap;
  const _HorizonLayer({required this.state, this.onGoalTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Horizon glow line
        Positioned(
          left: 0,
          right: 0,
          bottom: 60,
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AetheraTokens.auroraTeal.withValues(alpha: 0.3),
                  AetheraTokens.nebulaPurple.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Goal structures on horizon
        Positioned.fill(
          child: GoalHorizon(goals: state.goals, onGoalTap: onGoalTap),
        ),
      ],
    );
  }
}

// â”€â”€â”€ Bottom Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BottomBar extends ConsumerWidget {
  final UniverseAppState state;
  final Future<void> Function(TimeCapsuleModel capsule) onOpenCapsule;

  const _BottomBar({required this.state, required this.onOpenCapsule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AetheraGlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: '💭',
                label: 'Sentir',
                onTap: () => _showEmotionSheet(context, ref),
              ),
            ),
            Expanded(
              child: _ActionButton(
                icon: '✦',
                label: 'Memoria',
                onTap: () => _showAddMemorySheet(context, ref),
              ),
            ),
            // Center FAB - send a heartbeat pulse to partner
            _PulseFAB(
              onTap: () => ref.read(universeProvider.notifier).sendPulse(),
            ),
            Expanded(
              child: _ActionButton(
                icon: '✨',
                label: 'Deseo',
                onTap: () => _showWishSheet(context, ref),
              ),
            ),
            Expanded(
              child: _ActionButton(
                icon: '⏳',
                label: 'Capsula',
                onTap: () => _showCreateCapsuleSheet(context, ref),
              ),
            ),
            Expanded(
              child: _ActionButton(
                icon: '🌙',
                label: 'Ritual',
                onTap: () => context.push(AetheraRoutes.ritual),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmotionSheet(BuildContext context, WidgetRef ref) {
    final currentMood = ref.read(universeProvider).couple?.user1Emotion?.mood;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _EmotionCheckInSheet(
            currentMood: currentMood,
            onSelect: (mood) {
              Navigator.of(context).pop();
              ref.read(universeProvider.notifier).updateEmotion(mood);
            },
          ),
    );
  }

  void _showWishSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _WishSheet(
            onSend: (message) async {
              Navigator.of(context).pop();
              await ref.read(universeProvider.notifier).sendWish(message);
            },
          ),
    );
  }

  void _showAddMemorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _AddMemorySheet(
            onSave: (title, description, type) async {
              Navigator.of(context).pop();
              await ref
                  .read(universeProvider.notifier)
                  .addMemory(
                    title: title,
                    description: description,
                    type: type,
                  );
            },
          ),
    );
  }

  void _showCreateCapsuleSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _CreateCapsuleSheet(
            onCreate: (title, message, unlockAt) async {
              Navigator.of(context).pop();
              await ref
                  .read(universeProvider.notifier)
                  .createTimeCapsule(
                    title: title,
                    message: message,
                    unlockAt: unlockAt,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Capsula enviada al futuro.')),
                );
              }
            },
            onOpenLatest: () async {
              final currentState = ref.read(universeProvider);
              final available =
                  currentState.capsules
                      .where(
                        (capsule) =>
                            capsule.isUnlocked &&
                            !capsule.isOpenedBy(currentState.currentUserId),
                      )
                      .toList()
                    ..sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
              if (available.isNotEmpty) {
                Navigator.of(context).pop();
                await onOpenCapsule(available.first);
              }
            },
          ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(label, style: AetheraTokens.labelSmall()),
          ],
        ),
      ),
    );
  }
}

class _DailyQuestionPanel extends StatelessWidget {
  final UniverseAppState state;
  final VoidCallback onAnswer;

  const _DailyQuestionPanel({required this.state, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final dailyQuestion = state.dailyQuestion;
    if (dailyQuestion == null) return const SizedBox.shrink();

    final answered = state.hasAnsweredDailyQuestion;
    final revealed = state.isDailyQuestionRevealed;

    return AetheraGlassPanel(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💬', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Pregunta del dia',
                style: AetheraTokens.labelLarge(color: AetheraTokens.starlight),
              ),
              const Spacer(),
              Text(
                dailyQuestion.dayKey,
                style: AetheraTokens.labelSmall(color: AetheraTokens.moonGlow),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dailyQuestion.question,
            style: AetheraTokens.bodyMedium(color: AetheraTokens.starlight),
          ),
          const SizedBox(height: 10),
          if (!answered)
            AetheraButton(
              label: 'Responder ahora',
              width: double.infinity,
              onPressed: onAnswer,
            ),
          if (answered && !revealed) ...[
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: AetheraTokens.auroraTeal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Respuesta enviada. Esperando a tu pareja para revelar.',
                    style: AetheraTokens.bodySmall(
                      color: AetheraTokens.moonGlow,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AetheraButton(
              label: 'Editar respuesta',
              variant: AetheraButtonVariant.ghost,
              width: double.infinity,
              onPressed: onAnswer,
            ),
          ],
          if (revealed) ...[
            _AnswerTile(
              label: 'Tu respuesta',
              answer:
                  state.myDailyQuestionAnswer?.trim().isNotEmpty == true
                      ? state.myDailyQuestionAnswer!
                      : 'Sin respuesta',
            ),
            const SizedBox(height: 8),
            _AnswerTile(
              label: 'Respuesta de tu pareja',
              answer:
                  state.partnerDailyQuestionAnswer?.trim().isNotEmpty == true
                      ? state.partnerDailyQuestionAnswer!
                      : 'Aun no disponible',
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final String label;
  final String answer;

  const _AnswerTile({required this.label, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: AetheraTokens.moonGlow.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AetheraTokens.labelSmall(color: AetheraTokens.auroraTeal),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: AetheraTokens.bodyMedium(color: AetheraTokens.starlight),
          ),
        ],
      ),
    );
  }
}

class _DailyQuestionAnswerSheet extends StatefulWidget {
  final String question;
  final String? initialAnswer;
  final Future<void> Function(String answer) onSubmit;

  const _DailyQuestionAnswerSheet({
    required this.question,
    required this.onSubmit,
    this.initialAnswer,
  });

  @override
  State<_DailyQuestionAnswerSheet> createState() =>
      _DailyQuestionAnswerSheetState();
}

class _DailyQuestionAnswerSheetState extends State<_DailyQuestionAnswerSheet> {
  late final TextEditingController _answerCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _answerCtrl = TextEditingController(text: widget.initialAnswer ?? '');
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _answerCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() => _isSaving = true);
    await widget.onSubmit(value);
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AetheraGlassPanel(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pregunta del dia', style: AetheraTokens.displaySmall()),
            const SizedBox(height: 8),
            Text(
              widget.question,
              style: AetheraTokens.bodyMedium(color: AetheraTokens.moonGlow),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: AetheraTokens.moonGlow.withValues(alpha: 0.15),
                ),
              ),
              child: TextField(
                controller: _answerCtrl,
                maxLines: 4,
                maxLength: 220,
                style: AetheraTokens.bodyLarge(color: AetheraTokens.starlight),
                decoration: InputDecoration(
                  hintText: 'Escribe tu respuesta...',
                  hintStyle: AetheraTokens.bodyMedium(
                    color: AetheraTokens.moonGlow.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterStyle: AetheraTokens.bodySmall(
                    color: AetheraTokens.dusk,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AetheraButton(
              label: _isSaving ? 'Guardando...' : 'Enviar respuesta',
              isLoading: _isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeCapsuleStatusPanel extends StatelessWidget {
  final List<TimeCapsuleModel> capsules;
  final String? currentUserId;
  final Future<void> Function(TimeCapsuleModel capsule) onOpenCapsule;

  const _TimeCapsuleStatusPanel({
    required this.capsules,
    required this.currentUserId,
    required this.onOpenCapsule,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final pending =
        capsules.where((capsule) => capsule.unlockAt.isAfter(now)).toList()
          ..sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
    final available =
        capsules
            .where(
              (capsule) =>
                  capsule.isUnlocked && !capsule.isOpenedBy(currentUserId),
            )
            .toList()
          ..sort((a, b) => a.unlockAt.compareTo(b.unlockAt));

    final nextCapsule = available.isNotEmpty ? available.first : null;
    final nextUnlock = pending.isNotEmpty ? pending.first.unlockAt : null;

    return AetheraGlassPanel(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('⏳', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Capsulas del tiempo',
                style: AetheraTokens.labelLarge(color: AetheraTokens.starlight),
              ),
              const Spacer(),
              Text(
                '${available.length} listas',
                style: AetheraTokens.labelSmall(
                  color: AetheraTokens.auroraTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            nextUnlock == null
                ? 'No hay capsulas pendientes por abrir.'
                : 'Proxima apertura: ${_formatDateTimeLabel(context, nextUnlock)}',
            style: AetheraTokens.bodySmall(color: AetheraTokens.moonGlow),
          ),
          if (nextCapsule != null) ...[
            const SizedBox(height: 10),
            AetheraButton(
              label: 'Abrir capsula',
              variant: AetheraButtonVariant.outlined,
              onPressed: () => onOpenCapsule(nextCapsule),
              width: double.infinity,
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateCapsuleSheet extends StatefulWidget {
  final Future<void> Function(String title, String message, DateTime unlockAt)
  onCreate;
  final Future<void> Function() onOpenLatest;

  const _CreateCapsuleSheet({
    required this.onCreate,
    required this.onOpenLatest,
  });

  @override
  State<_CreateCapsuleSheet> createState() => _CreateCapsuleSheetState();
}

class _CreateCapsuleSheetState extends State<_CreateCapsuleSheet> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  DateTime _unlockAt = DateTime.now().add(const Duration(days: 3));
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickUnlockAt() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _unlockAt.isAfter(now) ? _unlockAt : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AetheraTokens.auroraTeal,
                onPrimary: AetheraTokens.deepSpace,
                surface: AetheraTokens.cosmicNight,
                onSurface: AetheraTokens.starlight,
              ),
            ),
            child: child!,
          ),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_unlockAt),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AetheraTokens.auroraTeal,
                onPrimary: AetheraTokens.deepSpace,
                surface: AetheraTokens.cosmicNight,
                onSurface: AetheraTokens.starlight,
              ),
            ),
            child: child!,
          ),
    );
    if (pickedTime == null || !mounted) return;

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() => _unlockAt = selectedDateTime);
  }

  Future<void> _create() async {
    final message = _messageCtrl.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Escribe un mensaje.')));
      return;
    }
    if (!_unlockAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha debe estar en el futuro.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onCreate(_titleCtrl.text.trim(), message, _unlockAt);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AetheraGlassPanel(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('⏳', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text('Nueva capsula', style: AetheraTokens.displaySmall()),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Escribe algo para que solo se abra en una fecha futura.',
              style: AetheraTokens.bodySmall(color: AetheraTokens.moonGlow),
            ),
            const SizedBox(height: 18),
            _glassField(
              controller: _titleCtrl,
              hint: 'Titulo opcional...',
              maxLines: 1,
              maxLength: 48,
            ),
            const SizedBox(height: 10),
            _glassField(
              controller: _messageCtrl,
              hint: 'Mensaje para el futuro...',
              maxLines: 4,
              maxLength: 280,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickUnlockAt,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: AetheraTokens.moonGlow.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: AetheraTokens.auroraTeal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatDateTimeLabel(context, _unlockAt),
                        style: AetheraTokens.bodyMedium(
                          color: AetheraTokens.starlight,
                        ),
                      ),
                    ),
                    Text(
                      'Cambiar',
                      style: AetheraTokens.labelSmall(
                        color: AetheraTokens.auroraTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AetheraButton(
              label: _isSaving ? 'Guardando...' : 'Guardar capsula',
              isLoading: _isSaving,
              onPressed: _create,
            ),
            const SizedBox(height: 8),
            AetheraButton(
              label: 'Abrir una capsula lista',
              variant: AetheraButtonVariant.ghost,
              onPressed: widget.onOpenLatest,
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required int maxLength,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: AetheraTokens.moonGlow.withValues(alpha: 0.15),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        style: AetheraTokens.bodyLarge(color: AetheraTokens.starlight),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AetheraTokens.bodyMedium(
            color: AetheraTokens.moonGlow.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterStyle: AetheraTokens.bodySmall(color: AetheraTokens.dusk),
        ),
      ),
    );
  }
}

class _OpenedCapsuleSheet extends StatelessWidget {
  final TimeCapsuleModel capsule;

  const _OpenedCapsuleSheet({required this.capsule});

  @override
  Widget build(BuildContext context) {
    return AetheraGlassPanel(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🕊️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  capsule.title.isEmpty ? 'Capsula del tiempo' : capsule.title,
                  style: AetheraTokens.displaySmall(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Programada para ${_formatDateTimeLabel(context, capsule.unlockAt)}',
            style: AetheraTokens.bodySmall(color: AetheraTokens.moonGlow),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: AetheraTokens.auroraTeal.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              capsule.message,
              style: AetheraTokens.bodyLarge(
                color: AetheraTokens.starlight,
              ).copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Emotion Check-In Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmotionCheckInSheet extends StatefulWidget {
  final ValueChanged<String> onSelect;
  final String? currentMood;

  const _EmotionCheckInSheet({required this.onSelect, this.currentMood});

  @override
  State<_EmotionCheckInSheet> createState() => _EmotionCheckInSheetState();
}

class _EmotionCheckInSheetState extends State<_EmotionCheckInSheet> {
  String? _hoveredMood;

  Color _moodColor(String mood) {
    switch (mood) {
      case 'joy':
        return AetheraTokens.emotionJoy;
      case 'love':
        return AetheraTokens.emotionLove;
      case 'peace':
        return AetheraTokens.emotionPeace;
      case 'longing':
        return AetheraTokens.emotionLonging;
      case 'melancholy':
        return AetheraTokens.emotionMelancholy;
      case 'anxious':
        return AetheraTokens.emotionAnxious;
      default:
        return AetheraTokens.moonGlow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AetheraGlassPanel(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Â¿CÃ³mo te sientes?', style: AetheraTokens.displaySmall()),
            const SizedBox(height: 6),
            Text(
              'Tu universo reflejarÃ¡ lo que hay en tu corazÃ³n.',
              style: AetheraTokens.bodyMedium(color: AetheraTokens.moonGlow),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 18,
              alignment: WrapAlignment.center,
              children:
                  AppConstants.emotions.map((mood) {
                    final isSelected = mood == (widget.currentMood ?? '');
                    final isHovered = mood == _hoveredMood;
                    final color = _moodColor(mood);
                    return GestureDetector(
                      onTapDown: (_) => setState(() => _hoveredMood = mood),
                      onTapUp: (_) => setState(() => _hoveredMood = null),
                      onTapCancel: () => setState(() => _hoveredMood = null),
                      onTap: () => widget.onSelect(mood),
                      child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: color.withValues(alpha: 0.8),
                                        width: 1.5,
                                      )
                                      : Border.all(color: Colors.transparent),
                              color:
                                  isSelected || isHovered
                                      ? color.withValues(alpha: 0.12)
                                      : Colors.transparent,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedScale(
                                  scale: isHovered ? 1.15 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: EmotionOrb(
                                    mood: mood,
                                    size: isSelected ? 62 : 54,
                                    animated: isSelected,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppConstants.emotionLabels[mood] ?? mood,
                                  style: AetheraTokens.labelSmall(
                                    color:
                                        isSelected
                                            ? color
                                            : AetheraTokens.moonGlow,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    width: 16,
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                          .animate(key: ValueKey(mood))
                          .fadeIn(
                            duration: 300.ms,
                            delay: Duration(
                              milliseconds:
                                  AppConstants.emotions.indexOf(mood) * 60,
                            ),
                          ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Add Memory Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AddMemorySheet extends StatefulWidget {
  final Future<void> Function(String title, String description, String type)
  onSave;

  const _AddMemorySheet({required this.onSave});

  @override
  State<_AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<_AddMemorySheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedType = 'constellation';
  bool _isSaving = false;

  static const _types = [
    ('constellation', 'â­', 'ConstelaciÃ³n'),
    ('tree', 'ðŸŒ³', 'Ãrbol'),
    ('lighthouse', 'ðŸ®', 'Faro'),
    ('bridge', 'ðŸŒ‰', 'Puente'),
    ('island', 'ðŸï¸', 'Isla'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    await widget.onSave(
      _titleCtrl.text.trim(),
      _descCtrl.text.trim(),
      _selectedType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AetheraGlassPanel(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'âœ¦',
                  style: TextStyle(
                    color: AetheraTokens.auroraTeal,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text('Nueva memoria', style: AetheraTokens.displaySmall()),
              ],
            ),

            const SizedBox(height: 20),

            // Type selector
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    _types.map((t) {
                      final (type, emoji, label) = t;
                      final isSelected = _selectedType == type;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AetheraTokens.auroraTeal
                                      : AetheraTokens.moonGlow.withValues(
                                        alpha: 0.2,
                                      ),
                              width: isSelected ? 1.5 : 1,
                            ),
                            color:
                                isSelected
                                    ? AetheraTokens.auroraTeal.withValues(
                                      alpha: 0.1,
                                    )
                                    : Colors.transparent,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: AetheraTokens.labelSmall(
                                  color:
                                      isSelected
                                          ? AetheraTokens.auroraTeal
                                          : AetheraTokens.moonGlow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            _glassField(
              controller: _titleCtrl,
              hint: 'TÃ­tulo del recuerdo...',
              maxLines: 1,
            ),

            const SizedBox(height: 12),

            // Description
            _glassField(
              controller: _descCtrl,
              hint: 'CuÃ©ntame sobre este momento...',
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            AetheraButton(
              label: 'Guardar memoria  âœ¦',
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: AetheraTokens.moonGlow.withValues(alpha: 0.15),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: AetheraTokens.bodyLarge(color: AetheraTokens.starlight),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AetheraTokens.bodyMedium(
            color: AetheraTokens.moonGlow.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

// â”€â”€â”€ Add Goal Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AddGoalSheet extends StatefulWidget {
  final Future<void> Function(
    String title,
    String description,
    String symbol,
    DateTime targetDate,
  )
  onSave;

  const _AddGoalSheet({required this.onSave});

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedSymbol = 'lighthouse';
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;

  static const _symbols = [
    ('lighthouse', 'ðŸ®', 'Faro'),
    ('castle', 'ðŸ°', 'Castillo'),
    ('mountain', 'â›°ï¸', 'MontaÃ±a'),
    ('island', 'ðŸï¸', 'Isla'),
    ('bridge', 'ðŸŒ‰', 'Puente'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AetheraTokens.auroraTeal,
                onPrimary: AetheraTokens.deepSpace,
                surface: AetheraTokens.cosmicNight,
                onSurface: AetheraTokens.starlight,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    await widget.onSave(
      _titleCtrl.text.trim(),
      _descCtrl.text.trim(),
      _selectedSymbol,
      _targetDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AetheraGlassPanel(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Text('ðŸŽ¯', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text('Nueva meta', style: AetheraTokens.displaySmall()),
              ],
            ),

            const SizedBox(height: 20),

            // Symbol selector
            SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    _symbols.map((s) {
                      final (symbol, emoji, label) = s;
                      final isSelected = _selectedSymbol == symbol;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSymbol = symbol),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AetheraTokens.goldenDawn
                                      : AetheraTokens.moonGlow.withValues(
                                        alpha: 0.2,
                                      ),
                              width: isSelected ? 1.5 : 1,
                            ),
                            color:
                                isSelected
                                    ? AetheraTokens.goldenDawn.withValues(
                                      alpha: 0.08,
                                    )
                                    : Colors.transparent,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: AetheraTokens.labelSmall(
                                  color:
                                      isSelected
                                          ? AetheraTokens.goldenDawn
                                          : AetheraTokens.moonGlow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            _glassField(
              controller: _titleCtrl,
              hint: 'TÃ­tulo de la meta...',
              maxLines: 1,
            ),

            const SizedBox(height: 12),

            // Description
            _glassField(
              controller: _descCtrl,
              hint: 'DescrÃ­bela con detalle...',
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Date picker row
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: AetheraTokens.moonGlow.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('ðŸ“…', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    Text(
                      'Fecha objetivo: ${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                      style: AetheraTokens.bodyMedium(
                        color: AetheraTokens.moonGlow,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AetheraTokens.dusk,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            AetheraButton(
              label: 'Crear meta  ðŸŽ¯',
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: AetheraTokens.moonGlow.withValues(alpha: 0.15),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: AetheraTokens.bodyLarge(color: AetheraTokens.starlight),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AetheraTokens.bodyMedium(
            color: AetheraTokens.moonGlow.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

// â”€â”€â”€ Goal Detail Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GoalDetailSheet extends StatefulWidget {
  final GoalModel goal;
  final Future<void> Function(double progress) onUpdateProgress;

  const _GoalDetailSheet({required this.goal, required this.onUpdateProgress});

  @override
  State<_GoalDetailSheet> createState() => _GoalDetailSheetState();
}

class _GoalDetailSheetState extends State<_GoalDetailSheet> {
  late double _progress;
  bool _isSaving = false;
  bool _justCompleted = false;

  @override
  void initState() {
    super.initState();
    _progress = widget.goal.progress;
  }

  int get _daysLeft {
    final diff = widget.goal.targetDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    if (_progress >= 1.0 && !widget.goal.isCompleted) {
      setState(() => _justCompleted = true);
    }
    await widget.onUpdateProgress(_progress);
    if (mounted) setState(() => _isSaving = false);
  }

  String _iconForSymbol(String symbol) {
    switch (symbol) {
      case 'lighthouse':
        return 'ðŸ®';
      case 'bridge':
        return 'ðŸŒ‰';
      case 'island':
        return 'ðŸï¸';
      case 'mountain':
        return 'â›°ï¸';
      case 'castle':
        return 'ðŸ°';
      default:
        return 'ðŸ›ï¸';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.goal.isCompleted || _justCompleted;
    final progressPercent = (_progress * 100).round();
    final accentColor =
        isCompleted ? AetheraTokens.goldenDawn : AetheraTokens.auroraTeal;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AetheraGlassPanel(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Symbol + title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _iconForSymbol(widget.goal.symbol),
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.goal.title,
                        style: AetheraTokens.displaySmall(),
                      ),
                      const SizedBox(height: 4),
                      if (widget.goal.description.isNotEmpty)
                        Text(
                          widget.goal.description,
                          style: AetheraTokens.bodyMedium(
                            color: AetheraTokens.moonGlow,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: 'ðŸ“…',
                  label:
                      isCompleted ? 'Completada' : '$_daysLeft dÃ­as restantes',
                  color:
                      isCompleted
                          ? AetheraTokens.goldenDawn
                          : AetheraTokens.moonGlow,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: 'âœ¦',
                  label: '$progressPercent% completado',
                  color: accentColor,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Progress label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progreso',
                  style: AetheraTokens.labelLarge(
                    color: AetheraTokens.moonGlow,
                  ),
                ),
                Text(
                  '$progressPercent%',
                  style: AetheraTokens.labelLarge(color: accentColor),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Progress bar track
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: AetheraTokens.moonGlow.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),

            const SizedBox(height: 4),

            // Slider
            if (!widget.goal.isCompleted)
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: accentColor,
                  inactiveTrackColor: AetheraTokens.moonGlow.withValues(
                    alpha: 0.1,
                  ),
                  thumbColor: accentColor,
                  overlayColor: accentColor.withValues(alpha: 0.15),
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: Slider(
                  value: _progress,
                  onChanged: (v) => setState(() => _progress = v),
                ),
              ),

            // Completed celebration banner
            if (isCompleted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AetheraTokens.goldenDawn.withValues(alpha: 0.12),
                      AetheraTokens.nebulaPurple.withValues(alpha: 0.12),
                    ],
                  ),
                  border: Border.all(
                    color: AetheraTokens.goldenDawn.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ðŸ†', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(
                      'Â¡Meta cumplida! +20 conexiÃ³n',
                      style: AetheraTokens.labelLarge(
                        color: AetheraTokens.goldenDawn,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (!widget.goal.isCompleted) ...[
              const SizedBox(height: 24),
              AetheraButton(
                label:
                    _progress >= 1.0
                        ? 'Â¡Completar meta! ðŸ†'
                        : 'Guardar progreso',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AetheraTokens.radiusFull),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(label, style: AetheraTokens.labelSmall(color: color)),
        ],
      ),
    );
  }
}

// â”€â”€â”€ New Memory Toast â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NewMemoryToast extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AetheraTokens.radiusFull),
          color: AetheraTokens.auroraTeal.withValues(alpha: 0.12),
          border: Border.all(
            color: AetheraTokens.auroraTeal.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'âœ¦',
              style: TextStyle(color: AetheraTokens.auroraTeal, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              'Nueva memoria aÃ±adida al universo',
              style: AetheraTokens.labelSmall(color: AetheraTokens.auroraTeal),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Music Toggle Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MusicToggleButton extends StatefulWidget {
  @override
  State<_MusicToggleButton> createState() => _MusicToggleButtonState();
}

class _MusicToggleButtonState extends State<_MusicToggleButton> {
  bool _isMuted = false;

  Future<void> _toggle() async {
    final newMuted = !_isMuted;
    setState(() => _isMuted = newMuted);
    await MusicService.instance.setMuted(newMuted);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              _isMuted
                  ? Colors.white.withValues(alpha: 0.03)
                  : AetheraTokens.auroraTeal.withValues(alpha: 0.08),
          border: Border.all(
            color:
                _isMuted
                    ? Colors.white.withValues(alpha: 0.08)
                    : AetheraTokens.auroraTeal.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          _isMuted ? Icons.music_off_rounded : Icons.music_note_rounded,
          color: _isMuted ? AetheraTokens.dusk : AetheraTokens.auroraTeal,
          size: 14,
        ),
      ),
    );
  }
}

// â”€â”€â”€ Pulse FAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Animated heart button that sends a heartbeat pulse to the partner.
// Shows a ripple + toast so the sender gets visual confirmation.

class _PulseFAB extends StatefulWidget {
  final VoidCallback onTap;
  const _PulseFAB({required this.onTap});

  @override
  State<_PulseFAB> createState() => _PulseFABState();
}

class _PulseFABState extends State<_PulseFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    widget.onTap();
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: SizedBox(
        width: 60,
        height: 54,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AetheraTokens.auroraGradient,
                boxShadow: AetheraTokens.auroraGlow(),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AetheraTokens.deepSpace,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Emotion Ripple Overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmotionRippleOverlay extends StatefulWidget {
  final String mood;
  const _EmotionRippleOverlay({required this.mood});

  @override
  State<_EmotionRippleOverlay> createState() => _EmotionRippleOverlayState();
}

class _EmotionRippleOverlayState extends State<_EmotionRippleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _expand;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _fade = Tween(
      begin: 0.18,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _emotionColor(String mood) {
    switch (mood) {
      case 'joy':
        return AetheraTokens.emotionJoy;
      case 'love':
        return AetheraTokens.emotionLove;
      case 'peace':
        return AetheraTokens.emotionPeace;
      case 'longing':
        return AetheraTokens.emotionLonging;
      case 'melancholy':
        return AetheraTokens.emotionMelancholy;
      case 'anxious':
        return AetheraTokens.emotionAnxious;
      default:
        return AetheraTokens.auroraTeal;
    }
  }

  String _emotionLabel(String mood) {
    switch (mood) {
      case 'joy':
        return 'AlegrÃ­a âœ¨';
      case 'love':
        return 'Amor ðŸ’•';
      case 'peace':
        return 'Paz ðŸŒ¿';
      case 'longing':
        return 'Anhelo ðŸŒ™';
      case 'melancholy':
        return 'MelancolÃ­a ðŸŒŒ';
      case 'anxious':
        return 'Angustia ðŸŒŠ';
      default:
        return 'Neutral âœ¦';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _emotionColor(widget.mood);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder:
            (_, __) => Stack(
              fit: StackFit.expand,
              children: [
                // Ripple circle
                Center(
                  child: Container(
                    width:
                        MediaQuery.of(context).size.width * 2.5 * _expand.value,
                    height:
                        MediaQuery.of(context).size.width * 2.5 * _expand.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: _fade.value),
                    ),
                  ),
                ),
                // Center toast
                if (_ctrl.value < 0.7)
                  Center(
                    child: Opacity(
                      opacity: (1.0 - _ctrl.value / 0.7).clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: color.withValues(alpha: 0.15),
                          border: Border.all(
                            color: color.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _emotionLabel(widget.mood),
                              style: AetheraTokens.displaySmall().copyWith(
                                color: color,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+${AppConstants.pointsDailyCheckin} conexiÃ³n',
                              style: AetheraTokens.bodySmall(
                                color: color.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      ),
    );
  }
}

// â”€â”€â”€ Memory Detail Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MemoryDetailSheet extends StatelessWidget {
  final String title;
  final String description;

  const _MemoryDetailSheet({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return AetheraGlassPanel(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('âœ¦', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AetheraTokens.displaySmall())),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: AetheraTokens.bodyLarge()),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Streak Badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StreakBadge extends StatelessWidget {
  final int days;
  const _StreakBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AetheraTokens.radiusFull),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B8A), Color(0xFFFFD700)],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('ðŸ”¥', style: TextStyle(fontSize: 9)),
          const SizedBox(width: 3),
          Text(
            '$days',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AetheraTokens.deepSpace,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Wish Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WishSheet extends StatefulWidget {
  final Future<void> Function(String message) onSend;
  const _WishSheet({required this.onSend});

  @override
  State<_WishSheet> createState() => _WishSheetState();
}

class _WishSheetState extends State<_WishSheet> {
  final _ctrl = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    await widget.onSend(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AetheraGlassPanel(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sparkle header
            ShaderMask(
              shaderCallback:
                  (b) => const LinearGradient(
                    colors: [
                      AetheraTokens.auroraTeal,
                      AetheraTokens.nebulaPurple,
                      AetheraTokens.roseQuartz,
                    ],
                  ).createShader(b),
              child: const Text(
                'âœ¨',
                style: TextStyle(fontSize: 36, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Lanza un deseo al universo',
              style: AetheraTokens.displaySmall(),
            ),
            const SizedBox(height: 6),
            Text(
              'Vuela como una estrella fugaz hasta tu persona.',
              style: AetheraTokens.bodyMedium(color: AetheraTokens.moonGlow),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Message field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: AetheraTokens.auroraTeal.withValues(alpha: 0.25),
                ),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: 3,
                maxLength: 120,
                style: AetheraTokens.bodyLarge(color: AetheraTokens.starlight),
                decoration: InputDecoration(
                  hintText: 'Te pienso, te extraÃ±o, te amo...',
                  hintStyle: AetheraTokens.bodyMedium(
                    color: AetheraTokens.moonGlow.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterStyle: AetheraTokens.bodySmall(
                    color: AetheraTokens.dusk,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AetheraButton(
              label: _isSending ? 'Lanzando...' : 'Lanzar deseo  âœ¨',
              isLoading: _isSending,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Incoming Wish Overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _IncomingWishOverlay extends StatefulWidget {
  final dynamic wish; // WishModel
  final VoidCallback onSeen;
  const _IncomingWishOverlay({required this.wish, required this.onSeen});

  @override
  State<_IncomingWishOverlay> createState() => _IncomingWishOverlayState();
}

class _IncomingWishOverlayState extends State<_IncomingWishOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _starCtrl;
  late final AnimationController _revealCtrl;
  late final Animation<double> _starProgress;
  late final Animation<double> _starFade;
  late final Animation<double> _revealScale;
  late final Animation<double> _revealFade;
  bool _showMessage = false;

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _starProgress = CurvedAnimation(parent: _starCtrl, curve: Curves.easeIn);
    _starFade = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_starCtrl);
    _revealScale = CurvedAnimation(
      parent: _revealCtrl,
      curve: Curves.easeOutBack,
    );
    _revealFade = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);

    _starCtrl.forward().then((_) {
      if (mounted) {
        setState(() => _showMessage = true);
        _revealCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark scrim
        GestureDetector(
          onTap: _showMessage ? widget.onSeen : null,
          child: Container(color: Colors.black.withValues(alpha: 0.55)),
        ),

        // Shooting star animation
        if (!_showMessage)
          AnimatedBuilder(
            animation: _starCtrl,
            builder: (_, __) {
              const angleRad = 0.52; // ~30 degrees
              final progress = _starProgress.value;
              final totalDx = size.width * 0.7;
              final totalDy = totalDx * 0.6;
              final startX = size.width * 0.05;
              final startY = size.height * 0.08;
              final headX = startX + totalDx * progress;
              final headY = startY + totalDy * progress;
              final tailLen = size.width * 0.28;
              final tailX = headX - tailLen * math.cos(angleRad);
              final tailY = headY - tailLen * math.sin(angleRad);

              return CustomPaint(
                painter: _WishStarPainter(
                  head: Offset(headX, headY),
                  tail: Offset(tailX, tailY),
                  alpha: _starFade.value,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),

        // Revealed message panel
        if (_showMessage)
          Center(
            child: ScaleTransition(
              scale: _revealScale,
              child: FadeTransition(
                opacity: _revealFade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AetheraGlassPanel(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback:
                              (b) => const LinearGradient(
                                colors: [
                                  AetheraTokens.auroraTeal,
                                  AetheraTokens.roseQuartz,
                                ],
                              ).createShader(b),
                          child: const Text(
                            'âœ¨',
                            style: TextStyle(fontSize: 40, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Un deseo llegÃ³ a tu universo',
                          style: AetheraTokens.bodySmall(
                            color: AetheraTokens.moonGlow,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AetheraTokens.auroraTeal.withValues(
                              alpha: 0.06,
                            ),
                            border: Border.all(
                              color: AetheraTokens.auroraTeal.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Text(
                            widget.wish.message as String,
                            style: AetheraTokens.bodyLarge(
                              color: AetheraTokens.starlight,
                            ).copyWith(
                              fontStyle: FontStyle.italic,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: widget.onSeen,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AetheraTokens.radiusFull,
                              ),
                              gradient: AetheraTokens.auroraGradient,
                            ),
                            child: Text(
                              'Recibido  ðŸ’•',
                              style: AetheraTokens.labelLarge(
                                color: AetheraTokens.deepSpace,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WishStarPainter extends CustomPainter {
  final Offset head;
  final Offset tail;
  final double alpha;

  const _WishStarPainter({
    required this.head,
    required this.tail,
    required this.alpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (alpha <= 0.01) return;
    final linePaint =
        Paint()
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..shader = LinearGradient(
            colors: [
              const Color(0x00E8F4FD),
              Color.fromRGBO(100, 255, 218, alpha),
            ],
          ).createShader(Rect.fromPoints(tail, head));
    canvas.drawLine(tail, head, linePaint);

    // Bright head
    canvas.drawCircle(
      head,
      3,
      Paint()..color = Color.fromRGBO(232, 244, 253, alpha),
    );
    // Teal glow
    canvas.drawCircle(
      head,
      10,
      Paint()..color = Color.fromRGBO(100, 255, 218, alpha * 0.4),
    );
    // Rose outer glow
    canvas.drawCircle(
      head,
      20,
      Paint()..color = Color.fromRGBO(255, 107, 138, alpha * 0.2),
    );
  }

  @override
  bool shouldRepaint(_WishStarPainter old) =>
      old.head != head || old.alpha != alpha;
}

// â”€â”€â”€ Solo Mode Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SoloBanner extends StatelessWidget {
  final String inviteCode;

  const _SoloBanner({required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AetheraRoutes.profile),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              AetheraTokens.nebulaPurple.withValues(alpha: 0.25),
              AetheraTokens.auroraTeal.withValues(alpha: 0.12),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(
            color: AetheraTokens.auroraTeal.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AetheraTokens.nebulaPurple.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('ðŸ’«', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invita a tu pareja',
                    style: AetheraTokens.labelLarge(
                      color: AetheraTokens.starlight,
                    ),
                  ),
                  Text(
                    'CÃ³digo: $inviteCode  â€¢  Toca para conectar',
                    style: AetheraTokens.bodySmall(
                      color: AetheraTokens.auroraTeal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AetheraTokens.moonGlow,
            ),
          ],
        ),
      ),
    );
  }
}

class _CosmicEventCutsceneOverlay extends StatefulWidget {
  final String eventName;
  final VoidCallback onSkip;

  const _CosmicEventCutsceneOverlay({
    required this.eventName,
    required this.onSkip,
  });

  @override
  State<_CosmicEventCutsceneOverlay> createState() =>
      _CosmicEventCutsceneOverlayState();
}

class _CosmicEventCutsceneOverlayState
    extends State<_CosmicEventCutsceneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4300),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final p = _ctrl.value;
        final fadeIn = Curves.easeOut.transform((p / 0.18).clamp(0.0, 1.0));
        final fadeOut =
            1.0 - Curves.easeIn.transform(((p - 0.82) / 0.18).clamp(0.0, 1.0));
        final opacity = (fadeIn * fadeOut).clamp(0.0, 1.0);
        final titleRise = 12 * (1 - Curves.easeOutCubic.transform(p));

        return Opacity(
          opacity: opacity,
          child: Material(
            color: Colors.black.withValues(alpha: 0.45),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _CosmicEventBurstPainter(progress: p)),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.1),
                        radius: 0.95 + p * 0.2,
                        colors: [
                          AetheraTokens.auroraTeal.withValues(alpha: 0.16),
                          AetheraTokens.nebulaPurple.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 44,
                  child: TextButton(
                    onPressed: widget.onSkip,
                    child: Text(
                      'Saltar',
                      style: AetheraTokens.bodySmall(
                        color: AetheraTokens.moonGlow,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Transform.translate(
                    offset: Offset(0, titleRise),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'EVENTO CÃ“SMICO DESBLOQUEADO',
                          style: AetheraTokens.labelLarge(
                            color: AetheraTokens.auroraTeal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ShaderMask(
                          shaderCallback:
                              (bounds) => LinearGradient(
                                colors: [
                                  AetheraTokens.goldenDawn,
                                  AetheraTokens.auroraTeal,
                                  AetheraTokens.nebulaPurple,
                                ],
                              ).createShader(bounds),
                          child: Text(
                            widget.eventName,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 46,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '+${AppConstants.pointsSyncRitual} conexiÃ³n â€¢ Reliquia forjada',
                          style: AetheraTokens.bodyMedium(
                            color: AetheraTokens.starlight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CosmicEventBurstPainter extends CustomPainter {
  final double progress;

  const _CosmicEventBurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final maxRadius = size.shortestSide * 0.75;
    final ringAlpha = (1.0 - progress).clamp(0.0, 1.0);

    for (int i = 0; i < 3; i++) {
      final t = ((progress - i * 0.12) / 0.72).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final radius = maxRadius * t;
      final stroke = (3.8 - i).clamp(1.4, 4.0);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = (i % 2 == 0
                  ? AetheraTokens.auroraTeal
                  : AetheraTokens.roseQuartz)
              .withValues(alpha: 0.22 * ringAlpha),
      );
    }

    final sparks = 90;
    final rng = math.Random(33);
    for (int i = 0; i < sparks; i++) {
      final baseA = (i / sparks) * math.pi * 2;
      final jitter = (rng.nextDouble() - 0.5) * 0.18;
      final angle = baseA + jitter;
      final speed = 0.22 + rng.nextDouble() * 0.78;
      final radius = maxRadius * speed * progress;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      final alpha = (1 - progress) * (0.35 + rng.nextDouble() * 0.45);
      final color = switch (i % 3) {
        0 => AetheraTokens.auroraTeal,
        1 => AetheraTokens.goldenDawn,
        _ => AetheraTokens.nebulaPurple,
      };
      canvas.drawCircle(
        Offset(x, y),
        1.2 + rng.nextDouble() * 2.2,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_CosmicEventBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
