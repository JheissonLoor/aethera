import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/core/theme/aethera_motion.dart';
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
import 'package:aethera/core/services/haptics_service.dart';
import 'package:aethera/core/services/music_service.dart';
import 'package:aethera/l10n/l10n_ext.dart';

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

class _UniverseScreenState extends ConsumerState<UniverseScreen>
    with SingleTickerProviderStateMixin {
  String? _lastMood;
  String? _lastCutsceneMemoryId;
  Timer? _cosmicCutsceneTimer;
  late final AnimationController _cameraDriftController;

  @override
  void initState() {
    super.initState();
    _cameraDriftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MusicService.instance.play();
    });
  }

  @override
  void dispose() {
    _cosmicCutsceneTimer?.cancel();
    _cameraDriftController.dispose();
    MusicService.instance.stop();
    super.dispose();
  }

  Widget _parallaxLayer({required Widget child, required double depth}) {
    return AnimatedBuilder(
      animation: _cameraDriftController,
      child: child,
      builder: (context, cachedChild) {
        final phase = _cameraDriftController.value * 2 * math.pi;
        final dx = math.sin(phase) * depth;
        final dy = math.cos(phase * 0.82) * depth * 0.72;
        return Transform.translate(offset: Offset(dx, dy), child: cachedChild);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(universeProvider);
    final media = MediaQuery.of(context);
    final compact = media.size.width < 370 || media.size.height < 740;
    final hasTopPanels =
        state.dailyQuestion != null || state.capsules.isNotEmpty;
    final showEmpty = _showUniverseEmptyState(state);
    final showSoloBanner = state.couple?.isSolo == true;

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
          _parallaxLayer(
            depth: 4,
            child: EmotionalSky(combinedMood: state.combinedMood),
          ),

          _parallaxLayer(
            depth: 6,
            child: NebulaLayer(universeLevel: state.universeLevel),
          ),

          _parallaxLayer(depth: 8, child: const CosmicBackground()),

          const ShootingStarOverlay(),

          _parallaxLayer(
            depth: 10,
            child: AuroraEffect(opacity: state.showAurora ? 1.0 : 0.0),
          ),

          _parallaxLayer(
            depth: 12,
            child: _AmbientGlowLayer(universeLevel: state.universeLevel),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: compact ? 128 : 140,
            height: 120,
            child: _HorizonLayer(
              state: state,
              onGoalTap: (goal) => _showGoalDetail(context, ref, goal),
            ),
          ),

          ..._buildMemoryObjects(context, state),
          Positioned(
            left: compact ? 16 : 24,
            right: compact ? 16 : 24,
            bottom: compact ? 194 : 210,
            child: AnimatedSwitcher(
              duration: AetheraMotion.screen,
              switchInCurve: AetheraMotion.enter,
              switchOutCurve: AetheraMotion.exit,
              child:
                  showEmpty
                      ? _UniverseEmptyStateCard(
                            key: const ValueKey('empty_visible'),
                            onCreateMemory: _showQuickAddMemorySheet,
                            onCheckIn: _showQuickEmotionSheet,
                          )
                          .animate()
                          .fadeIn(duration: 420.ms)
                          .slideY(begin: 0.12, end: 0)
                      : const SizedBox.shrink(key: ValueKey('empty_hidden')),
            ),
          ),

          HeartbeatOverlay(
            isActive: state.partnerOnline || state.receivedPulse,
          ),

          AnimatedPositioned(
            duration: AetheraMotion.screen,
            curve: AetheraMotion.standard,
            top: compact ? 96 : 108,
            left: compact ? 14 : 20,
            right: compact ? 14 : 20,
            child: IgnorePointer(
              ignoring: !hasTopPanels,
              child: AnimatedOpacity(
                duration: AetheraMotion.screen,
                curve: AetheraMotion.standard,
                opacity: hasTopPanels ? 1 : 0,
                child: AnimatedSwitcher(
                  duration: AetheraMotion.sheet,
                  switchInCurve: AetheraMotion.enter,
                  switchOutCurve: AetheraMotion.exit,
                  child:
                      hasTopPanels
                          ? Column(
                            key: ValueKey(
                              'panels_${state.dailyQuestion?.id}_${state.capsules.length}',
                            ),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (state.dailyQuestion != null)
                                _DailyQuestionPanel(
                                      state: state,
                                      compact: compact,
                                      onAnswer:
                                          () => _showDailyQuestionAnswerSheet(
                                            state,
                                          ),
                                    )
                                    .animate(
                                      key: ValueKey(
                                        'dq_${state.dailyQuestion?.id}_${state.hasAnsweredDailyQuestion}_${state.isDailyQuestionRevealed}',
                                      ),
                                    )
                                    .fadeIn(duration: 360.ms)
                                    .slideY(begin: -0.08, end: 0),
                              if (state.dailyQuestion != null &&
                                  state.capsules.isNotEmpty)
                                const SizedBox(height: 8),
                              if (state.capsules.isNotEmpty)
                                _TimeCapsuleStatusPanel(
                                      capsules: state.capsules,
                                      compact: compact,
                                      currentUserId: state.currentUserId,
                                      onOpenCapsule: _openCapsule,
                                    )
                                    .animate(
                                      key: ValueKey(
                                        'tc_${state.capsules.length}_${state.currentUserId}',
                                      ),
                                    )
                                    .fadeIn(delay: 70.ms, duration: 360.ms)
                                    .slideY(begin: -0.08, end: 0),
                            ],
                          )
                          : const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          if (state.newMemoryFromPartner)
            Positioned(
              top: hasTopPanels ? (compact ? 248 : 266) : (compact ? 148 : 160),
              left: 24,
              right: 24,
              child: _NewMemoryToast()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.4, end: 0),
            ),

          if (state.emotionFeedback != null)
            Positioned.fill(
              child: _EmotionRippleOverlay(
                mood: state.emotionFeedback!,
              ).animate().fadeIn(duration: 300.ms),
            ),

          if (state.incomingWish != null)
            Positioned.fill(
              child: _IncomingWishOverlay(
                wish: state.incomingWish!,
                onSeen:
                    () => ref.read(universeProvider.notifier).markWishSeen(),
              ).animate().fadeIn(duration: 400.ms),
            ),

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

          Positioned(
            left: 20,
            right: 20,
            bottom: compact ? 102 : 110,
            child: AnimatedSwitcher(
              duration: AetheraMotion.screen,
              switchInCurve: AetheraMotion.enter,
              switchOutCurve: AetheraMotion.exit,
              child:
                  showSoloBanner
                      ? _SoloBanner(
                            key: const ValueKey('solo_banner_on'),
                            inviteCode: state.couple!.inviteCode,
                          )
                          .animate()
                          .fadeIn(delay: 1200.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0)
                      : const SizedBox.shrink(key: ValueKey('solo_banner_off')),
            ),
          ),

          const _CinematicVignetteLayer(),

          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  state: state,
                  compact: compact,
                ).animate().fadeIn(duration: 780.ms).slideY(begin: -0.16),
                const Spacer(),
                _BottomBar(
                      state: state,
                      compact: compact,
                      onOpenCapsule: _openCapsule,
                    )
                    .animate()
                    .fadeIn(duration: 720.ms, delay: 160.ms)
                    .slideY(begin: 0.16),
                SizedBox(height: compact ? 10 : 16),
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

  bool _showUniverseEmptyState(UniverseAppState state) {
    if (state.isLoading) return false;
    if (state.couple?.isSolo == true) return false;
    return state.memories.isEmpty &&
        state.goals.isEmpty &&
        state.capsules.isEmpty &&
        state.dailyQuestion == null;
  }

  void _showQuickAddMemorySheet() {
    HapticsService.secondaryAction();
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
              HapticsService.affirmation();
            },
          ),
    );
  }

  void _showQuickEmotionSheet() {
    HapticsService.secondaryAction();
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
              HapticsService.affirmation();
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
              HapticsService.affirmation();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr('Respuesta guardada.', 'Answer saved.'),
                    ),
                  ),
                );
              }
            },
          ),
    );
  }

  Future<void> _openCapsule(TimeCapsuleModel capsule) async {
    HapticsService.primaryAction();
    final opened = await ref
        .read(universeProvider.notifier)
        .openTimeCapsule(capsule.id);
    if (!mounted) return;
    if (opened == null) {
      HapticsService.secondaryAction();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Esta cápsula aún no se puede abrir.',
              'This capsule cannot be opened yet.',
            ),
          ),
        ),
      );
      return;
    }
    HapticsService.affirmation();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _OpenedCapsuleSheet(capsule: opened),
    );
  }
}

class _AmbientGlowLayer extends StatefulWidget {
  final int universeLevel;

  const _AmbientGlowLayer({required this.universeLevel});

  @override
  State<_AmbientGlowLayer> createState() => _AmbientGlowLayerState();
}

class _AmbientGlowLayerState extends State<_AmbientGlowLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levelFactor = (widget.universeLevel / 12).clamp(0.22, 1.0);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;
          final dxA = math.cos(t * math.pi * 2) * 46;
          final dyA = math.sin(t * math.pi * 2) * 34;
          final dxB = math.cos((t + 0.35) * math.pi * 2) * 38;
          final dyB = math.sin((t + 0.35) * math.pi * 2) * 30;
          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(dxA, dyA),
                child: Align(
                  alignment: const Alignment(-0.82, -0.78),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AetheraTokens.auroraTeal.withValues(
                            alpha: 0.2 * levelFactor,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(dxB, dyB),
                child: Align(
                  alignment: const Alignment(0.9, 0.72),
                  child: Container(
                    width: 330,
                    height: 330,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AetheraTokens.nebulaPurple.withValues(
                            alpha: 0.22 * levelFactor,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CinematicVignetteLayer extends StatelessWidget {
  const _CinematicVignetteLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.1),
                radius: 1.06,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.24),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.24),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 112,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final UniverseAppState state;
  final bool compact;
  const _TopBar({required this.state, required this.compact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: 12,
      ),
      child: AetheraGlassPanel(
        borderRadius: compact ? 20 : 22,
        padding: EdgeInsets.fromLTRB(
          compact ? 13 : 16,
          12,
          compact ? 13 : 16,
          compact ? 10 : 12,
        ),
        backgroundColor: const Color(0x1A0C1428),
        borderColor: Colors.white.withValues(alpha: 0.18),
        shadows: [
          BoxShadow(
            color: AetheraTokens.nebulaPurple.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AetheraTokens.auroraTeal.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback:
                                (bounds) => const LinearGradient(
                                  colors: [
                                    AetheraTokens.starlight,
                                    AetheraTokens.auroraTeal,
                                  ],
                                ).createShader(bounds),
                            child: Text(
                              context.tr('Tu Universo', 'Your Universe'),
                              style: AetheraTokens.displaySmall().copyWith(
                                color: Colors.white,
                                fontSize: compact ? 22 : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr(
                              'Ritmo vivo entre ustedes',
                              'Live rhythm between you',
                            ),
                            style: AetheraTokens.bodySmall(
                              color: AetheraTokens.moonGlow.withValues(
                                alpha: 0.78,
                              ),
                            ).copyWith(fontSize: compact ? 11 : null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MusicToggleButton(),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      label: context.tr('Abrir perfil', 'Open profile'),
                      child: GestureDetector(
                        onTap: () {
                          HapticsService.navigation();
                          context.push(AetheraRoutes.profile);
                        },
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
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _TopPulseLine(
                  strength: state.connectionStrength,
                  partnerOnline: state.partnerOnline,
                ),
                if (state.streakDays >= 2 ||
                    !state.isSyncConnected ||
                    state.pendingSyncActions > 0) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (state.streakDays >= 2)
                          _StreakBadge(days: state.streakDays),
                        if (!state.isSyncConnected ||
                            state.pendingSyncActions > 0)
                          _SyncStatusBadge(state: state),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    EmotionOrb(
                      mood: state.couple?.user1Emotion?.mood ?? 'neutral',
                      size: compact ? 31 : 34,
                      animated: false,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ConnectionBar(
                        strength: state.connectionStrength,
                        level: state.universeLevel,
                        compact: compact,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        EmotionOrb(
                          mood: state.couple?.user2Emotion?.mood ?? 'neutral',
                          size: compact ? 31 : 34,
                          animated: false,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: AnimatedContainer(
                            duration: AetheraMotion.emphasized,
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
          ],
        ),
      ),
    );
  }
}

class _TopPulseLine extends StatelessWidget {
  final int strength;
  final bool partnerOnline;

  const _TopPulseLine({required this.strength, required this.partnerOnline});

  @override
  Widget build(BuildContext context) {
    final progress = (strength / 100).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 3,
        color: Colors.white.withValues(alpha: 0.08),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress,
            child: AnimatedContainer(
              duration: AetheraMotion.screen,
              curve: AetheraMotion.standard,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    partnerOnline
                        ? AetheraTokens.auroraTeal
                        : AetheraTokens.moonGlow,
                    AetheraTokens.nebulaPurple,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncStatusBadge extends StatelessWidget {
  final UniverseAppState state;

  const _SyncStatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final offline = !state.isSyncConnected;
    final queued = state.pendingSyncActions;
    final color = offline ? AetheraTokens.roseQuartz : AetheraTokens.auroraTeal;
    final icon = offline ? Icons.cloud_off_rounded : Icons.sync_rounded;
    final label =
        offline
            ? (queued > 0
                ? context.tr('Sin conexión ($queued)', 'Offline ($queued)')
                : context.tr('Sin conexión', 'Offline'))
            : context.tr('Sincronizando $queued', 'Syncing $queued');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: AetheraTokens.labelSmall(color: color)),
        ],
      ),
    );
  }
}

class _ConnectionBar extends StatelessWidget {
  final int strength;
  final int level;
  final bool compact;
  const _ConnectionBar({
    required this.strength,
    required this.level,
    required this.compact,
  });

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
              context.tr('Nivel $level', 'Level $level'),
              style: AetheraTokens.labelSmall(
                color: AetheraTokens.auroraTeal,
              ).copyWith(fontSize: compact ? 10 : null),
            ),
            AnimatedSwitcher(
              duration: AetheraMotion.short,
              switchInCurve: AetheraMotion.enter,
              switchOutCurve: AetheraMotion.exit,
              child: Text(
                '$strength%',
                key: ValueKey(strength),
                style: AetheraTokens.labelSmall(
                  color: AetheraTokens.moonGlow,
                ).copyWith(fontSize: compact ? 10 : null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            height: compact ? 3 : 4,
            color: Colors.white.withValues(alpha: 0.08),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: (strength / 100.0).clamp(0.0, 1.0),
              ),
              duration: AetheraMotion.screen,
              curve: AetheraMotion.standard,
              builder:
                  (_, value, __) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AetheraTokens.auroraTeal,
                              AetheraTokens.nebulaPurple,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AetheraTokens.auroraTeal.withValues(
                                alpha: 0.38,
                              ),
                              blurRadius: 10,
                            ),
                          ],
                        ),
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

class _HorizonLayer extends StatelessWidget {
  final UniverseAppState state;
  final void Function(GoalModel)? onGoalTap;
  const _HorizonLayer({required this.state, this.onGoalTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
        Positioned.fill(
          child: GoalHorizon(goals: state.goals, onGoalTap: onGoalTap),
        ),
      ],
    );
  }
}

class _BottomBar extends ConsumerWidget {
  final UniverseAppState state;
  final bool compact;
  final Future<void> Function(TimeCapsuleModel capsule) onOpenCapsule;

  const _BottomBar({
    required this.state,
    required this.compact,
    required this.onOpenCapsule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
      child: AetheraGlassPanel(
        borderRadius: compact ? 21 : 24,
        padding: EdgeInsets.fromLTRB(10, 8, 10, compact ? 10 : 12),
        backgroundColor: const Color(0x1D0B1124),
        borderColor: Colors.white.withValues(alpha: 0.2),
        shadows: [
          BoxShadow(
            color: AetheraTokens.auroraTeal.withValues(alpha: 0.14),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 2,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AetheraTokens.auroraTeal.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.mood_rounded,
                    compact: compact,
                    label: context.tr('Sentir', 'Feel'),
                    onTap: () => _showEmotionSheet(context, ref),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.auto_awesome_outlined,
                    compact: compact,
                    label: context.tr('Memoria', 'Memory'),
                    onTap: () => _showAddMemorySheet(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                _PulseFAB(
                  compact: compact,
                  onTap: () => ref.read(universeProvider.notifier).sendPulse(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.self_improvement_rounded,
                    compact: compact,
                    label: context.tr('Ritual', 'Ritual'),
                    onTap: () => context.push(AetheraRoutes.ritual),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.more_horiz_rounded,
                    compact: compact,
                    label: context.tr('Más', 'More'),
                    onTap: () => _showQuickActionsMenu(context, ref),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEmotionSheet(BuildContext context, WidgetRef ref) {
    HapticsService.secondaryAction();
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
              HapticsService.affirmation();
            },
          ),
    );
  }

  void _showWishSheet(BuildContext context, WidgetRef ref) {
    HapticsService.secondaryAction();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _WishSheet(
            onSend: (message) async {
              Navigator.of(context).pop();
              await ref.read(universeProvider.notifier).sendWish(message);
              HapticsService.affirmation();
            },
          ),
    );
  }

  void _showAddMemorySheet(BuildContext context, WidgetRef ref) {
    HapticsService.secondaryAction();
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
              HapticsService.affirmation();
            },
          ),
    );
  }

  void _showCreateCapsuleSheet(BuildContext context, WidgetRef ref) {
    HapticsService.secondaryAction();
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
              HapticsService.affirmation();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr(
                        'Cápsula enviada al futuro.',
                        'Capsule sent to the future.',
                      ),
                    ),
                  ),
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

  void _showQuickActionsMenu(BuildContext context, WidgetRef ref) {
    HapticsService.secondaryAction();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _QuickActionsSheet(
            onWish:
                () => _openSecondaryAction(
                  context,
                  () => _showWishSheet(context, ref),
                ),
            onCapsule:
                () => _openSecondaryAction(
                  context,
                  () => _showCreateCapsuleSheet(context, ref),
                ),
            onRitual:
                () => _openSecondaryAction(
                  context,
                  () => context.push(AetheraRoutes.ritual),
                ),
          ),
    );
  }

  void _openSecondaryAction(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    Future<void>.delayed(AetheraMotion.stagger, action);
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final bool compact;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.compact,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    setState(() => _pressed = true);
    HapticsService.secondaryAction();
  }

  void _onTapUp([TapUpDetails? _]) {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapUp,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1,
          duration: AetheraMotion.micro,
          curve: AetheraMotion.enter,
          child: AnimatedOpacity(
            duration: AetheraMotion.short,
            opacity: _pressed ? 0.9 : 1,
            child: AnimatedContainer(
              duration: AetheraMotion.medium,
              height: widget.compact ? 52 : 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: _pressed ? 0.14 : 0.1),
                    Colors.white.withValues(alpha: _pressed ? 0.04 : 0.02),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: _pressed ? 0.28 : 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AetheraTokens.auroraTeal.withValues(
                      alpha: _pressed ? 0.18 : 0.08,
                    ),
                    blurRadius: _pressed ? 12 : 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: widget.compact ? 22 : 24,
                    height: widget.compact ? 22 : 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AetheraTokens.auroraTeal.withValues(
                        alpha: _pressed ? 0.18 : 0.12,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      size: widget.compact ? 13 : 14,
                      color: AetheraTokens.starlight,
                    ),
                  ),
                  SizedBox(height: widget.compact ? 3 : 4),
                  Text(
                    widget.label,
                    style: AetheraTokens.labelSmall(
                      color: AetheraTokens.moonGlow,
                    ).copyWith(fontSize: widget.compact ? 10 : null),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  final VoidCallback onWish;
  final VoidCallback onCapsule;
  final VoidCallback onRitual;

  const _QuickActionsSheet({
    required this.onWish,
    required this.onCapsule,
    required this.onRitual,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: AetheraGlassPanel(
          borderRadius: 22,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          backgroundColor: const Color(0x240A1224),
          borderColor: Colors.white.withValues(alpha: 0.22),
          shadows: [
            BoxShadow(
              color: AetheraTokens.nebulaPurple.withValues(alpha: 0.2),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Acciones rápidas', 'Quick actions'),
                style: AetheraTokens.labelLarge(color: AetheraTokens.starlight),
              ),
              const SizedBox(height: 8),
              _QuickActionTile(
                icon: Icons.auto_awesome_outlined,
                title: context.tr('Enviar deseo', 'Send wish'),
                subtitle: context.tr(
                  'Manda un deseo breve a tu pareja.',
                  'Send a short wish to your partner.',
                ),
                onTap: onWish,
              ).animate().fadeIn(duration: 260.ms).slideX(begin: 0.08, end: 0),
              _QuickActionTile(
                    icon: Icons.hourglass_bottom_rounded,
                    title: context.tr('Crear cápsula', 'Create capsule'),
                    subtitle: context.tr(
                      'Guarda un mensaje para abrir más adelante.',
                      'Save a message to open later.',
                    ),
                    onTap: onCapsule,
                  )
                  .animate(delay: 70.ms)
                  .fadeIn(duration: 260.ms)
                  .slideX(begin: 0.08, end: 0),
              _QuickActionTile(
                    icon: Icons.self_improvement_rounded,
                    title: context.tr('Abrir ritual', 'Open ritual'),
                    subtitle: context.tr(
                      'Ir directo al ritual semanal.',
                      'Go directly to the weekly ritual.',
                    ),
                    onTap: onRitual,
                  )
                  .animate(delay: 140.ms)
                  .fadeIn(duration: 260.ms)
                  .slideX(begin: 0.08, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AetheraMotion.short,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AetheraTokens.auroraTeal.withValues(alpha: 0.12),
                border: Border.all(
                  color: AetheraTokens.auroraTeal.withValues(alpha: 0.24),
                ),
              ),
              child: Icon(icon, size: 16, color: AetheraTokens.auroraTeal),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AetheraTokens.bodyMedium(
                      color: AetheraTokens.starlight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AetheraTokens.bodySmall(
                      color: AetheraTokens.moonGlow,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AetheraTokens.dusk,
            ),
          ],
        ),
      ),
    );
  }
}

class _UniverseEmptyStateCard extends StatelessWidget {
  final VoidCallback onCreateMemory;
  final VoidCallback onCheckIn;

  const _UniverseEmptyStateCard({
    super.key,
    required this.onCreateMemory,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 370;
    return AetheraGlassPanel(
      borderRadius: 24,
      backgroundColor: const Color(0x240A1224),
      borderColor: Colors.white.withValues(alpha: 0.22),
      shadows: [
        BoxShadow(
          color: AetheraTokens.nebulaPurple.withValues(alpha: 0.2),
          blurRadius: 24,
          spreadRadius: 2,
        ),
      ],
      padding: EdgeInsets.fromLTRB(
        18,
        compact ? 16 : 18,
        18,
        compact ? 14 : 16,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AetheraTokens.auroraTeal.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 56 : 62,
                height: compact ? 56 : 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AetheraTokens.auroraTeal.withValues(alpha: 0.35),
                      AetheraTokens.nebulaPurple.withValues(alpha: 0.26),
                    ],
                  ),
                  border: Border.all(
                    color: AetheraTokens.auroraTeal.withValues(alpha: 0.42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AetheraTokens.auroraTeal.withValues(alpha: 0.22),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AetheraTokens.starlight,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(
                  'Tu universo esta listo para empezar',
                  'Your universe is ready to begin',
                ),
                style: AetheraTokens.bodyLarge(
                  color: AetheraTokens.starlight,
                ).copyWith(fontSize: compact ? 15 : null),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  'Crea tu primera memoria o registra como te sientes para encender la experiencia.',
                  'Create your first memory or check in your mood to light up the experience.',
                ),
                style: AetheraTokens.bodySmall(
                  color: AetheraTokens.moonGlow,
                ).copyWith(fontSize: compact ? 11 : null),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _HintChip(
                    icon: Icons.auto_awesome_outlined,
                    label: context.tr('Primer recuerdo', 'First memory'),
                  ),
                  _HintChip(
                    icon: Icons.favorite_outline_rounded,
                    label: context.tr('Primer check-in', 'First check-in'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AetheraButton(
                      label: context.tr('Crear memoria', 'Create memory'),
                      onPressed: onCreateMemory,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AetheraButton(
                      label: context.tr('Check-in', 'Check-in'),
                      variant: AetheraButtonVariant.outlined,
                      onPressed: onCheckIn,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HintChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, size: 12, color: AetheraTokens.auroraTeal),
          const SizedBox(width: 6),
          Text(
            label,
            style: AetheraTokens.labelSmall(color: AetheraTokens.moonGlow),
          ),
        ],
      ),
    );
  }
}

class _DailyQuestionPanel extends StatelessWidget {
  final UniverseAppState state;
  final bool compact;
  final VoidCallback onAnswer;

  const _DailyQuestionPanel({
    required this.state,
    required this.compact,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final dailyQuestion = state.dailyQuestion;
    if (dailyQuestion == null) return const SizedBox.shrink();

    final answered = state.hasAnsweredDailyQuestion;
    final revealed = state.isDailyQuestionRevealed;

    return AetheraGlassPanel(
      borderRadius: 20,
      backgroundColor: const Color(0x220B1326),
      borderColor: AetheraTokens.auroraTeal.withValues(alpha: 0.28),
      shadows: [
        BoxShadow(
          color: AetheraTokens.auroraTeal.withValues(alpha: 0.14),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ],
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 22 : 24,
                height: compact ? 22 : 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AetheraTokens.auroraTeal.withValues(alpha: 0.16),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 12,
                  color: AetheraTokens.auroraTeal,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('Pregunta del dia', 'Question of the day'),
                style: AetheraTokens.labelLarge(
                  color: AetheraTokens.starlight,
                ).copyWith(fontSize: compact ? 13 : null),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Text(
                  dailyQuestion.dayKey,
                  style: AetheraTokens.labelSmall(
                    color: AetheraTokens.moonGlow,
                  ).copyWith(fontSize: compact ? 10 : null),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 7 : 8),
          Text(
            dailyQuestion.question,
            style: AetheraTokens.bodyMedium(
              color: AetheraTokens.starlight,
            ).copyWith(
              fontSize: compact ? 13 : null,
              height: compact ? 1.35 : null,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          if (!answered)
            AetheraButton(
              label: context.tr('Responder ahora', 'Answer now'),
              width: double.infinity,
              onPressed: onAnswer,
            ),
          if (answered && !revealed) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 7 : 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
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
                      context.tr(
                        'Respuesta enviada. Esperando a tu pareja para revelar.',
                        'Answer sent. Waiting for your partner to reveal.',
                      ),
                      style: AetheraTokens.bodySmall(
                        color: AetheraTokens.moonGlow,
                      ).copyWith(fontSize: compact ? 11 : null),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AetheraButton(
              label: context.tr('Editar respuesta', 'Edit answer'),
              variant: AetheraButtonVariant.ghost,
              width: double.infinity,
              onPressed: onAnswer,
            ),
          ],
          if (revealed) ...[
            _AnswerTile(
              label: context.tr('Tu respuesta', 'Your answer'),
              answer:
                  state.myDailyQuestionAnswer?.trim().isNotEmpty == true
                      ? state.myDailyQuestionAnswer!
                      : context.tr('Sin respuesta', 'No answer'),
            ),
            const SizedBox(height: 8),
            _AnswerTile(
              label: context.tr(
                'Respuesta de tu pareja',
                'Your partner answer',
              ),
              answer:
                  state.partnerDailyQuestionAnswer?.trim().isNotEmpty == true
                      ? state.partnerDailyQuestionAnswer!
                      : context.tr('Aun no disponible', 'Not available yet'),
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
    final compact = MediaQuery.of(context).size.width < 370;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(
          color: AetheraTokens.moonGlow.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AetheraTokens.labelSmall(
              color: AetheraTokens.auroraTeal,
            ).copyWith(fontSize: compact ? 10 : null),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: AetheraTokens.bodyMedium(
              color: AetheraTokens.starlight,
            ).copyWith(fontSize: compact ? 13 : null),
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
            Text(
              context.tr('Pregunta del día', 'Question of the day'),
              style: AetheraTokens.displaySmall(),
            ),
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
                  hintText: context.tr(
                    'Escribe tu respuesta...',
                    'Write your answer...',
                  ),
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
              label:
                  _isSaving
                      ? context.tr('Guardando...', 'Saving...')
                      : context.tr('Enviar respuesta', 'Send answer'),
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
  final bool compact;
  final String? currentUserId;
  final Future<void> Function(TimeCapsuleModel capsule) onOpenCapsule;

  const _TimeCapsuleStatusPanel({
    required this.capsules,
    required this.compact,
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
      borderRadius: 20,
      backgroundColor: const Color(0x220E1320),
      borderColor: AetheraTokens.goldenDawn.withValues(alpha: 0.28),
      shadows: [
        BoxShadow(
          color: AetheraTokens.goldenDawn.withValues(alpha: 0.14),
          blurRadius: 18,
          spreadRadius: 1,
        ),
      ],
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 22 : 24,
                height: compact ? 22 : 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AetheraTokens.goldenDawn.withValues(alpha: 0.16),
                ),
                child: const Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 12,
                  color: AetheraTokens.goldenDawn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('Capsulas del tiempo', 'Time capsules'),
                style: AetheraTokens.labelLarge(
                  color: AetheraTokens.starlight,
                ).copyWith(fontSize: compact ? 13 : null),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Text(
                  context.tr(
                    '${available.length} listas',
                    '${available.length} ready',
                  ),
                  style: AetheraTokens.labelSmall(
                    color: AetheraTokens.goldenDawn,
                  ).copyWith(fontSize: compact ? 10 : null),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 7 : 8),
          Text(
            nextUnlock == null
                ? context.tr(
                  'No hay capsulas pendientes por abrir.',
                  'There are no capsules pending to open.',
                )
                : context.tr(
                  'Proxima apertura: ${_formatDateTimeLabel(context, nextUnlock)}',
                  'Next opening: ${_formatDateTimeLabel(context, nextUnlock)}',
                ),
            style: AetheraTokens.bodySmall(
              color: AetheraTokens.moonGlow,
            ).copyWith(fontSize: compact ? 11 : null),
          ),
          if (nextCapsule != null) ...[
            SizedBox(height: compact ? 8 : 10),
            AetheraButton(
              label: context.tr('Abrir capsula', 'Open capsule'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Escribe un mensaje.', 'Write a message.')),
        ),
      );
      return;
    }
    if (!_unlockAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'La fecha debe estar en el futuro.',
              'The date must be in the future.',
            ),
          ),
        ),
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
                Text(
                  context.tr('Nueva cápsula', 'New capsule'),
                  style: AetheraTokens.displaySmall(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                'Escribe algo para que solo se abra en una fecha futura.',
                'Write something that only opens on a future date.',
              ),
              style: AetheraTokens.bodySmall(color: AetheraTokens.moonGlow),
            ),
            const SizedBox(height: 18),
            _glassField(
              controller: _titleCtrl,
              hint: context.tr('Titulo opcional...', 'Optional title...'),
              maxLines: 1,
              maxLength: 48,
            ),
            const SizedBox(height: 10),
            _glassField(
              controller: _messageCtrl,
              hint: context.tr(
                'Mensaje para el futuro...',
                'Message for the future...',
              ),
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
                      context.tr('Cambiar', 'Change'),
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
              label:
                  _isSaving
                      ? context.tr('Guardando...', 'Saving...')
                      : context.tr('Guardar cápsula', 'Save capsule'),
              isLoading: _isSaving,
              onPressed: _create,
            ),
            const SizedBox(height: 8),
            AetheraButton(
              label: context.tr(
                'Abrir una cápsula lista',
                'Open a ready capsule',
              ),
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
                  capsule.title.isEmpty
                      ? context.tr('Cápsula del tiempo', 'Time capsule')
                      : capsule.title,
                  style: AetheraTokens.displaySmall(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(
              'Programada para ${_formatDateTimeLabel(context, capsule.unlockAt)}',
              'Scheduled for ${_formatDateTimeLabel(context, capsule.unlockAt)}',
            ),
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

  String _moodLabel(BuildContext context, String mood) {
    switch (mood) {
      case 'joy':
        return context.tr('Alegría', 'Joy');
      case 'love':
        return context.tr('Amor', 'Love');
      case 'peace':
        return context.tr('Paz', 'Peace');
      case 'longing':
        return context.tr('Anhelo', 'Longing');
      case 'melancholy':
        return context.tr('Melancolía', 'Melancholy');
      case 'anxious':
        return context.tr('Angustia', 'Anxious');
      default:
        return context.tr('Neutral', 'Neutral');
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
            Text(
              context.tr('¿Cómo te sientes?', 'How are you feeling?'),
              style: AetheraTokens.displaySmall(),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'Tu universo reflejará lo que hay en tu corazón.',
                'Your universe will reflect what is in your heart.',
              ),
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
                            duration: AetheraMotion.short,
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
                                  duration: AetheraMotion.short,
                                  child: EmotionOrb(
                                    mood: mood,
                                    size: isSelected ? 62 : 54,
                                    animated: isSelected,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _moodLabel(context, mood),
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
    ('constellation', '⭐'),
    ('tree', '🌳'),
    ('lighthouse', '🏮'),
    ('bridge', '🌉'),
    ('island', '🏝️'),
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
            Row(
              children: [
                const Text(
                  '✦',
                  style: TextStyle(
                    color: AetheraTokens.auroraTeal,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  context.tr('Nueva memoria', 'New memory'),
                  style: AetheraTokens.displaySmall(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    _types.map((t) {
                      final (type, emoji) = t;
                      final isSelected = _selectedType == type;
                      final label = switch (type) {
                        'constellation' => context.tr(
                          'Constelación',
                          'Constellation',
                        ),
                        'tree' => context.tr('Árbol', 'Tree'),
                        'lighthouse' => context.tr('Faro', 'Lighthouse'),
                        'bridge' => context.tr('Puente', 'Bridge'),
                        'island' => context.tr('Isla', 'Island'),
                        _ => type,
                      };
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = type),
                        child: AnimatedContainer(
                          duration: AetheraMotion.short,
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

            _glassField(
              controller: _titleCtrl,
              hint: context.tr('Título del recuerdo...', 'Memory title...'),
              maxLines: 1,
            ),

            const SizedBox(height: 12),

            _glassField(
              controller: _descCtrl,
              hint: context.tr(
                'Cuéntame sobre este momento...',
                'Tell me about this moment...',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            AetheraButton(
              label: context.tr('Guardar memoria  ✦', 'Save memory  ✦'),
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
    ('lighthouse', '🏮'),
    ('castle', '🏰'),
    ('mountain', '⛰️'),
    ('island', '🏝️'),
    ('bridge', '🌉'),
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
            Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(
                  context.tr('Nueva meta', 'New goal'),
                  style: AetheraTokens.displaySmall(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    _symbols.map((s) {
                      final (symbol, emoji) = s;
                      final isSelected = _selectedSymbol == symbol;
                      final label = switch (symbol) {
                        'lighthouse' => context.tr('Faro', 'Lighthouse'),
                        'castle' => context.tr('Castillo', 'Castle'),
                        'mountain' => context.tr('Montaña', 'Mountain'),
                        'island' => context.tr('Isla', 'Island'),
                        'bridge' => context.tr('Puente', 'Bridge'),
                        _ => symbol,
                      };
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSymbol = symbol),
                        child: AnimatedContainer(
                          duration: AetheraMotion.short,
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

            _glassField(
              controller: _titleCtrl,
              hint: context.tr('Título de la meta...', 'Goal title...'),
              maxLines: 1,
            ),

            const SizedBox(height: 12),

            _glassField(
              controller: _descCtrl,
              hint: context.tr(
                'Descríbela con detalle...',
                'Describe it in detail...',
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

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
                    const Text('📅', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    Text(
                      context.tr(
                        'Fecha objetivo: ${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                        'Target date: ${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                      ),
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
              label: context.tr('Crear meta  🎯', 'Create goal  🎯'),
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
        return '🏮';
      case 'bridge':
        return '🌉';
      case 'island':
        return '🏝️';
      case 'mountain':
        return '⛰️';
      case 'castle':
        return '🏰';
      default:
        return '🏛️';
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

            Row(
              children: [
                _StatChip(
                  icon: '📅',
                  label:
                      isCompleted
                          ? context.tr('Completada', 'Completed')
                          : context.tr(
                            '$_daysLeft días restantes',
                            '$_daysLeft days left',
                          ),
                  color:
                      isCompleted
                          ? AetheraTokens.goldenDawn
                          : AetheraTokens.moonGlow,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: '✦',
                  label: context.tr(
                    '$progressPercent% completado',
                    '$progressPercent% completed',
                  ),
                  color: accentColor,
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('Progreso', 'Progress'),
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
                    const Text('🏆', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(
                      context.tr(
                        '¡Meta cumplida! +20 conexión',
                        'Goal completed! +20 connection',
                      ),
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
                        ? context.tr('¡Completar meta! 🏆', 'Complete goal! 🏆')
                        : context.tr('Guardar progreso', 'Save progress'),
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
              '✦',
              style: TextStyle(color: AetheraTokens.auroraTeal, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr(
                'Nueva memoria añadida al universo',
                'New memory added to the universe',
              ),
              style: AetheraTokens.labelSmall(color: AetheraTokens.auroraTeal),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicToggleButton extends StatefulWidget {
  @override
  State<_MusicToggleButton> createState() => _MusicToggleButtonState();
}

class _MusicToggleButtonState extends State<_MusicToggleButton> {
  bool _isMuted = false;
  bool _isPressed = false;

  Future<void> _toggle() async {
    HapticsService.secondaryAction();
    final newMuted = !_isMuted;
    setState(() => _isMuted = newMuted);
    await MusicService.instance.setMuted(newMuted);
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
  }

  void _onTapUp([TapUpDetails? _]) {
    if (!_isPressed) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          _isMuted
              ? context.tr('Activar música', 'Enable music')
              : context.tr('Silenciar música', 'Mute music'),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapUp,
        onTap: _toggle,
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : 1,
          duration: AetheraMotion.micro,
          curve: AetheraMotion.enter,
          child: AnimatedOpacity(
            duration: AetheraMotion.short,
            opacity: _isPressed ? 0.9 : 1,
            child: AnimatedContainer(
              duration: AetheraMotion.medium,
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
          ),
        ),
      ),
    );
  }
}

class _PulseFAB extends StatefulWidget {
  final bool compact;
  final VoidCallback onTap;
  const _PulseFAB({required this.compact, required this.onTap});

  @override
  State<_PulseFAB> createState() => _PulseFABState();
}

class _PulseFABState extends State<_PulseFAB> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _idleCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _idleScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AetheraMotion.screenSlow,
    );
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _idleScale = Tween<double>(
      begin: 0.94,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _idleCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticsService.primaryAction();
    widget.onTap();
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr('Enviar pulso', 'Send pulse'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: SizedBox(
          width: widget.compact ? 54 : 60,
          height: widget.compact ? 50 : 54,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ScaleTransition(
                  scale: _idleScale,
                  child: Container(
                    width: widget.compact ? 46 : 52,
                    height: widget.compact ? 46 : 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AetheraTokens.auroraTeal.withValues(alpha: 0.42),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AetheraTokens.auroraTeal.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: widget.compact ? 46 : 52,
                    height: widget.compact ? 46 : 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AetheraTokens.auroraGradient,
                      boxShadow: AetheraTokens.auroraGlow(),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AetheraTokens.deepSpace,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

  String _emotionLabel(BuildContext context, String mood) {
    switch (mood) {
      case 'joy':
        return context.tr('Alegría ✨', 'Joy ✨');
      case 'love':
        return context.tr('Amor 💕', 'Love 💕');
      case 'peace':
        return context.tr('Paz 🌿', 'Peace 🌿');
      case 'longing':
        return context.tr('Anhelo 🌙', 'Longing 🌙');
      case 'melancholy':
        return context.tr('Melancolía 🌌', 'Melancholy 🌌');
      case 'anxious':
        return context.tr('Angustia 🌊', 'Anxious 🌊');
      default:
        return context.tr('Neutral ✦', 'Neutral ✦');
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
                              _emotionLabel(context, widget.mood),
                              style: AetheraTokens.displaySmall().copyWith(
                                color: color,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr(
                                '+${AppConstants.pointsDailyCheckin} conexión',
                                '+${AppConstants.pointsDailyCheckin} connection',
                              ),
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
              const Text('✦', style: TextStyle(fontSize: 20)),
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
          const Text('🔥', style: TextStyle(fontSize: 9)),
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
                '✨',
                style: TextStyle(fontSize: 36, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr(
                'Lanza un deseo al universo',
                'Send a wish to the universe',
              ),
              style: AetheraTokens.displaySmall(),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'Vuela como una estrella fugaz hasta tu persona.',
                'It flies like a shooting star to your person.',
              ),
              style: AetheraTokens.bodyMedium(color: AetheraTokens.moonGlow),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
                  hintText: context.tr(
                    'Te pienso, te extraño, te amo...',
                    'I miss you, I think of you, I love you...',
                  ),
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
              label:
                  _isSending
                      ? context.tr('Lanzando...', 'Launching...')
                      : context.tr('Lanzar deseo  ✨', 'Send wish  ✨'),
              isLoading: _isSending,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomingWishOverlay extends StatefulWidget {
  final dynamic wish; // Modelo de deseo
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
        GestureDetector(
          onTap: _showMessage ? widget.onSeen : null,
          child: Container(color: Colors.black.withValues(alpha: 0.55)),
        ),

        if (!_showMessage)
          AnimatedBuilder(
            animation: _starCtrl,
            builder: (_, __) {
              const angleRad = 0.52; // aprox. 30 grados
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
                            '✨',
                            style: TextStyle(fontSize: 40, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.tr(
                            'Un deseo llegó a tu universo',
                            'A wish arrived in your universe',
                          ),
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
                              context.tr('Recibido  💕', 'Received  💕'),
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

    canvas.drawCircle(
      head,
      3,
      Paint()..color = Color.fromRGBO(232, 244, 253, alpha),
    );
    canvas.drawCircle(
      head,
      10,
      Paint()..color = Color.fromRGBO(100, 255, 218, alpha * 0.4),
    );
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

class _SoloBanner extends StatelessWidget {
  final String inviteCode;
  const _SoloBanner({super.key, required this.inviteCode});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr('Invita a tu pareja', 'Invite your partner'),
      child: GestureDetector(
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
              const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: AetheraTokens.starlight,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Invita a tu pareja', 'Invite your partner'),
                      style: AetheraTokens.labelLarge(
                        color: AetheraTokens.starlight,
                      ),
                    ),
                    Text(
                      context.tr(
                        'Codigo: $inviteCode - Toca para conectar',
                        'Code: $inviteCode - Tap to connect',
                      ),
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
                      context.tr('Saltar', 'Skip'),
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
                          context.tr(
                            'EVENTO CÓSMICO DESBLOQUEADO',
                            'COSMIC EVENT UNLOCKED',
                          ),
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
                          context.tr(
                            '+${AppConstants.pointsSyncRitual} conexión • Reliquia forjada',
                            '+${AppConstants.pointsSyncRitual} connection • Relic forged',
                          ),
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
