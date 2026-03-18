import 'package:flutter_test/flutter_test.dart';
import 'package:aethera/core/providers/app_state_notifier.dart';
import 'package:aethera/core/router/app_router.dart';

void main() {
  group('resolveAppRedirect', () {
    late AppStateNotifier state;

    setUp(() {
      state = AppStateNotifier(autoBootstrap: false);
    });

    tearDown(() {
      state.dispose();
    });

    test('mantiene splash sin redireccion', () {
      state.debugSetSession(isAuthenticated: false, onboardingDone: false);

      final target = resolveAppRedirect(
        stateNotifier: state,
        matchedLocation: AetheraRoutes.splash,
      );

      expect(target, isNull);
    });

    test('redirige a onboarding cuando no esta completado', () {
      state.debugSetSession(
        isAuthenticated: true,
        coupleId: 'c1',
        onboardingDone: false,
      );

      final target = resolveAppRedirect(
        stateNotifier: state,
        matchedLocation: AetheraRoutes.universe,
      );

      expect(target, AetheraRoutes.onboarding);
    });

    test('redirige a auth cuando onboarding esta hecho pero no hay sesion', () {
      state.debugSetSession(isAuthenticated: false, onboardingDone: true);

      final target = resolveAppRedirect(
        stateNotifier: state,
        matchedLocation: AetheraRoutes.universe,
      );

      expect(target, AetheraRoutes.auth);
    });

    test('redirige a pairing cuando no existe coupleId', () {
      state.debugSetSession(
        isAuthenticated: true,
        onboardingDone: true,
        coupleId: '',
      );

      final target = resolveAppRedirect(
        stateNotifier: state,
        matchedLocation: AetheraRoutes.universe,
      );

      expect(target, AetheraRoutes.pairing);
    });

    test('usuario autenticado y con pareja sale de auth hacia universe', () {
      state.debugSetSession(
        isAuthenticated: true,
        onboardingDone: true,
        coupleId: 'c1',
      );

      final target = resolveAppRedirect(
        stateNotifier: state,
        matchedLocation: AetheraRoutes.auth,
      );

      expect(target, AetheraRoutes.universe);
    });
  });
}
