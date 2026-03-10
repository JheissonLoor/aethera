import 'package:equatable/equatable.dart';

class GoalModel extends Equatable {
  final String id;
  final String coupleId;
  final String title;
  final String description;
  final DateTime targetDate;
  final double progress; // 0.0-1.0
  final String symbol;   // estructura en el horizonte
  final DateTime createdAt;
  final DateTime? completedAt;

  const GoalModel({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.description,
    required this.targetDate,
    required this.progress,
    required this.symbol,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => completedAt != null;

  /// Distancia visual en el universo: 0.0 = cercano (completo), 1.0 = lejano (nuevo)
  double get universeDistance => 1.0 - progress;

  factory GoalModel.fromMap(String id, Map<String, dynamic> map) => GoalModel(
        id: id,
        coupleId: map['coupleId'] as String,
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        targetDate: map['targetDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['targetDate'] as int)
            : DateTime.now().add(const Duration(days: 30)),
        progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
        symbol: map['symbol'] as String? ?? 'lighthouse',
        createdAt: map['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
            : DateTime.now(),
        completedAt: map['completedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'coupleId': coupleId,
        'title': title,
        'description': description,
        'targetDate': targetDate.millisecondsSinceEpoch,
        'progress': progress,
        'symbol': symbol,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props => [id, progress, completedAt];
}
