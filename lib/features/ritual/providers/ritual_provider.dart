import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Notifier, NotifierProvider, Provider;
import 'package:aethera/core/services/ritual_service.dart';
import 'package:aethera/core/services/notification_service.dart';

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
      );
}

class RitualNotifier extends Notifier<RitualState> {
  RitualService get _service => ref.read(ritualServiceProvider);
  StreamSubscription? _ritualSub;

  @override
  RitualState build() {
    ref.onDispose(() {
      _ritualSub?.cancel();
    });
    return RitualState(weekQuestion: RitualService.currentWeekQuestion);
  }

  /// Subscribe to live ritual data for this week.
  void watchRitual(String coupleId, String userId, String partnerUserId) {
    _ritualSub?.cancel();
    _ritualSub = _service.watchThisWeekRitual(coupleId).listen((data) {
      if (data == null) {
        state = state.copyWith(alreadyCompleted: false, partnerCompleted: false);
        return;
      }
      final completedBy = (data['completedBy'] as List?) ?? [];
      final partnerJustCompleted =
          !state.partnerCompleted && completedBy.contains(partnerUserId);
      state = state.copyWith(
        alreadyCompleted: completedBy.contains(userId),
        partnerCompleted: completedBy.contains(partnerUserId),
        myAnswer: data['answer_$userId'] as String?,
        myGratitude: (data['gratitude_$userId'] as List?)?.cast<String>(),
        partnerAnswer: data['answer_$partnerUserId'] as String?,
        partnerGratitude:
            (data['gratitude_$partnerUserId'] as List?)?.cast<String>(),
        weekQuestion: data['question'] as String? ?? _service.getWeekQuestion(),
      );
      if (partnerJustCompleted) {
        NotificationService.instance.showPartnerRitualNotification();
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
    } catch (e) {
      state = state.copyWith(
          status: RitualStatus.error, error: 'No se pudo guardar el ritual');
    }
  }

}

final ritualProvider =
    NotifierProvider<RitualNotifier, RitualState>(RitualNotifier.new);
