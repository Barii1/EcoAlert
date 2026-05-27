import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/surface_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tier definitions
// ─────────────────────────────────────────────────────────────────────────────

// Guest (general)     → read-only, no personalization
// Registered          → alerts + location, no health calibration
// Premium             → all features: health calibration, geo-radius, AQI threshold

// Available health conditions a user can self-select
const _kAllConditions = [
  'Asthma',
  'COPD',
  'Heart Condition',
  'Diabetes',
  'Elderly Care',
  'Child Care',
  'Hypertension',
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late List<String> _selectedConditions;
  bool _savingConditions = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _selectedConditions = List<String>.from(user?.healthConditions ?? []);
  }

  Future<void> _toggleCondition(String condition, AuthProvider auth) async {
    final next = List<String>.from(_selectedConditions);
    if (next.contains(condition)) {
      next.remove(condition);
    } else {
      next.add(condition);
    }
    setState(() {
      _selectedConditions = next;
      _savingConditions = true;
    });
    await auth.updateHealthConditions(next);
    if (mounted) setState(() => _savingConditions = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.currentUser;

    final isAdmin = auth.isAdmin;
    final isGuest = !isAdmin && auth.currentRole == UserRole.general;
    final isPremium = !isAdmin && auth.currentRole == UserRole.premium;
    final isRegistered = !isAdmin && auth.currentRole == UserRole.registered;

    final tierLabel = isAdmin
        ? 'Admin'
        : isGuest
            ? 'Guest'
            : isPremium
                ? 'Premium'
                : 'Registered';

    final tierColor = isAdmin
        ? AppColors.warning
        : isPremium
            ? AppColors.info
            : isGuest
                ? AppColors.textSecondary
                : AppColors.success;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 60),
                  children: [
                    // ── Profile header ──────────────────────────────────────
                    _buildProfileHeader(user, tierLabel, tierColor, isAdmin, context),
                    const SizedBox(height: 20),

                    // ── Guest banner ─────────────────────────────────────────
                    if (isGuest) ...[
                      _guestBanner(),
                      const SizedBox(height: 20),
                    ],

                    // ── Admin shortcut ───────────────────────────────────────
                    if (isAdmin) ...[
                      _adminShortcut(context),
                      const SizedBox(height: 20),
                    ],

                    // ── Tier card ────────────────────────────────────────────
                    if (!isAdmin) ...[
                      _buildTierCard(isGuest, isRegistered, isPremium, tierColor, context),
                      const SizedBox(height: 24),
                    ],

                    // ── Location (Registered + Premium) ──────────────────────
                    if (!isGuest) ...[
                      _sectionLabel('Location'),
                      const SizedBox(height: 10),
                      _buildLocationCard(context),
                      const SizedBox(height: 24),
                    ],

                    // ── Health calibration (Premium only) ────────────────────
                    _sectionLabel('AI Health Calibration'),
                    const SizedBox(height: 10),
                    isPremium || isAdmin
                        ? _buildHealthCard(auth)
                        : _buildLockedCard(
                            icon: Icons.monitor_heart_rounded,
                            title: 'Health Calibration',
                            description:
                                'Tell the app about your health conditions to receive '
                                'personalised AQI warnings and smog alerts.',
                            tier: 'Premium',
                          ),
                    const SizedBox(height: 24),

                    // ── Appearance ───────────────────────────────────────────
                    _sectionLabel('Appearance'),
                    const SizedBox(height: 10),
                    _buildSection([
                      _ToggleTile(
                        icon: theme.isDarkMode
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        title: 'Dark Mode',
                        value: theme.isDarkMode,
                        onChanged: (_) => theme.toggleTheme(),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── About & Support ──────────────────────────────────────
                    _sectionLabel('About & Support'),
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
                      ),
                      _InfoTile(
                        icon: Icons.info_outline_rounded,
                        title: 'App Version',
                        value: '1.0.0',
                      ),
                      _NavTile(
                        icon: Icons.mail_outline_rounded,
                        title: 'Contact Support',
                        subtitle: 'support@ecoalert.pk',
                        onTap: () => _showContact(context),
                        isLast: true,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── Sign out ─────────────────────────────────────────────
                    if (auth.isAuthenticated) _buildSignOut(auth, context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

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
              Text('Profile & Settings',
                  style: AppTextStyles.headline
                      .copyWith(color: AppColors.textPrimary)),
              Text('Personalise your EcoAlert experience',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Profile header ─────────────────────────────────────────────────────────

  Widget _buildProfileHeader(UserModel? user, String tierLabel, Color tierColor,
      bool isAdmin, BuildContext context) {
    final displayName =
        user?.username.isNotEmpty == true ? user!.username : 'EcoAlert User';
    final initial = displayName[0].toUpperCase();

    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tierColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: tierColor.withOpacity(0.25)),
            ),
            child: Center(
              child: Text(initial,
                  style: AppTextStyles.headline.copyWith(
                      color: tierColor, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (user?.email.isNotEmpty == true)
                  Text(user!.email,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                if (user?.city.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: AppColors.textDisabled),
                    const SizedBox(width: 3),
                    Text(user!.city,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textDisabled, fontSize: 11)),
                  ]),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tierColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tierColor.withOpacity(0.3)),
            ),
            child: Text(tierLabel,
                style: AppTextStyles.label
                    .copyWith(color: tierColor, letterSpacing: 0.8)),
          ),
        ],
      ),
    );
  }

  // ── Guest banner ────────────────────────────────────────────────────────────

  Widget _guestBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You are browsing as a guest. Sign up for a free account to report hazards and customise alerts.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Admin shortcut ──────────────────────────────────────────────────────────

  Widget _adminShortcut(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/admin'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: AppColors.warning, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Dashboard',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text('Manage reports, users & broadcasts',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.warning),
          ],
        ),
      ),
    );
  }

  // ── Tier card ───────────────────────────────────────────────────────────────

  Widget _buildTierCard(bool isGuest, bool isRegistered, bool isPremium,
      Color tierColor, BuildContext context) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.info.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium,
                color: AppColors.info, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'You have Premium access — all features are unlocked.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium,
              color: AppColors.textDisabled, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGuest
                      ? 'Create a free account to unlock basic features'
                      : 'Upgrade to Premium for health calibration & geo-alerts',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      height: 1.4),
                ),
                if (isRegistered) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Premium unlocks: health conditions, custom AQI thresholds, geo-alert radius',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          if (isRegistered) ...[
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Text('Upgrade',
                  style: AppTextStyles.label.copyWith(color: AppColors.info)),
            ),
          ],
        ],
      ),
    );
  }

  // ── Location card ───────────────────────────────────────────────────────────

  Widget _buildLocationCard(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: AppColors.textSecondary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('City Location',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500)),
                  Consumer<LocationProvider>(
                    builder: (_, loc, __) => Text(
                      loc.currentCity.isNotEmpty
                          ? loc.currentCity
                          : context.watch<AuthProvider>().currentUser?.city ?? 'Not set',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final loc = context.read<LocationProvider>();
                await loc.getCurrentLocation();
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(
                  content: Text('Location updated to ${loc.currentCity}'),
                  backgroundColor: AppColors.bgElevated,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.my_location_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Detect',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Health calibration card (Premium) ──────────────────────────────────────

  Widget _buildHealthCard(AuthProvider auth) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select your health conditions',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'EcoAlert personalises AQI thresholds and smog warnings based on your conditions.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              if (_savingConditions)
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kAllConditions.map((condition) {
              final selected = _selectedConditions.contains(condition);
              return GestureDetector(
                onTap: () => _toggleCondition(condition, auth),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.info.withOpacity(0.15)
                        : AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.info.withOpacity(0.5)
                          : AppColors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 14,
                        color: selected
                            ? AppColors.info
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        condition,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: selected
                              ? AppColors.info
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedConditions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.tune_rounded,
                    size: 13, color: AppColors.textDisabled),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _buildPersonalisationNote(_selectedConditions),
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textDisabled, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _buildPersonalisationNote(List<String> conditions) {
    final hasRespiratory =
        conditions.any((c) => c == 'Asthma' || c == 'COPD');
    final hasCardiac = conditions.contains('Heart Condition');
    final notes = <String>[];
    if (hasRespiratory) notes.add('AQI alerts activated at 50 (Good→Moderate)');
    if (hasCardiac) notes.add('Heatwave alerts at lower temperature thresholds');
    if (conditions.contains('Elderly Care') || conditions.contains('Child Care')) {
      notes.add('Conservative thresholds applied for vulnerable groups');
    }
    if (notes.isEmpty) notes.add('Your conditions are saved and will personalise your alerts');
    return notes.join(' · ');
  }

  // ── Locked feature card ─────────────────────────────────────────────────────

  Widget _buildLockedCard({
    required IconData icon,
    required String title,
    required String description,
    required String tier,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textDisabled, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.textDisabled,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: Text(tier,
                          style: AppTextStyles.label.copyWith(
                              color: AppColors.info, fontSize: 9)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textDisabled, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded,
              size: 16, color: AppColors.textDisabled),
        ],
      ),
    );
  }

  // ── Sign out ────────────────────────────────────────────────────────────────

  Widget _buildSignOut(AuthProvider auth, BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmSignOut(context, auth),
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
            const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
            const SizedBox(width: 10),
            Text('Sign Out',
                style: AppTextStyles.titleMed.copyWith(
                    color: AppColors.danger, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: AppColors.textSecondary)),
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
                    color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Contact dialog ──────────────────────────────────────────────────────────

  void _showContact(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Contact Support',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _contactRow(Icons.mail_outline_rounded, 'support@ecoalert.pk'),
            const SizedBox(height: 8),
            _contactRow(Icons.phone_outlined, '+92 300 1234567'),
            const SizedBox(height: 8),
            _contactRow(Icons.emergency_rounded, '1122 (Emergency Hotline)',
                color: AppColors.danger),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text,
      {Color color = AppColors.textSecondary}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(text,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }

  // ── Shared layout helpers ───────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text.toUpperCase(),
            style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary, letterSpacing: 1.2)),
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

// ── Tile components ────────────────────────────────────────────────────────

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
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
                      Text(title,
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary)),
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
          const Divider(height: 1, indent: 64, color: AppColors.borderSubtle),
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
  });
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
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
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.textSecondary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500)),
              ),
              Text(value,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const Divider(height: 1, indent: 64, color: AppColors.borderSubtle),
      ],
    );
  }
}
