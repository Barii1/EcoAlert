import 'package:flutter/material.dart';
import 'profile_setup_screen.dart';

class LocationPromptScreen extends StatelessWidget {
  const LocationPromptScreen({super.key});

  void _allowLocation(BuildContext context) {
    // In a real app, request location permission here
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
    );
  }

  void _enterManually(BuildContext context) {
    // Navigate to manual city entry or directly to profile setup
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f2323),
      body: Stack(
        children: [
          // Background gradient decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height / 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF007f80).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Center content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Radar/location visual
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Concentric circles
                            Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF007f80).withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                            Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF007f80).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF007f80).withOpacity(0.1),
                              ),
                            ),

                            // Main icon container
                            Transform.rotate(
                              angle: 0.05,
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF0f2323),
                                      const Color(0xFF1a2f2f),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF007f80),
                                  size: 48,
                                ),
                              ),
                            ),

                            // Indicator badge
                            Positioned(
                              top: 60,
                              right: 60,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF0f2323),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Title
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
                                text: 'Stay Safe with\n',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'Local Alerts',
                                style: TextStyle(color: Color(0xFF007f80)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'To provide you with AI-powered flood and smog predictions for your exact street, EcoAlert needs to know where you are.',
                          style: TextStyle(
                            color: const Color(0xFFaaaaaa),
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Bottom actions
                  Column(
                    children: [
                      // Primary button
                      ElevatedButton(
                        onPressed: () => _allowLocation(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007f80),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: const Color(0xFF007f80).withOpacity(0.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.near_me, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Allow Location Access',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Secondary button
                      TextButton(
                        onPressed: () => _enterManually(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text(
                          'Enter City Manually',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Privacy note
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'YOUR LOCATION IS NEVER SHARED',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
