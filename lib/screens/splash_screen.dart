import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

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
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        Navigator.pushReplacementNamed(
          context,
          auth.isAdmin ? '/admin' : '/navigation',
        );
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
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
      backgroundColor: Colors.black,
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
              const Text(
                'ECOALERT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 6.5,
                  fontFamily: 'Sans-serif',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'predict  ·  prepare  ·  protect',
                style: TextStyle(
                  color: Color(0x44ffffff),
                  fontSize: 12,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 2.5,
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
                        backgroundColor: const Color(0x15ffffff),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0x44ffffff),
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
