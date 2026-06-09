import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a secret memory stored in an encrypted vault.
class MemoryVault {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final DateTime createdAt;
  final String revealCondition; // 'immediate', 'challenge_complete', 'anniversary', 'birthday'
  final DateTime? revealDate;
  final bool isRevealed;
  final DateTime? revealedAt;
  final String? cosmetic; // Special unlock like 'heart_lock', 'crystal_vault'

  MemoryVault({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.revealCondition,
    this.revealDate,
    this.isRevealed = false,
    this.revealedAt,
    this.cosmetic,
  });

  bool get canReveal {
    switch (revealCondition) {
      case 'immediate':
        return true;
      case 'challenge_complete':
        return false; // Logic handled by challenges
      case 'anniversary':
      case 'birthday':
        if (revealDate == null) return false;
        return DateTime.now().isAfter(revealDate!);
      default:
        return false;
    }
  }

  factory MemoryVault.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemoryVault(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      revealCondition: data['revealCondition'] ?? 'immediate',
      revealDate: (data['revealDate'] as Timestamp?)?.toDate(),
      isRevealed: data['isRevealed'] ?? false,
      revealedAt: (data['revealedAt'] as Timestamp?)?.toDate(),
      cosmetic: data['cosmetic'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'revealCondition': revealCondition,
      'revealDate': revealDate != null ? Timestamp.fromDate(revealDate!) : null,
      'isRevealed': isRevealed,
      'revealedAt': revealedAt != null ? Timestamp.fromDate(revealedAt!) : null,
      'cosmetic': cosmetic,
    };
  }
}

/// Collections of related memory vaults
class MemoryVaultCollection {
  final String id;
  final String title;
  final String? description;
  final List<String> vaultIds;
  final DateTime createdAt;
  final String theme; // 'love', 'adventure', 'milestones'

  MemoryVaultCollection({
    required this.id,
    required this.title,
    this.description,
    required this.vaultIds,
    required this.createdAt,
    required this.theme,
  });
}
