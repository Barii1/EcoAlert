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
        ],
      );
    },
  );
}
