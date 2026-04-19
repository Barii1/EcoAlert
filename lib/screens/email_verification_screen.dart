import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/app_text_styles.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late Timer _verificationCheckTimer;
  late Timer _resendCooldownTimer;
  int _resendCooldown = 0;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _verificationCheckTimer.cancel();
    _resendCooldownTimer.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    // Check every 2 seconds if email is verified
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      if (isVerified && mounted) {
        Navigator.pushReplacementNamed(context, '/navigation');
      }
    });
  }

  Future<void> _handleResendEmail() async {
    if (_resendCooldown > 0) return;

    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      setState(() => _resendCooldown = 60);
      _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendCooldown > 0) {
          setState(() => _resendCooldown--);
        } else {
          timer.cancel();
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not resend email: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleContinue() async {
    setState(() => _isChecking = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      if (!mounted) return;
      if (isVerified) {
        Navigator.pushReplacementNamed(context, '/navigation');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Check your inbox and spam folder.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isChecking = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isChecking = false);
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
          onPressed: () => Navigator.pop(context),
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
                    child: Icon(
                      Icons.mail_outline,
                      size: 44,
                      color: primary,
                    ),
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
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 8,
                        shadowColor: primary.withOpacity(0.2),
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'I\'ve Verified, Continue',
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
                          color: primary.withOpacity(0.3),
                          width: 1.5,
                        ),
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
                    'Check your email and spam folder',
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
