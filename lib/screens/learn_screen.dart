// Hassaan/Bilal: ensure these tables exist in Supabase:
//
// CREATE TABLE IF NOT EXISTS guides (
//   id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
//   title text,
//   subtitle text,
//   category text,          -- e.g. 'Flood', 'Air', 'Heat', 'Health'
//   icon_name text,         -- e.g. 'flood', 'air', 'heat', 'health'
//   duration_minutes int,
//   content jsonb,          -- [{"heading":"...", "steps":["..."]}]
//   is_featured bool DEFAULT false,
//   created_at timestamptz DEFAULT now()
// );
//
// CREATE TABLE IF NOT EXISTS facts (
//   id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
//   text text,
//   source text,
//   category text           -- e.g. 'flood', 'air', 'heat', 'health'
// );
//
// CREATE TABLE IF NOT EXISTS user_saved_guides (
//   user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
//   guide_title text NOT NULL,
//   created_at timestamptz DEFAULT now(),
//   PRIMARY KEY (user_id, guide_title)
// );
//
// Recommended RLS:
//   ALTER TABLE guides ENABLE ROW LEVEL SECURITY;
//   CREATE POLICY "read_all" ON guides FOR SELECT USING (true);
//   ALTER TABLE facts  ENABLE ROW LEVEL SECURITY;
//   CREATE POLICY "read_all" ON facts  FOR SELECT USING (true);
//   ALTER TABLE user_saved_guides ENABLE ROW LEVEL SECURITY;
//   CREATE POLICY "own_saves" ON user_saved_guides USING (auth.uid() = user_id);

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../models/guide_model.dart';
import '../widgets/app_background.dart';
import 'guide_detail_screen.dart';
import 'prep_checklist_screen.dart';

// ── Category helpers ──────────────────────────────────────────────────────────

const _kCategoryColors = {
  'All':    AppColors.primary,
  'Flood':  Color(0xFF1565C0),
  'Air':    Color(0xFFF57F17),
  'Heat':   Color(0xFFD84315),
  'Health': Color(0xFF7B1FA2),
};

Color _colorForCategory(String cat) =>
    _kCategoryColors[cat] ?? AppColors.primary;

/// Normalises raw Supabase category strings to title-case values used
/// by the local colour map (e.g. 'flood' → 'Flood', 'aqi' → 'Air').
String _normalizeCat(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'flood':                  return 'Flood';
    case 'air': case 'smog':
    case 'aqi': case 'smog/aqi':   return 'Air';
    case 'heat': case 'heatwave':  return 'Heat';
    case 'health':                 return 'Health';
    default:
      return raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}';
  }
}

// ── Icon helper ───────────────────────────────────────────────────────────────

/// Maps an icon_name string from the Supabase `guides` table to a Flutter
/// IconData.  Extend this list to support new icon names.
IconData iconFromName(String name) {
  switch (name.trim().toLowerCase()) {
    case 'flood':
    case 'water':             return Icons.water_rounded;
    case 'thunderstorm':      return Icons.thunderstorm_rounded;
    case 'umbrella':          return Icons.umbrella_rounded;
    case 'air':
    case 'smog':
    case 'aqi':               return Icons.air_rounded;
    case 'masks':
    case 'mask':              return Icons.masks_rounded;
    case 'home':              return Icons.home_rounded;
    case 'heat':
    case 'heatwave':
    case 'thermostat':        return Icons.thermostat_rounded;
    case 'sunny':
    case 'wb_sunny':          return Icons.wb_sunny_rounded;
    case 'water_drop':        return Icons.water_drop_rounded;
    case 'health':
    case 'health_and_safety': return Icons.health_and_safety_rounded;
    case 'family':            return Icons.family_restroom_rounded;
    case 'favorite':
    case 'heart':             return Icons.favorite_rounded;
    case 'psychology':        return Icons.psychology_rounded;
    case 'child':
    case 'child_care':        return Icons.child_care_rounded;
    case 'flood_rounded':     return Icons.flood_rounded;
    default:                  return Icons.article_outlined;
  }
}

// ── Fallback hardcoded data ───────────────────────────────────────────────────

const List<_GuideItem> _kFallbackGuides = [
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

const List<_DYKFact> _kFallbackFacts = [
  _DYKFact(
    icon: Icons.water_rounded,
    color: Color(0xFF1565C0),
    text: 'Pakistan loses up to 3% of GDP annually to flood damage.',
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
        'Pakistan recorded 51 °C in Jacobabad — one of the highest temperatures ever measured on Earth.',
  ),
  _DYKFact(
    icon: Icons.masks_rounded,
    color: Color(0xFFE65100),
    text:
        'An N95 mask filters 95 % of airborne particles — including smog and wildfire smoke.',
  ),
  _DYKFact(
    icon: Icons.water_damage_rounded,
    color: Color(0xFF0288D1),
    text:
        'The 2022 Pakistan floods submerged one-third of the entire country, displacing 33 million people.',
  ),
  _DYKFact(
    icon: Icons.child_care_rounded,
    color: Color(0xFF7B1FA2),
    text:
        'Children under 5 are 3× more vulnerable to air pollution health effects than adults.',
  ),
  _DYKFact(
    icon: Icons.local_drink_rounded,
    color: Color(0xFF00838F),
    text:
        'Drinking 2–3 litres of water daily can cut heatstroke risk by over 60 % during extreme heat events.',
  ),
  _DYKFact(
    icon: Icons.flood_rounded,
    color: Color(0xFF1565C0),
    text:
        'Flash floods can develop in as little as 6 hours after heavy rainfall begins in urban areas.',
  ),
  _DYKFact(
    icon: Icons.psychology_rounded,
    color: Color(0xFF4527A0),
    text:
        'Up to 30 % of disaster survivors experience PTSD — mental health care is part of emergency response.',
  ),
  _DYKFact(
    icon: Icons.favorite_rounded,
    color: Color(0xFFC62828),
    text:
        'Poor air quality increases heart attack risk by up to 48 % on days when AQI exceeds 150.',
  ),
];

// ── Row → model helpers ───────────────────────────────────────────────────────

/// Converts a Supabase `guides` row into a [_GuideItem].
_GuideItem _guideItemFromRow(Map<String, dynamic> row) {
  final rawCat    = row['category'] as String? ?? '';
  final category  = _normalizeCat(rawCat);
  final iconName  = row['icon_name'] as String? ?? rawCat;
  final icon      = iconFromName(iconName);
  final color     = _colorForCategory(category);
  final minutes   = (row['duration_minutes'] as int?) ?? 5;

  return _GuideItem(
    title:        row['title']    as String? ?? 'Untitled',
    subtitle:     row['subtitle'] as String? ?? '',
    icon:         icon,
    color:        color,
    duration:     '$minutes min',
    category:     category,
    featured:     (row['is_featured'] as bool?) ?? false,
    guideContent: _parseGuideContent(row['content'], row['title'] as String? ?? ''),
  );
}

/// Converts a Supabase `facts` row into a [_DYKFact].
_DYKFact _dykFactFromRow(Map<String, dynamic> row) {
  final cat   = row['category'] as String? ?? 'general';
  final color = _colorForCategory(_normalizeCat(cat));
  final icon  = iconFromName(cat);
  return _DYKFact(
    icon:  icon,
    color: color,
    text:  row['text'] as String? ?? '',
  );
}

/// Parses a Supabase `content` jsonb value (expected to be a list of section
/// objects or a map with a 'sections' key) into a [GuideContent].
/// Returns null if content is null or unparseable.
GuideContent? _parseGuideContent(dynamic contentJson, String title) {
  if (contentJson == null) return null;
  try {
    final List<dynamic> rawSections;
    if (contentJson is List) {
      rawSections = contentJson;
    } else if (contentJson is Map) {
      rawSections =
          (contentJson['sections'] as List?) ?? (contentJson['steps'] as List?) ?? [];
    } else {
      return null;
    }
    final sections = rawSections.map((s) {
      final map    = Map<String, dynamic>.from(s as Map);
      final heading = map['heading'] as String?
          ?? map['title'] as String?
          ?? '';
      final steps  = ((map['steps'] as List?) ?? [])
          .map((e) => e.toString())
          .toList();
      return GuideSection(heading: heading, steps: steps);
    }).toList();

    return GuideContent(title: title, sections: sections);
  } catch (e) {
    debugPrint('[LearnScreen] content parse error: $e');
    return null;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  Map<String, bool> _savedGuides = {};
  Map<String, bool> _readGuides  = {};

  // ── Remote data (null = not yet fetched / fallback in use) ──────────────────
  List<_GuideItem>? _remoteGuides;
  List<_DYKFact>?   _remoteFacts;
  bool              _isLoadingRemote = true;

  // ── Active data (remote if available, hardcoded otherwise) ─────────────────
  List<_GuideItem> get _activeGuides => _remoteGuides ?? _kFallbackGuides;
  List<_DYKFact>   get _activeFacts  => _remoteFacts  ?? _kFallbackFacts;

  // ── Dynamic category chip list ──────────────────────────────────────────────
  List<String> get _categories {
    final cats = <String>['All'];
    for (final g in _activeGuides) {
      if (!cats.contains(g.category)) cats.add(g.category);
    }
    return cats;
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSavedGuides();
    _loadReadGuides();
    _fetchRemote();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Supabase fetch ────────────────────────────────────────────────────────────

  Future<void> _fetchRemote() async {
    if (!mounted) return;
    setState(() => _isLoadingRemote = true);
    try {
      final db = Supabase.instance.client;

      final guidesData = await db
          .from('guides')
          .select()
          .order('created_at', ascending: false);

      final factsData = await db.from('facts').select();

      final remoteGuides = (guidesData as List)
          .map((r) => _guideItemFromRow(Map<String, dynamic>.from(r as Map)))
          .toList();

      final remoteFacts = (factsData as List)
          .map((r) => _dykFactFromRow(Map<String, dynamic>.from(r as Map)))
          .toList();

      if (mounted) {
        setState(() {
          _remoteGuides      = remoteGuides.isNotEmpty ? remoteGuides : null;
          _remoteFacts       = remoteFacts.isNotEmpty  ? remoteFacts  : null;
          _isLoadingRemote   = false;
          // Reset category if it no longer exists in the new guide list.
          if (_selectedCategory != 'All' &&
              !_categories.contains(_selectedCategory)) {
            _selectedCategory = 'All';
          }
        });
      }

      // Reload save/read state so new guide titles are covered.
      await _loadSavedGuides();
      await _loadReadGuides();
    } catch (e) {
      debugPrint('[LearnScreen] Supabase fetch error: $e');
      // FALLBACK: using hardcoded data, Supabase fetch failed
      if (mounted) setState(() => _isLoadingRemote = false);
    }
  }

  // ── SharedPreferences ─────────────────────────────────────────────────────────

  Future<void> _loadSavedGuides() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;

    if (uid != null) {
      try {
        final rows = await Supabase.instance.client
            .from('user_saved_guides')
            .select('guide_title')
            .eq('user_id', uid);

        final saved = {
          for (final r in (rows as List))
            (r as Map)['guide_title'] as String: true,
        };

        if (mounted) {
          setState(() {
            _savedGuides = {
              for (final g in _activeGuides)
                g.title: saved[g.title] ?? false,
            };
          });
        }
        return;
      } catch (e) {
        debugPrint('[LearnScreen] Supabase saved guides load error: $e');
      }
    }

    // Guest / network error — fall back to SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    final map   = <String, bool>{};
    for (final g in _activeGuides) {
      map[g.title] = prefs.getBool('saved_guide_${g.title}') ?? false;
    }
    if (mounted) setState(() => _savedGuides = map);
  }

  Future<void> _loadReadGuides() async {
    final prefs = await SharedPreferences.getInstance();
    final map   = <String, bool>{};
    for (final g in _activeGuides) {
      map[g.title] = prefs.getBool('read_guide_${g.title}') ?? false;
    }
    if (mounted) setState(() => _readGuides = map);
  }

  Future<void> _toggleSaved(_GuideItem guide) async {
    final next = !(_savedGuides[guide.title] ?? false);
    setState(() => _savedGuides[guide.title] = next);

    // Always persist to SharedPreferences as local cache.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('saved_guide_${guide.title}', next);

    // Sync to Supabase when logged in.
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        if (next) {
          await Supabase.instance.client.from('user_saved_guides').upsert({
            'user_id':     uid,
            'guide_title': guide.title,
          });
        } else {
          await Supabase.instance.client
              .from('user_saved_guides')
              .delete()
              .eq('user_id', uid)
              .eq('guide_title', guide.title);
        }
      } catch (e) {
        debugPrint('[LearnScreen] Supabase toggle saved error: $e');
      }
    }
  }

  // ── Filtering ─────────────────────────────────────────────────────────────────

  List<_GuideItem> get _filtered {
    var list = _selectedCategory == 'All'
        ? _activeGuides
        : _activeGuides
            .where((g) => g.category == _selectedCategory)
            .toList();
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

  // ── Navigation ────────────────────────────────────────────────────────────────

  void _open(_GuideItem guide) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuideDetailScreen(
          title:         guide.title,
          category:      guide.detailCategory,
          readTimeLabel: '${guide.duration} read',
          accentColor:   guide.color,
          icon:          guide.icon,
          guideContent:  guide.guideContent, // parsed from Supabase content jsonb
        ),
      ),
    ).then((_) => _loadReadGuides());
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final featured    = _activeGuides.firstWhere(
      (g) => g.featured,
      orElse: () => _activeGuides.first,
    );
    final showFeatured =
        _searchQuery.isEmpty && _selectedCategory == 'All';
    final guides =
        _filtered.where((g) => !g.featured || !showFeatured).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildSearchBar(),

              // Thin loading bar while remote fetch is in-flight
              if (_isLoadingRemote)
                LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primary.withOpacity(0.5),
                  backgroundColor: Colors.transparent,
                ),

              const SizedBox(height: AppSpacing.p10),
              _buildCategoryFilter(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.p16, AppSpacing.p12, AppSpacing.p16, 110),
                  children: [
                    // ── Hero card ──────────────────────────────────────────
                    if (showFeatured) ...[
                      _HeroCard(
                        guide: featured,
                        onTap: () => _open(featured),
                      ),
                      const SizedBox(height: AppSpacing.p20),
                      _buildSectionHeader(
                        'Safety Guides',
                        trailing: TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const PrepChecklistScreen()),
                          ),
                          icon: const Icon(Icons.checklist_rounded,
                              size: 16),
                          label: const Text('Checklist'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p10),
                    ],

                    // ── Guide grid ─────────────────────────────────────────
                    if (guides.isEmpty && _searchQuery.isNotEmpty)
                      _buildEmpty()
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:  2,
                          mainAxisSpacing: AppSpacing.p10,
                          crossAxisSpacing: AppSpacing.p10,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: guides.length,
                        itemBuilder: (_, i) => _GuideGridCard(
                          guide:          guides[i],
                          saved:          _savedGuides[guides[i].title] ?? false,
                          read:           _readGuides[guides[i].title]  ?? false,
                          onTap:          () => _open(guides[i]),
                          onToggleSaved:  () => _toggleSaved(guides[i]),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.p24),

                    // ── Did You Know? ──────────────────────────────────────
                    _buildSectionHeader('Did You Know?'),
                    const SizedBox(height: AppSpacing.p10),
                    _DYKSection(facts: _activeFacts),

                    const SizedBox(height: AppSpacing.p24),

                    // ── Emergency contacts ─────────────────────────────────
                    _buildEmergencySection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-builders ──────────────────────────────────────────────────────────────

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
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textSecondary),
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
          filled:       true,
          fillColor:    AppColors.bgCard,
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

  /// Category chips — derived dynamically from [_categories] so they always
  /// reflect what's in the active guide list (remote or hardcoded fallback).
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.p8),
        itemBuilder: (_, i) {
          final cat      = _categories[i];
          final selected = _selectedCategory == cat;
          final accent   = _colorForCategory(cat);
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withOpacity(0.15)
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: selected
                      ? accent.withOpacity(0.5)
                      : AppColors.borderSubtle,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat,
                    style: AppTextStyles.label.copyWith(
                      color: selected ? accent : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 3, height: 16,
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
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySection() {
    const contacts = [
      ('Rescue 1122', '1122'),
      ('Police',       '15'),
      ('Ambulance',    '115'),
      ('Fire Brigade', '16'),
      ('NDMA Helpline','1700'),
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
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radius12),
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
          Wrap(
            spacing: AppSpacing.p8,
            runSpacing: AppSpacing.p8,
            children: contacts
                .map((c) => GestureDetector(
                      onTap: () => launchUrl(Uri.parse('tel:${c.$2}')),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color:  AppColors.danger.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                              color: AppColors.danger.withOpacity(0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.call_rounded,
                                size: 13, color: AppColors.danger),
                            const SizedBox(width: 6),
                            Text(c.$1,
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                )),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 6),
                              width: 1, height: 12,
                              color: AppColors.danger.withOpacity(0.3),
                            ),
                            Text(c.$2,
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                )),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.guide, required this.onTap});

  final _GuideItem guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radius16),
      child: SizedBox(
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: guide.color.withOpacity(0.25)),
            Positioned(
              right: -20, bottom: -20,
              child: Icon(guide.icon,
                  size: 160, color: guide.color.withOpacity(0.12)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.75),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
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
                          color: guide.color.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                color: guide.color, size: 11),
                            const SizedBox(width: 4),
                            Text('FEATURED',
                                style: AppTextStyles.label.copyWith(
                                  color: guide.color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                )),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${guide.duration} read',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 10,
                            )),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(guide.title,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 3),
                  Text(guide.subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.p12),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: guide.color,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Start Reading',
                              style: AppTextStyles.label.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              )),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Guide grid card ───────────────────────────────────────────────────────────

class _GuideGridCard extends StatelessWidget {
  const _GuideGridCard({
    required this.guide,
    required this.saved,
    required this.read,
    required this.onTap,
    required this.onToggleSaved,
  });

  final _GuideItem guide;
  final bool saved;
  final bool read;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radius12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSpacing.radius12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 3, color: guide.color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.p12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: guide.color.withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(guide.icon,
                                    color: guide.color, size: 22),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: onToggleSaved,
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    saved
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 18,
                                    color: saved
                                        ? AppColors.danger
                                        : AppColors.textDisabled,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.p10),
                          Text(
                            guide.title,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 11, color: AppColors.textDisabled),
                              const SizedBox(width: 4),
                              Text('${guide.duration} read',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.textDisabled,
                                    fontSize: 10,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (read)
          Positioned(
            top: -7, right: -7,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgCard, width: 2),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 12, color: Colors.black),
            ),
          ),
      ],
    );
  }
}

// ── Did You Know — auto-scrolling PageView ────────────────────────────────────

class _DYKSection extends StatefulWidget {
  const _DYKSection({required this.facts});

  /// Fact list — either fetched from Supabase or the hardcoded fallback.
  final List<_DYKFact> facts;

  @override
  State<_DYKSection> createState() => _DYKSectionState();
}

class _DYKSectionState extends State<_DYKSection> {
  late final PageController _ctrl;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl  = PageController(viewportFraction: 1.0);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || widget.facts.isEmpty) return;
      final next = (_page + 1) % widget.facts.length;
      _ctrl.animateToPage(next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facts = widget.facts;
    if (facts.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: facts.length,
            itemBuilder: (_, i) => _DYKCard(fact: facts[i]),
          ),
        ),
        const SizedBox(height: AppSpacing.p10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(facts.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.textDisabled,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DYKCard extends StatelessWidget {
  const _DYKCard({required this.fact});
  final _DYKFact fact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(AppSpacing.p14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radius12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: fact.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(fact.icon, color: fact.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.p12),
          Expanded(
            child: Text(
              fact.text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _GuideItem {
  const _GuideItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.duration,
    required this.category,
    this.featured = false,
    this.guideContent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String duration;
  final String category;
  final bool featured;

  /// Populated when the guide is loaded from Supabase (content jsonb parsed).
  /// Null for hardcoded fallback guides — GuideDetailScreen falls back to its
  /// own built-in _contentFor() logic in that case.
  final GuideContent? guideContent;

  String get detailCategory {
    if (category == 'Air') return 'Smog/AQI';
    if (category == 'Health') return 'Health';
    return category;
  }
}

class _DYKFact {
  const _DYKFact(
      {required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;
}
