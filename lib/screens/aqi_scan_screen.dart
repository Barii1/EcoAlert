import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../providers/aqi_provider.dart';
import '../providers/location_provider.dart';

/// AQI Scan Screen — camera overlay with live AQI data.
/// Accessed from: Home AQI card (secondary action) + Report Hazard screen.
class AqiScanScreen extends StatefulWidget {
  const AqiScanScreen({super.key});

  @override
  State<AqiScanScreen> createState() => _AqiScanScreenState();
}

class _AqiScanScreenState extends State<AqiScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AqiProvider>().loadForCity(
            context.read<LocationProvider>().currentCity,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SCAN AQI',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AqiProvider>(
        builder: (context, aqi, _) {
          final reading = aqi.current;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.p20),
                // Camera preview placeholder (full implementation requires camera package)
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppSpacing.radius16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              size: 64,
                              color: AppColors.textDisabled,
                            ),
                            const SizedBox(height: AppSpacing.p12),
                            Text(
                              'Camera preview',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Point at visible haze or smog',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textDisabled,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (reading != null)
                        Positioned(
                          left: AppSpacing.p16,
                          right: AppSpacing.p16,
                          bottom: AppSpacing.p16,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.p12),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard.withOpacity(0.95),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radius12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AQI  ${reading.aqi}  ${reading.categoryLabel}',
                                      style: AppTextStyles.titleMed.copyWith(
                                        color: reading.color,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${reading.city} • Updated now',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.p24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _captureAndReport(context, reading),
                        icon: const Icon(Icons.camera_alt_rounded, size: 20),
                        label: const Text('Capture & Report'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textInverse,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.p16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (reading != null) {
                            Navigator.pushReplacementNamed(
                              context,
                              '/aqi-detail',
                              arguments: reading,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Loading AQI data...'),
                                backgroundColor: AppColors.bgElevated,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.air, size: 20),
                        label: const Text('My AQI'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.p16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.p24),
                Text(
                  'Point camera at visible haze or smog and capture to submit a community air quality report.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _captureAndReport(BuildContext context, dynamic reading) {
    // Navigate to ReportHazardScreen with pre-filled air_quality data
    Navigator.pushNamed(
      context,
      '/report-hazard',
      arguments: {
        'type': 'air_quality',
        'description': reading != null
            ? 'AQI reading: ${reading.aqi} (${reading.categoryLabel})'
            : 'Community AQI report',
      },
    );
  }
}
