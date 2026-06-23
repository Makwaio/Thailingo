import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Getters instead of fields so Firebase.instance isn't accessed at
  // construction time (which would crash on web where Firebase is not init'd).
  FirebaseAuth get _auth => FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) return null;
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
    if (kIsWeb) return;
    await Future.wait([
      _googleSignIn.signOut(),
      _auth.signOut(),
    ]);
  }

  User? getCurrentUser() => kIsWeb ? null : _auth.currentUser;
  bool isSignedIn() => kIsWeb ? false : _auth.currentUser != null;
  String? getUserId() => kIsWeb ? null : _auth.currentUser?.uid;
  String? getUserName() => kIsWeb ? null : _auth.currentUser?.displayName;
  String? getUserEmail() => kIsWeb ? null : _auth.currentUser?.email;
  String? getUserPhoto() => kIsWeb ? null : _auth.currentUser?.photoURL;

  Stream<User?> get authStateChanges =>
      kIsWeb ? Stream.value(null) : _auth.authStateChanges();
}
