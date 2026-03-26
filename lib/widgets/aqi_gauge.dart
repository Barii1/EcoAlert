import 'package:flutter/material.dart';

/// Circular gauge for AQI detail screen.
class AqiGauge extends StatelessWidget {
  const AqiGauge({
    super.key,
    required this.aqi,
    required this.color,
    this.size = 180,
  });

  final int aqi;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(value: (aqi / 500).clamp(0.0, 1.0), color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$aqi',
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'AQI',
                style: TextStyle(
                  fontSize: size * 0.1,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final trackPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final valuePaint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const startAngle = 3.14 * 0.75;
    const sweepAngle = 3.14 * 1.5;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, trackPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * value, false, valuePaint);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value || old.color != color;
}
