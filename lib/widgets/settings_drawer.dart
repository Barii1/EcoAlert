import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardColor;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Drawer(
      backgroundColor: scaffoldBg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      (auth.currentUser?.username ?? 'G').isNotEmpty
                          ? (auth.currentUser?.username ?? 'G')[0].toUpperCase()
                          : 'G',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentUser?.username ?? 'Guest User',
                          style: AppTextStyles.titleMed.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          auth.currentUser?.email ?? '',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: cs.onSurface.withOpacity(0.55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: cs.onSurface.withOpacity(0.1)),
            const SizedBox(height: 8),

            _SectionTitle(title: 'Quick actions'),

            // Dark Mode toggle
            Consumer<ThemeProvider>(
              builder: (context, theme, _) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: CircleAvatar(
                  radius: 18,
                  backgroundColor: cardColor,
                  child: Icon(
                    theme.isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                title: Text(
                  'Dark Mode',
                  style: AppTextStyles.bodyPrimary.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                value: theme.isDarkMode,
                onChanged: (_) => theme.toggleTheme(),
              ),
            ),

            const SizedBox(height: 8),
            Divider(color: cs.onSurface.withOpacity(0.1)),
            const SizedBox(height: 8),

            _SectionTitle(title: 'Account'),

            // Profile tile
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: cardColor,
                child: Icon(Icons.person_outline, color: AppColors.textSecondary, size: 18),
              ),
              title: Text(
                'Profile',
                style: AppTextStyles.bodyPrimary.copyWith(color: cs.onSurface),
              ),
              trailing: Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.4), size: 18),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: cardColor,
                child: Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 18),
              ),
              title: Text(
                'Alert Settings',
                style: AppTextStyles.bodyPrimary.copyWith(color: cs.onSurface),
              ),
              trailing: Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.4), size: 18),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/alert-settings');
              },
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: cardColor,
                child: Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 18),
              ),
              title: Text(
                'All Settings',
                style: AppTextStyles.bodyPrimary.copyWith(color: cs.onSurface),
              ),
              trailing: Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.4), size: 18),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),

            const SizedBox(height: 8),
            Divider(color: cs.onSurface.withOpacity(0.1)),
            const SizedBox(height: 8),

            _SectionTitle(title: 'Legal'),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: cardColor,
                child: Icon(Icons.privacy_tip_outlined, color: AppColors.textSecondary, size: 18),
              ),
              title: Text(
                'Privacy Policy',
                style: AppTextStyles.bodyPrimary.copyWith(color: cs.onSurface),
              ),
              trailing: Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.4), size: 18),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/privacy');
              },
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: cardColor,
                child: Icon(Icons.article_outlined, color: AppColors.textSecondary, size: 18),
              ),
              title: Text(
                'Terms & Conditions',
                style: AppTextStyles.bodyPrimary.copyWith(color: cs.onSurface),
              ),
              trailing: Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.4), size: 18),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/terms');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4, left: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: cs.onSurface.withOpacity(0.45),
          letterSpacing: 1.0,
          fontSize: 10,
        ),
      ),
    );
  }
}
