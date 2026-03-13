import 'package:aethera/shared/models/daily_question_model.dart';
import 'package:aethera/shared/models/time_capsule_model.dart';

DailyQuestionModel aplicarRespuestaDiaria({
  required DailyQuestionModel pregunta,
  required String userId,
  required String respuesta,
  DateTime? ahora,
}) {
  final user = userId.trim();
  final answer = respuesta.trim();
  if (user.isEmpty || answer.isEmpty) {
    return pregunta;
  }

  final respuestas = Map<String, String>.from(pregunta.answers);
  respuestas[user] = answer;
  final revealAt =
      respuestas.length >= 2 && pregunta.revealedAt == null
          ? (ahora ?? DateTime.now())
          : pregunta.revealedAt;

  return DailyQuestionModel(
    id: pregunta.id,
    coupleId: pregunta.coupleId,
    dayKey: pregunta.dayKey,
    question: pregunta.question,
    answers: respuestas,
    createdAt: pregunta.createdAt,
    revealedAt: revealAt,
  );
}

TimeCapsuleModel? abrirCapsulaOptimista({
  required TimeCapsuleModel capsula,
  required String userId,
  DateTime? ahora,
}) {
  final user = userId.trim();
  if (user.isEmpty) return null;

  final now = ahora ?? DateTime.now();
  if (capsula.unlockAt.isAfter(now)) {
    return null;
  }

  if (capsula.openedByUserIds.contains(user)) {
    return capsula;
  }

  return TimeCapsuleModel(
    id: capsula.id,
    coupleId: capsula.coupleId,
    title: capsula.title,
    message: capsula.message,
    createdByUserId: capsula.createdByUserId,
    createdAt: capsula.createdAt,
    unlockAt: capsula.unlockAt,
    openedByUserIds: <String>{...capsula.openedByUserIds, user}.toList(),
  );
}
