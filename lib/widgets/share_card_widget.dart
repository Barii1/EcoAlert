import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A fixed-size (320 × auto) shareable card wrapped in a RepaintBoundary.
/// Pass [repaintKey] to the parent so it can call
/// (repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage().
class ShareCardWidget extends StatelessWidget {
  const ShareCardWidget({
    required this.repaintKey,
    required this.city,
    required this.metricLabel,
    required this.value,
    required this.valueLabel,
    required this.accentColor,
    required this.timestamp,
    super.key,
  });

  final GlobalKey repaintKey;
  final String city;

  /// Short label shown above the big number: "AQI" or "Flood Risk"
  final String metricLabel;

  /// The big displayed value: e.g. "152" or "73%"
  final String value;

  /// Category / level text: e.g. "Unhealthy" or "High Risk"
  final String valueLabel;

  final Color accentColor;
  final DateTime timestamp;

  static const double _kCardWidth = 320;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: SizedBox(
        width: _kCardWidth,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: _kCardWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Branded header ───────────────────────────────────────
                Container(
                  color: const Color(0xFF111111),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.eco_rounded,
                            color: accentColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'EcoAlert',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      // City pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 11, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text(
                              city,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Metric block ─────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metric label (AQI / Flood Risk)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          metricLabel,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Big value + category side by side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 64,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                valueLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Thin accent divider
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.6),
                              accentColor.withOpacity(0.0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Timestamp
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 13, color: Color(0xFF888888)),
                          const SizedBox(width: 5),
                          Text(
                            DateFormat('MMM d, yyyy · h:mm a')
                                .format(timestamp),
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Tagline footer ───────────────────────────────────────
                Container(
                  color: const Color(0xFFF7F7F7),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.shield_rounded,
                          size: 13, color: accentColor),
                      const SizedBox(width: 6),
                      const Text(
                        'Stay safe. Stay informed.',
                        style: TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
