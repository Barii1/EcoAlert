import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../config/app_config.dart';
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
        ],
      );
    },
  );
}

Future<void> showPlanSelectionSheet(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your plan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade anytime. Premium unlocks geo-based warnings and priority alerts.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            _PlanCard(
              title: 'Basic',
              price: 'Free',
              bullets: const [
                'Core alerts & map access',
                'Standard refresh rate',
              ],
              highlight: false,
              onTap: () async {
                await auth.markPlanPromptSeen();
                if (context.mounted) Navigator.pop(context);
              },
              buttonLabel: 'Continue with Basic',
            ),
            const SizedBox(height: 12),
            _PlanCard(
              title: 'Premium',
              price: AppConfig.premiumPriceLabel,
              bullets: const [
                'Geo-based warnings',
                'Priority notifications',
                'Live GPS map marker',
              ],
              highlight: true,
              onTap: () async {
                await auth.upgradeToPremium();
                await auth.markPlanPromptSeen();
                if (context.mounted) Navigator.pop(context);
              },
              buttonLabel: 'Upgrade to Premium',
            ),
          ],
        ),
      );
    },
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.bullets,
    required this.highlight,
    required this.onTap,
    required this.buttonLabel,
  });

  final String title;
  final String price;
  final List<String> bullets;
  final bool highlight;
  final VoidCallback onTap;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final borderColor = highlight ? AppColors.primary : AppColors.borderSubtle;
    final badgeColor = highlight ? AppColors.primary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  price,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    highlight ? AppColors.primary : AppColors.bgPrimary,
                foregroundColor: AppColors.textInverse,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onTap,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
