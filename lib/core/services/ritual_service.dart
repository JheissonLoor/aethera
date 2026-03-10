import 'package:cloud_firestore/cloud_firestore.dart';

class RitualService {
  final _db = FirebaseFirestore.instance;

  // ── Rotating weekly questions ─────────────────────────────────────────────
  static String get currentWeekQuestion {
    final week = ((DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays) / 7).floor();
    return _questions[week % _questions.length];
  }

  static const _questions = [
    '¿Qué momento de esta semana hubieras querido compartir conmigo?',
    '¿Cuál fue tu mayor desafío esta semana y cómo lo superaste?',
    '¿Qué aprendiste sobre ti mismo/a esta semana?',
    '¿Qué es lo que más extrañas de mí en este momento?',
    'Si pudiéramos pasar un día juntos esta semana, ¿qué harías?',
    '¿Qué te emociona más de nuestro futuro juntos?',
    '¿Hubo algo que quisiste decirme y no dijiste?',
    '¿Cuál fue el momento más difícil de esta semana?',
    '¿Qué cosa pequeña te alegró el corazón esta semana?',
    '¿Qué sueño personal tienes que quieras que yo conozca?',
  ];

  String getWeekQuestion() {
    final week = _weekNumber(DateTime.now());
    return _questions[week % _questions.length];
  }

  String getWeekId([DateTime? date]) {
    final d = date ?? DateTime.now();
    final week = _weekNumber(d).toString().padLeft(2, '0');
    return '${d.year}-W$week';
  }

  int _weekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return ((date.difference(startOfYear).inDays) / 7).floor();
  }

  // ── Firestore ops ─────────────────────────────────────────────────────────

  /// Real-time stream of the current week's ritual document.
  Stream<Map<String, dynamic>?> watchThisWeekRitual(String coupleId) {
    return _db
        .collection('rituals')
        .doc(coupleId)
        .collection('weekly')
        .doc(getWeekId())
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  Future<Map<String, dynamic>?> getThisWeekRitual(String coupleId) async {
    final doc = await _db
        .collection('rituals')
        .doc(coupleId)
        .collection('weekly')
        .doc(getWeekId())
        .get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> submitRitual({
    required String coupleId,
    required String userId,
    required String answer,
    required List<String> gratitude,
  }) async {
    final weekId = getWeekId();
    final ref = _db
        .collection('rituals')
        .doc(coupleId)
        .collection('weekly')
        .doc(weekId);

    await ref.set({
      'question': getWeekQuestion(),
      'answer_$userId': answer.trim(),
      'gratitude_$userId': gratitude.map((g) => g.trim()).toList(),
      'completedBy': FieldValue.arrayUnion([userId]),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));

    // +15 connection strength
    await _db.collection('couples').doc(coupleId).update({
      'connectionStrength': FieldValue.increment(15),
    });
  }
}
