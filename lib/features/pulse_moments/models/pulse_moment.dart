import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Pulse Moment - a real-time emotional microburst between partners.
/// Synchronized across devices with haptic and visual feedback.
class PulseMoment {
  final String id;
  final String senderId;
  final String emotion;
  final String? message;
  final DateTime createdAt;
  final bool isAcknowledged;
  final DateTime? acknowledgedAt;

  // Cosmetic properties for visual customization
  final String? cosmetic; // 'heartbeat', 'glow', 'sparkle', etc.

  PulseMoment({
    required this.id,
    required this.senderId,
    required this.emotion,
    this.message,
    required this.createdAt,
    this.isAcknowledged = false,
    this.acknowledgedAt,
    this.cosmetic,
  });

  factory PulseMoment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PulseMoment(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      emotion: data['emotion'] ?? 'neutral',
      message: data['message'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAcknowledged: data['isAcknowledged'] ?? false,
      acknowledgedAt: (data['acknowledgedAt'] as Timestamp?)?.toDate(),
      cosmetic: data['cosmetic'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'emotion': emotion,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAcknowledged': isAcknowledged,
      'acknowledgedAt': acknowledgedAt != null ? Timestamp.fromDate(acknowledgedAt!) : null,
      'cosmetic': cosmetic,
    };
  }

  PulseMoment copyWith({
    String? id,
    String? senderId,
    String? emotion,
    String? message,
    DateTime? createdAt,
    bool? isAcknowledged,
    DateTime? acknowledgedAt,
    String? cosmetic,
  }) {
    return PulseMoment(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      emotion: emotion ?? this.emotion,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      cosmetic: cosmetic ?? this.cosmetic,
    );
  }
}
