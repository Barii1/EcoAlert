import 'package:flutter/material.dart';

/// Run this widget to generate an app icon
/// Take a screenshot of the displayed icon and save it as app_icon.png
class IconGeneratorWidget extends StatelessWidget {
  const IconGeneratorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Container(
            width: 1024,
            height: 1024,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E7D32), // Dark green
                  Color(0xFF66BB6A), // Light green
                ],
              ),
              borderRadius: BorderRadius.circular(230),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main eco leaf icon
                Center(
                  child: Transform.scale(
                    scale: 1.8,
                    child: const Icon(
                      Icons.eco,
                      color: Colors.white,
                      size: 300,
                    ),
                  ),
                ),
                // Alert badge
                Positioned(
                  top: 150,
                  right: 150,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6F00), // Orange
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.priority_high,
                        color: Colors.white,
                        size: 160,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// To use this, create a temporary main.dart:
// void main() => runApp(const IconGeneratorWidget());
