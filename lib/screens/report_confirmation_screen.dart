import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';

class ReportConfirmationScreen extends StatelessWidget {
  const ReportConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isPremium = auth.isPremium;
    final reports = context.watch<ReportProvider>().reports;
    final latestReport = reports.isNotEmpty ? reports.first : null;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final hazardType = args?['hazardType'] ?? 'Hazard';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — fixed, not scrollable
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ],
              ),
            ),

            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Success icon
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgCard,
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.35),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.25),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Headline
                    const Text(
                      'Report Sent',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),

                    // Impact points badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.25)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: AppColors.success, size: 18),
                          SizedBox(width: 6),
                          Text(
                            '+50 Impact Points',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Body text
                    Text(
                      isPremium
                          ? 'Thank you for helping your community. Our AI has analyzed your report and geo-alerts are notifying nearby users in your area.'
                          : 'Thank you for helping your community. Our AI has analyzed your report and is alerting nearby users.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Hazard analysis card
                    _AnalysisCard(
                      hazardType: hazardType,
                      latestReport: latestReport,
                      isPremium: isPremium,
                    ),
                    const SizedBox(height: 14),

                    // Report summary card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        border: Border.all(color: AppColors.borderSubtle),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.bgElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.cloud_outlined,
                              color: AppColors.success,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        hazardType,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'PENDING REVIEW',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 12, color: Colors.white54),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        latestReport?.locationLabel ??
                                            'Location unavailable',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Primary action
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.textInverse,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () =>
                            Navigator.of(context).popUntil((r) => r.isFirst),
                        child: const Text(
                          'Return to Home',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Secondary action
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('View My Report',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white54)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward,
                              size: 16, color: Colors.white54),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Analysis card extracted to keep build() readable ─────────────────────────

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.hazardType,
    required this.latestReport,
    required this.isPremium,
  });

  final String hazardType;
  final dynamic latestReport;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final r = latestReport;
    final isSmog = hazardType.toLowerCase().contains('smog') ||
        hazardType.toLowerCase().contains('aqi');
    final hasSensorAqi = r != null && r.aqi > 0;

    final title = (isSmog && hasSensorAqi)
        ? 'Regional air quality (sensors)'
        : hasSensorAqi
            ? 'Environmental context'
            : 'Hazard analysis';

    final String detailLine;
    if (r == null) {
      detailLine = 'No report data loaded yet.';
    } else if (!hasSensorAqi) {
      detailLine = 'AQI and model confidence are not inferred for this hazard '
          'type on the device. Submit a Smog / AQI report to attach the latest '
          'regional sensor snapshot when available.';
    } else {
      final pol =
          r.mainPollutant.isNotEmpty ? r.mainPollutant : 'pollutant mix';
      final confText = r.confidence > 0
          ? '${(r.confidence * 100).round()}% (model)'
          : 'sensor snapshot only — model not scored';
      detailLine = 'AQI: ${r.aqi} • $pol • $confText';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            detailLine,
            style: TextStyle(
              color: hasSensorAqi ? AppColors.success : AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (isSmog && hasSensorAqi) ...[
            const SizedBox(height: 6),
            const Text(
              'Estimated from public sensor feeds (e.g. WAQI), not from on-device image classification.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.4),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            isPremium
                ? 'Geo-warning delivery: ENABLED'
                : 'Geo-warning delivery: LOCKED (Premium)',
            style: TextStyle(
              color: isPremium ? AppColors.success : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.notifications_active,
                      color: AppColors.primary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Instant geo alerts to nearby users',
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.lock, color: Colors.white38, size: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
