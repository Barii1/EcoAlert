import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecoalert/config/api_keys.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/location');
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f2323),
      body: Stack(
        children: [
          // Subtle background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.07,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Pakistan_physical_map.svg/2560px-Pakistan_physical_map.svg.png',
                    ),
                    fit: BoxFit.cover,
                    opacity: 0.1,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top navigation
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      // Logo
                      Row(
                        children: [
                          const Icon(
                            Icons.eco,
                            color: Color(0xFF007f80),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'EcoAlert',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Skip button
                      TextButton(
                        onPressed: _skipOnboarding,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: const Color(0xFF9abcbc),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildPage1(),
                      _buildPage2(),
                      _buildPage3(),
                      _buildPage4(),
                    ],
                  ),
                ),

                // Bottom navigation
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicators
                      Row(
                        children: List.generate(4, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            width: _currentPage == index ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? const Color(0xFF007f80)
                                  : const Color(0xFF334444),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      // Next button
                      GestureDetector(
                        onTap: _nextPage,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007f80),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF007f80).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero illustration
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007f80).withOpacity(0.2),
                      blurRadius: 100,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
              // Inner glow
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF007f80).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Radar circles
              ...List.generate(3, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 2000 + (index * 500)),
                  curve: Curves.easeInOut,
                  width: 100.0 + (index * 50),
                  height: 100.0 + (index * 50),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF007f80).withOpacity(0.3 - index * 0.1),
                      width: 2,
                    ),
                  ),
                );
              }),
              // Center icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF152e2e),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF007f80).withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Color(0xFF007f80),
                  size: 40,
                ),
              ),
            ],
          ),

          const SizedBox(height: 60),

          // Typography
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.1,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                  text: 'Stay Ahead of the ',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: 'Storm',
                  style: TextStyle(color: Color(0xFF007f80)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Receive instant, AI-driven notifications for environmental hazards like floods and toxic smog specific to your neighborhood.',
            style: TextStyle(
              color: const Color(0xFFaaaaaa),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for second page illustration
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007f80).withOpacity(0.2),
                      blurRadius: 100,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF152e2e),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF007f80).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Color(0xFF007f80),
                  size: 40,
                ),
              ),
            ],
          ),

          const SizedBox(height: 60),

          const Text(
            'Real-time Intelligence',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Get accurate predictions and safety recommendations powered by advanced AI algorithms.',
            style: TextStyle(
              color: const Color(0xFFaaaaaa),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Map visualization card
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              color: const Color(0xFF1a2c2c),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  // Map background
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://api.mapbox.com/styles/v1/mapbox/dark-v10/static/74.3587,31.5204,11,0/400x600@2x?access_token=${ApiKeys.mapbox}',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0f2323).withOpacity(0.1),
                          Colors.transparent,
                          const Color(0xFF0f2323).withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),

                  // Hazard indicator
                  Positioned(
                    top: 100,
                    right: 80,
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flood,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'HAZARD',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Info card at bottom
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a2c2c).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF007f80).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.alt_route,
                              color: Color(0xFF007f80),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Safe Route Found',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Avoiding Model Town flood zone',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF007f80),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.white,
                              size: 16,
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

          const SizedBox(height: 40),

          const Text(
            'Find Safe Paths',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Real-time maps showing hazard zones and AI-calculated alternative routes to keep you safe from floods and roadblocks.',
            style: TextStyle(
              color: const Color(0xFFaaaaaa),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPage4() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero illustration card
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: 320,
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1a2c2c).withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007f80).withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF007f80).withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                // Phone illustration
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 160,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9abcbc).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF9abcbc).withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF007f80).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.shield,
                                    color: Color(0xFF007f80),
                                    size: 32,
                                  ),
                                ),
                              ),
                              // Small people icons around
                              Positioned(
                                top: 20,
                                left: -8,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF007f80),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 20,
                                right: -8,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF007f80),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                left: 10,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF007f80),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                right: 10,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF007f80),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 12,
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
                // Floating icons
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF007f80),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF007f80),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162e2e).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF007f80).withOpacity(0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.group,
                      color: Color(0xFF007f80),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Typography
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.1,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                  text: 'Community &\n',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: 'Safety First',
                  style: TextStyle(color: Color(0xFF007f80)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Contribute to real-time alerts by reporting hazards. Stay safe with AI-curated guidelines tailored to Pakistan\'s climate.',
            style: TextStyle(
              color: const Color(0xFFaaaaaa),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
