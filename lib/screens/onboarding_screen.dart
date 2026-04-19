import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  void _handleGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();

    await prefs.setBool('onboarding_seen_v1', true);
    await prefs.setString('last_seen_version', packageInfo.version);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _handleLearnMore() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About EcoAlert',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF181D1A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'EcoAlert is an environmental intelligence platform that provides real-time predictions and alerts for critical weather events across Pakistan.',
                style: AppTextStyles.body.copyWith(
                  fontSize: 16,
                  color: const Color(0xFF404944),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Features',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181D1A),
                ),
              ),
              const SizedBox(height: 12),
              ...[
                ('Smog Alerts', 'Real-time air quality monitoring'),
                ('Flood Warnings', 'Early detection of water level rises'),
                ('Instant Notifications', 'SMS and push alerts before disaster strikes'),
              ].map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF002E20), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181D1A),
                              ),
                            ),
                            Text(
                              item.$2,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 14,
                                color: const Color(0xFF404944),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: Navigator.of(context).pop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002E20),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Got it',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF002E20);
    const primaryFixed = Color(0xFFB6EFD5);
    const onSurface = Color(0xFF181D1A);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida/ADBb0uithJKX56sGdCyVF-vM5v9HxltUMqHe8Y--POBxm__wuXAWnAjFF6o0-7ZxMnY4MJa8Yj37vD6yiomsnV_gA08bo9UkoHzrnGYX8bHSL6iLdV3rqhBFlsA_cbOZUiKsrwtzEFaScseG5PTJjYCBzDwhV9cG36H2qUnPvyELKMRQME03LlGmyAqdA2BjJYthM9GXGNL_qKywHKV00l-2Slx9FnrrYusFehk_nerf_fWb1oejgUYyF7fTeg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.transparent,
                    Colors.black.withOpacity(0.355),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.eco, color: primary, size: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'EcoAlert',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.02 * 24,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 64),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Environmental Intelligence',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.02 * 48,
                        color: Colors.white,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      children: [
                        const TextSpan(text: 'Protect Your '),
                        TextSpan(
                          text: 'Tomorrow',
                          style: AppTextStyles.headline.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.02 * 48,
                            color: primaryFixed,
                          ),
                        ),
                        const TextSpan(text: ', Today.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'EcoAlert provides real-time predictions and alerts for smog, flooding, and cloudbursts across Pakistan, keeping you and your family safe.',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleGetStarted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 12,
                        shadowColor: primary.withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: AppTextStyles.headline.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleLearnMore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                      child: Text(
                        'Learn More',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.cloud,
                          title: 'Smog',
                          description: 'Air quality tracking',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.water_damage,
                          title: 'Flooding',
                          description: 'Early rise detection',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Divider(color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bolt, color: primaryFixed, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instant Notifications',
                              style: AppTextStyles.headline.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Receive alerts via SMS and Push before disaster strikes.',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.33,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.755),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF002E20).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF002E20), size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181D1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF404944),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
