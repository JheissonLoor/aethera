import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart';
import 'package:aethera/features/cosmetics/models/cosmetic.dart';
import 'package:aethera/features/auth/providers/auth_provider.dart';

final firestore = FirebaseFirestore.instance;

/// Get all available cosmetics
final allCosmeticsProvider = FutureProvider<List<CosmeticItem>>((ref) async {
  try {
    final snapshot = await firestore.collection('cosmetics').get();
    return snapshot.docs
        .map((doc) => CosmeticItem.fromFirestore(doc))
        .toList();
  } catch (e) {
    print('[v0] Error fetching cosmetics: $e');
    return [];
  }
});

/// Get user's cosmetic profile
final userCosmeticsProvider = StreamProvider<UserCosmeticsProfile?>((ref) async* {
  final userId = ref.watch(authProvider)?.uid;

  if (userId == null) {
    yield null;
    return;
  }

  try {
    yield* firestore
        .collection('user_cosmetics')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return UserCosmeticsProfile(
              userId: userId,
              unlockedCosmeticIds: [],
              equippedCosmetics: {},
              totalPoints: 0,
              lastUpdated: DateTime.now(),
            );
          }
          return UserCosmeticsProfile.fromFirestore(doc);
        });
  } catch (e) {
    print('[v0] Error fetching user cosmetics: $e');
    yield null;
  }
});

/// Unlock a cosmetic
final unlockCosmeticProvider =
    FutureProvider.family<void, String>((ref, cosmeticId) async {
  final userId = ref.watch(authProvider)?.uid;

  if (userId == null) {
    throw Exception('User not found');
  }

  try {
    final userCosmeticRef = firestore.collection('user_cosmetics').doc(userId);

    await userCosmeticRef.update({
      'unlockedCosmeticIds': FieldValue.arrayUnion([cosmeticId]),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    ref.refresh(userCosmeticsProvider);
  } catch (e) {
    print('[v0] Error unlocking cosmetic: $e');
    rethrow;
  }
});

/// Equip a cosmetic
final equipCosmeticProvider =
    FutureProvider.family<void, ({String cosmeticId, String category})>(
        (ref, params) async {
  final userId = ref.watch(authProvider)?.uid;

  if (userId == null) {
    throw Exception('User not found');
  }

  try {
    final userCosmeticRef = firestore.collection('user_cosmetics').doc(userId);

    await userCosmeticRef.update({
      'equippedCosmetics.${params.category}': params.cosmeticId,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    ref.refresh(userCosmeticsProvider);
  } catch (e) {
    print('[v0] Error equipping cosmetic: $e');
    rethrow;
  }
});

/// Add points to user
final addPointsProvider = FutureProvider.family<void, int>((ref, points) async {
  final userId = ref.watch(authProvider)?.uid;

  if (userId == null) {
    throw Exception('User not found');
  }

  try {
    final userCosmeticRef = firestore.collection('user_cosmetics').doc(userId);

    await userCosmeticRef.update({
      'totalPoints': FieldValue.increment(points),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    ref.refresh(userCosmeticsProvider);
  } catch (e) {
    print('[v0] Error adding points: $e');
    rethrow;
  }
});
