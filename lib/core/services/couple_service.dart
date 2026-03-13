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

  Future<String> _generateUniqueCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    String code;
    bool exists;
    do {
      code = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
      final q =
          await _col.where('inviteCode', isEqualTo: code).limit(1).get();
      exists = q.docs.isNotEmpty;
    } while (exists);
    return code;
  }

  Future<CoupleModel> createCouple(String user1Id) async {
    final code = await _generateUniqueCode();
    final coupleId = _uuid.v4();
    final couple = CoupleModel(
      id: coupleId,
      user1Id: user1Id,
      user2Id: '',
      inviteCode: code,
      createdAt: DateTime.now(),
      connectionStrength: 0,
      universeState: UniverseState.initial(),
    );
    await _col.doc(coupleId).set(couple.toMap());
    await _firestore
        .collection('users')
        .doc(user1Id)
        .update({'coupleId': coupleId});
    return couple;
  }

  Future<CoupleModel> joinCouple(String inviteCode, String user2Id) async {
    final q = await _col
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase().trim())
        .limit(1)
        .get();
    if (q.docs.isEmpty) throw Exception('Código inválido');
    final doc = q.docs.first;
    final couple = CoupleModel.fromMap(doc.id, doc.data());
    if (couple.user1Id == user2Id) {
      throw Exception('No puedes conectarte contigo mismo');
    }
    if (couple.user2Id.isNotEmpty) {
      throw Exception('Este universo ya tiene pareja');
    }
    await doc.reference.update({'user2Id': user2Id});
    await _firestore
        .collection('users')
        .doc(user2Id)
        .update({'coupleId': couple.id});
    return couple.copyWith(user2Id: user2Id);
  }

  Future<CoupleModel?> getCoupleById(String coupleId) async {
    final doc = await _col.doc(coupleId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CoupleModel.fromMap(doc.id, doc.data()!);
  }

  Stream<CoupleModel?> coupleStream(String coupleId) =>
      _col.doc(coupleId).snapshots().map(
            (doc) =>
                doc.exists ? CoupleModel.fromMap(doc.id, doc.data()!) : null,
          );
}
