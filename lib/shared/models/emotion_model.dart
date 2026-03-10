import 'package:equatable/equatable.dart';

class EmotionModel extends Equatable {
  final String mood;
  final double intensity;
  final DateTime updatedAt;

  const EmotionModel({
    required this.mood,
    required this.intensity,
    required this.updatedAt,
  });

  static EmotionModel get neutral => EmotionModel(
        mood: 'neutral',
        intensity: 0.5,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  factory EmotionModel.create({
    required String mood,
    double intensity = 0.8,
  }) =>
      EmotionModel(
        mood: mood,
        intensity: intensity,
        updatedAt: DateTime.now(),
      );

  factory EmotionModel.fromMap(Map<String, dynamic> map) => EmotionModel(
        mood: map['mood'] as String? ?? 'neutral',
        intensity: (map['intensity'] as num?)?.toDouble() ?? 0.5,
        updatedAt: map['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'mood': mood,
        'intensity': intensity,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  EmotionModel copyWith({
    String? mood,
    double? intensity,
    DateTime? updatedAt,
  }) =>
      EmotionModel(
        mood: mood ?? this.mood,
        intensity: intensity ?? this.intensity,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [mood, intensity, updatedAt];
}
