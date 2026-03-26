import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

Future<void> showPremiumFeatureDialog(
  BuildContext context, {
  required String featureName,
}) async {
  final auth = context.read<AuthProvider>();
  if (auth.currentRole == UserRole.general) {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text(
            'Sign in required',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Please sign in to access $featureName.\n\nPremium users also unlock geo-based warnings and priority notifications.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: const Text('Go to Login'),
            ),
          ],
        );
      },
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(
          'Premium feature',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '$featureName is available in EcoAlert Premium.\n\nUpgrade to unlock geo-based warnings, priority notifications, and emergency help tools.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Not now', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
            ),
            onPressed: () {
              context.read<AuthProvider>().upgradeToPremium();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Premium unlocked (demo).'),
                  backgroundColor: AppColors.bgElevated,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Upgrade'),
          ),
        ],
      );
    },
  );
}

Future<void> showUpgradePromptDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(
          'Upgrade to Premium',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get real-time protection with:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const _PerkRow(icon: Icons.gps_fixed, text: 'Geo-location based warnings'),
            const SizedBox(height: 8),
            const _PerkRow(icon: Icons.notifications_active, text: 'Priority notifications'),
            const SizedBox(height: 8),
            const _PerkRow(icon: Icons.emergency, text: 'Emergency help shortcuts'),
            const SizedBox(height: 8),
            const _PerkRow(icon: Icons.shield, text: 'Early hazard alerts & guidance'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe later', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
            ),
            onPressed: () {
              context.read<AuthProvider>().upgradeToPremium();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Premium unlocked (demo).'),
                  backgroundColor: AppColors.bgElevated,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Upgrade now'),
          ),
        ],
      );
    },
  );
}

class PremiumLock extends StatelessWidget {
  const PremiumLock({
    super.key,
    required this.locked,
    required this.featureName,
    required this.child,
  });

  final bool locked;
  final String featureName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    return Stack(
      children: [
        Opacity(opacity: 0.45, child: child),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showPremiumFeatureDialog(
                context,
                featureName: featureName,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: AppColors.textPrimary.withOpacity(0.85)),
          ),
        ),
      ],
    );
  }
}
