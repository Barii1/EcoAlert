import 'package:ecoalert/widgets/mountain_logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ADD local_auth to pubspec.yaml, then uncomment:
// [local_auth] import 'package:local_auth/local_auth.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/ea_field.dart';
import '../widgets/sso_button.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onRegister;
  final Color accent;

  const LoginScreen({
    super.key,
    this.onSuccess,
    this.onRegister,
    this.accent = AppColors.primary,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _authProvider!.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthStateChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    final auth = _authProvider;
    if (auth == null || !auth.isAuthenticated) return;
    _handlePostLoginNavigation(auth);
  }

  Future<void> _handlePostLoginNavigation(AuthProvider auth) async {
    if (auth.isAdmin) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin');
      return;
    }
    // Biometric offer unwired — navigate directly.
    // Re-enable by restoring: await _maybeOfferBiometric();
    if (!mounted) return;
    if (widget.onSuccess != null) {
      widget.onSuccess!.call();
    } else {
      Navigator.pushReplacementNamed(context, '/navigation');
    }
  }

  /// Checks whether the device supports biometrics and, if the preference
  /// hasn't been set yet, shows a dialog asking the user to enable it.
  Future<void> _maybeOfferBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Already decided — don't ask again.
      if (prefs.containsKey('biometric_enabled')) return;

      // ── Uncomment once local_auth is in pubspec.yaml ──────────────────
      // [local_auth] final localAuth = LocalAuthentication();
      // [local_auth] final canUse = await localAuth.canCheckBiometrics ||
      // [local_auth]               await localAuth.isDeviceSupported();
      // [local_auth] if (!canUse || !mounted) return;
      // ──────────────────────────────────────────────────────────────────

      // Placeholder: show dialog on any device until local_auth is wired up.
      // Remove this `if (!mounted) return;` line once the block above is on.
      if (!mounted) return;

      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _BiometricSetupDialog(),
      );

      if (result == 'yes') {
        await prefs.setBool('biometric_enabled', true);
      } else if (result == 'no') {
        await prefs.setBool('biometric_enabled', false);
      }
      // 'later' or dismissed → don't save; prompt again on next login.
    } catch (_) {
      // Never block login because of a biometric setup error.
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email address first, then tap Forgot Password'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(email);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Password reset email sent to $email'
              : authProvider.errorMessage ?? 'Could not send reset email',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleEmailLogin() async {
    final form = _formKey.currentState;
    if (form != null && !form.validate()) return;

    try {
      await context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // Navigation is handled by _onAuthStateChanged listener.
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Login failed: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final proceeded = await authProvider.signInWithGoogle();
    if (!mounted || proceeded) return;
    // proceeded == false: either cancelled (no errorMessage) or a real error.
    final error = authProvider.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final VoidCallback registerAction =
        widget.onRegister ?? () => Navigator.pushNamed(context, '/signup');

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BrandHeader(accent: widget.accent, authProvider: authProvider),
                  const SizedBox(height: 40),
                  const Text(
                    'Sign in',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EAField(
                          label: 'EMAIL',
                          controller: _emailController,
                          hint: 'you@agency.gov',
                          keyboardType: TextInputType.emailAddress,
                          autofillHint: AutofillHints.email,
                          errorText: null,
                          accent: widget.accent,
                          onChanged: (_) {},
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        EAField(
                          label: 'PASSWORD',
                          controller: _passwordController,
                          hint: '••••••••',
                          obscure: _obscurePassword,
                          autofillHint: AutofillHints.password,
                          errorText: null,
                          accent: widget.accent,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                          onChanged: (_) {},
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : _handleForgotPassword,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 52,
                          child: TextButton(
                            onPressed: authProvider.isLoading ? null : _handleEmailLogin,
                            style: TextButton.styleFrom(
                              backgroundColor: authProvider.isLoading
                                  ? AppColors.borderSubtle
                                  : Colors.grey[800],
                              foregroundColor: AppColors.textInverse,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                              padding: EdgeInsets.zero,
                            ).copyWith(
                              overlayColor: WidgetStateProperty.all(
                                Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(AppColors.textInverse),
                                    ),
                                  )
                                : const Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      color: AppColors.textInverse,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const _DividerLabel(label: 'OR CONTINUE WITH'),
                        const SizedBox(height: 20),
                        SsoButton(
                          label: 'Continue with Google',
                          icon: const Icon(
                            Icons.g_mobiledata,
                            color: Color(0xFF9E9E9E),
                            size: 28,
                          ),
                          onTap: authProvider.isLoading ? null : _handleGoogleLogin,
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              const Text(
                                'New to EcoAlert?',
                                style: TextStyle(
                                  color: AppColors.textDisabled,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    authProvider.isLoading ? null : registerAction,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'REGISTER NOW →',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'V 4.2.1 · STATION #ECO-2046',
                            style: TextStyle(
                              color: AppColors.textDisabled,
                              fontSize: 10,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final Color accent;
  final AuthProvider authProvider;

  const _BrandHeader({required this.accent, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const MountainLogo(width: 176),
        const SizedBox(height: 14),
        const Text(
          'ECOALERT',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'predict ⋅ prepare ⋅ protect',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 2,
          color: Colors.grey,
        ),
      ],
    );
  }
}

// ignore: unused_element
class _AmbientOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final String label;

  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: AppColors.borderSubtle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 2.0,
              color: AppColors.textDisabled,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: AppColors.borderSubtle),
        ),
      ],
    );
  }
}


// ── Biometric setup dialog ────────────────────────────────────────────────────

class _BiometricSetupDialog extends StatelessWidget {
  const _BiometricSetupDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.fingerprint, color: AppColors.primary, size: 44),
      title: Text(
        'Enable Fingerprint Login?',
        style: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        'Use fingerprint or Face ID for faster, secure access next time.',
        style: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'no'),
          child: Text('No Thanks',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'later'),
          child: Text('Ask Later',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'yes'),
          child: Text(
            'Yes',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _TinyDot extends StatelessWidget {
  const _TinyDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}
