import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _ensureUserDocument(user);
      }
      notifyListeners();
    });
  }

  Future<void> _ensureUserDocument(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          photoUrl: user.photoURL ?? '',
          totalScore: 0,
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      }
    } catch (e) {
      debugPrint('Error ensuring user document: $e');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web-specific sign-in
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(
          googleProvider,
        );
        final user = userCredential.user;
        if (user != null) {
          await _checkAndCreateUser(user);
        }
        return user;
      } else {
        // Mobile sign-in
        final GoogleSignInAccount? googleUser = await _googleSignIn
            .authenticate();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: null,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        final user = userCredential.user;
        if (user != null) {
          await _checkAndCreateUser(user);
        }
        return user;
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> _checkAndCreateUser(User user) async {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL ?? '',
        totalScore: 0,
      );
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
    }
  }

  Future<void> updateUserScore(int scoreToAdd) async {
    if (_user == null) return;
    try {
      await _firestore.collection('users').doc(_user!.uid).set({
        'totalScore': FieldValue.increment(scoreToAdd),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user score: $e');
    }
  }

  Future<void> saveQuizResult({
    required int score,
    required int totalQuestions,
    required String subjectName,
  }) async {
    if (_user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('history')
          .add({
            'score': score,
            'totalQuestions': totalQuestions,
            'subjectName': subjectName,
            'date': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error saving quiz result: $e');
    }
  }

  Stream<QuerySnapshot> getQuizHistory() {
    if (_user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('history')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
