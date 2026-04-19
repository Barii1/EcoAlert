import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../config/app_text_styles.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _forgotPasswordCooldown = 0;
  late Timer _forgotPasswordTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    if (_forgotPasswordTimer.isActive) {
      _forgotPasswordTimer.cancel();
    }
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    // Check if still in cooldown
    if (_forgotPasswordCooldown > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait ${_forgotPasswordCooldown}s before trying again'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

    // Start 60-second cooldown
    if (success) {
      setState(() => _forgotPasswordCooldown = 60);
      _forgotPasswordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_forgotPasswordCooldown > 0) {
          setState(() => _forgotPasswordCooldown--);
        } else {
          timer.cancel();
        }
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Password reset email sent'
              : authProvider.errorMessage ?? 'Could not send reset email',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/navigation');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Google sign-in failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleEmailLogin() async {
    final form = _formKey.currentState;
    if (form != null && !form.validate()) return;

    try {
      await context.read<AuthProvider>().firebaseLogin(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/navigation');
      }
    } on FirebaseAuthException catch (e) {
      var message = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') message = 'No account found with this email.';
      if (e.code == 'wrong-password') message = 'Incorrect password.';
      if (e.code == 'invalid-email') message = 'Invalid email address.';
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    const primary = Color(0xFF002E20);
    const primaryContainer = Color(0xFF0B4634);
    const onBackground = Color(0xFF181D1A);
    const onSurfaceVariant = Color(0xFF404944);
    const surfaceContainerHighest = Color(0xFFDDE2DF);
    const outline = Color(0xFF707974);
    const outlineVariant = Color(0xFFC0C9C2);
    const background = Color(0xFFF6FAF6);

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/pakistan_mountains.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, __, ___) => Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCrLpbIV6ZDSKFbRHg0YeN_gFbGL-TqHAgkISLjBonvyFvA62K4xbLI2qUrWicJbw82WLw7Cx6qbcPC6sEJERwnTCvzqTHyozXFZ4aPOFX_qCXObzC038MBX8vunn10tmH_AJhaNxPek0_usVZmktVYf3MIsnh57nPt2YWHEJlgyN40b8u7wSPZ0soHzT7BTV_XuVu9ZCoR51vTAqHLxqc6PHMtcExlda8ZROXtYMr4WU0U912DLncpQEZTjvb3qPsLgYNSXFjyhzY',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33336854),
                    Color(0x66F6FAF6),
                    background,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: primaryContainer,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'EcoAlert',
                        style: AppTextStyles.displayLarge.copyWith(
                          color: primary,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Monitoring the Resilience of our Landscapes',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: onSurfaceVariant,
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 48),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.52),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.05),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Welcome Back',
                                    style: AppTextStyles.headline.copyWith(
                                      color: onBackground,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'EMAIL',
                                    style: AppTextStyles.label.copyWith(
                                      color: onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: AppTextStyles.body.copyWith(color: onBackground),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your email',
                                      hintStyle: AppTextStyles.body.copyWith(color: outline),
                                      filled: true,
                                      fillColor: surfaceContainerHighest,
                                      suffixIcon: const Icon(Icons.alternate_email, color: outline, size: 26),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        borderSide: BorderSide(color: primary.withOpacity(0.18)),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Text(
                                        'PASSWORD',
                                        style: AppTextStyles.label.copyWith(
                                          color: onSurfaceVariant,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: _forgotPasswordCooldown > 0
                                            ? null
                                            : (_handleForgotPassword),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          _forgotPasswordCooldown > 0
                                              ? 'Resend in ${_forgotPasswordCooldown}s'
                                              : 'Forgot Password?',
                                          style: AppTextStyles.body.copyWith(
                                            color: _forgotPasswordCooldown > 0
                                                ? primary.withOpacity(0.5)
                                                : primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    style: AppTextStyles.body.copyWith(color: onBackground),
                                    decoration: InputDecoration(
                                      hintText: '••••••••',
                                      hintStyle: AppTextStyles.body.copyWith(color: outline),
                                      filled: true,
                                      fillColor: surfaceContainerHighest,
                                      suffixIcon: const Icon(Icons.lock, color: outline, size: 26),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        borderSide: BorderSide(color: primary.withOpacity(0.18)),
                                      ),
                                    ),
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
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: authProvider.isLoading ? null : _handleEmailLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primary,
                                        foregroundColor: Colors.white,
                                        shape: const StadiumBorder(),
                                        elevation: 8,
                                        shadowColor: primary.withOpacity(0.2),
                                      ),
                                      child: authProvider.isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Login',
                                                  style: AppTextStyles.headline.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                const Icon(Icons.arrow_forward, size: 20),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: outlineVariant.withOpacity(0.35), thickness: 1)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          'or continue with',
                                          style: AppTextStyles.label.copyWith(
                                            color: outline,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2.0,
                                          ),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: outlineVariant.withOpacity(0.35), thickness: 1)),
                                    ],
                                  ),
                                  const SizedBox(height: 28),
                                  SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: onBackground,
                                        elevation: 1,
                                        shape: const StadiumBorder(),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.string(_googleLogoSvg, width: 20, height: 20),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Sign in with Google',
                                            style: AppTextStyles.body.copyWith(
                                              color: onBackground,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: AppTextStyles.body.copyWith(
                            color: onSurfaceVariant,
                            fontSize: 14,
                          ),
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: authProvider.isLoading ? null : () => Navigator.pushNamed(context, '/signup'),
                                child: Text(
                                  'Create an Account',
                                  style: AppTextStyles.body.copyWith(
                                    color: primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/privacy');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Privacy Policy',
                              style: AppTextStyles.label.copyWith(
                                color: onSurfaceVariant.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: outlineVariant,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/terms');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Terms of Service',
                              style: AppTextStyles.label.copyWith(
                                color: onSurfaceVariant.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 128,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [background, background.withOpacity(0)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const String _googleLogoSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
</svg>
''';
