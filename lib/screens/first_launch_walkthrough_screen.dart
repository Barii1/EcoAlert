import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';

// ── Slide data ────────────────────────────────────────────────────────────────

class _Slide {
  final IconData icon;
  final String title;
  final String description;
  const _Slide({
    required this.icon,
    required this.title,
    required this.description,
  });
}

const _kSlides = [
  _Slide(
    icon: Icons.eco_rounded,
    title: 'Welcome to EcoAlert',
    description: "Pakistan's real-time environmental alert app",
  ),
  _Slide(
    icon: Icons.air,
    title: 'Live Air Quality',
    description: 'AQI updated every 15 minutes from sensors near you',
  ),
  _Slide(
    icon: Icons.flood,
    title: 'Flood Risk Alerts',
    description: 'ML model predicts cloudburst risk 6 hours ahead',
  ),
  _Slide(
    icon: Icons.groups_rounded,
    title: 'Community Reports',
    description: 'Report and view hazards reported by people around you',
  ),
  _Slide(
    icon: Icons.health_and_safety_rounded,
    title: 'Your Safety, Simplified',
    description: 'Guided safety checklists and health tips',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class FirstLaunchWalkthroughScreen extends StatefulWidget {
  const FirstLaunchWalkthroughScreen({super.key});

  @override
  State<FirstLaunchWalkthroughScreen> createState() =>
      _FirstLaunchWalkthroughScreenState();
}

class _FirstLaunchWalkthroughScreenState
    extends State<FirstLaunchWalkthroughScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _kSlides.length - 1;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_walkthrough', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _next() => _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top row: Skip (hidden on last slide via opacity) ──────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Opacity(
                    opacity: _isLast ? 0.0 : 1.0,
                    child: TextButton(
                      onPressed: _isLast ? null : _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Skip',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Slides ───────────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _kSlides.length,
                  itemBuilder: (_, i) => _SlidePage(slide: _kSlides[i]),
                ),
              ),

              // ── Dot indicators ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_kSlides.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : AppColors.textDisabled,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 36),

              // ── Next / Get Started button ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: TextButton(
                    onPressed: _isLast ? _finish : _next,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textInverse,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(
                        Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      _isLast ? 'Get Started' : 'Next',
                      style: AppTextStyles.titleMed.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 44),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual slide ──────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with a subtle glowing circle behind it
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.06),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Icon(
              slide.icon,
              size: 96,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 48),

          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMed.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.65,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
