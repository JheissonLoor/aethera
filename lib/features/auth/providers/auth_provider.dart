import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValue, Provider;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:aethera/core/services/auth_service.dart';
import 'package:aethera/core/services/user_service.dart';
import 'package:aethera/shared/models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final userServiceProvider = Provider<UserService>((ref) => UserService());

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._authService, this._userService)
      : super(const AsyncValue.data(null));

  final AuthService _authService;
  final UserService _userService;

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.signIn(email, password);
    });
  }

  Future<void> register(
      String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final cred = await _authService.register(email, password);
      await _userService.createUser(UserModel(
        uid: cred.user!.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        createdAt: DateTime.now(),
      ));
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  void resetError() => state = const AsyncValue.data(null);
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) => AuthNotifier(
          ref.watch(authServiceProvider),
          ref.watch(userServiceProvider),
        ));
