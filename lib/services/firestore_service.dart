import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/quiz_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  // Update user stats after quiz
  Future<void> updateUserStats(String userId, QuizResult result) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userData = await userRef.get();

      if (userData.exists) {
        final currentTotal = userData.data()?['totalScore'] ?? 0;
        final currentQuizzes = userData.data()?['quizzesTaken'] ?? 0;
        final newTotal = currentTotal + result.score;
        final newQuizzes = currentQuizzes + 1;
        final newAverage = newTotal / newQuizzes;

        await userRef.update({
          'totalScore': newTotal,
          'quizzesTaken': newQuizzes,
          'averageScore': newAverage,
        });

        // Save quiz result
        await userRef.collection('quizHistory').add(result.toMap());

        // Update leaderboard
        await updateLeaderboard(userId, userData.data()?['name'] ?? 'Unknown', newTotal);
      }
    } catch (e) {
      throw Exception('Error updating user stats: $e');
    }
  }

  // Update leaderboard
  Future<void> updateLeaderboard(String userId, String userName, int totalScore) async {
    try {
      await _firestore.collection('leaderboard').doc(userId).set({
        'userId': userId,
        'userName': userName,
        'totalScore': totalScore,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating leaderboard: $e');
    }
  }

  // Get leaderboard
  Stream<List<Map<String, dynamic>>> getLeaderboard() {
    return _firestore
        .collection('leaderboard')
        .orderBy('totalScore', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
