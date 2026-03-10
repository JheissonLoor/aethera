import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:firebase_database/firebase_database.dart';

/// Manages real-time presence in Firebase Realtime Database.
///
/// Structure:
///   presence/{coupleId}/user1Online : bool
///   presence/{coupleId}/user2Online : bool
///   presence/{coupleId}/pulse       : {from: userId, at: serverTimestamp}
class PresenceService with WidgetsBindingObserver {
  final _db = FirebaseDatabase.instance;

  String? _coupleId;
  String? _userId;
  bool _isUser1 = false;
  DatabaseReference? _myRef;

  // ─── Connect / Disconnect ──────────────────────────────────────────────────

  Future<void> connect({
    required String coupleId,
    required String userId,
    required bool isUser1,
  }) async {
    _coupleId = coupleId;
    _userId = userId;
    _isUser1 = isUser1;
    _myRef = _db.ref('presence/$coupleId/${isUser1 ? 'user1Online' : 'user2Online'}');
    WidgetsBinding.instance.addObserver(this);
    await _setOnline(true);
  }

  Future<void> disconnect() async {
    await _setOnline(false);
    WidgetsBinding.instance.removeObserver(this);
    _myRef = null;
    _coupleId = null;
    _userId = null;
  }

  Future<void> _setOnline(bool online) async {
    if (_myRef == null) return;
    await _myRef!.set(online);
    // Firebase will also set false automatically when TCP connection drops
    if (online) await _myRef!.onDisconnect().set(false);
  }

  // ─── App Lifecycle ─────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnline(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _setOnline(false);
    }
  }

  // ─── Partner Online Stream ────────────────────────────────────────────────

  /// Emits true/false as the partner connects or disconnects.
  Stream<bool> partnerOnlineStream() {
    final coupleId = _coupleId;
    if (coupleId == null) return const Stream.empty();
    final partnerField = _isUser1 ? 'user2Online' : 'user1Online';
    return _db
        .ref('presence/$coupleId/$partnerField')
        .onValue
        .map((event) => event.snapshot.value as bool? ?? false);
  }

  // ─── Pulse ────────────────────────────────────────────────────────────────

  /// Writes a heartbeat pulse to RTDB for the partner to react to.
  Future<void> sendPulse() async {
    final coupleId = _coupleId;
    final userId = _userId;
    if (coupleId == null || userId == null) return;
    await _db.ref('presence/$coupleId/pulse').set({
      'from': userId,
      'at': ServerValue.timestamp,
    });
  }

  /// Emits true (for ~8 s) whenever the partner sends a pulse.
  Stream<bool> incomingPulseStream() {
    final coupleId = _coupleId;
    final userId = _userId;
    if (coupleId == null || userId == null) return const Stream.empty();
    return _db.ref('presence/$coupleId/pulse').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return false;
      final from = data['from'] as String?;
      final at = data['at'] as int?;
      if (from == null || at == null || from == userId) return false;
      // Only react to pulses that arrived in the last 8 seconds
      return DateTime.now().millisecondsSinceEpoch - at < 8000;
    });
  }
}
