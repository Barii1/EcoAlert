import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import 'map_heatmap_layer.dart';

class MapLegend extends StatelessWidget {
  const MapLegend({
    super.key,
    required this.mode,
  });

  final HeatmapMode mode;

  @override
  Widget build(BuildContext context) {
    final labels = mode == HeatmapMode.aqi
        ? const ['Hazardous', 'Unhealthy', 'Moderate', 'Safe']
        : const ['Severe', 'High', 'Moderate', 'Low'];

    final colors = mode == HeatmapMode.aqi
        ? const [
            Color(0xFF6D1B1B),
            Color(0xFFE53935),
            Color(0xFFFF9800),
            Color(0xFF2ECC71),
          ]
        : const [
            Color(0xFFE53935),
            Color(0xFFFF9800),
            Color(0xFFFFD54F),
            Color(0xFF2ECC71),
          ];

    return Opacity(
      opacity: 0.85,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 92,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: labels
                    .map(
                      (label) => Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
