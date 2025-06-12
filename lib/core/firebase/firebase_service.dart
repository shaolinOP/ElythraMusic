import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:elythra_music/core/firebase/firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static GoogleSignIn get googleSignIn => GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
      );

  /// Initialize Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await auth.signInWithCredential(credential);
    } catch (e) {
      // print('Error signing in with Google: $e');
      return null;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await Future.wait([
      auth.signOut(),
      googleSignIn.signOut(),
    ]);
  }

  /// Get current user
  static User? get currentUser => auth.currentUser;

  /// Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  /// Listen to auth state changes
  static Stream<User?> get authStateChanges => auth.authStateChanges();
}