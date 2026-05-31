import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_text_styles.dart';
import '../models/guide_model.dart';
import '../widgets/app_background.dart';
import '../widgets/surface_card.dart';

class GuideDetailScreen extends StatefulWidget {
  const GuideDetailScreen({
    super.key,
    required this.title,
    required this.category,
    required this.readTimeLabel,
    this.accentColor = AppColors.primary,
    this.icon = Icons.menu_book_rounded,
    this.guideContent,
  });

  final String title;
  final String category;
  final String readTimeLabel;
  final Color accentColor;
  final IconData icon;

  /// Optional structured content. When provided the screen renders from it;
  /// otherwise falls back to the built-in _contentFor() logic.
  final GuideContent? guideContent;

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  bool _markedAsRead = false;

  @override
  void initState() {
    super.initState();
    _loadReadState();
  }

  Future<void> _loadReadState() async {
    final prefs = await SharedPreferences.getInstance();
    final read = prefs.getBool('read_guide_${widget.title}') ?? false;
    if (mounted) setState(() => _markedAsRead = read);
  }

  Future<void> _markAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('read_guide_${widget.title}', true);
    if (mounted) setState(() => _markedAsRead = true);
  }

  /// Resolve whichever content source is active into the internal model.
  _GuideContent _resolveContent() {
    if (widget.guideContent != null) {
      return _GuideContent(
        summary: null,
        sections: widget.guideContent!.sections
            .map((s) => _GuideSection(title: s.heading, steps: s.steps))
            .toList(),
      );
    }
    return _contentFor(title: widget.title, category: widget.category);
  }

  @override
  Widget build(BuildContext context) {
    final content = _resolveContent();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── App bar ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTextStyles.titleMed.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ───────────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.p16,
                    AppSpacing.p8,
                    AppSpacing.p16,
                    AppSpacing.p24,
                  ),
                  children: [
                    // Meta card (category + read time)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.p16),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radius16),
                        gradient: LinearGradient(
                          colors: [
                            widget.accentColor.withOpacity(0.2),
                            AppColors.bgCard,
                          ],
                        ),
                        border: Border.all(
                          color: widget.accentColor.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radius12),
                            ),
                            child: Icon(widget.icon,
                                color: widget.accentColor, size: 28),
                          ),
                          const SizedBox(width: AppSpacing.p12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.category,
                                  style: AppTextStyles.label.copyWith(
                                    color: widget.accentColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 14,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.readTimeLabel,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.p16),

                    // Summary (only shown when using the fallback content)
                    if (content.summary != null && content.summary!.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.p12),
                        child: SurfaceCard(
                          child: Text(
                            content.summary!,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.9),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),

                    // Guide sections
                    ...content.sections.map(
                      (s) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.p12),
                        child: _SectionCard(
                          title: s.title,
                          accentColor: widget.accentColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < s.steps.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.p10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: widget.accentColor
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: widget.accentColor
                                                .withOpacity(0.35),
                                          ),
                                        ),
                                        child: Text(
                                          '${i + 1}',
                                          style: AppTextStyles.label.copyWith(
                                            color: widget.accentColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.p10),
                                      Expanded(
                                        child: Text(
                                          s.steps[i],
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                            color: AppColors.textPrimary
                                                .withOpacity(0.88),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.p8),

                    // ── Mark as Read button ───────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: TextButton(
                        onPressed: _markedAsRead ? null : _markAsRead,
                        style: TextButton.styleFrom(
                          backgroundColor: _markedAsRead
                              ? AppColors.success.withOpacity(0.08)
                              : AppColors.success.withOpacity(0.12),
                          disabledBackgroundColor:
                              AppColors.success.withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radius12),
                            side: BorderSide(
                              color: AppColors.success
                                  .withOpacity(_markedAsRead ? 0.2 : 0.35),
                            ),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _markedAsRead
                                  ? Icons.check_circle_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 18,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: AppSpacing.p8),
                            Text(
                              _markedAsRead
                                  ? 'Marked as Read'
                                  : 'Mark as Read',
                              style: AppTextStyles.titleMed.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.accentColor,
  });

  final String title;
  final Widget child;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.p8),
              Text(
                title,
                style: AppTextStyles.titleMed.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p12),
          child,
        ],
      ),
    );
  }
}

// ── Internal content model ────────────────────────────────────────────────────

class _GuideContent {
  const _GuideContent({this.summary, required this.sections});

  final String? summary;
  final List<_GuideSection> sections;
}

class _GuideSection {
  const _GuideSection({required this.title, required this.steps});

  final String title;
  final List<String> steps;
}

// ── Hardcoded fallback content ────────────────────────────────────────────────

_GuideContent _contentFor({
  required String title,
  required String category,
}) {
  if (category == 'Flood') {
    return const _GuideContent(
      summary:
          'Flood risk can change quickly after heavy rain or a cloudburst. Use this step-by-step guide to prepare early, stay safe during flooding, and recover after water recedes.',
      sections: [
        _GuideSection(
          title: 'Before (Preparation)',
          steps: [
            'Save emergency numbers and share a meetup point with family.',
            'Prepare a go-bag: water, snacks, torch, power bank, meds, copies of IDs.',
            'Move valuables and electrical items above floor level.',
            'Know 2 safe routes to higher ground; avoid underpasses and canals.',
          ],
        ),
        _GuideSection(
          title: 'During (Response)',
          steps: [
            'Do not walk or drive through flood water. Turn around if the road is flooded.',
            'If water enters your home, switch off electricity only if safe to reach the main switch.',
            'Move to higher floors/roof access if needed and call for help early.',
            'Keep children away from drains; fast water can pull them in.',
          ],
        ),
        _GuideSection(
          title: 'After (Recovery)',
          steps: [
            'Avoid contaminated water; wear gloves/boots while cleaning.',
            'Do not turn power back on until wiring is dry and checked.',
            'Discard food that touched flood water; boil drinking water if unsure.',
            'Document damage with photos for records and repairs.',
          ],
        ),
      ],
    );
  }

  if (category == 'Smog/AQI') {
    return const _GuideContent(
      summary:
          'Poor air quality increases breathing and heart risks. Use these steps to reduce exposure and protect vulnerable family members.',
      sections: [
        _GuideSection(
          title: 'Reduce Exposure',
          steps: [
            'Check AQI before going out; avoid outdoor exercise when AQI is high.',
            'Wear a well-fitted N95/KN95 mask when outside.',
            'Keep windows closed during peak smog; ventilate when AQI improves.',
          ],
        ),
        _GuideSection(
          title: 'Home Protection',
          steps: [
            'Use a fan with a clean filter or air purifier if available.',
            'Wet-mop floors and wipe surfaces to reduce indoor dust.',
            'Keep children and elderly indoors when visibility is low.',
          ],
        ),
      ],
    );
  }

  if (category == 'Heatwave') {
    return const _GuideContent(
      summary:
          'Heatwaves can cause dehydration and heatstroke quickly. Follow these steps to stay cool and recognize danger signs early.',
      sections: [
        _GuideSection(
          title: 'Stay Cool',
          steps: [
            'Drink water regularly even if you are not thirsty.',
            'Avoid outdoor work during noon; take breaks in shade.',
            'Wear light clothing; use a damp cloth to cool the skin.',
          ],
        ),
        _GuideSection(
          title: 'Watch for Heatstroke',
          steps: [
            'Danger signs: confusion, fainting, very hot skin, rapid pulse.',
            'Move the person to shade, cool them with water/fan, and seek medical help.',
          ],
        ),
      ],
    );
  }

  return const _GuideContent(
    summary:
        'Sudden heavy rainfall can flood streets in minutes. Use this quick guide to avoid high-risk routes and stay safe.',
    sections: [
      _GuideSection(
        title: 'Immediate Actions',
        steps: [
          'Avoid underpasses, bridges, and roads near drains/canals.',
          'Delay travel if possible; if you must travel, take main roads and move slowly.',
          'Keep your phone charged and share your location with family.',
        ],
      ),
      _GuideSection(
        title: 'If You\'re Stuck',
        steps: [
          'Stay in a safe high place; call emergency services early.',
          'Do not enter moving water; it can sweep you away.',
        ],
      ),
    ],
  );
}
