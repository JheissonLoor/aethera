import 'package:cloud_firestore/cloud_firestore.dart';

/// Visual cosmetic upgrade for the app (themes, icons, effects).
class CosmeticItem {
  final String id;
  final String name;
  final String description;
  final String category; // 'universe_theme', 'button_style', 'particle', 'glow'
  final String unlockCondition; // How to unlock
  final String? imageUrl;
  final int? pointsCost;
  final bool isDefault;

  CosmeticItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.unlockCondition,
    this.imageUrl,
    this.pointsCost,
    this.isDefault = false,
  });

  factory CosmeticItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CosmeticItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'universe_theme',
      unlockCondition: data['unlockCondition'] ?? 'challenge',
      imageUrl: data['imageUrl'],
      pointsCost: data['pointsCost'],
      isDefault: data['isDefault'] ?? false,
    );
  }
}

/// User's cosmetic collection and equipped items
class UserCosmeticsProfile {
  final String userId;
  final List<String> unlockedCosmeticIds;
  final Map<String, String> equippedCosmetics; // category -> cosmeticId
  final int totalPoints;
  final DateTime lastUpdated;

  UserCosmeticsProfile({
    required this.userId,
    required this.unlockedCosmeticIds,
    required this.equippedCosmetics,
    required this.totalPoints,
    required this.lastUpdated,
  });

  factory UserCosmeticsProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserCosmeticsProfile(
      userId: doc.id,
      unlockedCosmeticIds:
          List<String>.from(data['unlockedCosmeticIds'] ?? []),
      equippedCosmetics:
          Map<String, String>.from(data['equippedCosmetics'] ?? {}),
      totalPoints: data['totalPoints'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'unlockedCosmeticIds': unlockedCosmeticIds,
      'equippedCosmetics': equippedCosmetics,
      'totalPoints': totalPoints,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

/// Pre-built cosmetic templates
class CosmeticTemplates {
  static const List<Map<String, dynamic>> templates = [
    {
      'name': 'Aurora Borealis',
      'description': 'Magical aurora light theme',
      'category': 'universe_theme',
      'unlockCondition': 'complete_3_challenges',
      'isDefault': false,
    },
    {
      'name': 'Nebula Dream',
      'description': 'Purple nebula particle effects',
      'category': 'particle',
      'unlockCondition': 'reach_1_month_together',
      'isDefault': false,
    },
    {
      'name': 'Crystalline Glow',
      'description': 'Crystal-like button styling',
      'category': 'button_style',
      'unlockCondition': 'send_50_pulses',
      'isDefault': false,
    },
    {
      'name': 'Twilight Theme',
      'description': 'Soft twilight universe colors',
      'category': 'universe_theme',
      'unlockCondition': 'complete_all_challenges_week',
      'isDefault': false,
    },
  ];
}
