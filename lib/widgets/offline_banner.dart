import 'package:flutter/material.dart';

import '../config/app_text_styles.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({
    super.key,
    required this.isOffline,
    required this.lastUpdated,
  });

  final bool isOffline;
  final DateTime? lastUpdated;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _dismissedForSession = false;

  @override
  Widget build(BuildContext context) {
    final visible = widget.isOffline && !_dismissedForSession;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, -1.15),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: visible ? 1 : 0,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFB56A18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD18A3A), width: 0.8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66231205),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.wifi_off_rounded,
                      color: Color(0xFFFFF0DC), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "You're offline — showing cached data",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFFFFF6E7),
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      if (widget.lastUpdated != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatLastUpdated(widget.lastUpdated!),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFFFFECD1),
                            fontSize: 11,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 16,
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFFFFF0DC), size: 16),
                    onPressed: () {
                      setState(() {
                        _dismissedForSession = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatLastUpdated(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes < 1 ? 1 : diff.inMinutes;
      return 'Last updated $minutes minute${minutes == 1 ? '' : 's'} ago';
    }
    final hours = diff.inHours < 1 ? 1 : diff.inHours;
    return 'Last updated $hours hour${hours == 1 ? '' : 's'} ago';
  }
}
