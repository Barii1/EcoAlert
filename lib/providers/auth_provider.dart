import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_tables.dart';
import '../models/user_model.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_service.dart';
import '../utils/hash_utils.dart';

class AuthProvider extends ChangeNotifier {
  SupabaseAuthService? _supabaseAuthService;
  SupabaseService? _supabaseService;
  bool _isSupabaseUser = false;
  bool get isSupabaseUser => _isSupabaseUser;
  bool _isEmailVerified = true;
  bool get isEmailVerified => _isEmailVerified;
  bool _hasShownVerifyWarning = false;
  bool get hasShownVerifyWarning => _hasShownVerifyWarning;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;
  final bool _useSupabase;

  /// Optional callback invoked after successful Firebase login or sign-up.
  void Function()? onAuthLoginSuccess;

  /// Optional callback after sign-out. Receives the uid of the user who logged out.
  void Function(String? uid)? onAuthLogoutSuccess;

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasShownUpgradePrompt = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  AuthProvider({
    SupabaseAuthService? supabaseAuthService,
    SupabaseService? supabaseService,
    bool useSupabase = false,
  })  : _supabaseAuthService = supabaseAuthService,
        _supabaseService = supabaseService,
        _useSupabase = useSupabase {
    if (supabaseAuthService != null) {
      _authStateSubscription =
          supabaseAuthService.authStateChanges.listen(_onAuthStateChange);
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onAuthStateChange(AuthState state) async {
    if (state.event == AuthChangeEvent.signedIn &&
        !_isAuthenticated &&
        state.session?.user != null) {
      // Handles OAuth callbacks (e.g. Google). Email/password login sets
      // _isAuthenticated = true synchronously before this fires, so the
      // !_isAuthenticated guard prevents double-processing.
      final user = state.session!.user;
      _isSupabaseUser = true;
      _isEmailVerified = user.emailConfirmedAt != null;
      _isAuthenticated = true;
      try {
        _profile = await _supabaseService?.getById(SupabaseTables.profiles, user.id);
      } catch (_) {
        _profile = null;
      }
      _currentUser = _profileToUserModel(user.id, _profile);
      _hasShownUpgradePrompt =
          _currentUser!.role == UserRole.premium || _currentUser!.role == UserRole.admin;
      _hasShownVerifyWarning = false;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      onAuthLoginSuccess?.call();
    } else if (state.event == AuthChangeEvent.signedOut && _isAuthenticated) {
      _clearLocalAuthState();
      notifyListeners();
    }
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUsingSupabase => _useSupabase;

  UserRole get currentRole => _currentUser?.role ?? UserRole.general;
  bool get isAdmin => currentRole == UserRole.admin;
  bool get isPremium => currentRole == UserRole.premium;
  bool get isBasic => currentRole == UserRole.registered;

  bool get hasShownUpgradePrompt => _hasShownUpgradePrompt;

  bool get shouldShowPlanPrompt {
    if (_currentUser == null) return false;
    if (_currentUser!.role == UserRole.admin) return false;
    if (_currentUser!.role == UserRole.premium) return false;
    return (_profile?['has_seen_plan_prompt'] as bool? ??
        _profile?['hasSeenPlanPrompt'] as bool? ??
        false) !=
      true;
  }

  void markUpgradePromptShown() {
    _hasShownUpgradePrompt = true;
  }

  Future<void> markPlanPromptSeen() async {
    _hasShownUpgradePrompt = true;
    final uid = _currentUser?.id;
    if (uid != null && _supabaseService != null) {
      await _supabaseService!.updateRow(
        SupabaseTables.profiles,
        uid,
        {'has_seen_plan_prompt': true},
      );
      _profile = {
        ...?_profile,
        'has_seen_plan_prompt': true,
      };
      notifyListeners();
    }
  }

  Future<void> upgradeToPremium() async {
    final uid = _currentUser?.id;
    if (uid == null || _supabaseService == null) return;
    await _supabaseService!.updateRow(
      SupabaseTables.profiles,
      uid,
      {'role': 'premium'},
    );
    _profile = {
      ...?_profile,
      'role': 'premium',
    };
    _currentUser = _profileToUserModel(uid, _profile);
    notifyListeners();
  }

  void markVerifyWarningShown() {
    _hasShownVerifyWarning = true;
  }

  UserModel _profileToUserModel(String uid, Map<String, dynamic>? profile) {
    String readString(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = profile?[key];
        if (value is String && value.isNotEmpty) return value;
      }
      return fallback;
    }

    final role = readString(['role'], fallback: 'registered_user');
    final mappedRole = UserModel.roleFromString(role);
    final rawConditions = profile?['health_conditions'];
    final healthConditions = rawConditions is List
        ? rawConditions.map((e) => e.toString()).toList()
        : <String>[];

    return UserModel(
      id: uid,
      username: readString(['username'], fallback: 'User'),
      email: readString(['email']),
      phoneNumber: readString(['phoneNumber', 'phone_number']),
      cnicNumber: '',
      province: readString(['province']),
      city: readString(['city']),
      createdAt: DateTime.now(),
      role: mappedRole,
      healthConditions: healthConditions,
    );
  }

  Future<void> updateHealthConditions(List<String> conditions) async {
    final uid = _currentUser?.id;
    if (uid == null || _supabaseService == null) return;
    await _supabaseService!.updateRow(
      SupabaseTables.profiles,
      uid,
      {'health_conditions': conditions},
    );
    _profile = {...?_profile, 'health_conditions': conditions};
    _currentUser = _profileToUserModel(uid, _profile);
    notifyListeners();
  }

  void _clearLocalAuthState() {
    _isSupabaseUser = false;
    _profile = null;
    _currentUser = null;
    _isAuthenticated = false;
    _hasShownUpgradePrompt = false;
    _isEmailVerified = true;
    _hasShownVerifyWarning = false;
  }

  Future<void> initAuth() async {
    if (_supabaseAuthService == null || _supabaseService == null) return;
    final user = _supabaseAuthService!.currentUser;
    if (user == null) {
      _clearLocalAuthState();
      notifyListeners();
      return;
    }
    _isSupabaseUser = true;
    _isEmailVerified = user.emailConfirmedAt != null;
    _isAuthenticated = true;
    try {
      _profile = await _supabaseService!.getById(SupabaseTables.profiles, user.id);
    } catch (_) {
      _profile = null;
    }
    _currentUser = _profileToUserModel(user.id, _profile);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_supabaseAuthService == null || _supabaseService == null) {
      _isLoading = false;
      _errorMessage =
          'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY.';
      notifyListeners();
      throw const AuthException('Supabase is not initialized.');
    }

    try {
      final response = await _supabaseAuthService!.signIn(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException('Login failed. Please try again.');
      }

      _isSupabaseUser = true;
      _isEmailVerified = user.emailConfirmedAt != null;
      _isAuthenticated = true;

      try {
        _profile = await _supabaseService!.getById(SupabaseTables.profiles, user.id);
      } catch (e) {
        debugPrint('[AuthProvider] Profile fetch error: $e');
        _profile = null;
      }
      if (_profile == null) {
        debugPrint('[AuthProvider] WARNING: profile is null for ${user.email} — '
            'check RLS SELECT policy on profiles table and that the row exists.');
      } else {
        debugPrint('[AuthProvider] Profile loaded — role: ${_profile!['role']} '
            'email: ${user.email}');
      }
      _currentUser = _profileToUserModel(user.id, _profile);
      debugPrint('[AuthProvider] Mapped role → ${_currentUser!.role.name} '
          '| isAdmin: ${_currentUser!.role == UserRole.admin}');
      _hasShownUpgradePrompt =
          _currentUser!.role == UserRole.premium || _currentUser!.role == UserRole.admin;
      _hasShownVerifyWarning = false;
      _errorMessage = null;
      onAuthLoginSuccess?.call();
    } on AuthException catch (e) {
      _isAuthenticated = false;
      _errorMessage = e.message;
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

  Future<void> supabaseSignUp({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String cnicNumber,
    required String province,
    required String city,
  }) async {
    if (_supabaseAuthService == null || _supabaseService == null) {
      throw const AuthException('Supabase is not configured.');
    }
    final response = await _supabaseAuthService!.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'phone_number': phoneNumber,
        'province': province,
        'city': city,
      },
    );
    final user = response.user;
    if (user != null) {
      try {
        await _supabaseService!.client.from(SupabaseTables.profiles).upsert({
          'id': user.id,
          'username': username,
          'email': email,
          'phone_number': phoneNumber,
          'cnic_hash': HashUtils.hashCnic(cnicNumber),
          'province': province,
          'city': city,
          'role': 'registered',
          'has_seen_plan_prompt': false,
        });
        _profile = await _supabaseService!.getById(SupabaseTables.profiles, user.id);
      } catch (_) {
        _profile = null;
      }
      _isSupabaseUser = true;
      _isEmailVerified = user.emailConfirmedAt != null;
      _currentUser = _profileToUserModel(user.id, _profile);
      _isAuthenticated = response.session != null;
      _hasShownVerifyWarning = false;
      notifyListeners();
      // Only fire login success when there is a real session (email confirmation
      // disabled). When confirmation is required, session is null here and the
      // auth state listener handles completion after the user verifies.
      if (response.session != null) {
        onAuthLoginSuccess?.call();
      }
    }
  }

  Future<void> logout() async {
    final uid = _currentUser?.id;
    try {
      if (_supabaseAuthService != null) {
        await _supabaseAuthService!.signOut();
      }
    } catch (_) {
      // Still clear local session if network/sign-out fails.
    }
    _clearLocalAuthState();
    notifyListeners();
    onAuthLogoutSuccess?.call(uid);
  }

  Future<void> tryAutoLogin() async {
    if (!_useSupabase) return;
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
      if (!_useSupabase || _supabaseAuthService == null) {
        _errorMessage =
            'Account creation requires Supabase. Check your project configuration.';
        return false;
      }

      await supabaseSignUp(
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
    } on AuthException catch (e) {
      _errorMessage = e.message;
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
      if (_supabaseAuthService == null) {
        throw const AuthException('Supabase is not configured.');
      }
      await _supabaseAuthService!.resetPassword(email.trim());
      _errorMessage = null;
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Password reset failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Shows the native Google account picker and signs in via Supabase
  /// signInWithIdToken. Returns true if sign-in is in progress (popup accepted),
  /// false if the user cancelled (no error) or an error occurred (errorMessage set).
  /// Completion is handled by [_onAuthStateChange].
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_supabaseAuthService == null) {
      _isLoading = false;
      _errorMessage = 'Auth service not available.';
      notifyListeners();
      return false;
    }

    try {
      final proceeded = await _supabaseAuthService!.signInWithGoogle();
      if (!proceeded) {
        // User dismissed the popup — not an error, just stop loading.
        _isLoading = false;
        notifyListeners();
        return false;
      }
      // Sign-in submitted. Keep _isLoading = true — _onAuthStateChange clears it.
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Google sign-in failed: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
