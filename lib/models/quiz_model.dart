class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}

class QuizResult {
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final String topic;
  final DateTime completedAt;

  QuizResult({
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.topic,
    required this.completedAt,
  });

  double get percentage => (correctAnswers / totalQuestions) * 100;

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'topic': topic,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}
