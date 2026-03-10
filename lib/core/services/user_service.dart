import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aethera/shared/models/user_model.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  Future<void> createUser(UserModel user) =>
      _col.doc(user.uid).set(user.toMap());

  Future<UserModel?> getUser(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }

  Future<void> updateCoupleId(String uid, String coupleId) =>
      _col.doc(uid).update({'coupleId': coupleId});

  Stream<UserModel?> userStream(String uid) => _col.doc(uid).snapshots().map(
        (doc) => doc.exists ? UserModel.fromMap(uid, doc.data()!) : null,
      );
}
