import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:aethera/core/constants/app_constants.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/core/services/ritual_service.dart';
import 'package:aethera/features/ritual/providers/ritual_provider.dart';
import 'package:aethera/features/universe/providers/universe_provider.dart';
import 'package:aethera/features/universe/widgets/cosmic_background.dart';
import 'package:aethera/features/universe/widgets/aurora_effect.dart';
import 'package:aethera/l10n/l10n_ext.dart';
import 'package:aethera/shared/widgets/aethera_button.dart';
import 'package:aethera/shared/widgets/aethera_glass_panel.dart';

class RitualScreen extends ConsumerStatefulWidget {
  const RitualScreen({super.key});

  @override
  ConsumerState<RitualScreen> createState() => _RitualScreenState();
}

class _RitualScreenState extends ConsumerState<RitualScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  bool _justCompletedThisSession = false;

  final _answerCtrl = TextEditingController();
  final _gratitude1 = TextEditingController();
  final _gratitude2 = TextEditingController();
  final _gratitude3 = TextEditingController();

  late AnimationController _celebrationCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _cartaRevealCtrl;

  final _ritualSvc = RitualService();

  @override
  void initState() {
    super.initState();
    _celebrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _cartaRevealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initRitual());
  }

  void _initRitual() {
    final universe = ref.read(universeProvider);
    final couple = universe.couple;
    final myUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (couple != null && myUserId.isNotEmpty) {
      final partnerUserId =
          couple.user1Id == myUserId ? couple.user2Id : couple.user1Id;
      ref
          .read(ritualProvider.notifier)
          .watchRitual(couple.id, myUserId, partnerUserId);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _answerCtrl.dispose();
    _gratitude1.dispose();
    _gratitude2.dispose();
    _gratitude3.dispose();
    _celebrationCtrl.dispose();
    _pulseCtrl.dispose();
    _cartaRevealCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final universe = ref.read(universeProvider);
    final coupleId = universe.couple?.id;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (coupleId == null || userId == null) return;

    await ref
        .read(ritualProvider.notifier)
        .submit(
          coupleId: coupleId,
          userId: userId,
          answer: _answerCtrl.text,
          gratitude: [_gratitude1.text, _gratitude2.text, _gratitude3.text],
        );

    setState(() => _justCompletedThisSession = true);
    _celebrationCtrl.forward();
    _nextPage();
  }

  Future<void> _inviteSync() async {
    final universe = ref.read(universeProvider);
    final coupleId = universe.couple?.id;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (coupleId == null || userId == null) return;
    await ref
        .read(ritualProvider.notifier)
        .sendSyncInvite(coupleId: coupleId, userId: userId);
  }

  Future<void> _startSyncHold() async {
    final universe = ref.read(universeProvider);
    final coupleId = universe.couple?.id;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (coupleId == null || userId == null) return;
    await ref
        .read(ritualProvider.notifier)
        .startSyncHold(coupleId: coupleId, userId: userId);
  }

  Future<void> _stopSyncHold() async {
    final universe = ref.read(universeProvider);
    final coupleId = universe.couple?.id;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (coupleId == null || userId == null) return;
    await ref
        .read(ritualProvider.notifier)
        .stopSyncHold(coupleId: coupleId, userId: userId);
  }

  void _goToPartnerCarta() {
    _cartaRevealCtrl.reset();
    _pageCtrl.animateToPage(
      3,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(milliseconds: 700), () {
      _cartaRevealCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ritualState = ref.watch(ritualProvider);
    final showAlreadyCompleted =
        ritualState.alreadyCompleted && !_justCompletedThisSession;

    return Scaffold(
      backgroundColor: AetheraTokens.deepSpace,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CosmicBackground(),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder:
                (_, __) => AuroraEffect(opacity: 0.5 + _pulseCtrl.value * 0.3),
          ),

          // ── Main content ──────────────────────────────────────────────
          if (showAlreadyCompleted)
            _AlreadyCompletedView(
              state: ritualState,
              onInviteSync: () {
                _inviteSync();
              },
              onSyncHoldStart: () {
                _startSyncHold();
              },
              onSyncHoldEnd: () {
                _stopSyncHold();
              },
              onViewPartnerCarta: () {
                setState(() => _justCompletedThisSession = true);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _cartaRevealCtrl.reset();
                  _currentPage = 3;
                  _cartaRevealCtrl.forward();
                });
              },
            )
          else
            PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) => setState(() => _currentPage = p),
              children: [
                // Page 0: Question
                _QuestionPage(
                  question:
                      ritualState.weekQuestion.isNotEmpty
                          ? ritualState.weekQuestion
                          : _ritualSvc.getWeekQuestion(),
                  controller: _answerCtrl,
                  onNext: _nextPage,
                ),
                // Page 1: Gratitude
                _GratitudePage(
                  ctrl1: _gratitude1,
                  ctrl2: _gratitude2,
                  ctrl3: _gratitude3,
                  isLoading: ritualState.status == RitualStatus.loading,
                  onSubmit: _submit,
                ),
                // Page 2: Celebration
                _CelebrationPage(
                  animCtrl: _celebrationCtrl,
                  pulseCtrl: _pulseCtrl,
                  ritualState: ritualState,
                  onInviteSync: () {
                    _inviteSync();
                  },
                  onSyncHoldStart: () {
                    _startSyncHold();
                  },
                  onSyncHoldEnd: () {
                    _stopSyncHold();
                  },
                  onViewPartnerCarta: _goToPartnerCarta,
                  onClose: () => context.pop(),
                ),
                // Page 3: Partner's carta reveal
                _PartnerCartaPage(
                  revealCtrl: _cartaRevealCtrl,
                  partnerAnswer: ritualState.partnerAnswer,
                  partnerGratitude: ritualState.partnerGratitude,
                  question:
                      ritualState.weekQuestion.isNotEmpty
                          ? ritualState.weekQuestion
                          : _ritualSvc.getWeekQuestion(),
                  onClose: () => context.pop(),
                ),
              ],
            ),

          // ── Back button (pages 0-1 only) ──────────────────────────────
          // Wrapped in Positioned so it doesn't cover the full Stack and
          // block tap events destined for the TextFields below.
          if (!showAlreadyCompleted && _currentPage < 2)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () {
                      if (_currentPage == 0) {
                        context.pop();
                      } else {
                        _pageCtrl.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AetheraTokens.moonGlow,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Page indicator (pages 0-1 only) ──────────────────────────
          if (!showAlreadyCompleted && _currentPage < 2)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  2,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color:
                          i == _currentPage
                              ? AetheraTokens.auroraTeal
                              : AetheraTokens.moonGlow.withValues(alpha: 0.3),
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

// ─── Already Completed View ────────────────────────────────────────────────────

class _AlreadyCompletedView extends StatelessWidget {
  final RitualState state;
  final VoidCallback onInviteSync;
  final VoidCallback onSyncHoldStart;
  final VoidCallback onSyncHoldEnd;
  final VoidCallback onViewPartnerCarta;

  const _AlreadyCompletedView({
    required this.state,
    required this.onInviteSync,
    required this.onSyncHoldStart,
    required this.onSyncHoldEnd,
    required this.onViewPartnerCarta,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final week = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7)
        .floor()
        .toString()
        .padLeft(2, '0');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AetheraTokens.moonGlow,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Ritual Semanal', 'Weekly Ritual'),
                      style: AetheraTokens.displaySmall(),
                    ),
                    Text(
                      context.tr('Semana $week', 'Week $week'),
                      style: AetheraTokens.bodySmall(
                        color: AetheraTokens.moonGlow,
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(duration: 600.ms),

            const SizedBox(height: 32),

            // Completed badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AetheraTokens.auroraTeal.withValues(alpha: 0.08),
                border: Border.all(
                  color: AetheraTokens.auroraTeal.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '✓ ',
                    style: TextStyle(
                      color: AetheraTokens.auroraTeal,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    context.tr(
                      'Tu ritual de esta semana está completo',
                      'Your ritual for this week is complete',
                    ),
                    style: AetheraTokens.bodyMedium(
                      color: AetheraTokens.auroraTeal,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 28),

            // My answer card
            if (state.myAnswer != null && state.myAnswer!.isNotEmpty) ...[
              _CartaCard(
                label: context.tr('Tu respuesta', 'Your answer'),
                emoji: '✍️',
                question: state.weekQuestion,
                answer: state.myAnswer!,
                gratitude: state.myGratitude ?? [],
                accentColor: AetheraTokens.auroraTeal,
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 20),
            ],

            _SyncLiveCard(
              state: state,
              onInvite: onInviteSync,
              onHoldStart: onSyncHoldStart,
              onHoldEnd: onSyncHoldEnd,
            ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.08, end: 0),

            const SizedBox(height: 20),

            // Partner section
            if (state.partnerCompleted) ...[
              AetheraButton(
                label: context.tr('Leer su carta  💕', 'Read their letter  💕'),
                onPressed: onViewPartnerCarta,
              ).animate().fadeIn(delay: 500.ms),
            ] else ...[
              AetheraGlassPanel(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _PulsingDot(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              'Esperando su respuesta...',
                              'Waiting for their answer...',
                            ),
                            style: AetheraTokens.bodyMedium(
                              color: AetheraTokens.starlight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(
                              'Te avisaremos cuando complete su ritual',
                              'We will notify you when ritual is completed',
                            ),
                            style: AetheraTokens.bodySmall(
                              color: AetheraTokens.moonGlow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Carta Card ────────────────────────────────────────────────────────────────

class _CartaCard extends StatelessWidget {
  final String label;
  final String emoji;
  final String question;
  final String answer;
  final List<String> gratitude;
  final Color accentColor;

  const _CartaCard({
    required this.label,
    required this.emoji,
    required this.question,
    required this.answer,
    required this.gratitude,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cleanGratitude = gratitude.where((g) => g.trim().isNotEmpty).toList();
    return AetheraGlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(label, style: AetheraTokens.labelLarge(color: accentColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question,
            style: AetheraTokens.bodySmall(
              color: AetheraTokens.dusk,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),
          Text(answer, style: AetheraTokens.bodyMedium()),
          if (cleanGratitude.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: AetheraTokens.moonGlow.withValues(alpha: 0.15)),
            const SizedBox(height: 10),
            ...cleanGratitude.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.key + 1}.  ',
                      style: AetheraTokens.bodySmall(
                        color: AetheraTokens.roseQuartz,
                      ),
                    ),
                    Expanded(
                      child: Text(e.value, style: AetheraTokens.bodySmall()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Pulsing dot for "waiting" state ──────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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
      builder:
          (_, __) => Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AetheraTokens.nebulaPurple.withValues(
                alpha: 0.4 + _ctrl.value * 0.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: AetheraTokens.nebulaPurple.withValues(
                    alpha: _ctrl.value * 0.5,
                  ),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
    );
  }
}

// ─── Page 1: La Pregunta ──────────────────────────────────────────────────────

class _SyncLiveCard extends StatelessWidget {
  final RitualState state;
  final VoidCallback onInvite;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  const _SyncLiveCard({
    required this.state,
    required this.onInvite,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  @override
  Widget build(BuildContext context) {
    final progress = state.syncProgress.clamp(0.0, 1.0);
    final bothHolding = state.syncMeHolding && state.syncPartnerHolding;

    return AetheraGlassPanel(
      padding: const EdgeInsets.all(18),
      borderColor:
          state.syncCompleted
              ? AetheraTokens.auroraTeal.withValues(alpha: 0.38)
              : Colors.white.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                state.syncCompleted ? '✨' : '⚡',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('Sincronía en vivo', 'Live sync'),
                style: AetheraTokens.labelLarge(
                  color:
                      state.syncCompleted
                          ? AetheraTokens.auroraTeal
                          : AetheraTokens.starlight,
                ),
              ),
              const Spacer(),
              Text(
                '${AppConstants.syncRitualSeconds}s',
                style: AetheraTokens.bodySmall(color: AetheraTokens.moonGlow),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (state.syncCompleted) ...[
            Text(
              context.tr(
                'Evento desbloqueado: ${state.syncEvent ?? 'Ritual completo'}',
                'Unlocked event: ${state.syncEvent ?? 'Ritual completed'}',
              ),
              style: AetheraTokens.bodyMedium(color: AetheraTokens.auroraTeal),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                '+${AppConstants.pointsSyncRitual} Conexión · Reliquia añadida al universo',
                '+${AppConstants.pointsSyncRitual} Connection · Relic added to universe',
              ),
              style: AetheraTokens.bodySmall(color: AetheraTokens.moonGlow),
            ),
          ] else ...[
            Row(
              children: [
                _SyncBadge(
                  label: context.tr('Tú', 'You'),
                  active: state.syncMeHolding,
                ),
                const SizedBox(width: 8),
                _SyncBadge(
                  label: context.tr('Pareja', 'Partner'),
                  active: state.syncPartnerHolding,
                ),
                const Spacer(),
                Text(
                  bothHolding
                      ? context.tr('Sincronizando...', 'Syncing...')
                      : context.tr('Esperando sincronía', 'Waiting for sync'),
                  style: AetheraTokens.bodySmall(
                    color:
                        bothHolding
                            ? AetheraTokens.auroraTeal
                            : AetheraTokens.moonGlow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AetheraTokens.auroraTeal,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bothHolding
                  ? context.tr(
                    'Faltan ${state.syncSecondsLeft}s para desbloquear evento cósmico',
                    '${state.syncSecondsLeft}s left to unlock cosmic event',
                  )
                  : context.tr(
                    'Mantengan presionado al mismo tiempo para iniciar la cuenta',
                    'Hold at the same time to start the countdown',
                  ),
              style: AetheraTokens.bodySmall(color: AetheraTokens.moonGlow),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AetheraButton(
                    label: context.tr('Invitar', 'Invite'),
                    variant: AetheraButtonVariant.outlined,
                    onPressed: onInvite,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: context.tr(
                      'Mantener pulsado para sincronizar',
                      'Hold to sync',
                    ),
                    child: GestureDetector(
                      onLongPressStart: (_) => onHoldStart(),
                      onLongPressEnd: (_) => onHoldEnd(),
                      onLongPressCancel: onHoldEnd,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient:
                              state.syncMeHolding
                                  ? LinearGradient(
                                    colors: [
                                      AetheraTokens.auroraTeal.withValues(
                                        alpha: 0.35,
                                      ),
                                      AetheraTokens.nebulaPurple.withValues(
                                        alpha: 0.28,
                                      ),
                                    ],
                                  )
                                  : null,
                          color:
                              state.syncMeHolding
                                  ? null
                                  : Colors.white.withValues(alpha: 0.06),
                          border: Border.all(
                            color:
                                state.syncMeHolding
                                    ? AetheraTokens.auroraTeal.withValues(
                                      alpha: 0.7,
                                    )
                                    : Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            state.syncMeHolding
                                ? context.tr('SINCRONIZANDO...', 'SYNCING...')
                                : context.tr('MANTENER 60S', 'HOLD 60S'),
                            style: AetheraTokens.labelLarge(
                              color:
                                  state.syncMeHolding
                                      ? AetheraTokens.starlight
                                      : AetheraTokens.moonGlow,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  final String label;
  final bool active;

  const _SyncBadge({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color:
            active
                ? AetheraTokens.auroraTeal.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color:
              active
                  ? AetheraTokens.auroraTeal.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AetheraTokens.auroraTeal : AetheraTokens.moonGlow,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AetheraTokens.bodySmall(
              color: active ? AetheraTokens.auroraTeal : AetheraTokens.moonGlow,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionPage extends StatefulWidget {
  final String question;
  final TextEditingController controller;
  final VoidCallback onNext;

  const _QuestionPage({
    required this.question,
    required this.controller,
    required this.onNext,
  });

  @override
  State<_QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<_QuestionPage> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(
      () => setState(() => _hasText = widget.controller.text.isNotEmpty),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final week = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7)
        .floor()
        .toString()
        .padLeft(2, '0');

    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 72, 28, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AetheraTokens.nebulaPurple.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      color: AetheraTokens.nebulaPurple.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      context.tr(
                        'RITUAL SEMANAL · SEMANA $week',
                        'WEEKLY RITUAL · WEEK $week',
                      ),
                      style: AetheraTokens.labelSmall(
                        color: AetheraTokens.nebulaPurple,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 40),

              Text(
                    widget.question,
                    style: AetheraTokens.displayMedium().copyWith(
                      fontSize: 28,
                      height: 1.4,
                      letterSpacing: 0.5,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 800.ms)
                  .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 12),

              Container(
                width: 48,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AetheraTokens.auroraTeal,
                      AetheraTokens.nebulaPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.3, end: 0),

              const SizedBox(height: 36),

              AetheraGlassPanel(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      controller: widget.controller,
                      maxLines: 6,
                      minLines: 4,
                      style: AetheraTokens.bodyLarge(
                        color: AetheraTokens.starlight,
                      ),
                      decoration: InputDecoration(
                        hintText: context.tr(
                          'Escribe con honestidad... este espacio es solo para nosotros.',
                          'Write honestly... this space is only for us.',
                        ),
                        hintStyle: AetheraTokens.bodyMedium(
                          color: AetheraTokens.moonGlow.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 700.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 32),

              AnimatedOpacity(
                opacity: _hasText ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 300),
                child: AetheraButton(
                  label: context.tr('Siguiente →', 'Next →'),
                  onPressed: _hasText ? widget.onNext : null,
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Page 2: Gratitud ─────────────────────────────────────────────────────────

class _GratitudePage extends StatelessWidget {
  final TextEditingController ctrl1;
  final TextEditingController ctrl2;
  final TextEditingController ctrl3;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _GratitudePage({
    required this.ctrl1,
    required this.ctrl2,
    required this.ctrl3,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 72, 28, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                    shaderCallback:
                        (bounds) => const LinearGradient(
                          colors: [
                            AetheraTokens.roseQuartz,
                            AetheraTokens.nebulaPurple,
                          ],
                        ).createShader(bounds),
                    child: const Text('💕', style: TextStyle(fontSize: 48)),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOut),

              const SizedBox(height: 20),

              Text(
                context.tr('Gratitud', 'Gratitude'),
                style: AetheraTokens.displayMedium().copyWith(letterSpacing: 4),
              ).animate().fadeIn(delay: 100.ms, duration: 600.ms),

              const SizedBox(height: 8),

              Text(
                context.tr(
                  '¿Qué amas de él/ella esta semana?',
                  'What do you love about them this week?',
                ),
                style: AetheraTokens.bodyLarge(color: AetheraTokens.moonGlow),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 36),

              ...[
                (ctrl1, '1.  '),
                (ctrl2, '2.  '),
                (ctrl3, '3.  '),
              ].asMap().entries.map((entry) {
                final i = entry.key;
                final (ctrl, prefix) = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AetheraGlassPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          prefix,
                          style: AetheraTokens.bodyLarge(
                            color: AetheraTokens.roseQuartz,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            style: AetheraTokens.bodyLarge(
                              color: AetheraTokens.starlight,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  [
                                    context.tr(
                                      'Tu forma de hacerme reír...',
                                      'The way you make me laugh...',
                                    ),
                                    context.tr(
                                      'Cómo me haces sentir especial...',
                                      'How you make me feel special...',
                                    ),
                                    context.tr(
                                      'Algo que admiro de ti...',
                                      'Something I admire about you...',
                                    ),
                                  ][i],
                              hintStyle: AetheraTokens.bodyMedium(
                                color: AetheraTokens.moonGlow.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(
                    delay: Duration(milliseconds: 300 + i * 120),
                    duration: 500.ms,
                  ),
                );
              }),

              const SizedBox(height: 32),

              AetheraButton(
                label: context.tr('Completar ritual  ✨', 'Complete ritual  ✨'),
                isLoading: isLoading,
                onPressed: onSubmit,
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Page 3: Celebración ──────────────────────────────────────────────────────

class _CelebrationPage extends StatelessWidget {
  final AnimationController animCtrl;
  final AnimationController pulseCtrl;
  final RitualState ritualState;
  final VoidCallback onInviteSync;
  final VoidCallback onSyncHoldStart;
  final VoidCallback onSyncHoldEnd;
  final VoidCallback onViewPartnerCarta;
  final VoidCallback onClose;

  const _CelebrationPage({
    required this.animCtrl,
    required this.pulseCtrl,
    required this.ritualState,
    required this.onInviteSync,
    required this.onSyncHoldStart,
    required this.onSyncHoldEnd,
    required this.onViewPartnerCarta,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animCtrl,
      builder:
          (_, __) => Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _ParticlePainter(progress: animCtrl.value)),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: pulseCtrl,
                        builder:
                            (_, __) => Transform.scale(
                              scale: 1.0 + pulseCtrl.value * 0.15,
                              child: const Text(
                                '💕',
                                style: TextStyle(fontSize: 80),
                              ),
                            ),
                      ).animate().scale(
                        begin: const Offset(0.0, 0.0),
                        end: const Offset(1.0, 1.0),
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      ),

                      const SizedBox(height: 32),

                      Text(
                            context.tr('Ritual completado', 'Ritual completed'),
                            style: AetheraTokens.displayMedium().copyWith(
                              letterSpacing: 3,
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 12),

                      Text(
                        context.tr(
                          'Tu respuesta viaja hacia él/ella',
                          'Your answer is traveling to your partner',
                        ),
                        style: AetheraTokens.bodyMedium(
                          color: AetheraTokens.moonGlow,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 700.ms),

                      const SizedBox(height: 28),

                      Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: [
                                  AetheraTokens.auroraTeal.withValues(
                                    alpha: 0.2,
                                  ),
                                  AetheraTokens.nebulaPurple.withValues(
                                    alpha: 0.2,
                                  ),
                                ],
                              ),
                              border: Border.all(
                                color: AetheraTokens.auroraTeal.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '✦',
                                  style: TextStyle(
                                    color: AetheraTokens.auroraTeal,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('+15 Conexión', '+15 Connection'),
                                  style: AetheraTokens.labelLarge(
                                    color: AetheraTokens.auroraTeal,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 900.ms)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 20),

                      _SyncLiveCard(
                        state: ritualState,
                        onInvite: onInviteSync,
                        onHoldStart: onSyncHoldStart,
                        onHoldEnd: onSyncHoldEnd,
                      ).animate().fadeIn(delay: 1000.ms),

                      const SizedBox(height: 40),

                      // Partner carta button — appears if partner has completed
                      if (ritualState.partnerCompleted)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AetheraButton(
                                label: context.tr(
                                  'Leer su carta  💌',
                                  'Read their letter  💌',
                                ),
                                onPressed: onViewPartnerCarta,
                              )
                              .animate()
                              .fadeIn(delay: 1100.ms)
                              .slideY(begin: 0.2, end: 0),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            context.tr(
                              'Esperando su respuesta...',
                              'Waiting for their answer...',
                            ),
                            style: AetheraTokens.bodySmall(
                              color: AetheraTokens.dusk,
                            ),
                          ).animate().fadeIn(delay: 1100.ms),
                        ),

                      AetheraButton(
                        label: context.tr(
                          'Volver al universo',
                          'Back to universe',
                        ),
                        variant: AetheraButtonVariant.outlined,
                        onPressed: onClose,
                      ).animate().fadeIn(delay: 1300.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

// ─── Page 4: Partner's Carta Reveal ───────────────────────────────────────────

class _PartnerCartaPage extends StatelessWidget {
  final AnimationController revealCtrl;
  final String? partnerAnswer;
  final List<String>? partnerGratitude;
  final String question;
  final VoidCallback onClose;

  const _PartnerCartaPage({
    required this.revealCtrl,
    required this.partnerAnswer,
    required this.partnerGratitude,
    required this.question,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (partnerAnswer == null || partnerAnswer!.isEmpty) {
      return _WaitingForPartner(onClose: onClose);
    }

    return AnimatedBuilder(
      animation: revealCtrl,
      builder: (_, __) {
        final reveal = Curves.easeOutCubic.transform(revealCtrl.value);
        final cleanGratitude =
            (partnerGratitude ?? []).where((g) => g.trim().isNotEmpty).toList();

        return Stack(
          fit: StackFit.expand,
          children: [
            // Particle burst on reveal
            if (revealCtrl.value > 0.1)
              CustomPaint(
                painter: _CartaParticlePainter(progress: revealCtrl.value),
              ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  children: [
                    // Envelope icon with scale animation
                    Transform.scale(
                      scale: 0.3 + reveal * 0.7,
                      child: Opacity(
                        opacity: reveal,
                        child: Column(
                          children: [
                            Text(
                              '💌',
                              style: TextStyle(fontSize: 20 + reveal * 44),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr(
                                'Su carta para ti',
                                'Their letter for you',
                              ),
                              style: AetheraTokens.displaySmall().copyWith(
                                color: AetheraTokens.roseQuartz,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // The carta card — unfolds from top
                    ClipRect(
                      child: Align(
                        heightFactor: reveal,
                        alignment: Alignment.topCenter,
                        child: Opacity(
                          opacity: reveal > 0.3 ? (reveal - 0.3) / 0.7 : 0,
                          child: AetheraGlassPanel(
                            backgroundColor: AetheraTokens.roseQuartz
                                .withValues(alpha: 0.06),
                            borderColor: AetheraTokens.roseQuartz.withValues(
                              alpha: 0.25,
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Question
                                Text(
                                  question,
                                  style: AetheraTokens.bodySmall(
                                    color: AetheraTokens.dusk,
                                  ).copyWith(fontStyle: FontStyle.italic),
                                ),

                                const SizedBox(height: 16),

                                // Decorative line
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        AetheraTokens.roseQuartz.withValues(
                                          alpha: 0.5,
                                        ),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Their answer
                                Text(
                                  partnerAnswer!,
                                  style: AetheraTokens.bodyLarge().copyWith(
                                    height: 1.7,
                                  ),
                                ),

                                if (cleanGratitude.isNotEmpty) ...[
                                  const SizedBox(height: 24),

                                  Row(
                                    children: [
                                      const Text(
                                        '💕',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.tr(
                                          'Con gratitud',
                                          'With gratitude',
                                        ),
                                        style: AetheraTokens.labelLarge(
                                          color: AetheraTokens.roseQuartz,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  ...cleanGratitude.asMap().entries.map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${e.key + 1}.  ',
                                            style: AetheraTokens.bodyMedium(
                                              color: AetheraTokens.roseQuartz,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              e.value,
                                              style: AetheraTokens.bodyMedium(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 20),

                                // Sign-off
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    context.tr('Con amor  ✦', 'With love  ✦'),
                                    style: AetheraTokens.bodyMedium(
                                      color: AetheraTokens.roseQuartz,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    if (reveal > 0.9)
                      AetheraButton(
                        label: context.tr(
                          'Volver al universo',
                          'Back to universe',
                        ),
                        variant: AetheraButtonVariant.outlined,
                        onPressed: onClose,
                      ).animate().fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Waiting for partner page ─────────────────────────────────────────────────

class _WaitingForPartner extends StatelessWidget {
  final VoidCallback onClose;
  const _WaitingForPartner({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🌙',
                style: TextStyle(fontSize: 64),
              ).animate().fadeIn().scale(curve: Curves.elasticOut),
              const SizedBox(height: 28),
              Text(
                context.tr('Aún no ha respondido', 'No answer yet'),
                style: AetheraTokens.displaySmall(),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              Text(
                context.tr(
                  'Cuando complete su ritual, su carta aparecerá aquí.',
                  'When ritual is completed, their letter will appear here.',
                ),
                style: AetheraTokens.bodyMedium(color: AetheraTokens.moonGlow),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 48),
              AetheraButton(
                label: context.tr('Volver', 'Back'),
                variant: AetheraButtonVariant.outlined,
                onPressed: onClose,
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Particle Painters ─────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> _particles;

  _ParticlePainter({required this.progress}) : _particles = _buildParticles();

  static List<_Particle> _buildParticles() {
    final rng = Random(42);
    return List.generate(60, (i) {
      final angle = (i / 60) * 2 * pi + rng.nextDouble() * 0.3;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final color =
          [
            AetheraTokens.auroraTeal,
            AetheraTokens.roseQuartz,
            AetheraTokens.nebulaPurple,
            AetheraTokens.starlight,
            AetheraTokens.goldenDawn,
          ][rng.nextInt(5)];
      return _Particle(
        angle: angle,
        speed: speed,
        color: color,
        size: 2 + rng.nextDouble() * 4,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.width * 0.8;
    final fade =
        progress < 0.2
            ? progress / 0.2
            : progress > 0.7
            ? 1.0 - (progress - 0.7) / 0.3
            : 1.0;
    for (final p in _particles) {
      final r = p.speed * progress * maxR;
      final x = cx + cos(p.angle) * r;
      final y = cy + sin(p.angle) * r;
      canvas.drawCircle(
        Offset(x, y),
        p.size * (1 - progress * 0.5),
        Paint()..color = p.color.withValues(alpha: fade * 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _CartaParticlePainter extends CustomPainter {
  final double progress;

  const _CartaParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress > 0.5) return; // only burst at start
    final rng = Random(77);
    final cx = size.width / 2;
    final cy = size.height * 0.25;
    final burstProgress = (progress * 2).clamp(0.0, 1.0);
    final fade = 1.0 - burstProgress;

    for (int i = 0; i < 30; i++) {
      final angle = (i / 30) * 2 * pi + rng.nextDouble() * 0.5;
      final speed = (0.2 + rng.nextDouble() * 0.4) * size.width * 0.4;
      final x = cx + cos(angle) * speed * burstProgress;
      final y = cy + sin(angle) * speed * burstProgress;
      canvas.drawCircle(
        Offset(x, y),
        1.5 + rng.nextDouble() * 2.5,
        Paint()
          ..color = [
            AetheraTokens.roseQuartz,
            AetheraTokens.nebulaPurple,
            AetheraTokens.goldenDawn,
          ][rng.nextInt(3)].withValues(alpha: fade * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_CartaParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double angle;
  final double speed;
  final Color color;
  final double size;

  const _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
  });
}
