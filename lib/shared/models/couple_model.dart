import 'package:equatable/equatable.dart';
import 'emotion_model.dart';

class UniverseState extends Equatable {
  final String phase; // dawn|day|dusk|night|aurora|storm
  final int level;    // 1-5
  final DateTime lastInteraction;

  const UniverseState({
    required this.phase,
    required this.level,
    required this.lastInteraction,
  });

  factory UniverseState.initial() => UniverseState(
        phase: 'night',
        level: 1,
        lastInteraction: DateTime.now(),
      );

  factory UniverseState.fromMap(Map<String, dynamic> map) => UniverseState(
        phase: map['phase'] as String? ?? 'night',
        level: map['level'] as int? ?? 1,
        lastInteraction: map['lastInteraction'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastInteraction'] as int)
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'phase': phase,
        'level': level,
        'lastInteraction': lastInteraction.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props => [phase, level, lastInteraction];
}

class CoupleModel extends Equatable {
  final String id;
  final String user1Id;
  final String user2Id;
  final String inviteCode;
  final DateTime createdAt;
  final int connectionStrength; // 0-100
  final UniverseState universeState;
  final EmotionModel? user1Emotion;
  final EmotionModel? user2Emotion;

  const CoupleModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.inviteCode,
    required this.createdAt,
    required this.connectionStrength,
    required this.universeState,
    this.user1Emotion,
    this.user2Emotion,
  });

  factory CoupleModel.fromMap(String id, Map<String, dynamic> map) => CoupleModel(
        id: id,
        user1Id: map['user1Id'] as String? ?? '',
        user2Id: map['user2Id'] as String? ?? '',
        inviteCode: map['inviteCode'] as String? ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
            : DateTime.now(),
        connectionStrength: map['connectionStrength'] as int? ?? 0,
        universeState: map['universeState'] != null
            ? UniverseState.fromMap(map['universeState'] as Map<String, dynamic>)
            : UniverseState.initial(),
        user1Emotion: map['user1Emotion'] != null
            ? EmotionModel.fromMap(map['user1Emotion'] as Map<String, dynamic>)
            : null,
        user2Emotion: map['user2Emotion'] != null
            ? EmotionModel.fromMap(map['user2Emotion'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'user1Id': user1Id,
        'user2Id': user2Id,
        'inviteCode': inviteCode,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'connectionStrength': connectionStrength,
        'universeState': universeState.toMap(),
        if (user1Emotion != null) 'user1Emotion': user1Emotion!.toMap(),
        if (user2Emotion != null) 'user2Emotion': user2Emotion!.toMap(),
      };

  CoupleModel copyWith({
    String? user2Id,
    int? connectionStrength,
    UniverseState? universeState,
    EmotionModel? user1Emotion,
    EmotionModel? user2Emotion,
  }) =>
      CoupleModel(
        id: id,
        user1Id: user1Id,
        user2Id: user2Id ?? this.user2Id,
        inviteCode: inviteCode,
        createdAt: createdAt,
        connectionStrength: connectionStrength ?? this.connectionStrength,
        universeState: universeState ?? this.universeState,
        user1Emotion: user1Emotion ?? this.user1Emotion,
        user2Emotion: user2Emotion ?? this.user2Emotion,
      );

  /// True when this couple was created but no partner has joined yet.
  bool get isSolo => user2Id.isEmpty;

  String get combinedEmotion {
    final m1 = user1Emotion?.mood ?? 'neutral';
    final m2 = user2Emotion?.mood ?? 'neutral';
    if (m1 == m2) return m1;
    // Priority: love > joy > peace > longing > melancholy > anxious
    const priority = ['love', 'joy', 'peace', 'longing', 'melancholy', 'anxious', 'neutral'];
    final p1 = priority.indexOf(m1);
    final p2 = priority.indexOf(m2);
    return p1 <= p2 ? m1 : m2;
  }

  @override
  List<Object?> get props => [id, connectionStrength, universeState];
}
