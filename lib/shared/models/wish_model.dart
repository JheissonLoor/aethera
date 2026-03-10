class WishModel {
  final String id;
  final String message;
  final String fromUserId;
  final DateTime createdAt;
  final bool seen;

  const WishModel({
    required this.id,
    required this.message,
    required this.fromUserId,
    required this.createdAt,
    this.seen = false,
  });

  factory WishModel.fromMap(String id, Map<String, dynamic> map) => WishModel(
        id: id,
        message: map['message'] as String? ?? '',
        fromUserId: map['fromUserId'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            map['createdAt'] as int? ?? 0),
        seen: map['seen'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'message': message,
        'fromUserId': fromUserId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'seen': seen,
      };
}
