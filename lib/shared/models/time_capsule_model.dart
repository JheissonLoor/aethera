import 'package:equatable/equatable.dart';

class TimeCapsuleModel extends Equatable {
  final String id;
  final String coupleId;
  final String title;
  final String message;
  final String createdByUserId;
  final DateTime createdAt;
  final DateTime unlockAt;
  final List<String> openedByUserIds;

  const TimeCapsuleModel({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.message,
    required this.createdByUserId,
    required this.createdAt,
    required this.unlockAt,
    this.openedByUserIds = const <String>[],
  });

  bool get isUnlocked => !unlockAt.isAfter(DateTime.now());

  bool isOpenedBy(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    return openedByUserIds.contains(userId);
  }

  factory TimeCapsuleModel.fromMap(String id, Map<String, dynamic> map) {
    final rawOpenedBy = map['openedByUserIds'];
    final openedBy =
        rawOpenedBy is List
            ? rawOpenedBy.whereType<String>().toList(growable: false)
            : const <String>[];

    return TimeCapsuleModel(
      id: id,
      coupleId: map['coupleId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      createdByUserId: map['createdByUserId'] as String? ?? '',
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
              : DateTime.now(),
      unlockAt:
          map['unlockAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['unlockAt'] as int)
              : DateTime.now(),
      openedByUserIds: openedBy,
    );
  }

  Map<String, dynamic> toMap() => {
    'coupleId': coupleId,
    'title': title,
    'message': message,
    'createdByUserId': createdByUserId,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'unlockAt': unlockAt.millisecondsSinceEpoch,
    'openedByUserIds': openedByUserIds,
  };

  @override
  List<Object?> get props => [id, unlockAt, openedByUserIds];
}
