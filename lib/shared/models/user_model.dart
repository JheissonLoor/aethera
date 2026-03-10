import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? coupleId;
  final DateTime createdAt;
  final DateTime? lastSeen;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.coupleId,
    required this.createdAt,
    this.lastSeen,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) => UserModel(
        uid: uid,
        email: map['email'] as String? ?? '',
        displayName: map['displayName'] as String? ?? '',
        coupleId: map['coupleId'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
            : DateTime.now(),
        lastSeen: map['lastSeen'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] as int)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        if (coupleId != null) 'coupleId': coupleId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        if (lastSeen != null) 'lastSeen': lastSeen!.millisecondsSinceEpoch,
      };

  UserModel copyWith({String? coupleId}) => UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        coupleId: coupleId ?? this.coupleId,
        createdAt: createdAt,
        lastSeen: lastSeen,
      );

  @override
  List<Object?> get props => [uid, email, displayName, coupleId];
}
