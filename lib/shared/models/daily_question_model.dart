import 'package:equatable/equatable.dart';

class DailyQuestionModel extends Equatable {
  final String id;
  final String coupleId;
  final String dayKey;
  final String question;
  final Map<String, String> answers;
  final DateTime createdAt;
  final DateTime? revealedAt;

  const DailyQuestionModel({
    required this.id,
    required this.coupleId,
    required this.dayKey,
    required this.question,
    required this.answers,
    required this.createdAt,
    this.revealedAt,
  });

  bool get isRevealed => revealedAt != null || answers.length >= 2;

  bool isAnsweredBy(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    return answers.containsKey(userId);
  }

  String? answerBy(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    return answers[userId];
  }

  factory DailyQuestionModel.fromMap(String id, Map<String, dynamic> map) {
    final rawAnswers = map['answers'];
    final parsedAnswers = <String, String>{};
    if (rawAnswers is Map) {
      for (final entry in rawAnswers.entries) {
        final key = entry.key?.toString();
        final value = entry.value?.toString();
        if (key != null &&
            key.isNotEmpty &&
            value != null &&
            value.isNotEmpty) {
          parsedAnswers[key] = value;
        }
      }
    }

    return DailyQuestionModel(
      id: id,
      coupleId: map['coupleId'] as String? ?? '',
      dayKey: map['dayKey'] as String? ?? '',
      question: map['question'] as String? ?? '',
      answers: parsedAnswers,
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
              : DateTime.now(),
      revealedAt:
          map['revealedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['revealedAt'] as int)
              : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'coupleId': coupleId,
    'dayKey': dayKey,
    'question': question,
    'answers': answers,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'revealedAt': revealedAt?.millisecondsSinceEpoch,
  };

  @override
  List<Object?> get props => [id, dayKey, question, answers, revealedAt];
}
