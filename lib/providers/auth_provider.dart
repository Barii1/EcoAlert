import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../firebase_options.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuthService? _firebaseAuthService;
  bool _isFirebaseUser = false;
  bool get isFirebaseUser => _isFirebaseUser;
  Map<String, dynamic>? _firestoreProfile;
  Map<String, dynamic>? get firestoreProfile => _firestoreProfile;
  final bool _useFirebase;

  /// Optional callback invoked after successful Firebase login or sign-up.
  void Function()? onFirebaseLoginSuccess;

  /// Optional callback after Firebase sign-out.
  void Function()? onFirebaseLogoutSuccess;

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasShownUpgradePrompt = false;

  AuthProvider({bool? useFirebase})
      : _useFirebase = useFirebase ?? DefaultFirebaseOptions.isConfigured {
    if (_useFirebase) {
      _firebaseAuthService = FirebaseAuthService();
    }
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUsingFirebase => _useFirebase;

  UserRole get currentRole => _currentUser?.role ?? UserRole.general;
  bool get isAdmin => currentRole == UserRole.admin;
  bool get isPremium => currentRole == UserRole.premium;
  bool get isBasic => currentRole == UserRole.registered;

  bool get hasShownUpgradePrompt => _hasShownUpgradePrompt;

  void markUpgradePromptShown() {
    _hasShownUpgradePrompt = true;
  }

  UserModel _profileToUserModel(String uid, Map<String, dynamic>? profile) {
    final role = (profile?['role'] as String?) ?? 'user';
    final mappedRole = role == 'admin'
        ? UserRole.admin
        : role == 'premium'
            ? UserRole.premium
            : UserRole.registered;
    return UserModel(
      id: uid,
      username: (profile?['username'] as String?) ?? 'User',
      email: (profile?['email'] as String?) ?? '',
      phoneNumber: (profile?['phoneNumber'] as String?) ?? '',
      cnicNumber: '',
      province: (profile?['province'] as String?) ?? '',
      city: (profile?['city'] as String?) ?? '',
      createdAt: DateTime.now(),
      role: mappedRole,
    );
  }

  void _clearLocalAuthState() {
    _isFirebaseUser = false;
    _firestoreProfile = null;
    _currentUser = null;
    _isAuthenticated = false;
    _hasShownUpgradePrompt = false;
  }

  Future<void> initAuth() async {
    if (_firebaseAuthService == null) return;
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      _clearLocalAuthState();
      notifyListeners();
      return;
    }
    _isFirebaseUser = true;
    _firestoreProfile =
        await _firebaseAuthService!.getUserProfile(firebaseUser.uid);
    _currentUser = _profileToUserModel(firebaseUser.uid, _firestoreProfile);
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> firebaseLogin(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_firebaseAuthService == null) {
      _isLoading = false;
      _errorMessage =
          'Firebase is not configured. Check google-services.json and firebase_options.dart.';
      notifyListeners();
      throw FirebaseAuthException(code: 'not-initialized', message: _errorMessage);
    }

    try {
      final user = await _firebaseAuthService!.signIn(
        email: email,
        password: password,
      );

      if (user == null) {
        throw FirebaseAuthException(
          code: 'login-failed',
          message: 'Login failed. Please try again.',
        );
      }

      _isFirebaseUser = true;
      _firestoreProfile = await _firebaseAuthService!.getUserProfile(user.uid);
      _currentUser = _profileToUserModel(user.uid, _firestoreProfile);
      _isAuthenticated = true;
      _hasShownUpgradePrompt =
          _currentUser!.role == UserRole.premium || _currentUser!.role == UserRole.admin;
      _errorMessage = null;
      onFirebaseLoginSuccess?.call();
    } on FirebaseAuthException catch (e) {
      _isAuthenticated = false;
      _errorMessage = e.message ?? 'Login failed. Please try again.';
      rethrow;
    } catch (e) {
      _isAuthenticated = false;
      _errorMessage = 'Login failed: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> firebaseSignUp({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String cnicNumber,
    required String province,
    required String city,
  }) async {
    if (_firebaseAuthService == null) {
      throw FirebaseAuthException(
        code: 'not-initialized',
        message: 'Firebase is not configured.',
      );
    }
    final user = await _firebaseAuthService!.signUp(
      email: email,
      password: password,
      username: username,
      phoneNumber: phoneNumber,
      cnicNumber: cnicNumber,
      province: province,
      city: city,
    );
    if (user != null) {
      await user.sendEmailVerification();
      _isFirebaseUser = true;
      _firestoreProfile =
          await _firebaseAuthService!.getUserProfile(user.uid);
      _currentUser = _profileToUserModel(user.uid, _firestoreProfile);
      _isAuthenticated = true;
      notifyListeners();
      onFirebaseLoginSuccess?.call();
    }
  }

  Future<void> firebaseLogout() async {
    try {
      if (_firebaseAuthService != null) {
        await _firebaseAuthService!.signOut();
      } else {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // Still clear local session if network/sign-out fails.
    }
    _clearLocalAuthState();
    notifyListeners();
    onFirebaseLogoutSuccess?.call();
  }

  Future<void> tryAutoLogin() async {
    if (!_useFirebase) return;
    await initAuth();
  }

  Future<bool> signup({
    required String username,
    required String email,
    required String password,
    required String phoneNumber,
    required String cnicNumber,
    required String province,
    required String city,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_useFirebase || _firebaseAuthService == null) {
        _errorMessage =
            'Account creation requires Firebase. Check your project configuration.';
        return false;
      }

      await firebaseSignUp(
        email: email,
        password: password,
        username: username,
        phoneNumber: phoneNumber,
        cnicNumber: cnicNumber,
        province: province,
        city: city,
      );
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Signup failed';
      return false;
    } catch (e) {
      _errorMessage = 'Signup failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Password reset failed';
      return false;
    } catch (e) {
      _errorMessage = 'Password reset failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_firebaseAuthService == null) {
      _isLoading = false;
      _errorMessage = 'Firebase auth is not initialized.';
      notifyListeners();
      return false;
    }

    try {
      final user = await _firebaseAuthService!.signInWithGoogle();

      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isFirebaseUser = true;
      _firestoreProfile = await _firebaseAuthService!.getUserProfile(user.uid);
      _currentUser = _profileToUserModel(user.uid, _firestoreProfile);
      _isAuthenticated = true;
      _hasShownUpgradePrompt =
          _currentUser!.role == UserRole.premium || _currentUser!.role == UserRole.admin;
      _errorMessage = null;
      onFirebaseLoginSuccess?.call();

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Google sign-in failed';
      return false;
    } catch (e) {
      final raw = e.toString();
      if (raw.contains('ApiException: 10')) {
        _errorMessage =
            'Google Sign-In is not configured for this Android build (ApiException: 10). '
            'Add SHA-1/SHA-256 in Firebase, download a fresh google-services.json, and rebuild the app.';
      } else {
        _errorMessage = 'Google sign-in failed: $e';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await firebaseLogout();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
