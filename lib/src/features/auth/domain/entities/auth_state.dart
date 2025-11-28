import 'package:equatable/equatable.dart';
import 'package:clothwise/src/features/auth/domain/entities/app_user.dart';

/// Authentication state of the application
/// Tracks whether user is authenticated, loading, or has errors
class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  /// Current authenticated user (null if not logged in)
  final AppUser? user;

  /// Whether an auth operation is in progress
  final bool isLoading;

  /// Error message if any auth operation failed
  final String? error;

  /// Convenience getter for authentication status
  bool get isAuthenticated => user != null;

  /// Convenience getter for email verification status
  bool get isEmailVerified => user?.isEmailVerified ?? false;

  /// Create initial unauthenticated state
  factory AuthState.unauthenticated() {
    return const AuthState();
  }

  /// Create authenticated state with user
  factory AuthState.authenticated(AppUser user) {
    return AuthState(user: user);
  }

  /// Create loading state
  factory AuthState.loading() {
    return const AuthState(isLoading: true);
  }

  /// Create error state
  factory AuthState.error(String message) {
    return AuthState(error: message);
  }

  /// Create a copy with updated fields
  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [user, isLoading, error];
}
