import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// Run this file to generate app icon
// flutter run lib/generate_icon.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create a simple icon
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Background
  final backgroundPaint = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(512, 512),
      [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
    );
  canvas.drawRect(const Rect.fromLTWH(0, 0, 512, 512), backgroundPaint);
  
  // White circle background
  final circlePaint = Paint()
    ..color = Colors.white.withOpacity(0.2)
    ..style = PaintingStyle.fill;
  canvas.drawCircle(const Offset(256, 256), 200, circlePaint);
  
  // Leaf icon (simplified)
  final leafPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  
  final path = Path();
  path.moveTo(256, 150);
  path.quadraticBezierTo(320, 200, 300, 280);
  path.quadraticBezierTo(280, 320, 256, 340);
  path.quadraticBezierTo(232, 320, 212, 280);
  path.quadraticBezierTo(192, 200, 256, 150);
  canvas.drawPath(path, leafPaint);
  
  // Alert badge
  final badgePaint = Paint()
    ..color = Colors.orange
    ..style = PaintingStyle.fill;
  canvas.drawCircle(const Offset(350, 200), 40, badgePaint);
  
  final badgeBorderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;
  canvas.drawCircle(const Offset(350, 200), 40, badgeBorderPaint);
  
  debugPrint('Icon design complete - Please use an icon generator tool or design software');
  debugPrint('Recommended: Use Figma, Canva, or online icon maker');
  debugPrint('Then run: flutter pub run flutter_launcher_icons');
}
