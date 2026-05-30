import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Web client ID (type-3) from google-services.json — required by Supabase
// signInWithIdToken to validate the Google ID token server-side.
const _kGoogleWebClientId =
    '125523315849-rth5hgr9h6r3h0j3u812aqqsnltugij6.apps.googleusercontent.com';

class SupabaseAuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Shows the native Google account picker.
  /// Returns false if the user cancelled, true if Supabase session was created.
  /// Throws on unexpected errors.
  Future<bool> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(serverClientId: _kGoogleWebClientId);

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return false; // user cancelled

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('Google Sign-In failed: no ID token received.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    return true;
  }
}
