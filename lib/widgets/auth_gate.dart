import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/premium_ux.dart';

/// Redirects to [loginRoute] when the user is not signed in.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.child,
    this.loginRoute = '/login',
  });

  final Widget child;
  final String loginRoute;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, loginRoute, (route) => false);
      });
      return const Scaffold(
        backgroundColor: AppColors.bgSecondary,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (!auth.isEmailVerified && !auth.hasShownVerifyWarning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        auth.markVerifyWarningShown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your email is not verified yet. Some features may be limited.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    if (auth.shouldShowPlanPrompt && !auth.hasShownUpgradePrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        auth.markUpgradePromptShown();
        showPlanSelectionSheet(context);
      });
    }

    final location = context.read<LocationProvider>();
    if (!location.hasRequestedPermission && !location.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        location.getCurrentLocation();
      });
    }

    return child;
  }
}

/// Requires an authenticated admin ([UserRole.admin]).
class AdminGate extends StatelessWidget {
  const AdminGate({
    super.key,
    required this.child,
    this.loginRoute = '/login',
    this.fallbackRoute = '/navigation',
  });

  final Widget child;
  final String loginRoute;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, loginRoute, (route) => false);
      });
      return const Scaffold(
        backgroundColor: AppColors.bgSecondary,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (!auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, fallbackRoute, (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin access required.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
      return const Scaffold(
        backgroundColor: AppColors.bgSecondary,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return child;
  }
}
