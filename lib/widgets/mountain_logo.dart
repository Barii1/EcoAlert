import 'package:flutter/material.dart';

class MountainLogo extends StatelessWidget {
  final double? width;
  final double? height;

  const MountainLogo({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/mountain.png',
      width: width,
      height: height,
    );
  }
}
