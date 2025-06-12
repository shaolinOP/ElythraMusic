import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Enhanced authentication service with improved Google Sign-In and user management
class EnhancedAuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  static const String _userDataKey = 'user_data';
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// Enhanced Google Sign-In with better error handling
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      log('Starting Google Sign-In process');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        log('Google Sign-In cancelled by user');
        return null;
      }

      log('Google user obtained: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to obtain Google authentication tokens');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _saveUserData(userCredential.user!, googleAuth);
        log('Google Sign-In successful for: ${userCredential.user!.email}');
      }

      return userCredential;
    } catch (e) {
      log('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Enhanced sign out with cleanup
  static Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Sign out from Firebase
      await _firebaseAuth.signOut();
      
      // Clear stored user data
      await _clearUserData();
      
      log('User signed out successfully');
    } catch (e) {
      log('Sign out error: $e');
      rethrow;
    }
  }

  /// Check if user is currently signed in
  static bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// Get current user
  static User? get currentUser => _firebaseAuth.currentUser;

  /// Get user stream for real-time updates
  static Stream<User?> get userStream => _firebaseAuth.authStateChanges();

  /// Enhanced user profile with additional data
  static Future<EnhancedUserProfile?> getUserProfile() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userDataKey);
      
      if (userData != null) {
        final data = jsonDecode(userData);
        return EnhancedUserProfile.fromMap(data);
      }

      // Create profile from Firebase user if no cached data
      return EnhancedUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoURL: user.photoURL,
        isEmailVerified: user.emailVerified,
        creationTime: user.metadata.creationTime,
        lastSignInTime: user.metadata.lastSignInTime,
      );
    } catch (e) {
      log('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No user signed in');

    try {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
      
      // Update cached data
      final profile = await getUserProfile();
      if (profile != null) {
        final updatedProfile = profile.copyWith(
          displayName: displayName ?? profile.displayName,
          photoURL: photoURL ?? profile.photoURL,
        );
        await _saveUserProfile(updatedProfile);
      }
      
      log('User profile updated successfully');
    } catch (e) {
      log('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Refresh authentication token
  static Future<String?> refreshAuthToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken(true);
      
      // Cache the token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authTokenKey, token);
      
      return token;
    } catch (e) {
      log('Error refreshing auth token: $e');
      return null;
    }
  }

  /// Get cached auth token
  static Future<String?> getCachedAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_authTokenKey);
    } catch (e) {
      log('Error getting cached auth token: $e');
      return null;
    }
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No user signed in');

    try {
      // Sign out from Google first
      await _googleSignIn.signOut();
      
      // Delete Firebase account
      await user.delete();
      
      // Clear all cached data
      await _clearUserData();
      
      log('User account deleted successfully');
    } catch (e) {
      log('Error deleting user account: $e');
      rethrow;
    }
  }

  /// Check if user needs to re-authenticate
  static bool needsReauthentication() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return true;

    final lastSignIn = user.metadata.lastSignInTime;
    if (lastSignIn == null) return true;

    // Require re-auth if last sign-in was more than 30 days ago
    final daysSinceLastSignIn = DateTime.now().difference(lastSignIn).inDays;
    return daysSinceLastSignIn > 30;
  }

  /// Re-authenticate user
  static Future<void> reauthenticate() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No user signed in');

    try {
      // Get fresh Google credentials
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Re-authentication cancelled');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Re-authenticate with Firebase
      await user.reauthenticateWithCredential(credential);
      
      log('User re-authenticated successfully');
    } catch (e) {
      log('Re-authentication error: $e');
      rethrow;
    }
  }

  // Private helper methods
  static Future<void> _saveUserData(User user, GoogleSignInAuthentication googleAuth) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final profile = EnhancedUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoURL: user.photoURL,
        isEmailVerified: user.emailVerified,
        creationTime: user.metadata.creationTime,
        lastSignInTime: user.metadata.lastSignInTime,
        googleAccessToken: googleAuth.accessToken,
        googleIdToken: googleAuth.idToken,
      );

      await prefs.setString(_userDataKey, jsonEncode(profile.toMap()));
      
      if (googleAuth.accessToken != null) {
        await prefs.setString(_authTokenKey, googleAuth.accessToken!);
      }
    } catch (e) {
      log('Error saving user data: $e');
    }
  }

  static Future<void> _saveUserProfile(EnhancedUserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(profile.toMap()));
    } catch (e) {
      log('Error saving user profile: $e');
    }
  }

  static Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.remove(_authTokenKey);
      await prefs.remove(_refreshTokenKey);
    } catch (e) {
      log('Error clearing user data: $e');
    }
  }
}

/// Enhanced user profile with additional metadata
class EnhancedUserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final bool isEmailVerified;
  final DateTime? creationTime;
  final DateTime? lastSignInTime;
  final String? googleAccessToken;
  final String? googleIdToken;
  final Map<String, dynamic>? customData;

  const EnhancedUserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.isEmailVerified = false,
    this.creationTime,
    this.lastSignInTime,
    this.googleAccessToken,
    this.googleIdToken,
    this.customData,
  });

  factory EnhancedUserProfile.fromMap(Map<String, dynamic> map) {
    return EnhancedUserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'],
      isEmailVerified: map['isEmailVerified'] ?? false,
      creationTime: map['creationTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['creationTime'])
          : null,
      lastSignInTime: map['lastSignInTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSignInTime'])
          : null,
      googleAccessToken: map['googleAccessToken'],
      googleIdToken: map['googleIdToken'],
      customData: map['customData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isEmailVerified': isEmailVerified,
      'creationTime': creationTime?.millisecondsSinceEpoch,
      'lastSignInTime': lastSignInTime?.millisecondsSinceEpoch,
      'googleAccessToken': googleAccessToken,
      'googleIdToken': googleIdToken,
      'customData': customData,
    };
  }

  EnhancedUserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isEmailVerified,
    DateTime? creationTime,
    DateTime? lastSignInTime,
    String? googleAccessToken,
    String? googleIdToken,
    Map<String, dynamic>? customData,
  }) {
    return EnhancedUserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      creationTime: creationTime ?? this.creationTime,
      lastSignInTime: lastSignInTime ?? this.lastSignInTime,
      googleAccessToken: googleAccessToken ?? this.googleAccessToken,
      googleIdToken: googleIdToken ?? this.googleIdToken,
      customData: customData ?? this.customData,
    );
  }

  String get initials {
    if (displayName.isEmpty) return email.isNotEmpty ? email[0].toUpperCase() : '?';
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  bool get hasValidPhoto => photoURL != null && photoURL!.isNotEmpty;
}