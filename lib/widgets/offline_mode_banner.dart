import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../providers/connectivity_provider.dart';

class OfflineModeBanner extends StatelessWidget {
  const OfflineModeBanner({super.key, this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 0)});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        if (connectivityProvider.isOnline) {
          return const SizedBox.shrink();
        }

        return AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: Offset.zero,
          child: Container(
            margin: margin,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgCard.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgElevated,
                  ),
                  child: Icon(
                    Icons.wifi_off,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Mode',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last updated ${connectivityProvider.lastUpdateLabel}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 32,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      await connectivityProvider.retryConnection();
                    },
                    child: Text(
                      'RETRY',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
