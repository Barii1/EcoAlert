import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  children: [
                    if (user != null) ...[
                      _UserCard(user: user),
                      const SizedBox(height: 28),
                    ],

                    _sectionLabel('Appearance'),
                    const SizedBox(height: 10),
                    _buildSection([
                      _ToggleTile(
                        icon: theme.isDarkMode
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        title: 'Dark Mode',
                        subtitle: theme.isDarkMode ? 'Using dark theme' : 'Using light theme',
                        value: theme.isDarkMode,
                        onChanged: (_) => theme.toggleTheme(),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    _sectionLabel('Account'),
                    const SizedBox(height: 10),
                    _buildSection([
                      _NavTile(
                        icon: Icons.person_outline_rounded,
                        title: 'My Profile',
                        subtitle: 'Edit name, city, preferences',
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                      ),
                      _NavTile(
                        icon: Icons.notifications_outlined,
                        title: 'Alert Preferences',
                        subtitle: 'Notifications & thresholds',
                        onTap: () =>
                            Navigator.pushNamed(context, '/alert-settings'),
                        isLast: true,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    _sectionLabel('Legal'),
                    const SizedBox(height: 10),
                    _buildSection([
                      _NavTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => Navigator.pushNamed(context, '/privacy'),
                      ),
                      _NavTile(
                        icon: Icons.article_outlined,
                        title: 'Terms & Conditions',
                        onTap: () => Navigator.pushNamed(context, '/terms'),
                        isLast: true,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    _sectionLabel('About'),
                    const SizedBox(height: 10),
                    _buildSection([
                      _InfoTile(
                        icon: Icons.info_outline_rounded,
                        title: 'App Version',
                        value: '1.0.0',
                      ),
                      _InfoTile(
                        icon: Icons.cloud_outlined,
                        title: 'Data Sources',
                        value: 'WAQI · Open-Meteo',
                        isLast: true,
                      ),
                    ]),
                    const SizedBox(height: 36),

                    if (auth.isAuthenticated) ...[
                      _SignOutButton(auth: auth),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings',
                  style: AppTextStyles.headline
                      .copyWith(color: AppColors.textPrimary)),
              Text('App preferences & account',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(children: children),
    );
  }
}

// ── User card ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final initial = user.username.isNotEmpty
        ? user.username[0].toUpperCase()
        : (user.email.isNotEmpty ? user.email[0].toUpperCase() : 'U');

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username.isNotEmpty ? user.username : 'EcoAlert User',
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.city.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: AppColors.textDisabled),
                        const SizedBox(width: 4),
                        Text(
                          user.city,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textDisabled, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'Edit',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile types ───────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isLast = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
            top: isLast == false ? Radius.zero : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.textSecondary, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textDisabled, size: 18),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1, indent: 64, color: AppColors.borderSubtle),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.textPrimary,
            activeTrackColor: AppColors.primary.withOpacity(0.4),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.bgElevated,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.isLast = false,
  });
  final IconData icon;
  final String title;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.textSecondary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1, indent: 64, color: AppColors.borderSubtle),
      ],
    );
  }
}

// ── Sign out button ──────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.auth});
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmSignOut(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded,
                color: AppColors.danger, size: 18),
            const SizedBox(width: 10),
            Text(
              'Sign Out',
              style: AppTextStyles.titleMed.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              Navigator.pop(context);
              await auth.logout();
              nav.pushNamedAndRemoveUntil('/login', (_) => false);
            },
            child: const Text('Sign Out',
                style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
