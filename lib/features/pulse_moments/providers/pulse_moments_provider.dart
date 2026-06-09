import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart';
import 'package:aethera/features/pulse_moments/models/pulse_moment.dart';
import 'package:aethera/features/auth/providers/auth_provider.dart';

final firestore = FirebaseFirestore.instance;

/// Get current user's partner ID (should be implemented in auth/pair logic)
final partnerIdProvider = FutureProvider<String?>((ref) async {
  final userId = ref.watch(authProvider)?.uid;
  if (userId == null) return null;
  
  final userDoc = await firestore.collection('users').doc(userId).get();
  return userDoc.data()?['partnerId'] as String?;
});

/// Stream of received pulse moments from partner
final receivedPulsesProvider = StreamProvider<List<PulseMoment>>((ref) async* {
  final userId = ref.watch(authProvider)?.uid;
  final partnerId = await ref.watch(partnerIdProvider.future);

  if (userId == null || partnerId == null) {
    yield [];
    return;
  }

  try {
    yield* firestore
        .collection('pulses')
        .where('partnerId', isEqualTo: userId)
        .where('senderId', isEqualTo: partnerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => PulseMoment.fromFirestore(doc)).toList();
        });
  } catch (e) {
    print('[v0] Error fetching pulses: $e');
    yield [];
  }
});

/// Send a pulse moment to partner
final sendPulseProvider = FutureProvider.family<void, PulseMoment>((ref, pulse) async {
  final userId = ref.watch(authProvider)?.uid;
  final partnerId = await ref.watch(partnerIdProvider.future);

  if (userId == null || partnerId == null) {
    throw Exception('User or partner not found');
  }

  try {
    await firestore.collection('pulses').add({
      ...pulse.toFirestore(),
      'partnerId': partnerId,
    });

    ref.refresh(receivedPulsesProvider);
  } catch (e) {
    print('[v0] Error sending pulse: $e');
    rethrow;
  }
});

/// Acknowledge a received pulse
final acknowledgePulseProvider = FutureProvider.family<void, String>((ref, pulseId) async {
  try {
    await firestore.collection('pulses').doc(pulseId).update({
      'isAcknowledged': true,
      'acknowledgedAt': FieldValue.serverTimestamp(),
    });

    ref.refresh(receivedPulsesProvider);
  } catch (e) {
    print('[v0] Error acknowledging pulse: $e');
    rethrow;
  }
});
