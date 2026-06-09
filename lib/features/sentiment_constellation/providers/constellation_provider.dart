import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/features/sentiment_constellation/models/constellation.dart';
import 'package:aethera/features/auth/providers/auth_provider.dart';
import 'package:aethera/features/pulse_moments/providers/pulse_moments_provider.dart';

final firestore = FirebaseFirestore.instance;

/// Get the current pair's constellation
final constellationProvider = FutureProvider<SentimentConstellation?>((ref) async {
  final userId = ref.watch(authProvider)?.uid;
  if (userId == null) return null;

  try {
    final pairSnapshot = await firestore
        .collection('constellations')
        .where('pairId', arrayContains: userId)
        .limit(1)
        .get();

    if (pairSnapshot.docs.isEmpty) return null;

    final doc = pairSnapshot.docs.first;
    final data = doc.data();
    final pointsData = data['points'] as List<dynamic>? ?? [];

    return SentimentConstellation(
      id: doc.id,
      pairId: data['pairId'] ?? '',
      points: pointsData.map((p) {
        return ConstellationPoint(
          id: p['id'] ?? '',
          emotion: p['emotion'] ?? 'neutral',
          recordedAt: (p['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          x: (p['x'] ?? 0.0).toDouble(),
          y: (p['y'] ?? 0.0).toDouble(),
          note: p['note'],
        );
      }).toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  } catch (e) {
    print('[v0] Error fetching constellation: $e');
    return null;
  }
});

/// Add a point to the constellation based on an emotion
final addConstellationPointProvider =
    FutureProvider.family<void, String>((ref, emotion) async {
  final userId = ref.watch(authProvider)?.uid;
  final partnerId = await ref.watch(partnerIdProvider.future);

  if (userId == null || partnerId == null) {
    throw Exception('User or partner not found');
  }

  try {
    final pairId = [userId, partnerId].sort().join('_');

    // Generate position based on emotion (deterministic)
    final Random = DateTime.now().millisecond;
    final x = (Random % 100).toDouble();
    final y = ((Random + 50) % 100).toDouble();

    final newPoint = ConstellationPoint(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      emotion: emotion,
      recordedAt: DateTime.now(),
      x: x,
      y: y,
    );

    // Get or create constellation
    final constellationQuery = await firestore
        .collection('constellations')
        .where('pairId', arrayContains: userId)
        .limit(1)
        .get();

    if (constellationQuery.docs.isEmpty) {
      // Create new constellation
      await firestore.collection('constellations').add({
        'pairId': [userId, partnerId],
        'points': [newPoint.toFirestore()],
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } else {
      // Add to existing
      final docId = constellationQuery.docs.first.id;
      await firestore.collection('constellations').doc(docId).update({
        'points': FieldValue.arrayUnion([newPoint.toFirestore()]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    ref.refresh(constellationProvider);
  } catch (e) {
    print('[v0] Error adding constellation point: $e');
    rethrow;
  }
});
