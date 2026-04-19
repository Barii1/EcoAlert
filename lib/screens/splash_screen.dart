import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  double _progress = 0.0;
  bool _navigated = false;
  Timer? _progressTimer;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Simulate loading progress
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _progress += 0.02;
          if (_progress >= 1.0) {
            timer.cancel();
            _maybeNavigate();
          }
        });
      }
    });

    // Fallback navigation in case timers get paused.
    _fallbackTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_progress < 1.0) {
        setState(() {
          _progress = 1.0;
        });
      }
      _maybeNavigate();
    });
  }

  Future<void> _maybeNavigate() async {
    if (_navigated) return;
    if (_progress < 1.0) return;
    _navigated = true;
    final authProvider = context.read<AuthProvider>();

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // Get current version
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // Check onboarding conditions
    final onboardingSeenV1 = prefs.getBool('onboarding_seen_v1') ?? false;
    final lastSeenVersion = prefs.getString('last_seen_version') ?? '';
    final versionChanged = lastSeenVersion != currentVersion;

    // Show onboarding if first install OR version changed
    if (!onboardingSeenV1 || versionChanged) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
      return;
    }

    // Restore only a real Firebase session — never trust in-memory/demo flags alone.
    await authProvider.tryAutoLogin();
    if (!mounted) return;

    if (authProvider.isUsingFirebase) {
      if (FirebaseAuth.instance.currentUser == null) {
        await authProvider.firebaseLogout();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
    }

    if (authProvider.isAuthenticated) {
      if (authProvider.isAdmin) {
        Navigator.of(context).pushReplacementNamed('/admin');
      } else {
        Navigator.of(context).pushReplacementNamed('/navigation');
      }
      return;
    }

    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _fallbackTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // Background gradient: bgPrimary → bgSecondary
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.bgPrimary, AppColors.bgSecondary],
                ),
              ),
            ),
          ),

          // Primary glow
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGlow,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top spacer
                    const SizedBox(height: 60),

                    // Center content
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with glow effect
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryGlow,
                                      blurRadius: 80,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                              // Logo container
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.eco,
                                  size: 70,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Title
                          Text(
                            'EcoAlert',
                            style: AppTextStyles.displayLarge.copyWith(color: AppColors.textPrimary),
                          ),

                          const SizedBox(height: 12),

                          // Tagline
                          Text(
                            'Hyper-local Hazard Intelligence',
                            style: AppTextStyles.headline.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Bottom content
                    Column(
                      children: [
                        // Progress bar section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Progress header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'INITIALIZING SYSTEM',
                                  style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                                ),
                                TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: const Duration(seconds: 2),
                                  builder: (context, double value, child) {
                                    return Transform.rotate(
                                      angle: value * 2 * 3.14159,
                                      child: const Icon(
                                        Icons.sync,
                                        color: AppColors.primary,
                                        size: 16,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Progress bar
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.borderSubtle,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: Stack(
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: MediaQuery.of(context).size.width *
                                          0.88 *
                                          _progress,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryGlow,
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Footer text
                        Column(
                          children: [
                            Text(
                              'Powered by AI',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'v2.0.4 • Pakistan Region',
                              style: AppTextStyles.label.copyWith(color: AppColors.textDisabled),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
