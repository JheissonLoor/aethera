import 'package:equatable/equatable.dart';

class MemoryModel extends Equatable {
  final String id;
  final String coupleId;
  final String type; // tree|lighthouse|constellation|bridge|island
  final String title;
  final String description;
  final String? createdByUserId;
  final String? photoUrl;
  final DateTime createdAt;
  final double posX;
  final double posY;

  const MemoryModel({
    required this.id,
    required this.coupleId,
    required this.type,
    required this.title,
    required this.description,
    this.createdByUserId,
    this.photoUrl,
    required this.createdAt,
    required this.posX,
    required this.posY,
  });

  factory MemoryModel.fromMap(String id, Map<String, dynamic> map) =>
      MemoryModel(
        id: id,
        coupleId: map['coupleId'] as String,
        type: map['type'] as String? ?? 'constellation',
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        createdByUserId: map['createdByUserId'] as String?,
        photoUrl: map['photoUrl'] as String?,
        createdAt:
            map['createdAt'] != null
                ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
                : DateTime.now(),
        posX: (map['posX'] as num?)?.toDouble() ?? 0.5,
        posY: (map['posY'] as num?)?.toDouble() ?? 0.5,
      );

  Map<String, dynamic> toMap() => {
    'coupleId': coupleId,
    'type': type,
    'title': title,
    'description': description,
    if (createdByUserId != null) 'createdByUserId': createdByUserId,
    'photoUrl': photoUrl,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'posX': posX,
    'posY': posY,
  };

  @override
  List<Object?> get props => [id, type, title, posX, posY, createdByUserId];
}
