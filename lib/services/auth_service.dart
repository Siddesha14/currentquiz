import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final trimmedEmail = email.trim();
      final trimmedPassword = password.trim();
      final trimmedName = name.trim();

      print('AuthService: Creating user with email: $trimmedEmail');

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      print('AuthService: User created, UID: ${userCredential.user!.uid}');

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': trimmedName,
        'email': trimmedEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'totalScore': 0,
        'quizzesTaken': 0,
        'averageScore': 0.0,
      });

      print('AuthService: Firestore user document created');

      return null;
    } on FirebaseAuthException catch (e) {
      print('AuthService: Firebase Auth Error: ${e.code} - ${e.message}');
      return e.message;
    } catch (e) {
      print('AuthService: General Error: $e');
      return 'An error occurred. Please try again.';
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final trimmedEmail = email.trim();
      final trimmedPassword = password.trim();

      print('AuthService: Signing in with email: $trimmedEmail');

      await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      print('AuthService: Sign in successful');
      return null;
    } on FirebaseAuthException catch (e) {
      print('AuthService: Sign in error: ${e.code} - ${e.message}');
      return e.message;
    } catch (e) {
      print('AuthService: General sign in error: $e');
      return 'An error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }
}
