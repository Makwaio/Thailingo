import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _googleSignIn.signOut(),
      _auth.signOut(),
    ]);
  }

  User? getCurrentUser() => _auth.currentUser;
  bool isSignedIn() => _auth.currentUser != null;
  String? getUserId() => _auth.currentUser?.uid;
  String? getUserName() => _auth.currentUser?.displayName;
  String? getUserEmail() => _auth.currentUser?.email;
  String? getUserPhoto() => _auth.currentUser?.photoURL;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
