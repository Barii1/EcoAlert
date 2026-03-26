import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  // Create a 1024x1024 image
  final image = img.Image(width: 1024, height: 1024);
  
  // Fill with gradient (green)
  for (int y = 0; y < 1024; y++) {
    for (int x = 0; x < 1024; x++) {
      // Create gradient from dark green to light green
      final t = (x + y) / (1024 + 1024);
      final r = (46 + (102 - 46) * t).round();
      final g = (125 + (187 - 125) * t).round();
      final b = (50 + (106 - 50) * t).round();
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  
  // Draw a simple leaf shape (circle) in white
  img.fillCircle(image, x: 512, y: 450, radius: 250, color: img.ColorRgba8(255, 255, 255, 255));
  
  // Draw orange alert badge
  img.fillCircle(image, x: 750, y: 274, radius: 120, color: img.ColorRgba8(255, 111, 0, 255));
  
  // Draw white exclamation mark
  img.fillRect(image, x1: 740, y1: 220, x2: 760, y2: 290, color: img.ColorRgba8(255, 255, 255, 255));
  img.fillCircle(image, x: 750, y: 320, radius: 15, color: img.ColorRgba8(255, 255, 255, 255));
  
  // Save to file
  final file = File('assets/icons/app_icon.png');
  await file.create(recursive: true);
  await file.writeAsBytes(img.encodePng(image));
  
  stdout.writeln('✅ Icon created successfully at: ${file.path}');
  stdout.writeln('📦 Icon size: ${file.lengthSync()} bytes');
}
