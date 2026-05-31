// ADD local_auth to pubspec.yaml:
//   flutter pub add local_auth
//
// Also add to android/app/src/main/AndroidManifest.xml inside <manifest>:
//   <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
//   <uses-permission android:name="android.permission.USE_FINGERPRINT"/>
//
// After adding the package, uncomment every line marked [local_auth].

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// [local_auth] import 'package:local_auth/local_auth.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../providers/auth_provider.dart';

class BiometricGateScreen extends StatefulWidget {
  const BiometricGateScreen({super.key});

  @override
  State<BiometricGateScreen> createState() => _BiometricGateScreenState();
}

class _BiometricGateScreenState extends State<BiometricGateScreen> {
  // [local_auth] final _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Auto-trigger on first frame so the prompt appears immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (!mounted || _isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    try {
      // ── Uncomment the block below once local_auth is in pubspec.yaml ──
      // [local_auth] final didAuthenticate = await _localAuth.authenticate(
      // [local_auth]   localizedReason: 'Authenticate to access EcoAlert',
      // [local_auth]   options: const AuthenticationOptions(
      // [local_auth]     biometricOnly: true,
      // [local_auth]     stickyAuth: true,
      // [local_auth]   ),
      // [local_auth] );
      // [local_auth] if (!mounted) return;
      // [local_auth] _navigateAfterAuth(success: didAuthenticate);
      // ─────────────────────────────────────────────────────────────────

      // Placeholder until local_auth is wired up:
      // Validates the session and navigates; remove once the block above works.
      if (!mounted) return;
      _navigateAfterAuth(success: true);
    } catch (_) {
      if (!mounted) return;
      _navigateAfterAuth(success: false);
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  /// Navigates to /navigation on success (only if the Supabase session is
  /// still valid), or /login on failure or expired session.
  void _navigateAfterAuth({required bool success}) {
    if (!success) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    final auth = context.read<AuthProvider>();
    Navigator.pushReplacementNamed(
      context,
      auth.isAuthenticated ? '/navigation' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ────────────────────────────────────────────────
                Image.asset(
                  'assets/images/mountain.png',
                  width: 72,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  'ECOALERT',
                  style: AppTextStyles.displayMed.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome Back',
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Verify your identity to continue',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                ),

                const SizedBox(height: 56),

                // ── Fingerprint icon ─────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAuthenticating
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.07),
                    border: Border.all(
                      color: _isAuthenticating
                          ? AppColors.primary.withOpacity(0.5)
                          : AppColors.primary.withOpacity(0.18),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 48,
                    color: _isAuthenticating
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Primary button ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(
                          Colors.black.withOpacity(0.07)),
                    ),
                    child: _isAuthenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textInverse,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.fingerprint,
                                  size: 20,
                                  color: AppColors.textInverse),
                              const SizedBox(width: 8),
                              Text(
                                'Use Fingerprint / Face ID',
                                style: AppTextStyles.titleMed.copyWith(
                                  color: AppColors.textInverse,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Fallback to password ─────────────────────────────────
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: Text(
                    'Use password instead',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
