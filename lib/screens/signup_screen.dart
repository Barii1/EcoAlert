import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_text_styles.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getPasswordStrength(String password) {
    if (password.isEmpty) return 'weak';
    final hasNumbers = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]'));
    if (password.length >= 8 && hasNumbers && hasSpecial) return 'strong';
    if (password.length >= 8 && hasNumbers) return 'fair';
    return 'weak';
  }

  Widget _buildPasswordStrengthIndicator() {
    final strength = _getPasswordStrength(_passwordController.text);
    final color = strength == 'strong'
        ? Colors.green
        : strength == 'fair'
            ? Colors.orange
            : Colors.red;
    final label = strength == 'strong'
        ? 'Strong'
        : strength == 'fair'
            ? 'Fair'
            : 'Weak';

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength == 'strong'
                  ? 1.0
                  : strength == 'fair'
                      ? 0.66
                      : 0.33,
              minHeight: 4,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms and Conditions'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.signup(
        username: _emailController.text.trim().split('@')[0],
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
        cnicNumber: _cnicController.text.trim(),
        province: _provinceController.text.trim(),
        city: _cityController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        // Navigate to email verification screen
        Navigator.pushReplacementNamed(
          context,
          '/email-verification',
          arguments: _emailController.text.trim(),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Signup failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignup() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/navigation');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Google sign-up failed'),
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
                        'Join us to stay safe and informed',
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
                                    'Create Account',
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
                                  Text(
                                    'PHONE NUMBER',
                                    style: AppTextStyles.label.copyWith(
                                      color: onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: AppTextStyles.body.copyWith(color: onBackground),
                                    decoration: InputDecoration(
                                      hintText: '03XXXXXXXXX',
                                      hintStyle: AppTextStyles.body.copyWith(color: outline),
                                      filled: true,
                                      fillColor: surfaceContainerHighest,
                                      suffixIcon: const Icon(Icons.phone_iphone, color: outline, size: 24),
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
                                      final phone = value?.trim() ?? '';
                                      if (phone.isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      if (!RegExp(r'^\d{10,13}$').hasMatch(phone.replaceAll(RegExp(r'\D'), ''))) {
                                        return 'Please enter a valid phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'CNIC',
                                    style: AppTextStyles.label.copyWith(
                                      color: onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _cnicController,
                                    keyboardType: TextInputType.number,
                                    style: AppTextStyles.body.copyWith(color: onBackground),
                                    decoration: InputDecoration(
                                      hintText: '35202XXXXXXXX',
                                      hintStyle: AppTextStyles.body.copyWith(color: outline),
                                      filled: true,
                                      fillColor: surfaceContainerHighest,
                                      suffixIcon: const Icon(Icons.badge_outlined, color: outline, size: 24),
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
                                      final cnic = value?.trim() ?? '';
                                      if (cnic.isEmpty) {
                                        return 'Please enter your CNIC';
                                      }
                                      if (!RegExp(r'^\d{13}$').hasMatch(cnic.replaceAll(RegExp(r'\D'), ''))) {
                                        return 'CNIC must contain 13 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'PROVINCE',
                                    style: AppTextStyles.label.copyWith(
                                      color: onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _provinceController,
                                    style: AppTextStyles.body.copyWith(color: onBackground),
                                    decoration: InputDecoration(
                                      hintText: 'Punjab / Sindh / KPK / Balochistan',
                                      hintStyle: AppTextStyles.body.copyWith(color: outline),
                                      filled: true,
                                      fillColor: surfaceContainerHighest,
                                      suffixIcon: const Icon(Icons.map_outlined, color: outline, size: 24),
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
                                        return 'Please enter your province';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'CITY',
                                    style: AppTextStyles.label.copyWith(
                                      color: onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _cityController,
                                    style: AppTextStyles.body.copyWith(color: onBackground),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your city',
                                      hintStyle: AppTextStyles.body.copyWith(color: outline),
                                      filled: true,
                                      fillColor: surfaceContainerHighest,
                                      suffixIcon: const Icon(Icons.location_city, color: outline, size: 24),
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
                                        return 'Please enter your city';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'PASSWORD',
                                    style: AppTextStyles.label.copyWith(
                                      color: onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    onChanged: (_) => setState(() {}),
                                    style: AppTextStyles.body.copyWith(color: onBackground),
                                    decoration: InputDecoration(
                                      hintText: '••••••••',
                                      hintStyle: AppTextStyles.body.copyWith(color: outline),
                                      filled: true,
                                      fillColor: surfaceContainerHighest,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: outline,
                                          size: 26,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
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
                                        return 'Please enter a password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _buildPasswordStrengthIndicator(),
                                  const SizedBox(height: 20),
                                  Text(
                                    'CONFIRM PASSWORD',
                                    style: AppTextStyles.label.copyWith(
                                      color: onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    style: AppTextStyles.body.copyWith(color: onBackground),
                                    decoration: InputDecoration(
                                      hintText: '••••••••',
                                      hintStyle: AppTextStyles.body.copyWith(color: outline),
                                      filled: true,
                                      fillColor: surfaceContainerHighest,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                          color: outline,
                                          size: 26,
                                        ),
                                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                      ),
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
                                        return 'Please confirm your password';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _acceptTerms,
                                        onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                                        fillColor: MaterialStateProperty.all(primary),
                                      ),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            text: 'I agree to the ',
                                            style: AppTextStyles.body.copyWith(
                                              fontSize: 13,
                                              color: onSurfaceVariant,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Terms & Conditions',
                                                style: AppTextStyles.body.copyWith(
                                                  fontSize: 13,
                                                  color: primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () {
                                                    Navigator.pushNamed(context, '/terms');
                                                  },
                                              ),
                                              const TextSpan(text: ' and '),
                                              TextSpan(
                                                text: 'Privacy Policy',
                                                style: AppTextStyles.body.copyWith(
                                                  fontSize: 13,
                                                  color: primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () {
                                                    Navigator.pushNamed(context, '/privacy');
                                                  },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: authProvider.isLoading ? null : _handleSignup,
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
                                                  'Create Account',
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
                                      onPressed: authProvider.isLoading ? null : _handleGoogleSignup,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: onBackground,
                                        elevation: 1,
                                        shape: const StadiumBorder(),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.g_mobiledata, color: outline, size: 24),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Google',
                                            style: AppTextStyles.headline.copyWith(
                                              color: onBackground,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Center(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Already have an account? ',
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 13,
                                          color: onSurfaceVariant,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Log In',
                                            style: AppTextStyles.body.copyWith(
                                              fontSize: 13,
                                              color: primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                Navigator.pushReplacementNamed(context, '/login');
                                              },
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
                    ],
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
