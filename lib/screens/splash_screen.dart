import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _loadController;
  late Animation<double> _fadeAnim;
  late Animation<double> _loadAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _loadController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..forward();

    _loadAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _loadController,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _loadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Image.asset(
                  'assets/images/mountain.png',
                  width: screenWidth * 0.24,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'ECOALERT',
                style: AppTextStyles.displayMed.copyWith(
                  color: AppColors.textInverse,
                  letterSpacing: 6.5,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'predict  ·  prepare  ·  protect',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.6),
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.42,
                ),
                child: AnimatedBuilder(
                  animation: _loadAnim,
                  builder: (context, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _loadAnim.value,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withOpacity(0.4),
                        ),
                        minHeight: 1,
                      ),
                    );
                  },
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
