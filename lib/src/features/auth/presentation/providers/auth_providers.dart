import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clothwise/src/features/auth/data/services/firebase_auth_service.dart';
import 'package:clothwise/src/features/auth/domain/entities/app_user.dart';
import 'package:clothwise/src/features/auth/domain/entities/auth_state.dart';

/// Provider for FirebaseAuthService singleton
/// Use this to access auth methods throughout the app
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Stream provider for authentication state changes
/// Automatically updates when user signs in/out or verification status changes
/// Returns AsyncValue<AppUser?> - loading/data/error states
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

/// Provider for current authenticated user
/// Returns null if not authenticated
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.getCurrentUser();
});

/// State notifier for authentication operations
/// Manages login, registration, logout, and email verification
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(AuthState.unauthenticated());

  final FirebaseAuthService _authService;

  /// Register new user with email, password, and username
  /// Automatically sends verification email upon successful registration
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    // Set loading state
    state = AuthState.loading();

    try {
      // Create account and send verification email
      final user = await _authService.registerWithEmail(
        email: email,
        password: password,
        username: username,
      );

      // Update state with new user (email not verified yet)
      state = AuthState.authenticated(user);
    } catch (e) {
      // Update state with error
      state = AuthState.error(e.toString());
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Set loading state
    state = AuthState.loading();

    try {
      // Authenticate user
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      // Update state with authenticated user
      state = AuthState.authenticated(user);
    } catch (e) {
      // Update state with error
      state = AuthState.error(e.toString());
    }
  }

  /// Send verification email to current user
  /// Call this when user requests to resend verification code
  Future<void> sendVerificationEmail() async {
    try {
      await _authService.sendVerificationEmail();

      // Clear any previous errors
      state = state.copyWith(clearError: true);
    } catch (e) {
      // Update state with error
      state = state.copyWith(error: e.toString());
    }
  }

  /// Check if user's email has been verified
  /// Call this after user clicks verification link or manually checks
  /// Returns true if email is now verified
  Future<bool> checkEmailVerified() async {
    try {
      final isVerified = await _authService.checkEmailVerified();

      if (isVerified && state.user != null) {
        // Update user's verification status in state
        final updatedUser = state.user!.copyWith(isEmailVerified: true);
        state = AuthState.authenticated(updatedUser);
      }

      return isVerified;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _authService.signOut();

      // Reset to unauthenticated state
      state = AuthState.unauthenticated();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);

      // Clear any previous errors
      state = state.copyWith(clearError: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error from state
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for AuthNotifier
/// Use this to access auth operations and state throughout the app
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return AuthNotifier(authService);
});

/// Convenience provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAuthenticated;
});

/// Convenience provider to check if email is verified
final isEmailVerifiedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isEmailVerified;
});
