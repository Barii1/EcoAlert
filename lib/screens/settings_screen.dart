import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../config/eco_colors.dart';
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
    final colors = EcoColors.of(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, colors),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  children: [
                    if (user != null) ...[
                      _UserCard(user: user, colors: colors),
                      const SizedBox(height: 28),
                    ],

                    _sectionLabel('Appearance', colors),
                    const SizedBox(height: 10),
                    _buildSection(colors, [
                      _ToggleTile(
                        icon: theme.isDarkMode
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        title: 'Dark Mode',
                        subtitle: theme.isDarkMode
                            ? 'Using dark theme'
                            : 'Using light theme',
                        value: theme.isDarkMode,
                        onChanged: (_) => theme.toggleTheme(),
                        colors: colors,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    _sectionLabel('Account', colors),
                    const SizedBox(height: 10),
                    _buildSection(colors, [
                      _NavTile(
                        icon: Icons.person_outline_rounded,
                        title: 'My Profile',
                        subtitle: 'Edit name, city, preferences',
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        colors: colors,
                      ),
                      _NavTile(
                        icon: Icons.notifications_outlined,
                        title: 'Alert Preferences',
                        subtitle: 'Notifications & thresholds',
                        onTap: () =>
                            Navigator.pushNamed(context, '/alert-settings'),
                        isLast: true,
                        colors: colors,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    _sectionLabel('Legal', colors),
                    const SizedBox(height: 10),
                    _buildSection(colors, [
                      _NavTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => Navigator.pushNamed(context, '/privacy'),
                        colors: colors,
                      ),
                      _NavTile(
                        icon: Icons.article_outlined,
                        title: 'Terms & Conditions',
                        onTap: () => Navigator.pushNamed(context, '/terms'),
                        isLast: true,
                        colors: colors,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    _sectionLabel('About', colors),
                    const SizedBox(height: 10),
                    _buildSection(colors, [
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snap) => _InfoTile(
                          icon: Icons.info_outline_rounded,
                          title: 'App Version',
                          value: snap.hasData
                              ? '${snap.data!.version}+${snap.data!.buildNumber}'
                              : '—',
                          colors: colors,
                        ),
                      ),
                      _InfoTile(
                        icon: Icons.cloud_outlined,
                        title: 'Data Sources',
                        value: 'WAQI · Open-Meteo',
                        isLast: true,
                        colors: colors,
                      ),
                    ]),
                    const SizedBox(height: 36),

                    if (auth.isAuthenticated) ...[
                      _SignOutButton(auth: auth, colors: colors),
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

  Widget _buildAppBar(BuildContext context, EcoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.borderSubtle, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings',
                  style: AppTextStyles.headline
                      .copyWith(color: colors.textPrimary)),
              Text('App preferences & account',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: colors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, EcoColors colors) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: colors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(EcoColors colors, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: colors.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(children: children),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.colors});
  final UserModel user;
  final EcoColors colors;

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
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: colors.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: colors.primary.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: AppTextStyles.headline.copyWith(
                    color: colors.primary,
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
                        .copyWith(color: colors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.city.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 11, color: colors.textDisabled),
                        const SizedBox(width: 4),
                        Text(
                          user.city,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textDisabled, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Text(
                'Edit',
                style:
                    AppTextStyles.label.copyWith(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile types ────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.colors,
    this.subtitle,
    this.isLast = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final EcoColors colors;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
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
                    color: colors.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(icon, color: colors.textSecondary, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: colors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: colors.textDisabled, size: 18),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 64, color: colors.borderSubtle),
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
    required this.colors,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final EcoColors colors;

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
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colors.textSecondary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: colors.textSecondary),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colors.textInverse,
            activeTrackColor: colors.primary,
            inactiveThumbColor: colors.textSecondary,
            inactiveTrackColor: colors.bgElevated,
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
    required this.colors,
    this.isLast = false,
  });
  final IconData icon;
  final String title;
  final String value;
  final EcoColors colors;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(icon, color: colors.textSecondary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodySmall
                    .copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 64, color: colors.borderSubtle),
      ],
    );
  }
}

// ── Sign out button ───────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.auth, required this.colors});
  final AuthProvider auth;
  final EcoColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmSignOut(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: colors.danger.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.danger.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: colors.danger, size: 18),
            const SizedBox(width: 10),
            Text(
              'Sign Out',
              style: AppTextStyles.titleMed.copyWith(
                color: colors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final colors = EcoColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out',
            style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              Navigator.pop(context);
              await auth.logout();
              nav.pushNamedAndRemoveUntil('/login', (_) => false);
            },
            child: Text('Sign Out',
                style: TextStyle(
                    color: colors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
