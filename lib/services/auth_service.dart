import '../models/user_model.dart';

/// Result wrapper for auth operations.
class AuthResult {
  final bool success;
  final UserModel? user;
  final String? error;

  const AuthResult({required this.success, this.user, this.error});

  factory AuthResult.ok(UserModel user) =>
      AuthResult(success: true, user: user);

  factory AuthResult.fail(String error) =>
      AuthResult(success: false, error: error);
}

/// Abstract interface for authentication.
/// Implemented by FirebaseAuthService (real) and DemoAuthService (dev/testing).
abstract class AuthService {
  /// Sign in with email & password. Returns user profile on success.
  Future<AuthResult> signIn(String email, String password);

  /// Create a new account. Returns user profile on success.
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String cnicNumber,
    required String province,
    required String city,
  });

  /// Sign out the current user.
  Future<void> signOut();

  /// Get the currently signed-in user (null if not signed in).
  Future<UserModel?> getCurrentUser();

  /// Send password reset email.
  Future<AuthResult> resetPassword(String email);
}
