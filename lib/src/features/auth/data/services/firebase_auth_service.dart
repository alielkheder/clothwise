import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clothwise/src/features/auth/domain/entities/app_user.dart';

/// Firebase Authentication Service
/// Handles all authentication operations including:
/// - Email/password registration with email verification
/// - Login with email/password
/// - Email verification OTP
/// - Password reset
/// - User profile management in Firestore
class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Reference to users collection in Firestore
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Stream of authentication state changes
  /// Emits AppUser when logged in, null when logged out
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _getUserFromFirestore(firebaseUser.uid);
    });
  }

  /// Get current authenticated user
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _getUserFromFirestore(firebaseUser.uid);
  }

  /// Register new user with email, password, and username
  /// Automatically sends verification email after registration
  ///
  /// Throws:
  /// - 'weak-password' if password is too weak
  /// - 'email-already-in-use' if email is already registered
  /// - 'invalid-email' if email format is invalid
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Create user account in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create user');
      }

      // Update display name in Firebase Auth
      await firebaseUser.updateDisplayName(username);

      // Send verification email
      print('📧 Sending verification email to: $email');
      try {
        await firebaseUser.sendEmailVerification();
        print('✅ Verification email sent successfully during registration!');
      } catch (emailError) {
        print('❌ Failed to send verification email: $emailError');
        // Don't throw - user is already created, they can resend later
      }

      // Create user profile in Firestore
      final appUser = AppUser(
        uid: firebaseUser.uid,
        email: email,
        username: username,
        isEmailVerified: firebaseUser.emailVerified,
        createdAt: DateTime.now(),
      );

      await _usersCollection.doc(firebaseUser.uid).set(appUser.toFirestore());

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Sign in with email and password
  ///
  /// Throws:
  /// - 'user-not-found' if email doesn't exist
  /// - 'wrong-password' if password is incorrect
  /// - 'invalid-email' if email format is invalid
  /// - 'user-disabled' if account has been disabled
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to sign in');
      }

      // Update email verification status in Firestore
      await _updateEmailVerificationStatus(
        firebaseUser.uid,
        firebaseUser.emailVerified,
      );

      return await _getUserFromFirestore(firebaseUser.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Send verification email to current user
  /// Should be called when user needs to verify their email
  Future<void> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      if (user.emailVerified) {
        throw Exception('Email is already verified');
      }

      print('🔄 Attempting to send verification email to: ${user.email}');
      await user.sendEmailVerification();
      print('✅ Verification email sent successfully!');
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase error sending verification email: ${e.code} - ${e.message}');
      if (e.code == 'too-many-requests') {
        throw Exception(
          'Too many requests. Please wait a few minutes before requesting another verification email.',
        );
      }
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Error sending verification email: $e');
      throw Exception('Failed to send verification email: $e');
    }
  }

  /// Check if email is verified and update Firestore
  /// Call this after user clicks the verification link in their email
  /// Returns true if email is now verified
  Future<bool> checkEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Reload user data from Firebase to get latest verification status
      await user.reload();

      // Get fresh user instance after reload
      final refreshedUser = _auth.currentUser;
      final isVerified = refreshedUser?.emailVerified ?? false;

      // Update Firestore with new verification status
      if (isVerified) {
        await _updateEmailVerificationStatus(user.uid, true);
      }

      return isVerified;
    } catch (e) {
      throw Exception('Failed to check email verification: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  /// Delete user account (both Auth and Firestore)
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Delete Firestore document
      await _usersCollection.doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'This operation requires recent authentication. Please sign in again.',
        );
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // PRIVATE HELPER METHODS

  /// Fetch user profile from Firestore
  Future<AppUser> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();

      if (!doc.exists) {
        throw Exception('User profile not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      return AppUser.fromFirestore(data, uid);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  /// Update email verification status in Firestore
  Future<void> _updateEmailVerificationStatus(
    String uid,
    bool isVerified,
  ) async {
    try {
      await _usersCollection.doc(uid).update({
        'isEmailVerified': isVerified,
      });
    } catch (e) {
      // Non-critical error, just log it
      print('Failed to update email verification status: $e');
    }
  }

  /// Convert FirebaseAuthException to user-friendly error message
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }
}
