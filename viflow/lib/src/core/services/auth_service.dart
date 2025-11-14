import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Aktif kullanıcıyı döndürür
  User? get currentUser => _auth.currentUser;

  /// Aktif kullanıcının UID'sini döndürür
  String? get userId => _auth.currentUser?.uid;

  /// 1. Anonim Giriş (Uygulama açılışında)
  /// Mevcut oturum yoksa anonim oturum açar, varsa mevcut ID'yi döndürür.
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

  /// 2. Google ile Giriş/Hesap Bağlama
  /// Kullanıcı anonimse hesabı bağlar, değilse normal giriş yapar.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Kullanıcı iptal etti

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Eğer kullanıcı anonim olarak giriş yapmışsa, hesabı Google'a BAĞLA
      if (currentUser != null && currentUser!.isAnonymous) {
        return await currentUser!.linkWithCredential(credential);
      }
      // Zaten bir Google hesabı varsa veya oturum kapalıysa, normal GİRİŞ YAP
      else {
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      print("Google Giriş Hatası: $e");
      return null;
    }
  }

  /// 3. Çıkış Yap
  /// Veri sıfırlama veya hesap değiştirme için kullanılır.
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