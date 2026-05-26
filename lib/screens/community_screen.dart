import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../utils/snackbar_helper.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _tab = 0;
  final _tabs = ['All', 'Flood', 'Smog/AQI', 'Heatwave', 'Road'];

  final _posts = const [
    _PostData(
      name: 'Ali Khan',
      initials: 'AK',
      time: '12m ago',
      location: 'Johar Town, Lahore',
      tag: 'Flood',
      tagColor: AppColors.info,
      text:
          'Main boulevard completely flooded near Emporium Mall. Water waist-deep — avoid if you have a sedan.',
      agrees: 45,
      comments: 12,
      verified: true,
      critical: true,
    ),
    _PostData(
      name: 'Sarah M.',
      initials: 'SM',
      time: '1h ago',
      location: 'Liberty Market',
      tag: 'Smog/AQI',
      tagColor: AppColors.warning,
      text:
          'Visibility is very low near the market. Everyone coughing — please wear N95 masks before going outside.',
      agrees: 28,
      comments: 7,
      verified: false,
      critical: false,
    ),
    _PostData(
      name: 'EcoAlert',
      initials: 'EA',
      time: '2h ago',
      location: 'Canal Road',
      tag: 'Road',
      tagColor: AppColors.primary,
      text:
          'Traffic crawling near Canal Road underpass due to construction. Expect 15–20 min delay. Use Ferozepur Road.',
      agrees: 89,
      comments: 0,
      verified: true,
      critical: false,
      official: true,
    ),
    _PostData(
      name: 'Hamid R.',
      initials: 'HR',
      time: '3h ago',
      location: 'DHA Phase 5',
      tag: 'Heatwave',
      tagColor: AppColors.danger,
      text:
          'Dangerously hot — 44°C feels-like in direct sun. Keep children and elderly inside between 12–4pm.',
      agrees: 61,
      comments: 4,
      verified: true,
      critical: false,
    ),
  ];

  List<_PostData> get _visible => _tab == 0
      ? _posts
      : _posts.where((p) => p.tag == _tabs[_tab]).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community Watch',
                          style: AppTextStyles.headline.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hazard reports from your area',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => showComingSoon(context, 'Search'),
                    icon: const Icon(Icons.search_rounded,
                        color: AppColors.textSecondary),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/alerts'),
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Filter tabs ───────────────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _tabs.length,
              itemBuilder: (_, i) {
                final sel = i == _tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            sel ? AppColors.bgElevated : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel
                              ? AppColors.border
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        _tabs[i],
                        style: TextStyle(
                          color: sel
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.borderSubtle),

          // ── Feed ──────────────────────────────────────────────────────
          Expanded(
            child: _visible.isEmpty
                ? Center(
                    child: Text(
                      'No ${_tabs[_tab]} reports yet.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _visible.length,
                    itemBuilder: (_, i) =>
                        _PostCard(post: _visible[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

class _PostData {
  final String name;
  final String initials;
  final String time;
  final String location;
  final String tag;
  final Color tagColor;
  final String text;
  final int agrees;
  final int comments;
  final bool verified;
  final bool critical;
  final bool official;

  const _PostData({
    required this.name,
    required this.initials,
    required this.time,
    required this.location,
    required this.tag,
    required this.tagColor,
    required this.text,
    required this.agrees,
    required this.comments,
    required this.verified,
    required this.critical,
    this.official = false,
  });
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post});
  final _PostData post;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late int _agrees;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _agrees = widget.post.agrees;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: p.critical
              ? p.tagColor.withOpacity(0.35)
              : AppColors.borderSubtle,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: avatar + name + badge ─────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.tagColor.withOpacity(0.12),
                    border: Border.all(
                        color: p.tagColor.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      p.initials,
                      style: TextStyle(
                        color: p.tagColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (p.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded,
                                size: 12, color: AppColors.info),
                          ],
                          if (p.official) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.success.withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppColors.success
                                        .withOpacity(0.3)),
                              ),
                              child: const Text(
                                'OFFICIAL',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 10,
                              color: AppColors.textDisabled),
                          const SizedBox(width: 3),
                          Text(p.time,
                              style: const TextStyle(
                                  color: AppColors.textDisabled,
                                  fontSize: 10)),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on_rounded,
                              size: 10,
                              color: AppColors.textDisabled),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              p.location,
                              style: const TextStyle(
                                  color: AppColors.textDisabled,
                                  fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tag badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.tagColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: p.tagColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    p.tag,
                    style: TextStyle(
                      color: p.tagColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Content ───────────────────────────────────────────────
            Text(
              p.text,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 10),

            // ── Actions ───────────────────────────────────────────────
            Row(
              children: [
                // Agree
                GestureDetector(
                  onTap: () => setState(() {
                    _agreed = !_agreed;
                    _agrees += _agreed ? 1 : -1;
                  }),
                  child: Row(
                    children: [
                      Icon(
                        _agreed
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_alt_outlined,
                        size: 15,
                        color: _agreed
                            ? p.tagColor
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$_agrees Agree',
                        style: TextStyle(
                          color: _agreed
                              ? p.tagColor
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // Comments
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      '${p.comments}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                const Icon(Icons.share_outlined,
                    size: 15, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
