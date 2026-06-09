import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart';
import 'package:aethera/features/challenges/models/challenge.dart';
import 'package:aethera/features/auth/providers/auth_provider.dart';
import 'package:aethera/features/pulse_moments/providers/pulse_moments_provider.dart';

final firestore = FirebaseFirestore.instance;

/// Get the current week's challenge
final weeklyChallengeProvider = StreamProvider<ConnectionChallenge?>((ref) async* {
  final userId = ref.watch(authProvider)?.uid;
  const partnerId = ref.watch(partnerIdProvider.future);

  if (userId == null) {
    yield null;
    return;
  }

  try {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    yield* firestore
        .collection('challenges')
        .where('weekStart',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('weekEnd', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return ConnectionChallenge.fromFirestore(snapshot.docs.first);
        });
  } catch (e) {
    print('[v0] Error fetching weekly challenge: $e');
    yield null;
  }
});

/// Get all challenges for the relationship
final allChallengesProvider = StreamProvider<List<ConnectionChallenge>>((ref) async* {
  final userId = ref.watch(authProvider)?.uid;

  if (userId == null) {
    yield [];
    return;
  }

  try {
    yield* firestore
        .collection('challenges')
        .orderBy('weekStart', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ConnectionChallenge.fromFirestore(doc))
              .toList();
        });
  } catch (e) {
    print('[v0] Error fetching challenges: $e');
    yield [];
  }
});

/// Mark a challenge as completed by current user
final completeChallengeProvider =
    FutureProvider.family<void, String>((ref, challengeId) async {
  final userId = ref.watch(authProvider)?.uid;

  if (userId == null) {
    throw Exception('User not found');
  }

  try {
    await firestore.collection('challenges').doc(challengeId).update({
      'partnerOneCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
    });

    ref.refresh(weeklyChallengeProvider);
    ref.refresh(allChallengesProvider);
  } catch (e) {
    print('[v0] Error completing challenge: $e');
    rethrow;
  }
});

/// Create a new weekly challenge
final createWeeklyChallengeProvider =
    FutureProvider.family<void, ConnectionChallenge>((ref, challenge) async {
  try {
    await firestore.collection('challenges').add(challenge.toFirestore());
    ref.refresh(weeklyChallengeProvider);
    ref.refresh(allChallengesProvider);
  } catch (e) {
    print('[v0] Error creating challenge: $e');
    rethrow;
  }
});
