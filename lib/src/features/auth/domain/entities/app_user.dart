import 'package:equatable/equatable.dart';

/// User entity representing an authenticated user
/// Stores user profile information from Firebase Auth and Firestore
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.isEmailVerified,
    this.createdAt,
    this.profileImageUrl,
  });

  /// Unique user ID from Firebase Auth
  final String uid;

  /// User's email address
  final String email;

  /// User's display name/username
  final String username;

  /// Email verification status
  final bool isEmailVerified;

  /// Account creation timestamp
  final DateTime? createdAt;

  /// Optional profile picture URL
  final String? profileImageUrl;

  /// Convert Firestore document to AppUser
  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : null,
      profileImageUrl: data['profileImageUrl'] as String?,
    );
  }

  /// Convert AppUser to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
    };
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? uid,
    String? email,
    String? username,
    bool? isEmailVerified,
    DateTime? createdAt,
    String? profileImageUrl,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        username,
        isEmailVerified,
        createdAt,
        profileImageUrl,
      ];
}
