class UserModel {
  final String id;
  final String name;
  final String email;
  final int totalScore;
  final int quizzesTaken;
  final double averageScore;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.totalScore,
    required this.quizzesTaken,
    required this.averageScore,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      totalScore: map['totalScore'] ?? 0,
      quizzesTaken: map['quizzesTaken'] ?? 0,
      averageScore: (map['averageScore'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'totalScore': totalScore,
      'quizzesTaken': quizzesTaken,
      'averageScore': averageScore,
    };
  }
}
