import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aethera/core/providers/app_state_notifier.dart';
import 'package:aethera/core/router/app_router.dart';
import 'package:aethera/core/services/auth_service.dart';
import 'package:aethera/core/services/couple_service.dart';
import 'package:aethera/core/services/offline_sync_queue_service.dart';
import 'package:aethera/core/services/user_service.dart';
import 'package:aethera/features/auth/providers/auth_provider.dart';
import 'package:aethera/features/pairing/providers/pairing_provider.dart';
import 'package:aethera/features/universe/domain/universe_flow_helpers.dart';
import 'package:aethera/shared/models/couple_model.dart';
import 'package:aethera/shared/models/daily_question_model.dart';
import 'package:aethera/shared/models/time_capsule_model.dart';
import 'package:aethera/shared/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('E2E critico: login -> pairing -> universe', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    testWidgets('flujo completo con redireccion de router', (tester) async {
      final session = AppStateNotifier(autoBootstrap: false);
      final fakeAuth = _FakeAuthService(session: session, userId: 'u_test');
      final fakeUserService = _FakeUserService();
      final fakeCoupleService = _FakeCoupleService();

      session.debugSetSession(
        isAuthenticated: false,
        onboardingDone: true,
        coupleId: null,
      );

      final router = createAppRouter(
        stateNotifier: session,
        initialLocation: AetheraRoutes.auth,
        includeTelemetryObserver: false,
        authBuilder: (_) => const _AuthFlowTestPage(),
        pairingBuilder: (_) => const _PairingFlowTestPage(),
        universeBuilder:
            (_) => const Scaffold(body: Center(child: Text('Universo listo'))),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(fakeAuth),
            userServiceProvider.overrideWithValue(fakeUserService),
            coupleServiceProvider.overrideWithValue(fakeCoupleService),
            pairingAppStateNotifierProvider.overrideWithValue(session),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pump();
      expect(find.text('Iniciar sesion de prueba'), findsOneWidget);

      await tester.tap(find.text('Iniciar sesion de prueba'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Crear universo de prueba'), findsOneWidget);

      await tester.tap(find.text('Crear universo de prueba'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Universo listo'), findsOneWidget);
      expect(session.hasCoupleId, isTrue);
      expect(session.coupleId, 'c_test');
    });
  });

  group('E2E critico: offline -> online con cola de sync', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('encola acciones offline y las aplica al reconectar', () async {
      final queue = OfflineSyncQueueService();
      final now = DateTime(2026, 3, 13, 10, 0);
      final capsuleUnlock = now.subtract(const Duration(minutes: 5));

      final initialQuestion = DailyQuestionModel(
        id: 'c1_2026-03-13',
        coupleId: 'c1',
        dayKey: '2026-03-13',
        question: '¿Qué te hizo sonreír hoy?',
        answers: const <String, String>{},
        createdAt: now,
      );

      await queue.enqueue(
        OfflineSyncAction(
          id: 'a1',
          type: 'createTimeCapsule',
          payload: {
            'id': 'cap_1',
            'coupleId': 'c1',
            'title': 'Cápsula',
            'message': 'Nos vemos pronto',
            'createdByUserId': 'u1',
            'createdAt': now.millisecondsSinceEpoch,
            'unlockAt': capsuleUnlock.millisecondsSinceEpoch,
          },
          createdAtMs: now.millisecondsSinceEpoch,
        ),
      );

      await queue.enqueue(
        OfflineSyncAction(
          id: 'a2',
          type: 'submitDailyAnswer',
          payload: {
            'roundId': initialQuestion.id,
            'userId': 'u1',
            'answer': 'Pensé en ti cuando amaneció',
          },
          createdAtMs: now.millisecondsSinceEpoch + 1,
        ),
      );

      await queue.enqueue(
        OfflineSyncAction(
          id: 'a3',
          type: 'submitDailyAnswer',
          payload: {
            'roundId': initialQuestion.id,
            'userId': 'u2',
            'answer': 'Escuché nuestra canción',
          },
          createdAtMs: now.millisecondsSinceEpoch + 2,
        ),
      );

      await queue.enqueue(
        OfflineSyncAction(
          id: 'a4',
          type: 'openTimeCapsule',
          payload: {'capsuleId': 'cap_1', 'userId': 'u1'},
          createdAtMs: now.millisecondsSinceEpoch + 3,
        ),
      );

      expect(await queue.count(), 4);

      var question = initialQuestion;
      final capsules = <String, TimeCapsuleModel>{};
      final processed = <String>{};

      final pending = await queue.load();
      for (final action in pending) {
        switch (action.type) {
          case 'createTimeCapsule':
            final capsule = TimeCapsuleModel(
              id: action.payload['id'] as String,
              coupleId: action.payload['coupleId'] as String,
              title: action.payload['title'] as String,
              message: action.payload['message'] as String,
              createdByUserId: action.payload['createdByUserId'] as String,
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                action.payload['createdAt'] as int,
              ),
              unlockAt: DateTime.fromMillisecondsSinceEpoch(
                action.payload['unlockAt'] as int,
              ),
            );
            capsules[capsule.id] = capsule;
            processed.add(action.id);
            break;
          case 'submitDailyAnswer':
            question = aplicarRespuestaDiaria(
              pregunta: question,
              userId: action.payload['userId'] as String,
              respuesta: action.payload['answer'] as String,
              ahora: now,
            );
            processed.add(action.id);
            break;
          case 'openTimeCapsule':
            final capsuleId = action.payload['capsuleId'] as String;
            final userId = action.payload['userId'] as String;
            final existing = capsules[capsuleId];
            if (existing == null) break;
            final opened = abrirCapsulaOptimista(
              capsula: existing,
              userId: userId,
              ahora: now,
            );
            if (opened != null) {
              capsules[capsuleId] = opened;
              processed.add(action.id);
            }
            break;
          default:
            break;
        }
      }

      await queue.removeByIds(processed);

      expect(await queue.count(), 0);
      expect(question.isRevealed, isTrue);
      expect(question.answers['u1'], 'Pensé en ti cuando amaneció');
      expect(question.answers['u2'], 'Escuché nuestra canción');

      final openedCapsule = capsules['cap_1'];
      expect(openedCapsule, isNotNull);
      expect(openedCapsule!.openedByUserIds, contains('u1'));
    });
  });

  group('E2E critico: capsulas y pregunta diaria', () {
    test('capsula: bloqueada, desbloqueada e idempotente', () {
      final locked = TimeCapsuleModel(
        id: 'c_locked',
        coupleId: 'c1',
        title: '',
        message: 'Hola',
        createdByUserId: 'u1',
        createdAt: DateTime(2026, 3, 10),
        unlockAt: DateTime(2026, 3, 20),
      );

      final cannotOpen = abrirCapsulaOptimista(
        capsula: locked,
        userId: 'u2',
        ahora: DateTime(2026, 3, 13),
      );
      expect(cannotOpen, isNull);

      final unlocked = TimeCapsuleModel(
        id: 'c_open',
        coupleId: 'c1',
        title: '',
        message: 'Hola',
        createdByUserId: 'u1',
        createdAt: DateTime(2026, 3, 10),
        unlockAt: DateTime(2026, 3, 11),
      );

      final firstOpen = abrirCapsulaOptimista(
        capsula: unlocked,
        userId: 'u2',
        ahora: DateTime(2026, 3, 13),
      );
      expect(firstOpen, isNotNull);
      expect(firstOpen!.openedByUserIds, contains('u2'));

      final secondOpen = abrirCapsulaOptimista(
        capsula: firstOpen,
        userId: 'u2',
        ahora: DateTime(2026, 3, 13),
      );
      expect(secondOpen, isNotNull);
      expect(secondOpen!.openedByUserIds.where((id) => id == 'u2').length, 1);
    });

    test('pregunta diaria: reveal ocurre cuando ambos responden', () {
      final question = DailyQuestionModel(
        id: 'q1',
        coupleId: 'c1',
        dayKey: '2026-03-13',
        question: '¿Qué agradeces hoy?',
        answers: const <String, String>{},
        createdAt: DateTime(2026, 3, 13),
      );

      final first = aplicarRespuestaDiaria(
        pregunta: question,
        userId: 'u1',
        respuesta: 'Tu apoyo',
        ahora: DateTime(2026, 3, 13, 10, 0),
      );
      expect(first.isRevealed, isFalse);
      expect(first.answers.length, 1);

      final second = aplicarRespuestaDiaria(
        pregunta: first,
        userId: 'u2',
        respuesta: 'Tu paciencia',
        ahora: DateTime(2026, 3, 13, 10, 1),
      );
      expect(second.isRevealed, isTrue);
      expect(second.answers.length, 2);
      expect(second.revealedAt, isNotNull);
    });
  });
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({required this.session, required this.userId});

  final AppStateNotifier session;
  final String userId;
  String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;

  @override
  Future<void> signIn(String email, String password) async {
    _currentUserId = userId;
    session.debugSetSession(
      isAuthenticated: true,
      coupleId: null,
      onboardingDone: true,
    );
  }

  @override
  Future<String> register(String email, String password) async {
    _currentUserId = userId;
    session.debugSetSession(
      isAuthenticated: true,
      coupleId: null,
      onboardingDone: true,
    );
    return userId;
  }

  @override
  Future<void> signOut() async {
    _currentUserId = null;
    session.debugSetSession(
      isAuthenticated: false,
      coupleId: null,
      onboardingDone: true,
    );
  }
}

class _FakeUserService extends UserService {
  final Map<String, UserModel> _users = <String, UserModel>{};

  @override
  Future<void> createUser(UserModel user) async {
    _users[user.uid] = user;
  }
}

class _FakeCoupleService extends CoupleService {
  CoupleModel? _couple;

  @override
  Future<CoupleModel> createCouple(String user1Id) async {
    final created = CoupleModel(
      id: 'c_test',
      user1Id: user1Id,
      user2Id: '',
      inviteCode: 'ABC123',
      createdAt: DateTime(2026, 3, 13, 9, 0),
      connectionStrength: 0,
      universeState: UniverseState.initial(),
    );
    _couple = created;
    return created;
  }

  @override
  Future<CoupleModel> joinCouple(String inviteCode, String user2Id) async {
    final current = _couple;
    if (current == null) {
      throw Exception('No existe universo para unirse');
    }
    if (inviteCode.trim().toUpperCase() != current.inviteCode) {
      throw Exception('Codigo invalido');
    }
    _couple = current.copyWith(user2Id: user2Id);
    return _couple!;
  }
}

class _AuthFlowTestPage extends ConsumerWidget {
  const _AuthFlowTestPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed:
              () => ref
                  .read(authProvider.notifier)
                  .signIn('demo@aethera.dev', '123456'),
          child: const Text('Iniciar sesion de prueba'),
        ),
      ),
    );
  }
}

class _PairingFlowTestPage extends ConsumerWidget {
  const _PairingFlowTestPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final uid = ref.read(authServiceProvider).currentUserId;
            if (uid == null) return;
            await ref.read(pairingProvider.notifier).createCouple(uid);
            ref.read(pairingProvider.notifier).enterSolo();
          },
          child: const Text('Crear universo de prueba'),
        ),
      ),
    );
  }
}
