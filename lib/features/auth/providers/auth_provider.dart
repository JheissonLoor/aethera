import 'package:flutter_riverpod/flutter_riverpod.dart'
    show
        AsyncData,
        AsyncLoading,
        AsyncNotifier,
        AsyncNotifierProvider,
        AsyncValue,
        Provider;
import 'package:aethera/core/services/auth_service.dart';
import 'package:aethera/core/services/user_service.dart';
import 'package:aethera/shared/models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final userServiceProvider = Provider<UserService>((ref) => UserService());

class AuthNotifier extends AsyncNotifier<void> {
  AuthService get _authService => ref.read(authServiceProvider);
  UserService get _userService => ref.read(userServiceProvider);

  @override
  void build() {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _authService.signIn(email, password);
    });
  }

  Future<void> register(
      String email, String password, String displayName) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = await _authService.register(email, password);
      await _userService.createUser(UserModel(
        uid: uid,
        email: email.trim(),
        displayName: displayName.trim(),
        createdAt: DateTime.now(),
      ));
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await _authService.signOut();
    state = const AsyncData(null);
  }

  void resetError() => state = const AsyncData(null);
}

final authProvider = AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
