import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../providers/aqi_provider.dart';
import '../providers/location_provider.dart';

class AqiScanScreen extends StatefulWidget {
  const AqiScanScreen({super.key});

  @override
  State<AqiScanScreen> createState() => _AqiScanScreenState();
}

class _AqiScanScreenState extends State<AqiScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _cameraInitialized = false;
  bool _cameraError = false;
  bool _capturing = false;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCamera();
      context.read<AqiProvider>().loadForCity(
            context.read<LocationProvider>().currentCity,
          );
    });
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      setState(() => _cameraError = true);
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = true);
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      _controller = controller;
      setState(() => _cameraInitialized = true);
    } catch (e) {
      debugPrint('[AqiScan] Camera init error: $e');
      if (mounted) setState(() => _cameraError = true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndReport(BuildContext context, dynamic reading) async {
    if (_controller == null || !_cameraInitialized) {
      Navigator.pushNamed(context, '/report-hazard', arguments: {
        'type': 'air_quality',
        'description': reading != null
            ? 'AQI reading: ${reading.aqi} (${reading.categoryLabel})'
            : 'Community AQI report',
      });
      return;
    }
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await _controller!.takePicture();
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.pushNamed(context, '/report-hazard', arguments: {
        'type': 'air_quality',
        'imagePath': file.path,
        'description': reading != null
            ? 'AQI reading: ${reading.aqi} (${reading.categoryLabel})'
            : 'Community AQI report',
      });
    } catch (e) {
      debugPrint('[AqiScan] Capture error: $e');
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not capture photo. Try again.'),
            backgroundColor: AppColors.bgElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AqiProvider>(
        builder: (context, aqi, _) {
          final reading = aqi.current;
          final accentColor = reading?.color ?? AppColors.primary;

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Camera / fallback background ──────────────────────────
              if (_cameraInitialized && _controller != null)
                CameraPreview(_controller!)
              else if (_cameraError)
                _buildNoCamera()
              else
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),

              // ── Dark gradient vignette ────────────────────────────────
              _buildVignette(accentColor),

              // ── Scan frame corners ────────────────────────────────────
              if (_cameraInitialized)
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => _ScanFrame(
                    color: accentColor
                        .withOpacity(0.6 + 0.4 * _pulseCtrl.value),
                  ),
                ),

              // ── Top bar (back + title) ────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        _GlassBtn(
                          icon: Icons.close_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.air_rounded,
                                  color: accentColor, size: 14),
                              const SizedBox(width: 6),
                              const Text(
                                'AQI SCAN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 44), // balance
                      ],
                    ),
                  ),
                ),
              ),

              // ── AQI pill (top-centre when reading available) ──────────
              if (reading != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 64,
                  left: 24,
                  right: 24,
                  child: _AqiPill(reading: reading),
                ),

              // ── Bottom panel ──────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomPanel(
                  reading: reading,
                  capturing: _capturing,
                  accentColor: accentColor,
                  onCapture: () => _captureAndReport(context, reading),
                  onViewAqi: () {
                    if (reading != null) {
                      Navigator.pushReplacementNamed(
                        context,
                        '/aqi-detail',
                        arguments: reading,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('AQI data loading...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoCamera() {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgElevated,
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: AppColors.textDisabled, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            kIsWeb ? 'Camera not supported on web' : 'Camera unavailable',
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'You can still submit a report manually.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }

  Widget _buildVignette(Color accentColor) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.35, 0.65, 1.0],
          colors: [
            Colors.black.withOpacity(0.65),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.95),
          ],
        ),
      ),
    );
  }
}

// ── AQI pill floating at top ─────────────────────────────────────────────────
class _AqiPill extends StatelessWidget {
  const _AqiPill({required this.reading});
  final dynamic reading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: reading.color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: reading.color.withOpacity(0.15),
              border: Border.all(color: reading.color.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                '${reading.aqi}',
                style: TextStyle(
                  color: reading.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reading.categoryLabel.toUpperCase(),
                  style: TextStyle(
                    color: reading.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reading.city.split(',').first,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet panel ────────────────────────────────────────────────────────
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.reading,
    required this.capturing,
    required this.accentColor,
    required this.onCapture,
    required this.onViewAqi,
  });

  final dynamic reading;
  final bool capturing;
  final Color accentColor;
  final VoidCallback onCapture;
  final VoidCallback onViewAqi;

  String get _tipText {
    if (reading == null) return 'Loading air quality data...';
    final aqi = reading!.aqi as int;
    if (aqi <= 50) return 'Air quality is great. Safe for all outdoor activities.';
    if (aqi <= 100) return 'Sensitive groups should limit prolonged outdoor exertion.';
    if (aqi <= 150) return 'Limit outdoor time. Wear a mask if going outside.';
    if (aqi <= 200) return 'Avoid outdoor activities. Keep windows closed.';
    return 'Health emergency. Stay indoors — do not go outside.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // PM2.5 / PM10 mini bars
          if (reading != null) ...[
            _PollutantBar(
                label: 'PM2.5',
                value: (reading!.aqi as int).toDouble(),
                max: 300,
                color: accentColor),
            const SizedBox(height: 8),
            _PollutantBar(
                label: 'PM10 ',
                value: ((reading!.aqi as int) * 1.4).clamp(0, 300),
                max: 300,
                color: accentColor.withOpacity(0.7)),
            const SizedBox(height: 16),
          ],

          // Tip text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: accentColor, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _tipText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: capturing ? null : onCapture,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 52,
                    decoration: BoxDecoration(
                      color: capturing
                          ? accentColor.withOpacity(0.5)
                          : accentColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: capturing
                          ? []
                          : [
                              BoxShadow(
                                color: accentColor.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (capturing)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        else
                          const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          capturing ? 'Capturing...' : 'Capture & Report',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.p12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: onViewAqi,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            color: accentColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Full Data',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PollutantBar extends StatelessWidget {
  const _PollutantBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = (value / max).clamp(0.0, 1.0);
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Scan frame with animated corner brackets ──────────────────────────────────
class _ScanFrame extends StatelessWidget {
  const _ScanFrame({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ScanFramePainter(color: color),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const margin = 48.0;
    const arm = 28.0;
    const r = margin;
    final b = size.height - margin;
    final right = size.width - margin;

    // Top-left
    canvas.drawLine(Offset(r, b - (b - r)), Offset(r, r), paint);
    canvas.drawLine(Offset(r, r), Offset(r + arm, r), paint);
    // Top-right
    canvas.drawLine(Offset(right - arm, r), Offset(right, r), paint);
    canvas.drawLine(Offset(right, r), Offset(right, r + arm), paint);
    // Bottom-left
    canvas.drawLine(Offset(r, b - arm), Offset(r, b), paint);
    canvas.drawLine(Offset(r, b), Offset(r + arm, b), paint);
    // Bottom-right
    canvas.drawLine(Offset(right - arm, b), Offset(right, b), paint);
    canvas.drawLine(Offset(right, b), Offset(right, b - arm), paint);
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) => old.color != color;
}

// ── Glass button ──────────────────────────────────────────────────────────────
class _GlassBtn extends StatelessWidget {
  const _GlassBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
