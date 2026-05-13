import 'package:ecoalert/widgets/mountain_logo.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
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
  bool _remember = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isUsingFirebase) {
        await authProvider.firebaseLogin(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        final success = await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (!success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Login failed. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      if (authProvider.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (widget.onSuccess != null) {
        widget.onSuccess!.call();
      } else {
        Navigator.pushReplacementNamed(context, '/navigation');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isUsingFirebase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in requires Firebase setup. Use email login in demo mode.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await authProvider.signInWithGoogle();
    if (!mounted) return;

    if (success) {
      if (authProvider.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (widget.onSuccess != null) {
        widget.onSuccess!.call();
      } else {
        Navigator.pushReplacementNamed(context, '/navigation');
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? 'Google sign-in failed'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _SquareToggle(
                                  value: _remember,
                                  accent: Colors.grey,
                                  onChanged: (value) {
                                    setState(() => _remember = value);
                                  },
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => setState(() => _remember = !_remember),
                                  child: const Text(
                                    'Stay signed in',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
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
                          ],
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
                        const SizedBox(height: 16),

                        // ── TEST / DEMO button (visible for FYP demo) ──────
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, '/admin'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A00),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x55FFAA00)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.science_rounded, color: Color(0xFFFFAA00), size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'TEST  —  Skip login (FYP demo)',
                                  style: TextStyle(
                                    color: Color(0xFFFFAA00),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/navigation');
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'developers bypass',
                              style: TextStyle(
                                color: Color(0x22FFFFFF),
                                fontSize: 9,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
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

class _SquareToggle extends StatelessWidget {
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const _SquareToggle({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: value ? accent : Colors.transparent,
          border: Border.all(
            color: value ? accent : AppColors.borderSubtle,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: value
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : const SizedBox.shrink(),
      ),
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
