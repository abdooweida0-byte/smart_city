import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? firebaseUser;
  AppUser? appUser;
  bool initializing = true;

  StreamSubscription? _authSub;
  StreamSubscription? _userSub;

  AuthProvider() {
    _authSub = _auth.authStateChanges().listen((u) {
      firebaseUser = u;
      _userSub?.cancel();
      if (u == null) {
        appUser = null;
        initializing = false;
        notifyListeners();
        return;
      }
      _userSub = _db.collection('users').doc(u.uid).snapshots().listen((s) {
        appUser = s.exists
            ? AppUser.fromDoc(s)
            : AppUser(
                uid: u.uid,
                name: u.displayName ?? '',
                email: u.email ?? '',
                role: 'citizen',
                points: 0);
        initializing = false;
        notifyListeners();
      });
    });
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> register(String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await cred.user!.updateDisplayName(name.trim());
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': 'citizen',
        'points': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e);
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _msg(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'البريد أو كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      default:
        return 'حدث خطأ: ${e.code}';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
