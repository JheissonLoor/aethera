import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Notifier, NotifierProvider;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:aethera/core/services/couple_service.dart';
import 'package:aethera/shared/models/couple_model.dart';
import 'package:aethera/shared/models/emotion_model.dart';
import 'package:aethera/shared/models/memory_model.dart';
import 'package:aethera/shared/models/goal_model.dart';
import 'package:aethera/shared/models/wish_model.dart';
import 'package:aethera/core/constants/app_constants.dart';
import 'package:aethera/core/services/presence_service.dart';
import 'package:aethera/core/services/notification_service.dart';
import 'package:aethera/core/utils/streak_utils.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class UniverseAppState {
  final CoupleModel? couple;
  final List<MemoryModel> memories;
  final List<GoalModel> goals;
  final bool partnerOnline;
  final bool receivedPulse;
  final bool newMemoryFromPartner;
  final bool isLoading;
  final String? emotionFeedback;

  /// Incoming wish from partner, not yet seen
  final WishModel? incomingWish;

  /// Consecutive days both users checked in
  final int streakDays;

  const UniverseAppState({
    this.couple,
    this.memories = const [],
    this.goals = const [],
    this.partnerOnline = false,
    this.receivedPulse = false,
    this.newMemoryFromPartner = false,
    this.isLoading = true,
    this.emotionFeedback,
    this.incomingWish,
    this.streakDays = 0,
  });

  String get combinedMood => couple?.combinedEmotion ?? 'neutral';
  int get connectionStrength => couple?.connectionStrength ?? 0;
  int get universeLevel => couple?.universeState.level ?? 1;
  bool get showAurora =>
      partnerOnline || receivedPulse || connectionStrength >= 60;

  UniverseAppState copyWith({
    CoupleModel? couple,
    List<MemoryModel>? memories,
    List<GoalModel>? goals,
    bool? partnerOnline,
    bool? receivedPulse,
    bool? newMemoryFromPartner,
    bool? isLoading,
    String? emotionFeedback,
    bool clearEmotionFeedback = false,
    WishModel? incomingWish,
    bool clearIncomingWish = false,
    int? streakDays,
  }) => UniverseAppState(
    couple: couple ?? this.couple,
    memories: memories ?? this.memories,
    goals: goals ?? this.goals,
    partnerOnline: partnerOnline ?? this.partnerOnline,
    receivedPulse: receivedPulse ?? this.receivedPulse,
    newMemoryFromPartner: newMemoryFromPartner ?? this.newMemoryFromPartner,
    isLoading: isLoading ?? this.isLoading,
    emotionFeedback:
        clearEmotionFeedback ? null : (emotionFeedback ?? this.emotionFeedback),
    incomingWish:
        clearIncomingWish ? null : (incomingWish ?? this.incomingWish),
    streakDays: streakDays ?? this.streakDays,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

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
  final _coupleService = CoupleService();
  final _presence = PresenceService();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _coupleSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _memoriesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _goalsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _wishesSub;
  StreamSubscription<bool>? _partnerOnlineSub;
  StreamSubscription<bool>? _pulseSub;

  Timer? _pulseTimer;
  Timer? _memoryNotifTimer;

  bool _isUser1 = false;
  bool _sessionPointsAwarded = false;
  bool _memoriesInitialized = false;
  String? _myUserId;
  String? _coupleId;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    _sessionPointsAwarded = false;
    _memoriesInitialized = false;

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
        isLoading: false,
      );

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
            if (_memoriesInitialized) {
              final previousIds = state.memories.map((m) => m.id).toSet();
              isNewFromPartner = newMemories.any((memory) {
                if (previousIds.contains(memory.id)) return false;
                final authorId = memory.createdByUserId;
                return authorId == null || authorId != user.uid;
              });
            }
            _memoriesInitialized = true;

            state = state.copyWith(
              memories: newMemories,
              newMemoryFromPartner: isNewFromPartner,
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

      // Track IDs for wish system
      _myUserId = user.uid;
      _coupleId = coupleId;
      _isUser1 = initialCoupleData['user1Id'] == user.uid;

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
    } catch (_) {
      _fallbackToMockOrEmpty();
    }
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

  // ── Actions ───────────────────────────────────────────────────────────────

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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final emotionField = _isUser1 ? 'user1Emotion' : 'user2Emotion';
      await _db.collection('couples').doc(state.couple!.id).update({
        emotionField: emotion.toMap(),
        'connectionStrength': updated.connectionStrength,
      });
      await _tryIncrementStreak();
    }
  }

  Future<void> addMemory({
    required String title,
    required String description,
    required String type,
  }) async {
    final coupleId = state.couple?.id;
    if (coupleId == null) return;
    final memory = MemoryModel(
      id: const Uuid().v4(),
      coupleId: coupleId,
      type: type,
      title: title,
      description: description,
      createdByUserId: _myUserId ?? FirebaseAuth.instance.currentUser?.uid,
      createdAt: DateTime.now(),
      posX: 0.15 + (state.memories.length * 0.2) % 0.7,
      posY: 0.55 + (state.memories.length % 3) * 0.08,
    );
    // Stream will update state — no manual update needed
    await _db.collection('memories').doc(memory.id).set(memory.toMap());
    await _db.collection('couples').doc(coupleId).update({
      'connectionStrength': FieldValue.increment(AppConstants.pointsAddMemory),
    });
  }

  Future<void> addGoal({
    required String title,
    required String description,
    required String symbol,
    required DateTime targetDate,
  }) async {
    final coupleId = state.couple?.id;
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
    // Stream will update state — no manual update needed
    await _db.collection('goals').doc(goal.id).set(goal.toMap());
  }

  Future<void> updateGoalProgress(String goalId, double newProgress) async {
    final coupleId = state.couple?.id;
    if (coupleId == null) return;
    final existing = state.goals.firstWhere((g) => g.id == goalId);
    final clamped = newProgress.clamp(0.0, 1.0);
    final isNowCompleted = clamped >= 1.0 && !existing.isCompleted;

    // Immediate local update for responsive slider UI
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

    final Map<String, dynamic> data = {'progress': clamped};
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

  Future<void> sendPulse() async => _presence.sendPulse();

  /// Joins a partner's universe using their invite code.
  /// Used when the user is in solo mode and wants to connect with a partner.
  /// Returns an error string on failure, or null on success.
  Future<String?> joinPartner(String inviteCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'No hay sesión activa';
    try {
      await _coupleService.joinCouple(inviteCode, user.uid);
      // Re-initialize to pick up new couple streams
      _coupleSub?.cancel();
      _memoriesSub?.cancel();
      _goalsSub?.cancel();
      _wishesSub?.cancel();
      _partnerOnlineSub?.cancel();
      _pulseSub?.cancel();
      _coupleSub = null;
      _memoriesSub = null;
      _goalsSub = null;
      _wishesSub = null;
      _partnerOnlineSub = null;
      _pulseSub = null;
      state = const UniverseAppState(isLoading: true);
      await _init();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Sends a wish/message that flies as a shooting star to the partner's universe.
  Future<void> sendWish(String message) async {
    final coupleId = _coupleId ?? state.couple?.id;
    final userId = _myUserId;
    if (coupleId == null || userId == null || message.trim().isEmpty) return;
    final id = const Uuid().v4();
    await _db.collection('wishes').doc(id).set({
      'id': id,
      'coupleId': coupleId,
      'message': message.trim(),
      'fromUserId': userId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'seen': false,
    });
  }

  /// Marks the incoming wish as seen — removes the shooting star overlay.
  Future<void> markWishSeen() async {
    final wish = state.incomingWish;
    if (wish == null) return;
    state = state.copyWith(clearIncomingWish: true);
    await _db.collection('wishes').doc(wish.id).update({'seen': true});
  }

  /// Increments the connection streak if both users checked in today.
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

  // ── Fallback mock data ─────────────────────────────────────────────────────

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
    );
  }

  void _disposeResources() {
    _coupleSub?.cancel();
    _memoriesSub?.cancel();
    _goalsSub?.cancel();
    _wishesSub?.cancel();
    _partnerOnlineSub?.cancel();
    _pulseSub?.cancel();
    _pulseTimer?.cancel();
    _memoryNotifTimer?.cancel();
    _presence.disconnect();
  }
}

final universeProvider =
    NotifierProvider<UniverseNotifier, UniverseAppState>(UniverseNotifier.new);
