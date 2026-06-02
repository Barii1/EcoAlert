import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../utils/snackbar_helper.dart';

// ── Category helpers ──────────────────────────────────────────────────────────

const _kTabLabels = ['All', 'Flood', 'Smog/AQI', 'Heatwave', 'Road'];
const _kTabKeys   = ['all', 'flood', 'aqi',      'heatwave', 'roads'];

Color _categoryColor(String cat) {
  switch (cat) {
    case 'flood':    return AppColors.info;
    case 'aqi':      return AppColors.warning;
    case 'heatwave': return AppColors.danger;
    case 'roads':    return AppColors.primary;
    default:         return AppColors.textSecondary;
  }
}

String _categoryLabel(String cat) {
  switch (cat) {
    case 'flood':    return 'Flood';
    case 'aqi':      return 'Smog/AQI';
    case 'heatwave': return 'Heatwave';
    case 'roads':    return 'Road';
    default:         return 'General';
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1)  return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24)   return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CommunityProvider>();
      provider.setCategory('all');
      provider.loadPosts();
      provider.startRealtime();
    });
  }

  void _onTabTap(int i) {
    setState(() => _tab = i);
    context.read<CommunityProvider>().setCategory(_kTabKeys[i]);
  }

  void _openNewPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewPostSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityProvider>();
    final auth      = context.watch<AuthProvider>();
    final currentUid = auth.currentUser?.id;
    final isAdmin    = auth.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
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
                  // ── Compose button ──────────────────────────────────
                  IconButton(
                    onPressed: auth.isAuthenticated
                        ? _openNewPostSheet
                        : () => showComingSoon(context, 'Posting'),
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.textSecondary),
                    tooltip: 'New post',
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
              itemCount: _kTabLabels.length,
              itemBuilder: (_, i) {
                final sel = i == _tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _onTabTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.bgElevated
                            : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel
                              ? AppColors.border
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        _kTabLabels[i],
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
            child: _buildFeed(community, currentUid, isAdmin),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(
    CommunityProvider community,
    String? currentUid,
    bool isAdmin,
  ) {
    // Loading (initial fetch only)
    if (community.isLoading && community.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Error state
    if (community.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 56, color: AppColors.textDisabled),
              const SizedBox(height: 16),
              Text('Could not load data',
                  style: AppTextStyles.titleMed
                      .copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: community.loadPosts,
                child: const Text('Try Again',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (community.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 56, color: AppColors.textDisabled),
              const SizedBox(height: 16),
              Text(
                'Be the first to post in your community',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // List with pull-to-refresh
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.bgCard,
      onRefresh: community.loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: community.posts.length,
        itemBuilder: (ctx, i) {
          final post = community.posts[i];
          return _PostCard(
            key: ValueKey(post.id),
            post: post,
            currentUid: currentUid,
            isAdmin: isAdmin,
          );
        },
      ),
    );
  }
}

// ── New Post Bottom Sheet ─────────────────────────────────────────────────────

class _NewPostSheet extends StatefulWidget {
  const _NewPostSheet();

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _contentCtrl = TextEditingController();
  final _picker = ImagePicker();
  String _category = 'flood';
  File? _image;
  bool _submitting = false;

  static const _categories = [
    ('flood',    'Flood',     AppColors.info),
    ('aqi',      'Smog/AQI',  AppColors.warning),
    ('heatwave', 'Heatwave',  AppColors.danger),
    ('roads',    'Road',      AppColors.primary),
    ('general',  'General',   AppColors.textSecondary),
  ];

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xfile != null && mounted) {
      setState(() => _image = File(xfile.path));
    }
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;

    setState(() => _submitting = true);
    FocusScope.of(context).unfocus();

    final auth      = context.read<AuthProvider>();
    final community = context.read<CommunityProvider>();
    final city      = auth.currentUser?.city ?? '';

    final ok = await community.addPost(
      content: content,
      category: _category,
      city: city,
      image: _image,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not post — please try again.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('New Report',
              style: AppTextStyles.titleLarge
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 14),

          // Content field
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            autofocus: true,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Describe the hazard or situation…',
              hintStyle: AppTextStyles.body
                  .copyWith(color: AppColors.textDisabled),
              filled: true,
              fillColor: AppColors.bgElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Category chips
          Text('Category',
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _categories.map((cat) {
              final (key, label, color) = cat;
              final sel = _category == key;
              return GestureDetector(
                onTap: () => setState(() => _category = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        sel ? color.withOpacity(0.15) : AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: sel
                          ? color.withOpacity(0.5)
                          : AppColors.borderSubtle,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      color: sel ? color : AppColors.textSecondary,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Image picker row
          Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _image == null ? 'Add Photo' : 'Change Photo',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              if (_image != null) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_image!,
                      width: 48, height: 48, fit: BoxFit.cover),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _image = null),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textDisabled),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: _submitting ? null : _submit,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textInverse,
                      ),
                    )
                  : Text(
                      'Post Report',
                      style: AppTextStyles.titleMed.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Post Card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  const _PostCard({
    super.key,
    required this.post,
    required this.currentUid,
    required this.isAdmin,
  });

  final CommunityPost post;
  final String? currentUid;
  final bool isAdmin;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late bool _liked;
  late int _likes;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.isLikedByMe;
    _likes = widget.post.likes;
  }

  @override
  void didUpdateWidget(_PostCard old) {
    super.didUpdateWidget(old);
    if (widget.post.id != old.post.id ||
        widget.post.likes != old.post.likes ||
        widget.post.isLikedByMe != old.post.isLikedByMe) {
      _liked = widget.post.isLikedByMe;
      _likes = widget.post.likes;
    }
  }

  bool get _canDelete =>
      widget.isAdmin ||
      (widget.currentUid != null &&
          widget.currentUid == widget.post.userId);

  Future<void> _onLikeTap() async {
    HapticFeedback.lightImpact();
    // Optimistic update
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
    await context.read<CommunityProvider>().toggleLike(widget.post.id);
  }

  Future<void> _onDeleteTap() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete post?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This post will be permanently removed.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<CommunityProvider>().deletePost(widget.post.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p       = widget.post;
    final accent  = _categoryColor(p.category);
    final initials =
        p.username.isNotEmpty ? p.username[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: avatar + name + tag ────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.12),
                    border:
                        Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
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
                      Text(
                        p.username,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 10,
                              color: AppColors.textDisabled),
                          const SizedBox(width: 3),
                          Text(_timeAgo(p.createdAt),
                              style: const TextStyle(
                                  color: AppColors.textDisabled,
                                  fontSize: 10)),
                          if (p.city.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.location_on_rounded,
                                size: 10,
                                color: AppColors.textDisabled),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                p.city,
                                style: const TextStyle(
                                    color: AppColors.textDisabled,
                                    fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Category tag — reports get a special badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p.isReport) ...[
                        Icon(Icons.flag_rounded, size: 9, color: accent),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        p.isReport
                            ? 'Hazard Report'
                            : _categoryLabel(p.category),
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete button (own posts + admin only)
                if (_canDelete) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _onDeleteTap,
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppColors.textDisabled),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // ── Content ──────────────────────────────────────────────
            Text(
              p.content,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            // ── Image ─────────────────────────────────────────────────
            if (p.imageUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  p.imageUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 10),

            // ── Actions ───────────────────────────────────────────────
            Row(
              children: [
                // Like
                GestureDetector(
                  onTap: _onLikeTap,
                  child: Row(
                    children: [
                      Icon(
                        _liked
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_alt_outlined,
                        size: 15,
                        color:
                            _liked ? accent : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$_likes ${_likes == 1 ? 'Like' : 'Likes'}',
                        style: TextStyle(
                          color: _liked
                              ? accent
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
