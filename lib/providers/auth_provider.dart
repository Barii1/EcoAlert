import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/demo_auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../firebase_options.dart';

class AuthProvider extends ChangeNotifier {
  late final AuthService _authService;
  FirebaseAuthService? _firebaseAuthService;
  bool _isFirebaseUser = false;
  bool get isFirebaseUser => _isFirebaseUser;
  Map<String, dynamic>? _firestoreProfile;
  Map<String, dynamic>? get firestoreProfile => _firestoreProfile;
  final bool _useFirebase;

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasShownUpgradePrompt = false;

  AuthProvider({bool? useFirebase})
      : _useFirebase = useFirebase ?? DefaultFirebaseOptions.isConfigured {
    _authService = DemoAuthService();
    if (_useFirebase) {
      _firebaseAuthService = FirebaseAuthService();
    }
  }

  // ── Getters ──
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

  /// Call this on app startup. Restores Firebase session if user was
  /// previously logged in. Does nothing if no session exists.
  Future<void> initAuth() async {
    if (_firebaseAuthService == null) return;
    final User? firebaseUser = _firebaseAuthService!.getCurrentUser();
    if (firebaseUser != null) {
      _isFirebaseUser = true;
      _firestoreProfile = await _firebaseAuthService!
          .getUserProfile(firebaseUser.uid);
      _currentUser = _profileToUserModel(firebaseUser.uid, _firestoreProfile);
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  /// Real Firebase login. Throws on failure so UI can show error.
  Future<void> firebaseLogin(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_firebaseAuthService == null) {
      _isLoading = false;
      _errorMessage = 'Firebase auth is not initialized.';
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

  /// Real Firebase sign up. Throws on failure so UI can show error.
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
        message: 'Firebase auth is not initialized.',
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
      _firestoreProfile = await _firebaseAuthService!
          .getUserProfile(user.uid);
      _currentUser = _profileToUserModel(user.uid, _firestoreProfile);
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  /// Signs out Firebase user. Does not affect demo sessions.
  Future<void> firebaseLogout() async {
    if (_firebaseAuthService == null) return;
    await _firebaseAuthService!.signOut();
    _isFirebaseUser = false;
    _firestoreProfile = null;
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Try to restore a previously signed-in session (Firebase only).
  Future<void> tryAutoLogin() async {
    if (!_useFirebase) return;
    await initAuth();
  }

  // ══════════════════════════════════════════════
  //  REAL AUTH (via AuthService)
  // ══════════════════════════════════════════════

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signIn(email, password);

      if (result.success && result.user != null) {
        _currentUser = result.user;
        _isAuthenticated = true;
        _hasShownUpgradePrompt =
            _currentUser!.role == UserRole.premium ||
            _currentUser!.role == UserRole.admin;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.error ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
      if (_useFirebase && _firebaseAuthService != null) {
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
      }

      if (kDebugMode) {
        final result = await _authService.signUp(
          email: email,
          password: password,
          username: username,
          phoneNumber: phoneNumber,
          cnicNumber: cnicNumber,
          province: province,
          city: city,
        );

        if (result.success && result.user != null) {
          _currentUser = result.user;
          _isAuthenticated = true;
          _errorMessage = null;
          return true;
        }

        _errorMessage = result.error ?? 'Signup failed';
        return false;
      }

      _errorMessage = 'Signup is unavailable without Firebase in release mode.';
      return false;
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

  /// Sign in with Google. Returns true if successful.
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
      _hasShownUpgradePrompt = _currentUser!.role == UserRole.premium || _currentUser!.role == UserRole.admin;
      _errorMessage = null;

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Google sign-in failed';
      return false;
    } catch (e) {
      final raw = e.toString();
      if (raw.contains('ApiException: 10')) {
        _errorMessage =
            'Google Sign-In is not configured for this Android build (ApiException 10). '
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
    await _authService.signOut();
    _currentUser = null;
    _isAuthenticated = false;
    _hasShownUpgradePrompt = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════
  //  DEMO SHORTCUTS (kept for dev/testing)
  // ══════════════════════════════════════════════

  void demoLogin() {
    _currentUser = UserModel(
      id: 'dev',
      username: 'Developer',
      email: 'dev@ecoalert.app',
      phoneNumber: '0000000000',
      cnicNumber: '00000-0000000-0',
      province: 'Demo Province',
      city: 'Lahore',
      createdAt: DateTime.now(),
      role: UserRole.registered,
    );
    _isAuthenticated = true;
    _isLoading = false;
    _errorMessage = null;
    _hasShownUpgradePrompt = false;
    notifyListeners();
  }

  void demoBasicLogin() => demoLogin();

  void demoGuestLogin() {
    _currentUser = UserModel(
      id: 'guest',
      username: 'Guest',
      email: 'guest@ecoalert.app',
      phoneNumber: '',
      cnicNumber: '',
      province: '',
      city: 'Lahore',
      createdAt: DateTime.now(),
      role: UserRole.general,
    );
    _isAuthenticated = true;
    _isLoading = false;
    _errorMessage = null;
    _hasShownUpgradePrompt = false;
    notifyListeners();
  }

  void demoAdminLogin() {
    _currentUser = UserModel(
      id: 'admin',
      username: 'Admin',
      email: 'admin@ecoalert.app',
      phoneNumber: '0000000000',
      cnicNumber: '00000-0000000-0',
      province: 'System',
      city: 'HQ',
      createdAt: DateTime.now(),
      role: UserRole.admin,
    );
    _isAuthenticated = true;
    _isLoading = false;
    _errorMessage = null;
    _hasShownUpgradePrompt = true;
    notifyListeners();
  }

  void demoPremiumLogin() {
    _currentUser = UserModel(
      id: 'premium',
      username: 'Premium User',
      email: 'premium@ecoalert.app',
      phoneNumber: '0000000000',
      cnicNumber: '00000-0000000-0',
      province: 'Punjab',
      city: 'Lahore',
      createdAt: DateTime.now(),
      role: UserRole.premium,
    );
    _isAuthenticated = true;
    _isLoading = false;
    _errorMessage = null;
    _hasShownUpgradePrompt = true;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
