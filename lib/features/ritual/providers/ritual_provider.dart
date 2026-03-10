import 'dart:async';
import 'package:aethera/core/constants/app_constants.dart';
import 'package:aethera/core/services/notification_service.dart';
import 'package:aethera/core/services/ritual_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Notifier, NotifierProvider, Provider;

final ritualServiceProvider =
    Provider<RitualService>((ref) => RitualService());

enum RitualStatus { idle, loading, success, error }

class RitualState {
  final RitualStatus status;
  final bool alreadyCompleted;
  final bool partnerCompleted;
  final String? myAnswer;
  final List<String>? myGratitude;
  final String? partnerAnswer;
  final List<String>? partnerGratitude;
  final String weekQuestion;
  final String? error;

  // Live sync ritual state
  final bool syncMeHolding;
  final bool syncPartnerHolding;
  final bool syncCompleted;
  final double syncProgress; // 0..1
  final int syncSecondsLeft;
  final String? syncEvent;
  final String? syncInviteFrom;
  final int? syncInviteAt;

  const RitualState({
    this.status = RitualStatus.idle,
    this.alreadyCompleted = false,
    this.partnerCompleted = false,
    this.myAnswer,
    this.myGratitude,
    this.partnerAnswer,
    this.partnerGratitude,
    this.weekQuestion = '',
    this.error,
    this.syncMeHolding = false,
    this.syncPartnerHolding = false,
    this.syncCompleted = false,
    this.syncProgress = 0,
    this.syncSecondsLeft = AppConstants.syncRitualSeconds,
    this.syncEvent,
    this.syncInviteFrom,
    this.syncInviteAt,
  });

  RitualState copyWith({
    RitualStatus? status,
    bool? alreadyCompleted,
    bool? partnerCompleted,
    String? myAnswer,
    List<String>? myGratitude,
    String? partnerAnswer,
    List<String>? partnerGratitude,
    String? weekQuestion,
    String? error,
    bool? syncMeHolding,
    bool? syncPartnerHolding,
    bool? syncCompleted,
    double? syncProgress,
    int? syncSecondsLeft,
    String? syncEvent,
    bool clearSyncEvent = false,
    String? syncInviteFrom,
    int? syncInviteAt,
    bool clearSyncInvite = false,
  }) =>
      RitualState(
        status: status ?? this.status,
        alreadyCompleted: alreadyCompleted ?? this.alreadyCompleted,
        partnerCompleted: partnerCompleted ?? this.partnerCompleted,
        myAnswer: myAnswer ?? this.myAnswer,
        myGratitude: myGratitude ?? this.myGratitude,
        partnerAnswer: partnerAnswer ?? this.partnerAnswer,
        partnerGratitude: partnerGratitude ?? this.partnerGratitude,
        weekQuestion: weekQuestion ?? this.weekQuestion,
        error: error,
        syncMeHolding: syncMeHolding ?? this.syncMeHolding,
        syncPartnerHolding: syncPartnerHolding ?? this.syncPartnerHolding,
        syncCompleted: syncCompleted ?? this.syncCompleted,
        syncProgress: syncProgress ?? this.syncProgress,
        syncSecondsLeft: syncSecondsLeft ?? this.syncSecondsLeft,
        syncEvent: clearSyncEvent ? null : (syncEvent ?? this.syncEvent),
        syncInviteFrom:
            clearSyncInvite ? null : (syncInviteFrom ?? this.syncInviteFrom),
        syncInviteAt: clearSyncInvite ? null : (syncInviteAt ?? this.syncInviteAt),
      );
}

class RitualNotifier extends Notifier<RitualState> {
  RitualService get _service => ref.read(ritualServiceProvider);

  StreamSubscription? _ritualSub;
  Timer? _syncTick;

  String? _coupleId;
  String? _userId;
  String? _partnerUserId;
  int? _myHoldSinceMs;
  int? _partnerHoldSinceMs;
  bool _syncCompletionInFlight = false;

  @override
  RitualState build() {
    ref.onDispose(() {
      _ritualSub?.cancel();
      _syncTick?.cancel();
    });
    return RitualState(weekQuestion: RitualService.currentWeekQuestion);
  }

  /// Subscribe to live ritual data for this week.
  void watchRitual(String coupleId, String userId, String partnerUserId) {
    _ritualSub?.cancel();
    _coupleId = coupleId;
    _userId = userId;
    _partnerUserId = partnerUserId;

    _ritualSub = _service.watchThisWeekRitual(coupleId).listen((data) {
      if (data == null) {
        _myHoldSinceMs = null;
        _partnerHoldSinceMs = null;
        _syncTick?.cancel();
        _syncTick = null;
        state = state.copyWith(
          alreadyCompleted: false,
          partnerCompleted: false,
          syncMeHolding: false,
          syncPartnerHolding: false,
          syncCompleted: false,
          syncProgress: 0,
          syncSecondsLeft: AppConstants.syncRitualSeconds,
          clearSyncEvent: true,
          clearSyncInvite: true,
        );
        return;
      }

      final completedBy = (data['completedBy'] as List?) ?? [];
      final partnerJustCompleted =
          !state.partnerCompleted && completedBy.contains(partnerUserId);

      final myHolding = data['syncHolding_$userId'] == true;
      final partnerHolding = data['syncHolding_$partnerUserId'] == true;
      final mySince = (data['syncHoldSince_$userId'] as num?)?.toInt();
      final partnerSince =
          (data['syncHoldSince_$partnerUserId'] as num?)?.toInt();
      final syncCompleted = data['syncCompleted'] == true;
      final syncEvent = data['syncEvent'] as String?;
      final syncInviteFrom = data['syncInviteFrom'] as String?;
      final syncInviteAt = (data['syncInviteAt'] as num?)?.toInt();

      final partnerJustStarted = !state.syncPartnerHolding && partnerHolding;
      final partnerInviteArrived = syncInviteFrom == partnerUserId &&
          syncInviteAt != null &&
          syncInviteAt != state.syncInviteAt;
      final syncJustCompleted = !state.syncCompleted && syncCompleted;

      _myHoldSinceMs = mySince;
      _partnerHoldSinceMs = partnerSince;

      state = state.copyWith(
        alreadyCompleted: completedBy.contains(userId),
        partnerCompleted: completedBy.contains(partnerUserId),
        myAnswer: data['answer_$userId'] as String?,
        myGratitude: (data['gratitude_$userId'] as List?)?.cast<String>(),
        partnerAnswer: data['answer_$partnerUserId'] as String?,
        partnerGratitude:
            (data['gratitude_$partnerUserId'] as List?)?.cast<String>(),
        weekQuestion: data['question'] as String? ?? _service.getWeekQuestion(),
        syncMeHolding: myHolding,
        syncPartnerHolding: partnerHolding,
        syncCompleted: syncCompleted,
        syncEvent: syncEvent,
        syncInviteFrom: syncInviteFrom,
        syncInviteAt: syncInviteAt,
      );

      _recomputeSyncProgress();

      if (partnerJustCompleted) {
        NotificationService.instance.showPartnerRitualNotification();
      }
      if (partnerJustStarted || partnerInviteArrived) {
        NotificationService.instance.showSyncInviteNotification();
      }
      if (syncJustCompleted && syncEvent != null) {
        NotificationService.instance.showSyncUnlockedNotification(syncEvent);
      }
    });
  }

  Future<void> submit({
    required String coupleId,
    required String userId,
    required String answer,
    required List<String> gratitude,
  }) async {
    state = state.copyWith(status: RitualStatus.loading);
    try {
      await _service.submitRitual(
        coupleId: coupleId,
        userId: userId,
        answer: answer,
        gratitude: gratitude,
      );
      state = state.copyWith(
        status: RitualStatus.success,
        alreadyCompleted: true,
        myAnswer: answer,
        myGratitude: gratitude,
      );
    } catch (_) {
      state = state.copyWith(
        status: RitualStatus.error,
        error: 'No se pudo guardar el ritual',
      );
    }
  }

  Future<void> sendSyncInvite({
    required String coupleId,
    required String userId,
  }) async {
    await _service.sendSyncInvite(coupleId: coupleId, fromUserId: userId);
  }

  Future<void> startSyncHold({
    required String coupleId,
    required String userId,
  }) async {
    if (state.syncCompleted) return;
    await _service.setSyncHolding(
      coupleId: coupleId,
      userId: userId,
      isHolding: true,
    );
    if (!state.syncPartnerHolding) {
      await _service.sendSyncInvite(coupleId: coupleId, fromUserId: userId);
    }
  }

  Future<void> stopSyncHold({
    required String coupleId,
    required String userId,
  }) async {
    await _service.setSyncHolding(
      coupleId: coupleId,
      userId: userId,
      isHolding: false,
    );
  }

  void _recomputeSyncProgress() {
    if (state.syncCompleted) {
      _syncTick?.cancel();
      _syncTick = null;
      if (state.syncProgress != 1 || state.syncSecondsLeft != 0) {
        state = state.copyWith(syncProgress: 1, syncSecondsLeft: 0);
      }
      return;
    }

    if (!state.syncMeHolding ||
        !state.syncPartnerHolding ||
        _myHoldSinceMs == null ||
        _partnerHoldSinceMs == null) {
      _syncTick?.cancel();
      _syncTick = null;
      if (state.syncProgress != 0 ||
          state.syncSecondsLeft != AppConstants.syncRitualSeconds) {
        state = state.copyWith(
          syncProgress: 0,
          syncSecondsLeft: AppConstants.syncRitualSeconds,
        );
      }
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final overlapMs = now -
        (_myHoldSinceMs! > _partnerHoldSinceMs!
            ? _myHoldSinceMs!
            : _partnerHoldSinceMs!);
    final overlapSeconds = overlapMs / 1000.0;
    final clampedSeconds =
        overlapSeconds.clamp(0, AppConstants.syncRitualSeconds.toDouble());
    final progress = clampedSeconds / AppConstants.syncRitualSeconds;
    final secondsLeft = (AppConstants.syncRitualSeconds - clampedSeconds)
        .ceil()
        .clamp(0, AppConstants.syncRitualSeconds);

    state = state.copyWith(syncProgress: progress, syncSecondsLeft: secondsLeft);

    _syncTick ??= Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!ref.mounted) return;
      _recomputeSyncProgress();
    });

    if (clampedSeconds >= AppConstants.syncRitualSeconds &&
        !_syncCompletionInFlight) {
      _completeSyncIfNeeded();
    }
  }

  Future<void> _completeSyncIfNeeded() async {
    final coupleId = _coupleId;
    final userId = _userId;
    final partnerUserId = _partnerUserId;
    if (coupleId == null || userId == null || partnerUserId == null) return;

    _syncCompletionInFlight = true;
    try {
      await _service.completeSyncSession(
        coupleId: coupleId,
        userId: userId,
        partnerUserId: partnerUserId,
      );
    } finally {
      _syncCompletionInFlight = false;
    }
  }
}

final ritualProvider =
    NotifierProvider<RitualNotifier, RitualState>(RitualNotifier.new);
