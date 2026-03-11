import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aethera/core/constants/app_constants.dart';

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

  String getCurrentSyncEvent() {
    final week = _weekNumber(DateTime.now());
    return AppConstants.syncCosmicEvents[
      week % AppConstants.syncCosmicEvents.length
    ];
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

  // Live Sync Ritual

  Future<void> sendSyncInvite({
    required String coupleId,
    required String fromUserId,
  }) async {
    final ref = _db
        .collection('rituals')
        .doc(coupleId)
        .collection('weekly')
        .doc(getWeekId());

    await ref.set({
      'syncInviteFrom': fromUserId,
      'syncInviteAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> setSyncHolding({
    required String coupleId,
    required String userId,
    required bool isHolding,
  }) async {
    final ref = _db
        .collection('rituals')
        .doc(coupleId)
        .collection('weekly')
        .doc(getWeekId());

    final now = DateTime.now().millisecondsSinceEpoch;
    final updates = <String, dynamic>{
      'syncHolding_$userId': isHolding,
      'syncUpdatedAt': now,
    };
    if (isHolding) {
      updates['syncHoldSince_$userId'] = now;
    } else {
      updates['syncHoldSince_$userId'] = FieldValue.delete();
    }

    await ref.set(updates, SetOptions(merge: true));
  }

  Future<bool> completeSyncSession({
    required String coupleId,
    required String userId,
    required String partnerUserId,
    int requiredSeconds = AppConstants.syncRitualSeconds,
  }) async {
    final weekRef = _db
        .collection('rituals')
        .doc(coupleId)
        .collection('weekly')
        .doc(getWeekId());
    final coupleRef = _db.collection('couples').doc(coupleId);
    final memoryRef = _db.collection('memories').doc();

    return _db.runTransaction((tx) async {
      final weekSnap = await tx.get(weekRef);
      final data = weekSnap.data();
      if (data == null) return false;
      if (data['syncCompleted'] == true) return false;

      final myHolding = data['syncHolding_$userId'] == true;
      final partnerHolding = data['syncHolding_$partnerUserId'] == true;
      final mySince = (data['syncHoldSince_$userId'] as num?)?.toInt();
      final partnerSince = (data['syncHoldSince_$partnerUserId'] as num?)
          ?.toInt();
      if (!myHolding || !partnerHolding || mySince == null || partnerSince == null) {
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final overlapMs = now - (mySince > partnerSince ? mySince : partnerSince);
      if (overlapMs < requiredSeconds * 1000) return false;

      final event = getCurrentSyncEvent();
      tx.set(weekRef, {
        'syncCompleted': true,
        'syncCompletedAt': now,
        'syncEvent': event,
        'syncHolding_$userId': false,
        'syncHolding_$partnerUserId': false,
        'syncHoldSince_$userId': FieldValue.delete(),
        'syncHoldSince_$partnerUserId': FieldValue.delete(),
      }, SetOptions(merge: true));

      tx.update(coupleRef, {
        'connectionStrength': FieldValue.increment(AppConstants.pointsSyncRitual),
      });

      tx.set(memoryRef, {
        'id': memoryRef.id,
        'coupleId': coupleId,
        'type': 'relic',
        'title': event,
        'description':
            'Desbloquearon $event al sincronizar latidos durante ${requiredSeconds}s.',
        'createdByUserId': 'system',
        'createdAt': now,
        'posX': 0.5,
        'posY': 0.58,
      });

      return true;
    });
  }
}
