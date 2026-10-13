class FeedbackQuestion {
  final int id;
  final String questionText;
  final String? description;
  final int position;
  final bool active;
  final String? answerText;
  final bool answered;

  const FeedbackQuestion({
    required this.id,
    required this.questionText,
    this.description,
    required this.position,
    required this.active,
    this.answerText,
    required this.answered,
  });

  factory FeedbackQuestion.fromJson(Map<String, dynamic> json) {
    return FeedbackQuestion(
      id: json['id'] as int? ?? 0,
      questionText: json['question_text'] as String? ?? '',
      description: json['description'] as String?,
      position: json['position'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
      answerText: json['answer_text'] as String?,
      answered: json['answered'] as bool? ?? false,
    );
  }

  FeedbackQuestion copyWith({
    int? id,
    String? questionText,
    String? description,
    int? position,
    bool? active,
    String? answerText,
    bool? answered,
  }) {
    return FeedbackQuestion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      description: description ?? this.description,
      position: position ?? this.position,
      active: active ?? this.active,
      answerText: answerText ?? this.answerText,
      answered: answered ?? this.answered,
    );
  }
}

class FeedbackAnswerItem {
  final int questionId;
  final String answerText;

  const FeedbackAnswerItem({
    required this.questionId,
    required this.answerText,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'answer_text': answerText,
    };
  }
}
