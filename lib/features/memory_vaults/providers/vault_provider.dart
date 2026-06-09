import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart';
import 'package:aethera/features/memory_vaults/models/memory_vault.dart';
import 'package:aethera/features/auth/providers/auth_provider.dart';
import 'package:aethera/features/pulse_moments/providers/pulse_moments_provider.dart';

final firestore = FirebaseFirestore.instance;

/// Get all memory vaults for the current pair
final allMemoryVaultsProvider = StreamProvider<List<MemoryVault>>((ref) async* {
  final userId = ref.watch(authProvider)?.uid;
  final partnerId = await ref.watch(partnerIdProvider.future);

  if (userId == null || partnerId == null) {
    yield [];
    return;
  }

  try {
    final pairId = [userId, partnerId].sort().join('_');

    yield* firestore
        .collection('memory_vaults')
        .where('pairId', isEqualTo: pairId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MemoryVault.fromFirestore(doc))
              .toList();
        });
  } catch (e) {
    print('[v0] Error fetching memory vaults: $e');
    yield [];
  }
});

/// Get vaults that are ready to reveal
final revealableVaultsProvider = StreamProvider<List<MemoryVault>>((ref) async* {
  final allVaults = await ref.watch(allMemoryVaultsProvider.future);
  yield allVaults.where((v) => v.canReveal && !v.isRevealed).toList();
});

/// Create a new memory vault
final createVaultProvider =
    FutureProvider.family<void, MemoryVault>((ref, vault) async {
  final userId = ref.watch(authProvider)?.uid;
  final partnerId = await ref.watch(partnerIdProvider.future);

  if (userId == null || partnerId == null) {
    throw Exception('User or partner not found');
  }

  try {
    final pairId = [userId, partnerId].sort().join('_');

    await firestore.collection('memory_vaults').add({
      ...vault.toFirestore(),
      'pairId': pairId,
    });

    ref.refresh(allMemoryVaultsProvider);
  } catch (e) {
    print('[v0] Error creating vault: $e');
    rethrow;
  }
});

/// Reveal a memory vault
final revealVaultProvider = FutureProvider.family<void, String>((ref, vaultId) async {
  try {
    await firestore.collection('memory_vaults').doc(vaultId).update({
      'isRevealed': true,
      'revealedAt': FieldValue.serverTimestamp(),
    });

    ref.refresh(allMemoryVaultsProvider);
    ref.refresh(revealableVaultsProvider);
  } catch (e) {
    print('[v0] Error revealing vault: $e');
    rethrow;
  }
});

/// Delete a memory vault
final deleteVaultProvider = FutureProvider.family<void, String>((ref, vaultId) async {
  try {
    await firestore.collection('memory_vaults').doc(vaultId).delete();
    ref.refresh(allMemoryVaultsProvider);
  } catch (e) {
    print('[v0] Error deleting vault: $e');
    rethrow;
  }
});
