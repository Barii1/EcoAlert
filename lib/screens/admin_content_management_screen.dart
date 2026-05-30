import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/city_mappings.dart';

class AdminContentManagementScreen extends StatefulWidget {
  const AdminContentManagementScreen({super.key});

  @override
  State<AdminContentManagementScreen> createState() =>
      _AdminContentManagementScreenState();
}

class _AdminContentManagementScreenState
    extends State<AdminContentManagementScreen> {
  String _filter = 'all'; // all | published | draft | archived
  final _searchCtrl = TextEditingController();
  String _search = '';

  final List<_Article> _articles = [
    _Article(
      title: 'Surviving Flash Floods',
      type: 'Safety Guide',
      city: 'Lahore',
      description:
          'Safety steps for flash floods, evacuation, and immediate response for families.',
      timeAgo: 'Updated 2h ago',
      status: 'published',
    ),
    _Article(
      title: 'Understanding AQI Levels',
      type: 'Educational',
      city: 'Karachi',
      description:
          'AQI tiers explained with simple actions users should follow during hazardous air.',
      timeAgo: '1 day ago',
      status: 'published',
    ),
    _Article(
      title: 'Emergency Kit Checklist',
      type: 'Preparedness',
      city: 'Islamabad',
      description:
          'Checklist for emergency kits including medicine, water, food and flashlight.',
      timeAgo: 'Edited 4m ago',
      status: 'draft',
    ),
    _Article(
      title: 'Monsoon Warning System',
      type: 'Announcement',
      city: 'ALL',
      description:
          'Announcement for upcoming monsoon warning rollout and district-level awareness.',
      timeAgo: 'By Admin',
      status: 'archived',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Article> get _filtered {
    final q = _search.trim().toLowerCase();
    return _articles.where((a) {
      final matchFilter = switch (_filter) {
        'published' => a.status == 'published',
        'draft' => a.status == 'draft',
        'archived' => a.status == 'archived',
        _ => true,
      };
      if (!matchFilter) return false;
      if (q.isEmpty) return true;
      return a.title.toLowerCase().contains(q) ||
          a.type.toLowerCase().contains(q) ||
          a.city.toLowerCase().contains(q) ||
          a.description.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  int _count(String f) => switch (f) {
        'published' => _articles.where((a) => a.status == 'published').length,
        'draft' => _articles.where((a) => a.status == 'draft').length,
        'archived' => _articles.where((a) => a.status == 'archived').length,
        _ => _articles.length,
      };

  // ── Helpers ────────────────────────────────────────────────────────────────

  static const _types = [
    'Safety Guide',
    'Educational',
    'Preparedness',
    'Announcement',
  ];
  static const _statuses = ['draft', 'published', 'archived'];

  Color _colorForType(String type) => switch (type) {
        'Safety Guide' => AppColors.info,
        'Educational' => AppColors.warning,
        'Preparedness' => AppColors.success,
        'Announcement' => const Color(0xFFB07FFF),
        _ => AppColors.primary,
      };

  IconData _iconForType(String type) => switch (type) {
        'Safety Guide' => Icons.flood_outlined,
        'Educational' => Icons.school_outlined,
        'Preparedness' => Icons.medical_services_outlined,
        'Announcement' => Icons.campaign_outlined,
        _ => Icons.article_outlined,
      };

  (Color, String) _statusInfo(String status) => switch (status) {
        'published' => (AppColors.success, 'PUBLISHED'),
        'draft' => (AppColors.textSecondary, 'DRAFT'),
        'archived' => (AppColors.warning, 'ARCHIVED'),
        _ => (AppColors.textSecondary, status.toUpperCase()),
      };

  // ── Add / Edit sheet ───────────────────────────────────────────────────────

  void _showArticleSheet({_Article? existing, int? realIndex}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String type = existing?.type ?? 'Safety Guide';
    String city = existing?.city ?? 'Lahore';
    String status = existing?.status ?? 'draft';

    final cities = ['ALL', ...CityMappings.allCities];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        existing == null ? 'New Article' : 'Edit Article',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SheetField(ctrl: titleCtrl, label: 'Title', hint: 'e.g. Flash Flood Safety Tips'),
                  const SizedBox(height: 12),
                  _SheetField(ctrl: descCtrl, label: 'Description', hint: 'Short summary…', maxLines: 3),
                  const SizedBox(height: 12),
                  _SheetDropdown<String>(
                    label: 'Type',
                    value: type,
                    items: _types,
                    onChanged: (v) => setSheet(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  _SheetDropdown<String>(
                    label: 'City',
                    value: city,
                    items: cities,
                    onChanged: (v) => setSheet(() => city = v!),
                  ),
                  const SizedBox(height: 12),
                  _SheetDropdown<String>(
                    label: 'Status',
                    value: status,
                    items: _statuses,
                    onChanged: (v) => setSheet(() => status = v!),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Title is required'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      final entry = _Article(
                        title: title,
                        type: type,
                        city: city,
                        description: descCtrl.text.trim(),
                        timeAgo:
                            existing == null ? 'Just now' : 'Edited just now',
                        status: status,
                      );
                      setState(() {
                        if (realIndex != null) {
                          _articles[realIndex] = entry;
                        } else {
                          _articles.insert(0, entry);
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.bgPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      existing == null ? 'Save Article' : 'Save Changes',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _confirmDelete(int realIndex) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Article',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Delete "${_articles[realIndex].title}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _articles.removeAt(realIndex));
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Content Manager',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.primary),
            tooltip: 'Add Article',
            onPressed: () => _showArticleSheet(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Articles',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '${_articles.length}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_count('published')} published',
                            style: const TextStyle(
                                color: AppColors.success, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showArticleSheet(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.bgPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search title, type, city…',
              hintStyle:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              prefixIcon: const Icon(Icons.search,
                  color: AppColors.textSecondary, size: 18),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textSecondary, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                    label: 'All',
                    count: _count('all'),
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Published',
                    count: _count('published'),
                    selected: _filter == 'published',
                    color: AppColors.success,
                    onTap: () => setState(() => _filter = 'published')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Drafts',
                    count: _count('draft'),
                    selected: _filter == 'draft',
                    color: AppColors.textSecondary,
                    onTap: () => setState(() => _filter = 'draft')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Archived',
                    count: _count('archived'),
                    selected: _filter == 'archived',
                    color: AppColors.warning,
                    onTap: () => setState(() => _filter = 'archived')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section label
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'ARTICLES (${filtered.length})',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Center(
                child: Text('No articles found',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ...filtered.map((article) {
              final realIndex = _articles.indexOf(article);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ArticleCard(
                  article: article,
                  typeColor: _colorForType(article.type),
                  typeIcon: _iconForType(article.type),
                  statusInfo: _statusInfo(article.status),
                  onEdit: () =>
                      _showArticleSheet(existing: article, realIndex: realIndex),
                  onDelete: () => _confirmDelete(realIndex),
                ),
              );
            }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Article card ──────────────────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
    required this.typeColor,
    required this.typeIcon,
    required this.statusInfo,
    required this.onEdit,
    required this.onDelete,
  });
  final _Article article;
  final Color typeColor;
  final IconData typeIcon;
  final (Color, String) statusInfo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = statusInfo;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: typeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(article.type,
                            style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        const Text('•',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(article.city,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(width: 4),
                        const Text('•',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(article.timeAgo,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                    if (article.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        article.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.primary, size: 18),
                    tooltip: 'Edit',
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.danger, size: 18),
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.color,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.15) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected ? c.withOpacity(0.5) : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: selected ? c : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Sheet widgets ─────────────────────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.textSecondary, fontSize: 12),
        filled: true,
        fillColor: AppColors.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _SheetDropdown<T> extends StatelessWidget {
  const _SheetDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        dropdownColor: AppColors.bgCard,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
        ),
        icon: const Icon(Icons.expand_more,
            color: AppColors.textSecondary, size: 18),
        items: items
            .map((i) => DropdownMenuItem<T>(
                  value: i,
                  child: Text(i.toString(),
                      style:
                          const TextStyle(color: AppColors.textPrimary)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _Article {
  _Article({
    required this.title,
    required this.type,
    required this.city,
    required this.description,
    required this.timeAgo,
    required this.status,
  });

  String title;
  String type;
  String city;
  String description;
  String timeAgo;
  String status; // 'published' | 'draft' | 'archived'
}
