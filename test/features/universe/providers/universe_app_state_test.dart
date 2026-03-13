import 'package:flutter_test/flutter_test.dart';
import 'package:aethera/features/universe/providers/universe_provider.dart';
import 'package:aethera/shared/models/couple_model.dart';
import 'package:aethera/shared/models/daily_question_model.dart';

CoupleModel _buildCouple({int connectionStrength = 40, String user2Id = 'u2'}) {
  return CoupleModel(
    id: 'c1',
    user1Id: 'u1',
    user2Id: user2Id,
    inviteCode: 'ABC123',
    createdAt: DateTime(2026, 1, 10),
    connectionStrength: connectionStrength,
    universeState: UniverseState(
      phase: 'night',
      level: 2,
      lastInteraction: DateTime(2026, 1, 10),
    ),
  );
}

DailyQuestionModel _buildDailyQuestion({
  Map<String, String> answers = const {},
}) {
  return DailyQuestionModel(
    id: 'dq1',
    coupleId: 'c1',
    dayKey: '2026-03-13',
    question: 'Pregunta',
    answers: answers,
    createdAt: DateTime(2026, 3, 13),
  );
}

void main() {
  group('UniverseAppState', () {
    test('partnerUserId se calcula para usuario 1 y usuario 2', () {
      final forUser1 = UniverseAppState(
        couple: _buildCouple(user2Id: 'u2'),
        currentUserId: 'u1',
      );
      final forUser2 = UniverseAppState(
        couple: _buildCouple(user2Id: 'u2'),
        currentUserId: 'u2',
      );

      expect(forUser1.partnerUserId, 'u2');
      expect(forUser2.partnerUserId, 'u1');
    });

    test('showAurora se activa por conexion alta', () {
      final state = UniverseAppState(
        couple: _buildCouple(connectionStrength: 75),
        currentUserId: 'u1',
        partnerOnline: false,
        receivedPulse: false,
      );

      expect(state.showAurora, isTrue);
    });

    test('showAurora se activa por presencia o pulso', () {
      final byPresence = UniverseAppState(
        couple: _buildCouple(connectionStrength: 10),
        currentUserId: 'u1',
        partnerOnline: true,
      );
      final byPulse = UniverseAppState(
        couple: _buildCouple(connectionStrength: 10),
        currentUserId: 'u1',
        receivedPulse: true,
      );

      expect(byPresence.showAurora, isTrue);
      expect(byPulse.showAurora, isTrue);
    });

    test('respuestas diarias: estado y respuestas por usuario', () {
      final state = UniverseAppState(
        couple: _buildCouple(user2Id: 'u2'),
        currentUserId: 'u1',
        dailyQuestion: _buildDailyQuestion(
          answers: const {'u1': 'Mi respuesta', 'u2': 'Tu respuesta'},
        ),
      );

      expect(state.hasAnsweredDailyQuestion, isTrue);
      expect(state.isDailyQuestionRevealed, isTrue);
      expect(state.myDailyQuestionAnswer, 'Mi respuesta');
      expect(state.partnerDailyQuestionAnswer, 'Tu respuesta');
    });
  });
}
