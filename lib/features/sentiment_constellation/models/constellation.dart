import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a point in the emotional constellation.
/// Each emotion creates a star that connects to form the relationship journey.
class ConstellationPoint {
  final String id;
  final String emotion;
  final DateTime recordedAt;
  final double x;
  final double y;
  final String? note;

  ConstellationPoint({
    required this.id,
    required this.emotion,
    required this.recordedAt,
    required this.x,
    required this.y,
    this.note,
  });

  factory ConstellationPoint.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConstellationPoint(
      id: doc.id,
      emotion: data['emotion'] ?? 'neutral',
      recordedAt: (data['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      x: (data['x'] ?? 0.0).toDouble(),
      y: (data['y'] ?? 0.0).toDouble(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'emotion': emotion,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'x': x,
      'y': y,
      'note': note,
    };
  }
}

/// The complete constellation showing emotional journey
class SentimentConstellation {
  final String id;
  final String pairId;
  final List<ConstellationPoint> points;
  final DateTime createdAt;
  final DateTime lastUpdated;

  SentimentConstellation({
    required this.id,
    required this.pairId,
    required this.points,
    required this.createdAt,
    required this.lastUpdated,
  });

  // Calculate the overall emotional state
  String get dominantEmotion {
    if (points.isEmpty) return 'neutral';
    final emotionCounts = <String, int>{};
    for (final point in points) {
      emotionCounts[point.emotion] = (emotionCounts[point.emotion] ?? 0) + 1;
    }
    return emotionCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Average distance traveled (complexity of journey)
  double get journeyComplexity {
    if (points.length < 2) return 0;
    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      totalDistance += ((p2.x - p1.x).abs() + (p2.y - p1.y).abs());
    }
    return totalDistance / (points.length - 1);
  }
}
