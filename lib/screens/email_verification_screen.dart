import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_text_styles.dart';
import '../providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _resendCooldownTimer;
  int _resendCooldown = 0;
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    // Listen for deep-link-based verification: when the user taps the link on
    // their phone, supabase_flutter processes it, fires signedIn on the auth
    // stream, and AuthProvider sets isAuthenticated = true + notifies.
    _authProvider = context.read<AuthProvider>();
    _authProvider!.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthStateChanged);
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    if (_authProvider?.isAuthenticated == true) {
      Navigator.pushReplacementNamed(context, '/navigation');
    }
  }

  Future<void> _handleResendEmail() async {
    if (_resendCooldown > 0) return;
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      setState(() => _resendCooldown = 60);
      _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_resendCooldown > 0) {
          setState(() => _resendCooldown--);
        } else {
          t.cancel();
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Verification email sent'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not resend: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF002E20);
    const primaryContainer = Color(0xFF0B4634);
    const onBackground = Color(0xFF181D1A);
    const onSurfaceVariant = Color(0xFF404944);
    const background = Color(0xFFF6FAF6);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryContainer.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.mail_outline, size: 44, color: primary),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Verify Your Email',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: onSurfaceVariant,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the link in the email to verify.\nIf you verified on this device, the app will continue automatically.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: onSurfaceVariant.withOpacity(0.7),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Primary action: go to login and sign in with verified account
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 8,
                        shadowColor: primary.withOpacity(0.2),
                      ),
                      child: Text(
                        "I've Verified — Sign In",
                        style: AppTextStyles.headline.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _resendCooldown > 0 ? null : _handleResendEmail,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(
                            color: primary.withOpacity(0.3), width: 1.5),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        _resendCooldown > 0
                            ? 'Resend in ${_resendCooldown}s'
                            : 'Resend Email',
                        style: AppTextStyles.headline.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Check your spam folder if you don\'t see it',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: onSurfaceVariant.withOpacity(0.6),
                      fontSize: 12,
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
