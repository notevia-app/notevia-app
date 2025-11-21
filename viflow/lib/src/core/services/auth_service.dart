import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- DÜZELTME: WEB CLIENT ID ---
  // Google Cloud'dan aldığın Web Client ID'yi buraya yapıştır.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '222478628756-bcin8912la7aeedbspj4co9b9mi6ss96.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;
  String? get userId => _auth.currentUser?.uid;

  /// Başlangıçta Oturum Kontrolü
  Future<User?> initializeAuth() async {
    try {
      if (currentUser != null) {
        return currentUser;
      }
      UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print("Auth initialize Hatası: $e");
      return null;
    }
  }

  /// Anonim Giriş
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

  /// Google ile Giriş
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (currentUser != null && currentUser!.isAnonymous) {
        return await currentUser!.linkWithCredential(credential);
      } else {
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      print("Google Giriş Hatası: $e");
      rethrow;
    }
  }

  /// Çıkış
  Future<void> signOut() async {
    try { await _googleSignIn.signOut(); } catch (e) {}
    try { await _auth.signOut(); } catch (e) {}
  }
}