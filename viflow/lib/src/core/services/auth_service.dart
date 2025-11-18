import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '523503900616-6rbb5lf278c8802a0gg4suaujepe0ui6.apps.googleusercontent.com' : null,
    serverClientId: '523503900616-6rbb5lf278c8802a0gg4suaujepe0ui6.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;
  String? get userId => _auth.currentUser?.uid;

  /// 1. Anonim Giriş
  Future<String?> signInAnonymously() async {
    try {
      if (currentUser != null) return currentUser!.uid;
      UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user?.uid;
    } catch (e) {
      print("Anonim Auth Hatası: $e");
      return null;
    }
  }

  /// 2. Google ile Giriş
  Future<UserCredential?> signInWithGoogle() async {
    try {
      try { await _googleSignIn.disconnect(); } catch (_) {}
      try { await _googleSignIn.signOut(); } catch (_) {}

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Kullanıcı iptal etti

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (currentUser != null && currentUser!.isAnonymous) {
        try {
          return await currentUser!.linkWithCredential(credential);
        } catch (_) {
          try { await _auth.signOut(); } catch (_) {}
          return await _auth.signInWithCredential(credential);
        }
      } else {
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      print("Google Giriş Hatası: $e");
      // PlatformException(exception, ERROR, null, null) hatası burada yakalanıyor
      rethrow; // Hatanın nedenini görmek için tekrar fırlat
    }
  }

  /// 3. Çıkış Yap
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print("Google SignOut Hatası: $e");
    }
    try {
      await _auth.signOut();
    } catch (e) {
      print("Firebase SignOut Hatası: $e");
    }
  }
}