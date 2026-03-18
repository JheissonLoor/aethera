import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:aethera/shared/models/couple_model.dart';

class CoupleService {
  CoupleService({FirebaseFirestore? firestore, Uuid? uuid})
    : _db = firestore,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore? _db;
  FirebaseFirestore get _firestore => _db ?? FirebaseFirestore.instance;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('couples');
  CollectionReference<Map<String, dynamic>> get _inviteCol =>
      _firestore.collection('invite_codes');

  String _randomInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<CoupleModel> createCouple(String user1Id) async {
    const maxAttempts = 16;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final now = DateTime.now();
      final code = _randomInviteCode();
      final coupleId = _uuid.v4();
      final couple = CoupleModel(
        id: coupleId,
        user1Id: user1Id,
        user2Id: '',
        inviteCode: code,
        createdAt: now,
        connectionStrength: 0,
        universeState: UniverseState.initial(),
      );

      final coupleRef = _col.doc(coupleId);
      final inviteRef = _inviteCol.doc(code);
      final userRef = _firestore.collection('users').doc(user1Id);

      try {
        await _firestore.runTransaction((tx) async {
          final inviteSnap = await tx.get(inviteRef);
          if (inviteSnap.exists) {
            throw _InviteCodeCollision();
          }

          tx.set(coupleRef, couple.toMap());
          tx.set(inviteRef, {
            'coupleId': coupleId,
            'createdBy': user1Id,
            'createdAt': now.millisecondsSinceEpoch,
            'active': true,
          });
          tx.update(userRef, {'coupleId': coupleId});
        });
        return couple;
      } on _InviteCodeCollision {
        continue;
      }
    }

    throw Exception('No se pudo generar un codigo de invitacion unico');
  }

  Future<CoupleModel> joinCouple(String inviteCode, String user2Id) async {
    final normalizedCode = inviteCode.toUpperCase().trim();
    if (normalizedCode.length != 6) {
      throw Exception('Codigo invalido');
    }

    final inviteRef = _inviteCol.doc(normalizedCode);
    final inviteSnap = await inviteRef.get();
    final inviteData = inviteSnap.data();
    if (!inviteSnap.exists ||
        inviteData == null ||
        inviteData['active'] != true ||
        inviteData['coupleId'] is! String) {
      throw Exception('Codigo invalido');
    }

    final coupleId = inviteData['coupleId'] as String;
    final coupleRef = _col.doc(coupleId);
    final userRef = _firestore.collection('users').doc(user2Id);

    await _firestore.runTransaction((tx) async {
      final coupleSnap = await tx.get(coupleRef);
      final coupleData = coupleSnap.data();
      if (!coupleSnap.exists || coupleData == null) {
        throw Exception('Codigo invalido');
      }

      final user1Id = coupleData['user1Id'] as String? ?? '';
      final currentUser2Id = coupleData['user2Id'] as String? ?? '';
      if (user1Id == user2Id) {
        throw Exception('No puedes conectarte contigo mismo');
      }
      if (currentUser2Id.isNotEmpty) {
        throw Exception('Este universo ya tiene pareja');
      }

      final txInviteSnap = await tx.get(inviteRef);
      final txInviteData = txInviteSnap.data();
      if (!txInviteSnap.exists ||
          txInviteData == null ||
          txInviteData['active'] != true ||
          txInviteData['coupleId'] != coupleId) {
        throw Exception('Codigo invalido');
      }

      tx.update(coupleRef, {'user2Id': user2Id});
      tx.update(userRef, {'coupleId': coupleId});
      tx.update(inviteRef, {'active': false});
    });

    final joinedSnap = await coupleRef.get();
    final joinedData = joinedSnap.data();
    if (!joinedSnap.exists || joinedData == null) {
      throw Exception('No se pudo completar la vinculacion');
    }
    return CoupleModel.fromMap(joinedSnap.id, joinedData);
  }

  Future<CoupleModel?> getCoupleById(String coupleId) async {
    final doc = await _col.doc(coupleId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CoupleModel.fromMap(doc.id, doc.data()!);
  }

  Stream<CoupleModel?> coupleStream(String coupleId) => _col
      .doc(coupleId)
      .snapshots()
      .map(
        (doc) => doc.exists ? CoupleModel.fromMap(doc.id, doc.data()!) : null,
      );
}

class _InviteCodeCollision implements Exception {}
