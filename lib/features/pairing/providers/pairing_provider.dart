import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:aethera/core/services/couple_service.dart';
import 'package:aethera/core/providers/app_state_notifier.dart';
import 'package:aethera/shared/models/couple_model.dart';

final coupleServiceProvider =
    Provider<CoupleService>((ref) => CoupleService());

class PairingState {
  final CoupleModel? couple;
  final bool isLoading;
  final String? error;

  const PairingState({this.couple, this.isLoading = false, this.error});

  PairingState copyWith(
          {CoupleModel? couple, bool? isLoading, String? error}) =>
      PairingState(
        couple: couple ?? this.couple,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class PairingNotifier extends StateNotifier<PairingState> {
  PairingNotifier(this._service) : super(const PairingState());

  final CoupleService _service;

  /// Creates a new couple for [userId] and stores the code.
  /// Does NOT redirect — call [enterSolo] to proceed to universe.
  Future<void> createCouple(String userId) async {
    if (state.couple != null) return; // already created
    state = state.copyWith(isLoading: true, error: null);
    try {
      final couple = await _service.createCouple(userId);
      // Do NOT notify appStateNotifier here — user may still want to join
      // a partner's couple instead. Call enterSolo() to proceed solo.
      state = state.copyWith(couple: couple, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'No se pudo crear el universo');
    }
  }

  /// Sets the couple in appStateNotifier, triggering redirect to /universe.
  void enterSolo() {
    final couple = state.couple;
    if (couple != null) {
      appStateNotifier.setCoupleId(couple.id);
    }
  }

  Future<bool> joinCouple(String inviteCode, String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final couple = await _service.joinCouple(inviteCode, userId);
      appStateNotifier.setCoupleId(couple.id);
      state = state.copyWith(couple: couple, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final pairingProvider =
    StateNotifierProvider<PairingNotifier, PairingState>((ref) =>
        PairingNotifier(ref.watch(coupleServiceProvider)));
