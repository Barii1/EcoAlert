import 'package:flutter/foundation.dart' show kDebugMode;

import '../models/user_model.dart';
import 'auth_service.dart';

/// Demo/offline authentication for development and testing.
/// Used when Firebase is not configured (placeholder API keys).
class DemoAuthService implements AuthService {
  UserModel? _currentUser;

  @override
  Future<AuthResult> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (kDebugMode) {
      if (password != 'password123') {
        return AuthResult.fail('Invalid email or password');
      }

      final normalized = email.trim().toLowerCase();
      final UserRole role;
      if (normalized.contains('admin')) {
        role = UserRole.admin;
      } else if (normalized.contains('premium')) {
        role = UserRole.premium;
      } else {
        role = UserRole.registered;
      }

      _currentUser = UserModel(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        username: role == UserRole.admin ? 'admin_user' : normalized.split('@')[0],
        email: normalized,
        phoneNumber: '03001234567',
        cnicNumber: '12345-1234567-1',
        province: 'Punjab',
        city: 'Lahore',
        createdAt: DateTime.now(),
        role: role,
      );

      return AuthResult.ok(_currentUser!);
    }

    return AuthResult.fail('Demo authentication is disabled in release mode');
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String cnicNumber,
    required String province,
    required String city,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    _currentUser = UserModel(
      id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      email: email.trim(),
      phoneNumber: phoneNumber,
      cnicNumber: cnicNumber,
      province: province,
      city: city,
      createdAt: DateTime.now(),
      role: UserRole.registered,
    );

    return AuthResult.ok(_currentUser!);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<AuthResult> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const AuthResult(success: true);
  }
}
