import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Real Firebase Authentication + Firestore user profiles.
class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  @override
  Future<AuthResult> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) return AuthResult.fail('Sign-in returned no user.');

      final user = await _fetchUserProfile(uid);
      if (user == null) {
        return AuthResult.fail('User profile not found. Please contact support.');
      }

      return AuthResult.ok(user);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e.code));
    } catch (e) {
      return AuthResult.fail('Sign-in failed: $e');
    }
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
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) return AuthResult.fail('Account creation returned no user.');

      final now = DateTime.now();
      final user = UserModel(
        id: uid,
        username: username,
        email: email.trim(),
        phoneNumber: phoneNumber,
        cnicNumber: cnicNumber,
        province: province,
        city: city,
        createdAt: now,
        role: UserRole.registered,
      );

      // Store user profile in Firestore
      await _usersCol.doc(uid).set(user.toJson());

      return AuthResult.ok(user);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e.code));
    } catch (e) {
      return AuthResult.fail('Sign-up failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _fetchUserProfile(fbUser.uid);
  }

  @override
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult(success: true);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e.code));
    } catch (e) {
      return AuthResult.fail('Password reset failed: $e');
    }
  }

  /// Update user profile fields in Firestore.
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) async {
    await _usersCol.doc(uid).update(fields);
  }

  // ── Private helpers ──

  Future<UserModel?> _fetchUserProfile(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson({...doc.data()!, 'id': uid});
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication error: $code';
    }
  }
}
