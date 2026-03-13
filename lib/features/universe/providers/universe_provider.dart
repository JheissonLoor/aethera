import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Notifier, NotifierProvider;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:aethera/core/services/couple_service.dart';
import 'package:aethera/core/services/offline_sync_queue_service.dart';
import 'package:aethera/features/universe/domain/universe_flow_helpers.dart';
import 'package:aethera/shared/models/couple_model.dart';
import 'package:aethera/shared/models/emotion_model.dart';
import 'package:aethera/shared/models/memory_model.dart';
import 'package:aethera/shared/models/goal_model.dart';
import 'package:aethera/shared/models/time_capsule_model.dart';
import 'package:aethera/shared/models/daily_question_model.dart';
import 'package:aethera/shared/models/wish_model.dart';
import 'package:aethera/core/constants/app_constants.dart';
import 'package:aethera/core/constants/telemetry_events.dart';
import 'package:aethera/core/services/presence_service.dart';
import 'package:aethera/core/services/notification_service.dart';
import 'package:aethera/core/services/telemetry_service.dart';
import 'package:aethera/core/utils/streak_utils.dart';

// ─── Estado ───────────────────────────────────────────────────────────────────

class UniverseAppState {
  final CoupleModel? couple;
  final List<MemoryModel> memories;
  final List<GoalModel> goals;
  final List<TimeCapsuleModel> capsules;
  final String? currentUserId;
  final DailyQuestionModel? dailyQuestion;
  final bool isSyncConnected;
  final int pendingSyncActions;
  final bool partnerOnline;
  final bool receivedPulse;
  final bool newMemoryFromPartner;
  final bool isLoading;
  final String? emotionFeedback;

  /// Incoming wish from partner, not yet seen
  final WishModel? incomingWish;

  /// Pending fullscreen cutscene for a newly unlocked cosmic event.
  final String? cosmicEventName;
  final String? cosmicEventMemoryId;

  /// Consecutive days both users checked in
  final int streakDays;

  const UniverseAppState({
    this.couple,
    this.memories = const [],
    this.goals = const [],
    this.capsules = const [],
    this.currentUserId,
    this.dailyQuestion,
    this.isSyncConnected = true,
    this.pendingSyncActions = 0,
    this.partnerOnline = false,
    this.receivedPulse = false,
    this.newMemoryFromPartner = false,
    this.isLoading = true,
    this.emotionFeedback,
    this.incomingWish,
    this.cosmicEventName,
    this.cosmicEventMemoryId,
    this.streakDays = 0,
  });

  String get combinedMood => couple?.combinedEmotion ?? 'neutral';
  int get connectionStrength => couple?.connectionStrength ?? 0;
  int get universeLevel => couple?.universeState.level ?? 1;
  String? get partnerUserId {
    final me = currentUserId;
    final pair = couple;
    if (me == null || pair == null) return null;
    if (pair.user1Id == me) return pair.user2Id.isEmpty ? null : pair.user2Id;
    return pair.user1Id.isEmpty ? null : pair.user1Id;
  }

  bool get hasAnsweredDailyQuestion =>
      dailyQuestion?.isAnsweredBy(currentUserId) ?? false;
  bool get isDailyQuestionRevealed => dailyQuestion?.isRevealed ?? false;
  String? get myDailyQuestionAnswer => dailyQuestion?.answerBy(currentUserId);
  String? get partnerDailyQuestionAnswer =>
      dailyQuestion?.answerBy(partnerUserId);
  bool get showAurora =>
      partnerOnline || receivedPulse || connectionStrength >= 60;

  UniverseAppState copyWith({
    CoupleModel? couple,
    List<MemoryModel>? memories,
    List<GoalModel>? goals,
    List<TimeCapsuleModel>? capsules,
    String? currentUserId,
    bool clearCurrentUserId = false,
    DailyQuestionModel? dailyQuestion,
    bool clearDailyQuestion = false,
    bool? isSyncConnected,
    int? pendingSyncActions,
    bool? partnerOnline,
    bool? receivedPulse,
    bool? newMemoryFromPartner,
    bool? isLoading,
    String? emotionFeedback,
    bool clearEmotionFeedback = false,
    WishModel? incomingWish,
    bool clearIncomingWish = false,
    String? cosmicEventName,
    String? cosmicEventMemoryId,
    bool clearCosmicEvent = false,
    int? streakDays,
  }) => UniverseAppState(
    couple: couple ?? this.couple,
    memories: memories ?? this.memories,
    goals: goals ?? this.goals,
    capsules: capsules ?? this.capsules,
    currentUserId:
        clearCurrentUserId ? null : (currentUserId ?? this.currentUserId),
    dailyQuestion:
        clearDailyQuestion ? null : (dailyQuestion ?? this.dailyQuestion),
    isSyncConnected: isSyncConnected ?? this.isSyncConnected,
    pendingSyncActions: pendingSyncActions ?? this.pendingSyncActions,
    partnerOnline: partnerOnline ?? this.partnerOnline,
    receivedPulse: receivedPulse ?? this.receivedPulse,
    newMemoryFromPartner: newMemoryFromPartner ?? this.newMemoryFromPartner,
    isLoading: isLoading ?? this.isLoading,
    emotionFeedback:
        clearEmotionFeedback ? null : (emotionFeedback ?? this.emotionFeedback),
    incomingWish:
        clearIncomingWish ? null : (incomingWish ?? this.incomingWish),
    cosmicEventName:
        clearCosmicEvent ? null : (cosmicEventName ?? this.cosmicEventName),
    cosmicEventMemoryId:
        clearCosmicEvent
            ? null
            : (cosmicEventMemoryId ?? this.cosmicEventMemoryId),
    streakDays: streakDays ?? this.streakDays,
  );
}

// ─── Notificador ──────────────────────────────────────────────────────────────

class UniverseNotifier extends Notifier<UniverseAppState> {
  @override
  UniverseAppState build() {
    // If build is re-executed, avoid duplicated listeners/timers.
    _disposeResources();
    ref.onDispose(_disposeResources);
    _init();
    return const UniverseAppState();
  }

  final _db = FirebaseFirestore.instance;
  final _rtdb = FirebaseDatabase.instance;
  final _coupleService = CoupleService();
  final _presence = PresenceService();
  final _offlineQueue = OfflineSyncQueueService();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _coupleSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _memoriesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _goalsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _capsulesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _dailyQuestionSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _wishesSub;
  StreamSubscription<DatabaseEvent>? _syncConnectionSub;
  StreamSubscription<bool>? _partnerOnlineSub;
  StreamSubscription<bool>? _pulseSub;

  Timer? _pulseTimer;
  Timer? _memoryNotifTimer;

  bool _isUser1 = false;
  bool _sessionPointsAwarded = false;
  bool _memoriesInitialized = false;
  final Set<String> _seenCosmicEventMemoryIds = <String>{};
  String? _myUserId;
  String? _coupleId;
  bool _isFlushingQueuedActions = false;

  Future<void> _trackEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    await AppTelemetryService.instance.logEvent(name, parameters: parameters);
  }

  Future<void> _trackNonFatal({
    required String reason,
    required Object error,
    required StackTrace stackTrace,
    Map<String, Object?> context = const {},
  }) async {
    await AppTelemetryService.instance.recordNonFatal(
      reason: reason,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  bool _isPermanentSyncError(Object error) {
    if (error is UnsupportedError ||
        error is ArgumentError ||
        error is FormatException) {
      return true;
    }

    if (error is FirebaseException) {
      const permanentCodes = <String>{
        'permission-denied',
        'unauthenticated',
        'invalid-argument',
        'failed-precondition',
        'not-found',
        'already-exists',
      };
      return permanentCodes.contains(error.code.toLowerCase());
    }

    return false;
  }

  // ── Inicio ─────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    _sessionPointsAwarded = false;
    _memoriesInitialized = false;
    _seenCosmicEventMemoryIds.clear();
    await _updatePendingSyncCount();
    _subscribeSyncConnectivity();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _fallbackToMockOrEmpty();
      return;
    }
    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final coupleId = userDoc.data()?['coupleId'] as String?;
      if (coupleId == null || coupleId.isEmpty) {
        _fallbackToMockOrEmpty();
        return;
      }

      // Load initial couple data
      final coupleSnap = await _db.collection('couples').doc(coupleId).get();
      if (!coupleSnap.exists || coupleSnap.data() == null) {
        _fallbackToMockOrEmpty();
        return;
      }
      final initialCoupleData = coupleSnap.data()!;
      state = state.copyWith(
        couple: CoupleModel.fromMap(coupleSnap.id, initialCoupleData),
        streakDays: initialCoupleData['streakDays'] as int? ?? 0,
        currentUserId: user.uid,
        isLoading: false,
      );

      _myUserId = user.uid;
      _coupleId = coupleId;
      _isUser1 = initialCoupleData['user1Id'] == user.uid;

      final partnerId = initialCoupleData['user2Id'] as String? ?? '';
      if (partnerId.isNotEmpty) {
        _subscribeToDailyQuestion(coupleId: coupleId);
      } else {
        state = state.copyWith(clearDailyQuestion: true);
      }

      // Real-time couple listener
      _coupleSub = _db.collection('couples').doc(coupleId).snapshots().listen((
        snap,
      ) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          state = state.copyWith(
            couple: CoupleModel.fromMap(snap.id, data),
            streakDays: data['streakDays'] as int? ?? state.streakDays,
          );
        }
      });

      // Real-time memories stream
      _memoriesSub = _db
          .collection('memories')
          .where('coupleId', isEqualTo: coupleId)
          .snapshots()
          .listen((snap) {
            final newMemories =
                snap.docs
                    .map((d) => MemoryModel.fromMap(d.id, d.data()))
                    .toList();

            var isNewFromPartner = false;
            String? cosmicEventName;
            String? cosmicEventMemoryId;
            if (_memoriesInitialized) {
              final previousIds = state.memories.map((m) => m.id).toSet();
              for (final memory in newMemories) {
                if (previousIds.contains(memory.id)) continue;

                if (memory.type == 'relic') {
                  if (!_seenCosmicEventMemoryIds.contains(memory.id)) {
                    _seenCosmicEventMemoryIds.add(memory.id);
                    cosmicEventName =
                        memory.title.isNotEmpty
                            ? memory.title
                            : 'Evento Cósmico';
                    cosmicEventMemoryId = memory.id;
                  }
                  continue;
                }

                final authorId = memory.createdByUserId;
                if (authorId == null || authorId != user.uid) {
                  isNewFromPartner = true;
                }
              }
            } else {
              for (final memory in newMemories) {
                if (memory.type == 'relic') {
                  _seenCosmicEventMemoryIds.add(memory.id);
                }
              }
            }
            _memoriesInitialized = true;

            state = state.copyWith(
              memories: newMemories,
              newMemoryFromPartner: isNewFromPartner,
              cosmicEventName: cosmicEventName,
              cosmicEventMemoryId: cosmicEventMemoryId,
            );
            if (isNewFromPartner) {
              _memoryNotifTimer?.cancel();
              _memoryNotifTimer = Timer(const Duration(seconds: 4), () {
                if (ref.mounted) {
                  state = state.copyWith(newMemoryFromPartner: false);
                }
              });
              NotificationService.instance.showNewMemoryNotification();
            }
          });

      // Real-time goals stream
      _goalsSub = _db
          .collection('goals')
          .where('coupleId', isEqualTo: coupleId)
          .snapshots()
          .listen((snap) {
            state = state.copyWith(
              goals:
                  snap.docs
                      .map((d) => GoalModel.fromMap(d.id, d.data()))
                      .toList(),
            );
          });

      // Real-time time capsules stream
      _capsulesSub = _db
          .collection(AppConstants.colCapsules)
          .where('coupleId', isEqualTo: coupleId)
          .snapshots()
          .listen((snap) {
            final capsules =
                snap.docs
                    .map((d) => TimeCapsuleModel.fromMap(d.id, d.data()))
                    .toList()
                  ..sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
            state = state.copyWith(capsules: capsules);
          });

      // Real-time wishes stream - show incoming wish from partner
      _wishesSub = _db
          .collection('wishes')
          .where('coupleId', isEqualTo: coupleId)
          .where('seen', isEqualTo: false)
          .snapshots()
          .listen((snap) {
            // Find wishes NOT from me that are unseen
            final incoming =
                snap.docs
                    .where((d) => d.data()['fromUserId'] != user.uid)
                    .map((d) => WishModel.fromMap(d.id, d.data()))
                    .toList();
            if (incoming.isNotEmpty) {
              state = state.copyWith(incomingWish: incoming.first);
            }
          });

      // Presence
      await _presence.connect(
        coupleId: coupleId,
        userId: user.uid,
        isUser1: _isUser1,
      );
      _subscribeToPresence();
      unawaited(
        _trackEvent(
          'universe_loaded',
          parameters: {'source': 'firebase', 'solo_mode': partnerId.isEmpty},
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _trackNonFatal(
          reason: 'universe_init_failed',
          error: error,
          stackTrace: stackTrace,
        ),
      );
      _fallbackToMockOrEmpty();
    }
  }

  Future<void> _updatePendingSyncCount() async {
    final count = await _offlineQueue.count();
    if (ref.mounted) {
      state = state.copyWith(pendingSyncActions: count);
    }
  }

  void _subscribeSyncConnectivity() {
    _syncConnectionSub?.cancel();
    _syncConnectionSub = _rtdb.ref('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value == true;
      final wasConnected = state.isSyncConnected;
      state = state.copyWith(isSyncConnected: connected);
      if (connected && (!wasConnected || state.pendingSyncActions > 0)) {
        unawaited(_flushQueuedActions());
      }
    });
  }

  Future<void> _enqueueSyncAction({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final action = OfflineSyncAction(
      id: const Uuid().v4(),
      type: type,
      payload: payload,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    final result = await _offlineQueue.enqueue(action);
    if (ref.mounted) {
      state = state.copyWith(pendingSyncActions: result.queueSize);
    }
    unawaited(
      _trackEvent(
        TelemetryEvents.syncActionQueued,
        parameters: {'action_type': type, 'queue_size': result.queueSize},
      ),
    );
    if (result.droppedCount > 0) {
      unawaited(
        _trackEvent(
          TelemetryEvents.kpiQueueDrop,
          parameters: {
            'dropped': result.droppedCount,
            'remaining': result.queueSize,
            'drop_reason': 'queue_overflow',
          },
        ),
      );
    }
  }

  Future<void> _executeOrQueue({
    required String type,
    required Map<String, dynamic> payload,
    required Future<void> Function() onlineTask,
  }) async {
    if (!state.isSyncConnected) {
      await _enqueueSyncAction(type: type, payload: payload);
      return;
    }

    try {
      await onlineTask();
      unawaited(
        _trackEvent(
          TelemetryEvents.syncActionSent,
          parameters: {'action_type': type},
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _trackNonFatal(
          reason: 'sync_online_task_failed',
          error: error,
          stackTrace: stackTrace,
          context: {'action_type': type},
        ),
      );
      final connectedSnap = await _rtdb.ref('.info/connected').get();
      final connectedNow = connectedSnap.value == true;
      state = state.copyWith(isSyncConnected: connectedNow);
      if (!connectedNow) {
        await _enqueueSyncAction(type: type, payload: payload);
        unawaited(
          _trackEvent(
            TelemetryEvents.syncActionRequeued,
            parameters: {'action_type': type},
          ),
        );
        return;
      }
      unawaited(
        _trackEvent(
          TelemetryEvents.kpiSyncFailure,
          parameters: {
            'stage': 'online_task',
            'attempted': 1,
            'failed': 1,
            'failed_transient': 0,
            'dropped': 0,
          },
        ),
      );
      rethrow;
    }
  }

  Future<void> _flushQueuedActions() async {
    if (_isFlushingQueuedActions || !state.isSyncConnected) return;
    _isFlushingQueuedActions = true;
    try {
      final pending = await _offlineQueue.load();
      if (pending.isEmpty) {
        await _updatePendingSyncCount();
        return;
      }

      final processed = <String>{};
      var successCount = 0;
      var transientFailureCount = 0;
      var droppedCount = 0;
      for (final action in pending) {
        try {
          await _runQueuedAction(action);
          processed.add(action.id);
          successCount++;
        } catch (error, stackTrace) {
          unawaited(
            _trackNonFatal(
              reason: 'sync_queue_action_failed',
              error: error,
              stackTrace: stackTrace,
              context: {'action_type': action.type},
            ),
          );
          if (_isPermanentSyncError(error)) {
            processed.add(action.id);
            droppedCount++;
            unawaited(
              _trackEvent(
                TelemetryEvents.syncActionDropped,
                parameters: {'action_type': action.type},
              ),
            );
            continue;
          }

          final connectedSnap = await _rtdb.ref('.info/connected').get();
          final connectedNow = connectedSnap.value == true;
          state = state.copyWith(isSyncConnected: connectedNow);
          transientFailureCount++;
          // Conserva la acción en cola para reintento posterior.
          break;
        }
      }

      if (processed.isNotEmpty) {
        await _offlineQueue.removeByIds(processed);
      }
      await _updatePendingSyncCount();
      unawaited(
        _trackEvent(
          TelemetryEvents.syncQueueFlushed,
          parameters: {
            'attempted': pending.length,
            'success': successCount,
            'failed_transient': transientFailureCount,
            'dropped': droppedCount,
            'remaining': state.pendingSyncActions,
          },
        ),
      );
      final failedCount = transientFailureCount + droppedCount;
      if (failedCount > 0) {
        unawaited(
          _trackEvent(
            TelemetryEvents.kpiSyncFailure,
            parameters: {
              'stage': 'queue_flush',
              'attempted': pending.length,
              'failed': failedCount,
              'failed_transient': transientFailureCount,
              'dropped': droppedCount,
            },
          ),
        );
      }
      if (droppedCount > 0) {
        unawaited(
          _trackEvent(
            TelemetryEvents.kpiQueueDrop,
            parameters: {
              'dropped': droppedCount,
              'remaining': state.pendingSyncActions,
              'drop_reason': 'permanent_error',
            },
          ),
        );
      }
    } finally {
      _isFlushingQueuedActions = false;
    }
  }

  Future<void> _runQueuedAction(OfflineSyncAction action) async {
    switch (action.type) {
      case 'updateEmotion':
        await _persistEmotion(action.payload['mood'] as String? ?? '');
        return;
      case 'addMemory':
        await _persistMemoryFromPayload(action.payload);
        return;
      case 'addGoal':
        await _persistGoalFromPayload(action.payload);
        return;
      case 'updateGoalProgress':
        await _persistGoalProgressFromPayload(action.payload);
        return;
      case 'sendWish':
        await _persistWishFromPayload(action.payload);
        return;
      case 'createTimeCapsule':
        await _persistCapsuleFromPayload(action.payload);
        return;
      case 'submitDailyAnswer':
        await _persistDailyAnswerFromPayload(action.payload);
        return;
      case 'sendPulse':
        await _persistPulseFromPayload(action.payload);
        return;
      case 'openTimeCapsule':
        await _persistOpenCapsuleFromPayload(action.payload);
        return;
      default:
        throw UnsupportedError('Tipo de accion no soportado: ${action.type}');
    }
  }

  void _subscribeToDailyQuestion({required String coupleId}) {
    _dailyQuestionSub?.cancel();
    final today = dayKey(DateTime.now());
    final docId = _dailyQuestionDocId(coupleId, today);
    final ref = _db.collection(AppConstants.colDailyQuestions).doc(docId);

    _dailyQuestionSub = ref.snapshots().listen((snap) {
      final data = snap.data();
      if (snap.exists && data != null) {
        state = state.copyWith(
          dailyQuestion: DailyQuestionModel.fromMap(snap.id, data),
        );
        return;
      }

      final seeded = DailyQuestionModel(
        id: docId,
        coupleId: coupleId,
        dayKey: today,
        question: _preguntaParaDia(today),
        answers: const <String, String>{},
        createdAt: DateTime.now(),
      );

      state = state.copyWith(dailyQuestion: seeded);
      unawaited(_ensureDailyQuestionExists(ref: ref, question: seeded));
    });
  }

  Future<void> _ensureDailyQuestionExists({
    required DocumentReference<Map<String, dynamic>> ref,
    required DailyQuestionModel question,
  }) async {
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (snap.exists) return;
        tx.set(ref, question.toMap());
      });
    } catch (error, stackTrace) {
      unawaited(
        _trackNonFatal(
          reason: 'daily_question_seed_failed',
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  String _dailyQuestionDocId(String coupleId, String today) =>
      '${coupleId}_$today';

  String _preguntaParaDia(String today) {
    final pool = AppConstants.preguntasDiarias;
    if (pool.isEmpty) return '¿Cómo te sentiste hoy en nuestra relación?';
    final index = _hashEstable(today) % pool.length;
    return pool[index];
  }

  int _hashEstable(String input) {
    var hash = 0;
    for (final unit in input.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return hash;
  }

  void _subscribeToPresence() {
    _partnerOnlineSub = _presence.partnerOnlineStream().listen((online) {
      final justCameOnline = online && !state.partnerOnline;
      state = state.copyWith(partnerOnline: online);
      if (online && !_sessionPointsAwarded) {
        _sessionPointsAwarded = true;
        _awardSimultaneousPoints();
      }
      if (justCameOnline) {
        NotificationService.instance.showPartnerOnlineNotification();
      }
    });

    _pulseSub = _presence.incomingPulseStream().listen((hasPulse) {
      if (hasPulse && !state.receivedPulse) {
        _pulseTimer?.cancel();
        state = state.copyWith(receivedPulse: true);
        _pulseTimer = Timer(const Duration(seconds: 3), () {
          if (ref.mounted) state = state.copyWith(receivedPulse: false);
        });
        NotificationService.instance.showPulseNotification();
      }
    });
  }

  Future<void> _awardSimultaneousPoints() async {
    final coupleId = state.couple?.id;
    if (coupleId == null) return;
    await _db.collection('couples').doc(coupleId).update({
      'connectionStrength': FieldValue.increment(
        AppConstants.pointsSimultaneousOnline,
      ),
    });
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  Future<void> updateEmotion(String mood) async {
    if (state.couple == null) return;
    final emotion = EmotionModel.create(mood: mood);
    final updated =
        _isUser1
            ? state.couple!.copyWith(
              connectionStrength: (state.couple!.connectionStrength +
                      AppConstants.pointsDailyCheckin)
                  .clamp(0, AppConstants.maxConnectionStrength),
              user1Emotion: emotion,
            )
            : state.couple!.copyWith(
              connectionStrength: (state.couple!.connectionStrength +
                      AppConstants.pointsDailyCheckin)
                  .clamp(0, AppConstants.maxConnectionStrength),
              user2Emotion: emotion,
            );
    state = state.copyWith(couple: updated, emotionFeedback: mood);
    // Clear feedback after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (ref.mounted) state = state.copyWith(clearEmotionFeedback: true);
    });
    await _executeOrQueue(
      type: 'updateEmotion',
      payload: {'mood': mood},
      onlineTask: () => _persistEmotion(mood),
    );
    unawaited(_trackEvent('emotion_updated', parameters: {'mood': mood}));
  }

  Future<void> addMemory({
    required String title,
    required String description,
    required String type,
  }) async {
    final coupleId = _coupleId ?? state.couple?.id;
    final userId =
        _myUserId ??
        state.currentUserId ??
        FirebaseAuth.instance.currentUser?.uid;
    if (coupleId == null || userId == null) return;

    final memory = MemoryModel(
      id: const Uuid().v4(),
      coupleId: coupleId,
      type: type,
      title: title,
      description: description,
      createdByUserId: userId,
      createdAt: DateTime.now(),
      posX: 0.15 + (state.memories.length * 0.2) % 0.7,
      posY: 0.55 + (state.memories.length % 3) * 0.08,
    );

    state = state.copyWith(memories: [...state.memories, memory]);
    await _executeOrQueue(
      type: 'addMemory',
      payload: {
        'id': memory.id,
        'coupleId': memory.coupleId,
        'type': memory.type,
        'title': memory.title,
        'description': memory.description,
        'createdByUserId': memory.createdByUserId,
        'createdAt': memory.createdAt.millisecondsSinceEpoch,
        'posX': memory.posX,
        'posY': memory.posY,
      },
      onlineTask: () => _persistMemory(memory),
    );
    unawaited(_trackEvent('memory_added', parameters: {'memory_type': type}));
  }

  Future<void> addGoal({
    required String title,
    required String description,
    required String symbol,
    required DateTime targetDate,
  }) async {
    final coupleId = _coupleId ?? state.couple?.id;
    if (coupleId == null) return;

    final goal = GoalModel(
      id: const Uuid().v4(),
      coupleId: coupleId,
      title: title,
      description: description,
      targetDate: targetDate,
      progress: 0.0,
      symbol: symbol,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(goals: [...state.goals, goal]);
    await _executeOrQueue(
      type: 'addGoal',
      payload: {
        'id': goal.id,
        'coupleId': goal.coupleId,
        'title': goal.title,
        'description': goal.description,
        'targetDate': goal.targetDate.millisecondsSinceEpoch,
        'progress': goal.progress,
        'symbol': goal.symbol,
        'createdAt': goal.createdAt.millisecondsSinceEpoch,
      },
      onlineTask: () => _persistGoal(goal),
    );
    unawaited(_trackEvent('goal_added', parameters: {'symbol': symbol}));
  }

  Future<void> updateGoalProgress(String goalId, double newProgress) async {
    final coupleId = _coupleId ?? state.couple?.id;
    if (coupleId == null) return;

    final existing = state.goals.firstWhere((g) => g.id == goalId);
    final clamped = newProgress.clamp(0.0, 1.0);
    final isNowCompleted = clamped >= 1.0 && !existing.isCompleted;

    final updatedGoal = GoalModel(
      id: existing.id,
      coupleId: existing.coupleId,
      title: existing.title,
      description: existing.description,
      targetDate: existing.targetDate,
      progress: clamped,
      symbol: existing.symbol,
      createdAt: existing.createdAt,
      completedAt: isNowCompleted ? DateTime.now() : existing.completedAt,
    );
    state = state.copyWith(
      goals: state.goals.map((g) => g.id == goalId ? updatedGoal : g).toList(),
    );

    await _executeOrQueue(
      type: 'updateGoalProgress',
      payload: {'goalId': goalId, 'coupleId': coupleId, 'progress': clamped},
      onlineTask:
          () => _persistGoalProgress(
            goalId: goalId,
            coupleId: coupleId,
            progress: clamped,
          ),
    );
    unawaited(
      _trackEvent(
        'goal_progress_updated',
        parameters: {'completed': isNowCompleted, 'progress': clamped},
      ),
    );
  }

  Future<void> sendPulse() async {
    final coupleId = _coupleId ?? state.couple?.id;
    final userId = _myUserId ?? state.currentUserId;
    if (coupleId == null || userId == null) return;

    await _executeOrQueue(
      type: 'sendPulse',
      payload: {'coupleId': coupleId, 'userId': userId},
      onlineTask: () => _presence.sendPulse(),
    );
    unawaited(_trackEvent('pulse_sent'));
  }

  /// Se une al universo de la pareja usando su código de invitación.
  /// Se usa cuando el usuario está en modo solo y quiere conectarse.
  /// Devuelve un mensaje de error en caso de fallo, o null en éxito.
  Future<String?> joinPartner(String inviteCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'No hay sesión activa';
    try {
      await _coupleService.joinCouple(inviteCode, user.uid);
      // Re-initialize to pick up new couple streams
      _coupleSub?.cancel();
      _memoriesSub?.cancel();
      _goalsSub?.cancel();
      _capsulesSub?.cancel();
      _dailyQuestionSub?.cancel();
      _wishesSub?.cancel();
      _syncConnectionSub?.cancel();
      _partnerOnlineSub?.cancel();
      _pulseSub?.cancel();
      _coupleSub = null;
      _memoriesSub = null;
      _goalsSub = null;
      _capsulesSub = null;
      _dailyQuestionSub = null;
      _wishesSub = null;
      _syncConnectionSub = null;
      _partnerOnlineSub = null;
      _pulseSub = null;
      state = const UniverseAppState(isLoading: true);
      await _init();
      unawaited(_trackEvent('pair_join_success'));
      return null;
    } catch (error, stackTrace) {
      unawaited(
        _trackNonFatal(
          reason: 'pair_join_failed',
          error: error,
          stackTrace: stackTrace,
        ),
      );
      unawaited(_trackEvent('pair_join_failed'));
      return error.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Envía un deseo que viaja como estrella fugaz al universo de la pareja.
  Future<void> sendWish(String message) async {
    final coupleId = _coupleId ?? state.couple?.id;
    final userId = _myUserId ?? state.currentUserId;
    final normalized = message.trim();
    if (coupleId == null || userId == null || normalized.isEmpty) return;

    final id = const Uuid().v4();
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    await _executeOrQueue(
      type: 'sendWish',
      payload: {
        'id': id,
        'coupleId': coupleId,
        'fromUserId': userId,
        'message': normalized,
        'createdAt': createdAt,
      },
      onlineTask:
          () => _persistWish(
            id: id,
            coupleId: coupleId,
            userId: userId,
            message: normalized,
            createdAtMs: createdAt,
          ),
    );
    unawaited(_trackEvent('wish_sent'));
  }

  Future<void> submitDailyQuestionAnswer(String answer) async {
    final round = state.dailyQuestion;
    final userId =
        _myUserId ??
        state.currentUserId ??
        FirebaseAuth.instance.currentUser?.uid;
    if (round == null || userId == null) return;

    final normalized = answer.trim();
    if (normalized.isEmpty) return;

    final optimisticRound = aplicarRespuestaDiaria(
      pregunta: round,
      userId: userId,
      respuesta: normalized,
    );
    state = state.copyWith(dailyQuestion: optimisticRound);

    await _executeOrQueue(
      type: 'submitDailyAnswer',
      payload: {'roundId': round.id, 'userId': userId, 'answer': normalized},
      onlineTask:
          () => _persistDailyAnswer(
            roundId: round.id,
            userId: userId,
            answer: normalized,
          ),
    );
    unawaited(
      _trackEvent(
        'daily_answer_submitted',
        parameters: {'revealed': optimisticRound.isRevealed},
      ),
    );
  }

  /// Crea una cápsula del tiempo que se desbloquea en el futuro.
  Future<void> createTimeCapsule({
    required String message,
    required DateTime unlockAt,
    String title = '',
  }) async {
    final coupleId = _coupleId ?? state.couple?.id;
    final userId =
        _myUserId ??
        state.currentUserId ??
        FirebaseAuth.instance.currentUser?.uid;
    final trimmedMessage = message.trim();
    if (coupleId == null || userId == null || trimmedMessage.isEmpty) return;
    if (!unlockAt.isAfter(DateTime.now())) return;

    final capsule = TimeCapsuleModel(
      id: const Uuid().v4(),
      coupleId: coupleId,
      title: title.trim(),
      message: trimmedMessage,
      createdByUserId: userId,
      createdAt: DateTime.now(),
      unlockAt: unlockAt,
      openedByUserIds: const <String>[],
    );
    state = state.copyWith(
      capsules: [...state.capsules, capsule]
        ..sort((a, b) => a.unlockAt.compareTo(b.unlockAt)),
    );

    await _executeOrQueue(
      type: 'createTimeCapsule',
      payload: {
        'id': capsule.id,
        'coupleId': capsule.coupleId,
        'title': capsule.title,
        'message': capsule.message,
        'createdByUserId': capsule.createdByUserId,
        'createdAt': capsule.createdAt.millisecondsSinceEpoch,
        'unlockAt': capsule.unlockAt.millisecondsSinceEpoch,
      },
      onlineTask: () => _persistCapsule(capsule),
    );
    unawaited(_trackEvent('capsule_created'));
  }

  /// Abre una cápsula para el usuario actual y devuelve su contenido.
  Future<TimeCapsuleModel?> openTimeCapsule(String capsuleId) async {
    final userId =
        _myUserId ??
        state.currentUserId ??
        FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || capsuleId.isEmpty) return null;

    final capsule = _capsuleById(capsuleId);
    if (capsule == null) return null;
    final optimisticCapsule = abrirCapsulaOptimista(
      capsula: capsule,
      userId: userId,
    );
    if (optimisticCapsule == null) return null;

    if (!capsule.isOpenedBy(userId)) {
      _replaceCapsule(optimisticCapsule);

      try {
        await _executeOrQueue(
          type: 'openTimeCapsule',
          payload: {'capsuleId': capsuleId, 'userId': userId},
          onlineTask:
              () => _persistOpenCapsule(capsuleId: capsuleId, userId: userId),
        );
      } catch (error, stackTrace) {
        unawaited(
          _trackNonFatal(
            reason: 'open_capsule_failed',
            error: error,
            stackTrace: stackTrace,
            context: {'capsule_id': capsuleId},
          ),
        );
        if (!_isPermanentSyncError(error)) {
          await _enqueueSyncAction(
            type: 'openTimeCapsule',
            payload: {'capsuleId': capsuleId, 'userId': userId},
          );
          unawaited(
            _trackEvent(
              TelemetryEvents.syncActionRequeued,
              parameters: {'action_type': 'openTimeCapsule'},
            ),
          );
        }
        return optimisticCapsule;
      }
    }
    unawaited(_trackEvent('capsule_opened'));
    return _capsuleById(capsuleId);
  }

  void _replaceCapsule(TimeCapsuleModel capsule) {
    final updated =
        state.capsules
            .map((item) => item.id == capsule.id ? capsule : item)
            .toList()
          ..sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
    state = state.copyWith(capsules: updated);
  }

  Future<void> _persistEmotion(String mood) async {
    final couple = state.couple;
    if (couple == null) return;
    final emotion = EmotionModel.create(mood: mood);
    final emotionField = _isUser1 ? 'user1Emotion' : 'user2Emotion';
    await _db.collection('couples').doc(couple.id).update({
      emotionField: emotion.toMap(),
      'connectionStrength': couple.connectionStrength,
    });
    await _tryIncrementStreak();
  }

  Future<void> _persistMemory(MemoryModel memory) async {
    await _db.collection('memories').doc(memory.id).set(memory.toMap());
    await _db.collection('couples').doc(memory.coupleId).update({
      'connectionStrength': FieldValue.increment(AppConstants.pointsAddMemory),
    });
  }

  Future<void> _persistGoal(GoalModel goal) async {
    await _db.collection('goals').doc(goal.id).set(goal.toMap());
  }

  Future<void> _persistGoalProgress({
    required String goalId,
    required String coupleId,
    required double progress,
  }) async {
    final clamped = progress.clamp(0.0, 1.0);
    GoalModel? existing;
    for (final goal in state.goals) {
      if (goal.id == goalId) {
        existing = goal;
        break;
      }
    }
    final isNowCompleted =
        existing != null && clamped >= 1.0 && !existing.isCompleted;

    final data = <String, dynamic>{'progress': clamped};
    if (isNowCompleted) {
      data['completedAt'] = DateTime.now().millisecondsSinceEpoch;
    }
    await _db.collection('goals').doc(goalId).update(data);
    if (isNowCompleted) {
      await _db.collection('couples').doc(coupleId).update({
        'connectionStrength': FieldValue.increment(
          AppConstants.pointsGoalComplete,
        ),
      });
    }
  }

  Future<void> _persistWish({
    required String id,
    required String coupleId,
    required String userId,
    required String message,
    required int createdAtMs,
  }) async {
    await _db.collection('wishes').doc(id).set({
      'id': id,
      'coupleId': coupleId,
      'message': message,
      'fromUserId': userId,
      'createdAt': createdAtMs,
      'seen': false,
    });
  }

  Future<void> _persistCapsule(TimeCapsuleModel capsule) async {
    await _db
        .collection(AppConstants.colCapsules)
        .doc(capsule.id)
        .set(capsule.toMap());
  }

  Future<void> _persistOpenCapsule({
    required String capsuleId,
    required String userId,
  }) async {
    await _db.collection(AppConstants.colCapsules).doc(capsuleId).update({
      'openedByUserIds': FieldValue.arrayUnion(<String>[userId]),
    });
  }

  Future<void> _persistDailyAnswer({
    required String roundId,
    required String userId,
    required String answer,
  }) async {
    final roundRef = _db
        .collection(AppConstants.colDailyQuestions)
        .doc(roundId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(roundRef);
      final data = snap.data();
      if (data == null) return;

      final current = DailyQuestionModel.fromMap(snap.id, data);
      final answers = Map<String, String>.from(current.answers);
      answers[userId] = answer;

      final updates = <String, dynamic>{'answers': answers};
      if (answers.length >= 2 && current.revealedAt == null) {
        updates['revealedAt'] = DateTime.now().millisecondsSinceEpoch;
      }
      tx.update(roundRef, updates);
    });
  }

  Future<void> _persistMemoryFromPayload(Map<String, dynamic> payload) async {
    final memory = MemoryModel(
      id: payload['id'] as String? ?? const Uuid().v4(),
      coupleId: payload['coupleId'] as String? ?? '',
      type: payload['type'] as String? ?? 'constellation',
      title: payload['title'] as String? ?? '',
      description: payload['description'] as String? ?? '',
      createdByUserId: payload['createdByUserId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        payload['createdAt'] as int? ?? 0,
      ),
      posX: (payload['posX'] as num?)?.toDouble() ?? 0.5,
      posY: (payload['posY'] as num?)?.toDouble() ?? 0.5,
    );
    if (memory.coupleId.isEmpty) return;
    await _persistMemory(memory);
  }

  Future<void> _persistGoalFromPayload(Map<String, dynamic> payload) async {
    final goal = GoalModel(
      id: payload['id'] as String? ?? const Uuid().v4(),
      coupleId: payload['coupleId'] as String? ?? '',
      title: payload['title'] as String? ?? '',
      description: payload['description'] as String? ?? '',
      targetDate: DateTime.fromMillisecondsSinceEpoch(
        payload['targetDate'] as int? ?? 0,
      ),
      progress: (payload['progress'] as num?)?.toDouble() ?? 0.0,
      symbol: payload['symbol'] as String? ?? 'lighthouse',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        payload['createdAt'] as int? ?? 0,
      ),
    );
    if (goal.coupleId.isEmpty) return;
    await _persistGoal(goal);
  }

  Future<void> _persistGoalProgressFromPayload(
    Map<String, dynamic> payload,
  ) async {
    final goalId = payload['goalId'] as String? ?? '';
    final coupleId = payload['coupleId'] as String? ?? '';
    final progress = (payload['progress'] as num?)?.toDouble() ?? 0.0;
    if (goalId.isEmpty || coupleId.isEmpty) return;
    await _persistGoalProgress(
      goalId: goalId,
      coupleId: coupleId,
      progress: progress,
    );
  }

  Future<void> _persistWishFromPayload(Map<String, dynamic> payload) async {
    final id = payload['id'] as String? ?? '';
    final coupleId = payload['coupleId'] as String? ?? '';
    final userId = payload['fromUserId'] as String? ?? '';
    final message = payload['message'] as String? ?? '';
    final createdAtMs = payload['createdAt'] as int? ?? 0;
    if (id.isEmpty || coupleId.isEmpty || userId.isEmpty || message.isEmpty) {
      return;
    }
    await _persistWish(
      id: id,
      coupleId: coupleId,
      userId: userId,
      message: message,
      createdAtMs: createdAtMs,
    );
  }

  Future<void> _persistCapsuleFromPayload(Map<String, dynamic> payload) async {
    final capsule = TimeCapsuleModel(
      id: payload['id'] as String? ?? const Uuid().v4(),
      coupleId: payload['coupleId'] as String? ?? '',
      title: payload['title'] as String? ?? '',
      message: payload['message'] as String? ?? '',
      createdByUserId: payload['createdByUserId'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        payload['createdAt'] as int? ?? 0,
      ),
      unlockAt: DateTime.fromMillisecondsSinceEpoch(
        payload['unlockAt'] as int? ?? 0,
      ),
      openedByUserIds: const <String>[],
    );
    if (capsule.coupleId.isEmpty || capsule.createdByUserId.isEmpty) return;
    await _persistCapsule(capsule);
  }

  Future<void> _persistDailyAnswerFromPayload(
    Map<String, dynamic> payload,
  ) async {
    final roundId = payload['roundId'] as String? ?? '';
    final userId = payload['userId'] as String? ?? '';
    final answer = payload['answer'] as String? ?? '';
    if (roundId.isEmpty || userId.isEmpty || answer.isEmpty) return;
    await _persistDailyAnswer(roundId: roundId, userId: userId, answer: answer);
  }

  Future<void> _persistPulseFromPayload(Map<String, dynamic> payload) async {
    final coupleId = payload['coupleId'] as String? ?? '';
    final userId = payload['userId'] as String? ?? '';
    if (coupleId.isEmpty || userId.isEmpty) return;
    await _rtdb.ref('presence/$coupleId/pulse').set({
      'from': userId,
      'at': ServerValue.timestamp,
    });
  }

  Future<void> _persistOpenCapsuleFromPayload(
    Map<String, dynamic> payload,
  ) async {
    final capsuleId = payload['capsuleId'] as String? ?? '';
    final userId = payload['userId'] as String? ?? '';
    if (capsuleId.isEmpty || userId.isEmpty) return;
    await _persistOpenCapsule(capsuleId: capsuleId, userId: userId);
  }

  /// Marca el deseo entrante como visto y cierra el overlay de estrella fugaz.
  Future<void> markWishSeen() async {
    final wish = state.incomingWish;
    if (wish == null) return;
    state = state.copyWith(clearIncomingWish: true);
    await _db.collection('wishes').doc(wish.id).update({'seen': true});
    unawaited(_trackEvent('wish_seen'));
  }

  void dismissCosmicEventCutscene() {
    state = state.copyWith(clearCosmicEvent: true);
  }

  /// Incrementa la racha si ambas personas hicieron check-in hoy.
  Future<void> _tryIncrementStreak() async {
    final coupleId = _coupleId ?? state.couple?.id;
    if (coupleId == null) return;
    final todayStr = dayKey(DateTime.now());
    final yesterdayStr = dayKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final myCheckinField = _isUser1 ? 'lastCheckinUser1' : 'lastCheckinUser2';
    final partnerCheckinField =
        _isUser1 ? 'lastCheckinUser2' : 'lastCheckinUser1';

    final coupleRef = _db.collection('couples').doc(coupleId);
    int? newStreak;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(coupleRef);
      final data = snap.data();
      if (data == null) return;

      final lastStreakDate = data['lastStreakDate'] as String?;
      final partnerCheckinDate = data[partnerCheckinField] as String?;
      final currentStreak = data['streakDays'] as int? ?? 0;

      final updates = <String, dynamic>{myCheckinField: todayStr};

      final shouldIncrement = shouldIncrementStreakToday(
        lastStreakDate: lastStreakDate,
        user1CheckinDate: _isUser1 ? todayStr : partnerCheckinDate,
        user2CheckinDate: _isUser1 ? partnerCheckinDate : todayStr,
        todayKey: todayStr,
      );

      if (shouldIncrement) {
        newStreak = nextStreakValue(
          lastStreakDate: lastStreakDate,
          currentStreak: currentStreak,
          yesterdayKey: yesterdayStr,
        );
        updates['streakDays'] = newStreak;
        updates['lastStreakDate'] = todayStr;
      }

      tx.update(coupleRef, updates);
    });

    if (ref.mounted && newStreak != null) {
      state = state.copyWith(streakDays: newStreak);
    }
  }

  // ── Datos mock de respaldo ─────────────────────────────────────────────────

  void _fallbackToMockOrEmpty() {
    if (kDebugMode) {
      _loadMockData();
      return;
    }
    state = const UniverseAppState(isLoading: false);
  }

  void _loadMockData() {
    const uuid = Uuid();
    state = UniverseAppState(
      isLoading: false,
      currentUserId: 'user1',
      couple: CoupleModel(
        id: 'couple_demo',
        user1Id: 'user1',
        user2Id: 'user2',
        inviteCode: 'DEMO',
        createdAt: DateTime(2024, 6, 1),
        connectionStrength: 67,
        universeState: UniverseState(
          phase: 'aurora',
          level: 3,
          lastInteraction: DateTime.now(),
        ),
        user1Emotion: EmotionModel.create(mood: 'love'),
        user2Emotion: EmotionModel.create(mood: 'peace'),
      ),
      memories: [
        MemoryModel(
          id: uuid.v4(),
          coupleId: 'couple_demo',
          type: 'constellation',
          title: 'Primera llamada',
          description: 'La noche que hablamos 6 horas seguidas.',
          createdByUserId: 'user1',
          createdAt: DateTime(2024, 6, 10),
          posX: 0.2,
          posY: 0.65,
        ),
        MemoryModel(
          id: uuid.v4(),
          coupleId: 'couple_demo',
          type: 'tree',
          title: 'Cartas',
          description: 'Las primeras cartas escritas a mano que nos enviamos.',
          createdByUserId: 'user2',
          createdAt: DateTime(2024, 7, 3),
          posX: 0.7,
          posY: 0.70,
        ),
      ],
      goals: [
        GoalModel(
          id: uuid.v4(),
          coupleId: 'couple_demo',
          title: 'Encontrarnos en París',
          description: 'Nuestro primer reencuentro.',
          targetDate: DateTime(2025, 12, 1),
          progress: 0.6,
          symbol: 'castle',
          createdAt: DateTime(2024, 6, 1),
        ),
      ],
      capsules: [
        TimeCapsuleModel(
          id: uuid.v4(),
          coupleId: 'couple_demo',
          title: 'Para abrir en una semana',
          message: 'Si leemos esto, seguimos eligiendonos cada dia.',
          createdByUserId: 'user2',
          createdAt: DateTime(2024, 7, 10),
          unlockAt: DateTime.now().add(const Duration(days: 7)),
        ),
      ],
      dailyQuestion: DailyQuestionModel(
        id: 'couple_demo_${dayKey(DateTime.now())}',
        coupleId: 'couple_demo',
        dayKey: dayKey(DateTime.now()),
        question: _preguntaParaDia(dayKey(DateTime.now())),
        answers: const <String, String>{
          'user1': 'Hoy me acordé de ti cuando vi el atardecer.',
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  TimeCapsuleModel? _capsuleById(String capsuleId) {
    for (final capsule in state.capsules) {
      if (capsule.id == capsuleId) return capsule;
    }
    return null;
  }

  void _disposeResources() {
    _coupleSub?.cancel();
    _memoriesSub?.cancel();
    _goalsSub?.cancel();
    _capsulesSub?.cancel();
    _dailyQuestionSub?.cancel();
    _wishesSub?.cancel();
    _syncConnectionSub?.cancel();
    _partnerOnlineSub?.cancel();
    _pulseSub?.cancel();
    _pulseTimer?.cancel();
    _memoryNotifTimer?.cancel();
    _presence.disconnect();
  }
}

final universeProvider = NotifierProvider<UniverseNotifier, UniverseAppState>(
  UniverseNotifier.new,
);
