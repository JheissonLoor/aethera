import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;
  FirebaseAuth get _client => _auth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _client.authStateChanges();
  User? get currentUser => _client.currentUser;
  String? get currentUserId => _client.currentUser?.uid;

  Future<void> signIn(String email, String password) async {
    await _client.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<String> register(String email, String password) async {
    final credential = await _client.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user!.uid;
  }

  Future<void> signOut() => _client.signOut();
}
