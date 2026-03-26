import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/demo_auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../firebase_options.dart';

class AuthProvider extends ChangeNotifier {
  late final AuthService _authService;
  final bool _useFirebase;

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasShownUpgradePrompt = false;

  AuthProvider({bool? useFirebase})
      : _useFirebase = useFirebase ?? DefaultFirebaseOptions.isConfigured {
    _authService = _useFirebase ? FirebaseAuthService() : DemoAuthService();
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

  /// Try to restore a previously signed-in session (Firebase only).
  Future<void> tryAutoLogin() async {
    if (!_useFirebase) return;
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        _hasShownUpgradePrompt =
            user.role == UserRole.premium || user.role == UserRole.admin;
        notifyListeners();
      }
    } catch (_) {
      // Silent fail — user just sees the login screen
    }
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
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.error ?? 'Signup failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Signup failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.resetPassword(email);
      _isLoading = false;
      if (!result.success) {
        _errorMessage = result.error;
      }
      notifyListeners();
      return result.success;
    } catch (e) {
      _errorMessage = 'Password reset failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
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

  void upgradeToPremium() {
    if (_currentUser == null) return;
    if (_currentUser!.role == UserRole.admin) return;
    if (_currentUser!.role == UserRole.premium) return;
    _currentUser = _currentUser!.copyWith(role: UserRole.premium);
    notifyListeners();
  }

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
