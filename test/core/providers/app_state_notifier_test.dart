import 'package:flutter_test/flutter_test.dart';
import 'package:aethera/core/providers/app_state_notifier.dart';

void main() {
  group('AppStateNotifier', () {
    late AppStateNotifier notifier;

    setUp(() {
      notifier = AppStateNotifier(autoBootstrap: false);
    });

    tearDown(() {
      notifier.dispose();
    });

    test('debugSetSession aplica estado de sesion', () {
      notifier.debugSetSession(
        isAuthenticated: true,
        coupleId: 'c1',
        onboardingDone: true,
      );

      expect(notifier.isLoading, isFalse);
      expect(notifier.isAuthenticated, isTrue);
      expect(notifier.coupleId, 'c1');
      expect(notifier.hasCoupleId, isTrue);
      expect(notifier.onboardingDone, isTrue);
    });

    test('setCoupleId actualiza pareja activa en modo debug', () {
      notifier.debugSetSession(
        isAuthenticated: true,
        onboardingDone: true,
        coupleId: '',
      );

      notifier.setCoupleId('c123');
      expect(notifier.coupleId, 'c123');
      expect(notifier.hasCoupleId, isTrue);
    });

    test('debugClearSessionOverrides limpia los flags de debug', () {
      notifier.debugSetSession(
        isAuthenticated: true,
        coupleId: 'c1',
        onboardingDone: true,
      );

      notifier.debugClearSessionOverrides();
      expect(notifier.coupleId, isNull);
      expect(notifier.isAuthenticated, isFalse);
      expect(notifier.onboardingDone, isFalse);
    });
  });
}
