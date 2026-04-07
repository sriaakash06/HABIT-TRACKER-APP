import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  // Use GoogleSignIn.instance in v7.0.0+
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    try {
      _auth.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
    } catch (e) {
      debugPrint("Auth initialization error: $e");
    }
  }

  Future<String?> signUp(String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // Update display name immediately after account creation
      await credential.user?.updateDisplayName(displayName);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      // authenticate() replaced signIn() in v7.0.0+
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return 'Google sign in aborted';

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
