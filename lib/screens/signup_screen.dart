import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/mountain_logo.dart';

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
      ? const Color(0xFFAAAAAA)
      : strength == 'fair'
        ? const Color(0xFFFFAA55)
        : const Color(0xFFFF5555);
    final label = strength == 'strong'
        ? 'Strong'
        : strength == 'fair'
            ? 'Fair'
            : 'Weak';

    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: strength == 'strong'
                ? 1.0
                : strength == 'fair'
                    ? 0.66
                    : 0.33,
            minHeight: 4,
            backgroundColor: const Color(0x1AFFFFFF),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Color(0x55FFFFFF),
            fontSize: 9,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0x55FFFFFF),
        fontSize: 9,
        letterSpacing: 2.5,
        fontWeight: FontWeight.w300,
      ),
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0x28FFFFFF),
        fontSize: 12,
        fontWeight: FontWeight.w300,
      ),
      filled: false,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0x18FFFFFF)),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0x18FFFFFF)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0x55AAAAAA)),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0x88FF5555)),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xAAFF5555)),
      ),
      errorStyle: const TextStyle(
        color: Color(0xAAFF5555),
        fontSize: 10,
      ),
      contentPadding: const EdgeInsets.only(bottom: 8),
      suffixIcon: suffixIcon,
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
    if (!authProvider.isUsingFirebase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google sign-up requires Firebase. Check google-services.json and SHA fingerprints.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        const MountainLogo(width: 246),
                        const SizedBox(height: 12),
                        const Text(
                          'ECOALERT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w200,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            _BrandTag('predict'),
                            _BrandDot(),
                            _BrandTag('prepare'),
                            _BrandDot(),
                            _BrandTag('protect'),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Create your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Join the environmental monitoring network.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0x44FFFFFF),
                            fontSize: 9,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.3,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                      decoration: _inputDecoration(
                        label: 'EMAIL',
                        hint: 'Enter your email',
                        suffixIcon: const Icon(Icons.alternate_email, color: Color(0x55FFFFFF), size: 22),
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
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                      decoration: _inputDecoration(
                        label: 'PHONE NUMBER',
                        hint: '03XXXXXXXXX',
                        suffixIcon: const Icon(Icons.phone_iphone, color: Color(0x55FFFFFF), size: 22),
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
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _cnicController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                      decoration: _inputDecoration(
                        label: 'CNIC',
                        hint: '35202XXXXXXXX',
                        suffixIcon: const Icon(Icons.badge_outlined, color: Color(0x55FFFFFF), size: 22),
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
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _provinceController,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                      decoration: _inputDecoration(
                        label: 'PROVINCE',
                        hint: 'Punjab / Sindh / KPK / Balochistan',
                        suffixIcon: const Icon(Icons.map_outlined, color: Color(0x55FFFFFF), size: 22),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your province';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _cityController,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                      decoration: _inputDecoration(
                        label: 'CITY',
                        hint: 'Enter your city',
                        suffixIcon: const Icon(Icons.location_city, color: Color(0x55FFFFFF), size: 22),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your city';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                      decoration: _inputDecoration(
                        label: 'PASSWORD',
                        hint: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0x55FFFFFF),
                            size: 22,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                      decoration: _inputDecoration(
                        label: 'CONFIRM PASSWORD',
                        hint: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0x55FFFFFF),
                            size: 22,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                          activeColor: const Color(0xFFAAAAAA),
                          checkColor: Colors.black,
                          side: const BorderSide(color: Color(0x33FFFFFF)),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: 'I agree to the ',
                              style: const TextStyle(
                                color: Color(0x44FFFFFF),
                                fontSize: 9,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.3,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: const TextStyle(
                                    color: Color(0x88FFFFFF),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w300,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0x44FFFFFF),
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushNamed(context, '/terms');
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    color: Color(0x88FFFFFF),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w300,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0x44FFFFFF),
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
                      height: 52,
                      width: double.infinity,
                      child: TextButton(
                        onPressed: authProvider.isLoading ? null : _handleSignup,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFAAAAAA),
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CREATE ACCOUNT',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 3.0,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('→', style: TextStyle(color: Colors.black, fontSize: 16)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: const Color(0x0DFFFFFF))),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or continue with',
                            style: TextStyle(
                              fontSize: 8,
                              letterSpacing: 2.5,
                              color: Color(0x22FFFFFF),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: const Color(0x0DFFFFFF))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: authProvider.isLoading ? null : _handleGoogleSignup,
                          borderRadius: BorderRadius.zero,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: const Color(0x12FFFFFF)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.g_mobiledata, color: Color(0xAAFFFFFF), size: 24),
                                SizedBox(width: 10),
                                Text(
                                  'Google',
                                  style: TextStyle(
                                    color: Color(0xAAFFFFFF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        children: [
                          const Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: Color(0x33FFFFFF),
                              fontSize: 9,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: const Color(0x22FFFFFF)),
                              ),
                              child: const Text(
                                'SIGN IN →',
                                style: TextStyle(
                                  color: Color(0x88FFFFFF),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1.5,
                                ),
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
      ),
    );
  }

}

class _BrandTag extends StatelessWidget {
  final String text;
  const _BrandTag(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0x44FFFFFF),
            fontSize: 8,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
      );
}

class _BrandDot extends StatelessWidget {
  const _BrandDot();

  @override
  Widget build(BuildContext context) => Container(
        width: 2,
        height: 2,
        decoration: const BoxDecoration(
          color: Color(0x22FFFFFF),
          shape: BoxShape.circle,
        ),
      );
}


