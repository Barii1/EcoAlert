import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  final inputPath = args.isNotEmpty ? args[0] : 'assets/icons/app_icon_source.jpg';
  final outputPath = args.length > 1 ? args[1] : 'assets/icons/app_icon.png';

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Input not found: $inputPath');
    stderr.writeln('Place your logo at assets/icons/app_icon_source.jpg (or pass a path)');
    exitCode = 2;
    return;
  }

  final bytes = inputFile.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Could not decode image: $inputPath');
    exitCode = 3;
    return;
  }

  // Ensure a square 1024x1024 output for launcher icon generation.
  final square = img.copyResizeCropSquare(decoded, size: 1024);
  final pngBytes = img.encodePng(square, level: 6);

  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(pngBytes);

  stdout.writeln('Wrote $outputPath (1024x1024)');
}
