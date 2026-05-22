import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../widgets/app_background.dart';
import '../widgets/surface_card.dart';
import 'guide_detail_screen.dart';
import 'prep_checklist_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<_GuideItem> _guides = [
    // Flood
    _GuideItem(
      title: 'Flood Survival Guide',
      subtitle: 'What to do before, during and after a flood',
      icon: Icons.water_rounded,
      color: Color(0xFF1565C0),
      duration: '8 min',
      category: 'Flood',
      featured: true,
    ),
    _GuideItem(
      title: 'Cloudburst & Flash Floods',
      subtitle: 'Recognize sudden intense rainfall events',
      icon: Icons.thunderstorm_rounded,
      color: Color(0xFF0288D1),
      duration: '5 min',
      category: 'Flood',
    ),
    _GuideItem(
      title: 'Monsoon Preparedness',
      subtitle: 'Seasonal flood readiness checklist',
      icon: Icons.umbrella_rounded,
      color: Color(0xFF0097A7),
      duration: '6 min',
      category: 'Flood',
    ),
    // Air / Smog
    _GuideItem(
      title: 'Smog & Air Quality',
      subtitle: 'Protect yourself when AQI is unhealthy',
      icon: Icons.air_rounded,
      color: Color(0xFFF57F17),
      duration: '5 min',
      category: 'Air',
    ),
    _GuideItem(
      title: 'Asthma & Poor Air',
      subtitle: 'Managing respiratory conditions in smog season',
      icon: Icons.masks_rounded,
      color: Color(0xFFE65100),
      duration: '4 min',
      category: 'Air',
    ),
    _GuideItem(
      title: 'Indoor Air Quality',
      subtitle: 'Keep your home safe when AQI spikes',
      icon: Icons.home_rounded,
      color: Color(0xFF558B2F),
      duration: '4 min',
      category: 'Air',
    ),
    // Heat
    _GuideItem(
      title: 'Heatwave Preparedness',
      subtitle: 'Stay cool and recognize heatstroke',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFD84315),
      duration: '6 min',
      category: 'Heat',
    ),
    _GuideItem(
      title: 'Hydration & Heat',
      subtitle: 'Staying hydrated during extreme heat events',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF00838F),
      duration: '3 min',
      category: 'Heat',
    ),
    // Health
    _GuideItem(
      title: 'Children & Elderly Safety',
      subtitle: 'Extra precautions for vulnerable groups',
      icon: Icons.family_restroom_rounded,
      color: Color(0xFF7B1FA2),
      duration: '5 min',
      category: 'Health',
    ),
    _GuideItem(
      title: 'Heart Conditions & Hazards',
      subtitle: 'Environmental triggers for cardiac patients',
      icon: Icons.favorite_rounded,
      color: Color(0xFFC62828),
      duration: '5 min',
      category: 'Health',
    ),
    _GuideItem(
      title: 'Mental Health in Disasters',
      subtitle: 'Coping with stress, anxiety and trauma',
      icon: Icons.psychology_rounded,
      color: Color(0xFF4527A0),
      duration: '6 min',
      category: 'Health',
    ),
  ];

  static const List<_TabItem> _tabs = [
    _TabItem('All', Icons.grid_view_rounded),
    _TabItem('Flood', Icons.water_rounded),
    _TabItem('Air', Icons.air_rounded),
    _TabItem('Heat', Icons.wb_sunny_rounded),
    _TabItem('Health', Icons.favorite_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_GuideItem> get _filtered {
    final tab = _tabs[_tabController.index];
    var list = tab.label == 'All'
        ? _guides
        : _guides.where((g) => g.category == tab.label).toList();
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list
          .where((g) =>
              g.title.toLowerCase().contains(q) ||
              g.subtitle.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final featured = _guides.firstWhere((g) => g.featured);
    final guides = _filtered.where((g) => !g.featured).toList();
    final showFeatured =
        _searchQuery.isEmpty && _tabController.index == 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildSearchBar(),
              _buildTabs(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.p16, AppSpacing.p12, AppSpacing.p16, 110),
                  children: [
                    if (showFeatured) ...[
                      _FeaturedCard(
                        guide: featured,
                        onTap: () => _open(featured),
                      ),
                      const SizedBox(height: AppSpacing.p20),
                      _buildSectionHeader('Safety Guides', trailing: TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrepChecklistScreen()),
                        ),
                        icon: const Icon(Icons.checklist_rounded, size: 16),
                        label: const Text('Checklist'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0)),
                      )),
                      const SizedBox(height: AppSpacing.p10),
                    ],
                    if (guides.isEmpty && _searchQuery.isNotEmpty)
                      _buildEmpty()
                    else
                      ...guides.map((g) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.p10),
                            child: _GuideCard(
                                guide: g, onTap: () => _open(g)),
                          )),
                    const SizedBox(height: AppSpacing.p20),
                    _buildDYKSection(),
                    const SizedBox(height: AppSpacing.p20),
                    _EmergencyCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.p16, AppSpacing.p12, AppSpacing.p8, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learn & Prepare',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Safety guides for Pakistan\'s top hazards',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textPrimary),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.p16, AppSpacing.p10, AppSpacing.p16, 0),
      child: TextField(
        controller: _searchCtrl,
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search guides…',
          hintStyle:
              AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.bgCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius12),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius12),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.p10),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.p12),
        tabs: _tabs
            .map((t) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.icon, size: 14),
                      const SizedBox(width: 6),
                      Text(t.label,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleMed.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.p32),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.p12),
          Text(
            'No guides match "$_searchQuery"',
            style:
                AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDYKSection() {
    const facts = [
      _DYKFact(
        icon: Icons.water_rounded,
        color: Color(0xFF1565C0),
        text:
            'Pakistan loses up to 3% of GDP annually to flood damage.',
      ),
      _DYKFact(
        icon: Icons.air_rounded,
        color: Color(0xFFF57F17),
        text:
            'Lahore regularly ranks in the world\'s top 5 most polluted cities during winter smog season.',
      ),
      _DYKFact(
        icon: Icons.wb_sunny_rounded,
        color: Color(0xFFD84315),
        text:
            'Pakistan recorded 51°C in Jacobabad — one of the highest temperatures ever measured on Earth.',
      ),
      _DYKFact(
        icon: Icons.masks_rounded,
        color: Color(0xFFE65100),
        text:
            'An N95 mask filters 95% of airborne particles — including smog and wildfire smoke.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Did You Know?'),
        const SizedBox(height: AppSpacing.p10),
        ...facts.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.p8),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.p14),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(AppSpacing.radius12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: f.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(f.icon, color: f.color, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: Text(
                        f.text,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  void _open(_GuideItem guide) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuideDetailScreen(
          title: guide.title,
          category: guide.detailCategory,
          readTimeLabel: '${guide.duration} read',
          accentColor: guide.color,
          icon: guide.icon,
        ),
      ),
    );
  }
}

// ─── Featured Card ───
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.guide, required this.onTap});

  final _GuideItem guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radius16),
        onTap: onTap,
        child: Ink(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radius16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                guide.color.withOpacity(0.45),
                guide.color.withOpacity(0.15),
              ],
            ),
            border: Border.all(color: guide.color.withOpacity(0.5)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(guide.icon,
                    size: 130, color: guide.color.withOpacity(0.10)),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.p20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: guide.color.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  color: guide.color, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'FEATURED',
                                style: AppTextStyles.label.copyWith(
                                  color: guide.color,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${guide.duration} read',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      guide.title,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guide.subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Guide Card ───
class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide, required this.onTap});

  final _GuideItem guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.p14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: guide.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radius12),
            ),
            child: Icon(guide.icon, color: guide.color, size: 26),
          ),
          const SizedBox(width: AppSpacing.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guide.title,
                  style: AppTextStyles.titleMed.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  guide.subtitle,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: guide.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        guide.category.toUpperCase(),
                        style: AppTextStyles.label.copyWith(
                          color: guide.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.schedule_rounded,
                        size: 11, color: AppColors.textDisabled),
                    const SizedBox(width: 3),
                    Text(
                      '${guide.duration} read',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// ─── Emergency Card ───
class _EmergencyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const contacts = [
      ('Rescue 1122', '1122', Color(0xFFD32F2F)),
      ('Police', '15', Color(0xFF1565C0)),
      ('Ambulance', '115', Color(0xFF2E7D32)),
      ('Fire Brigade', '16', Color(0xFFE65100)),
      ('NDMA Helpline', '1700', Color(0xFF6A1B9A)),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radius16),
        border: Border.all(color: AppColors.danger.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radius12),
                ),
                child: const Icon(Icons.phone_in_talk_rounded,
                    color: AppColors.danger, size: 20),
              ),
              const SizedBox(width: AppSpacing.p12),
              Text(
                'Emergency Contacts',
                style: AppTextStyles.titleMed.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p14),
          ...contacts.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.p8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.$1,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          launchUrl(Uri.parse('tel:${c.$2}')),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.$3.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: c.$3.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call_rounded,
                                size: 12, color: c.$3),
                            const SizedBox(width: 4),
                            Text(
                              c.$2,
                              style: AppTextStyles.label.copyWith(
                                color: c.$3,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Data models ───
class _GuideItem {
  const _GuideItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.duration,
    required this.category,
    this.featured = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String duration;
  final String category;
  final bool featured;

  String get detailCategory {
    if (category == 'Air') return 'Smog/AQI';
    if (category == 'Health') return 'Health';
    return category;
  }
}

class _TabItem {
  const _TabItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _DYKFact {
  const _DYKFact(
      {required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;
}
