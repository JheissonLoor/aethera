import 'package:cloud_firestore/cloud_firestore.dart';

/// Gamified weekly challenge for couples to strengthen connection.
class ConnectionChallenge {
  final String id;
  final String title;
  final String description;
  final String category; // 'communication', 'adventure', 'creativity', 'intimacy'
  final int difficulty; // 1-5
  final int pointsReward;
  final String? cosmetic; // Cosmetic unlock if completed
  final DateTime weekStart;
  final DateTime weekEnd;

  // Completion status
  final bool partnerOneCompleted;
  final bool partnerTwoCompleted;
  final DateTime? completedAt;

  ConnectionChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.pointsReward,
    this.cosmetic,
    required this.weekStart,
    required this.weekEnd,
    this.partnerOneCompleted = false,
    this.partnerTwoCompleted = false,
    this.completedAt,
  });

  bool get isCompleted => partnerOneCompleted && partnerTwoCompleted;

  factory ConnectionChallenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConnectionChallenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'communication',
      difficulty: data['difficulty'] ?? 1,
      pointsReward: data['pointsReward'] ?? 10,
      cosmetic: data['cosmetic'],
      weekStart: (data['weekStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weekEnd: (data['weekEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
      partnerOneCompleted: data['partnerOneCompleted'] ?? false,
      partnerTwoCompleted: data['partnerTwoCompleted'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'pointsReward': pointsReward,
      'cosmetic': cosmetic,
      'weekStart': Timestamp.fromDate(weekStart),
      'weekEnd': Timestamp.fromDate(weekEnd),
      'partnerOneCompleted': partnerOneCompleted,
      'partnerTwoCompleted': partnerTwoCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}

/// Pre-built challenge templates
class ChallengeTemplate {
  static const List<Map<String, dynamic>> templates = [
    {
      'title': 'Desert Island Conversation',
      'description': 'Ask each other: If we were on a desert island, what 3 things would you bring?',
      'category': 'communication',
      'difficulty': 1,
    },
    {
      'title': 'Memory Lane',
      'description': 'Share a favorite memory together and recreate one element of it',
      'category': 'creativity',
      'difficulty': 2,
    },
    {
      'title': 'Blind Date Redo',
      'description': 'Plan and have a "first date" experience again',
      'category': 'adventure',
      'difficulty': 4,
    },
    {
      'title': 'Love Letter Exchange',
      'description': 'Write each other handwritten letters about what you love most',
      'category': 'intimacy',
      'difficulty': 3,
    },
    {
      'title': 'Dream Planning',
      'description': 'Discuss your shared dreams for the next 5 years',
      'category': 'communication',
      'difficulty': 2,
    },
    {
      'title': 'Couples Playlist',
      'description': 'Create a shared playlist with songs that represent your relationship',
      'category': 'creativity',
      'difficulty': 2,
    },
  ];
}
