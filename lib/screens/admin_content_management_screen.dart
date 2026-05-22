import 'package:flutter/material.dart';

class AdminContentManagementScreen extends StatefulWidget {
  const AdminContentManagementScreen({super.key});

  @override
  State<AdminContentManagementScreen> createState() =>
      _AdminContentManagementScreenState();
}

class _AdminContentManagementScreenState
    extends State<AdminContentManagementScreen> {
  String _selectedFilter = 'All Content';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_AdminContentEntry> _allContent = [
    _AdminContentEntry(
      title: 'Surviving Flash Floods',
      type: 'Safety Guide',
      city: 'Lahore',
      description:
          'Safety steps for flash floods, evacuation, and immediate response for families.',
      categoryColor: Colors.blue,
      icon: Icons.flood,
      timeAgo: 'Updated 2h ago',
      status: 'Published',
      statusColor: Colors.green,
    ),
    _AdminContentEntry(
      title: 'Understanding AQI Levels',
      type: 'Educational',
      city: 'Karachi',
      description:
          'AQI tiers explained with simple actions users should follow during hazardous air.',
      categoryColor: Colors.orange,
      icon: Icons.masks,
      timeAgo: '1 day ago',
      status: 'Published',
      statusColor: Colors.green,
    ),
    _AdminContentEntry(
      title: 'Emergency Kit Checklist',
      type: 'Preparedness',
      city: 'Islamabad',
      description:
          'Checklist for emergency kits including medicine, water, food and flashlight.',
      categoryColor: Colors.grey,
      icon: Icons.medical_services,
      timeAgo: 'Edited 4m ago',
      status: 'Draft',
      statusColor: Colors.grey,
    ),
    _AdminContentEntry(
      title: 'Monsoon Warning System',
      type: 'Announcement',
      city: 'ALL',
      description:
          'Announcement for upcoming monsoon warning rollout and district-level awareness.',
      categoryColor: Colors.purple,
      icon: Icons.campaign,
      timeAgo: 'By Admin',
      status: 'Archived',
      statusColor: Colors.yellow,
      isScheduled: true,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_AdminContentEntry> get _filteredContent {
    final query = _searchQuery.trim().toLowerCase();
    return _allContent.where((item) {
      if (!_matchesFilter(item)) return false;
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          item.type.toLowerCase().contains(query) ||
          item.city.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  bool _matchesFilter(_AdminContentEntry item) {
    switch (_selectedFilter) {
      case 'Published':
        return item.status == 'Published';
      case 'Drafts':
        return item.status == 'Draft';
      case 'Archived':
        return item.status == 'Archived';
      default:
        return true;
    }
  }

  // ── Add / Edit sheet ───────────────────────────────────────────────────────

  void _showArticleSheet({_AdminContentEntry? existing, int? index}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String type = existing?.type ?? 'Safety Guide';
    String city = existing?.city ?? 'Lahore';
    String status = existing?.status ?? 'Draft';

    final types = ['Safety Guide', 'Educational', 'Preparedness', 'Announcement'];
    final cities = ['ALL', 'Lahore', 'Karachi', 'Islamabad', 'Peshawar', 'Multan', 'Quetta'];
    final statuses = ['Draft', 'Published', 'Archived'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF162e2e),
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
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sheetField(titleCtrl, 'Title', 'e.g. Flash Flood Safety Tips'),
                  const SizedBox(height: 12),
                  _sheetField(descCtrl, 'Description', 'Short summary...', maxLines: 3),
                  const SizedBox(height: 12),
                  _sheetDropdown<String>(
                    label: 'Type',
                    value: type,
                    items: types,
                    onChanged: (v) => setSheet(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  _sheetDropdown<String>(
                    label: 'City',
                    value: city,
                    items: cities,
                    onChanged: (v) => setSheet(() => city = v!),
                  ),
                  const SizedBox(height: 12),
                  _sheetDropdown<String>(
                    label: 'Status',
                    value: status,
                    items: statuses,
                    onChanged: (v) => setSheet(() => status = v!),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Title is required')),
                        );
                        return;
                      }
                      final entry = _AdminContentEntry(
                        title: title,
                        type: type,
                        city: city,
                        description: descCtrl.text.trim(),
                        categoryColor: _colorForType(type),
                        icon: _iconForType(type),
                        timeAgo: existing == null ? 'Just now' : 'Edited just now',
                        status: status,
                        statusColor: _colorForStatus(status),
                        isScheduled: status == 'Archived',
                      );
                      setState(() {
                        if (index != null) {
                          _allContent[index] = entry;
                        } else {
                          _allContent.insert(0, entry);
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06e0e0),
                      foregroundColor: const Color(0xFF0f2323),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      existing == null ? 'Publish Article' : 'Save Changes',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162e2e),
        title: const Text('Delete Article', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${_allContent[index].title}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _allContent.removeAt(index));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _colorForType(String type) {
    switch (type) {
      case 'Safety Guide': return Colors.blue;
      case 'Educational':  return Colors.orange;
      case 'Preparedness': return Colors.grey;
      case 'Announcement': return Colors.purple;
      default:             return Colors.teal;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Safety Guide': return Icons.flood;
      case 'Educational':  return Icons.school;
      case 'Preparedness': return Icons.medical_services;
      case 'Announcement': return Icons.campaign;
      default:             return Icons.article;
    }
  }

  Color _colorForStatus(String status) {
    switch (status) {
      case 'Published': return Colors.green;
      case 'Draft':     return Colors.grey;
      case 'Archived':  return Colors.yellow;
      default:          return Colors.white;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredContent;
    return Scaffold(
      backgroundColor: const Color(0xFF0f2323),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0f2323).withOpacity(0.95),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Panel', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                        const Text(
                          'Content Manager',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF06e0e0).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF06e0e0).withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.article, color: Color(0xFF06e0e0), size: 20),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats + Add New
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF162e2e), Color(0xFF0f2323)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Articles', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${_allContent.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF06e0e0).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_allContent.where((c) => c.status == 'Published').length} published',
                                      style: const TextStyle(color: Color(0xFF06e0e0), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showArticleSheet(),
                            icon: const Icon(Icons.add_circle, size: 20),
                            label: const Text('Add New', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06e0e0),
                              foregroundColor: const Color(0xFF0f2323),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search title, type, city...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey),
                                onPressed: () => setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                }),
                              ),
                        filled: true,
                        fillColor: const Color(0xFF162e2e),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('All Content'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Published'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Drafts'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Archived'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'ARTICLES  (${filtered.length})',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 12),

                    if (filtered.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162e2e),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: const Text('No articles found', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                      )
                    else
                      ...filtered.map((content) {
                        final realIndex = _allContent.indexOf(content);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildArticleCard(content, realIndex),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label ||
        (_selectedFilter == 'All Content' && label == 'All Content');
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = label),
      selectedColor: const Color(0xFF06e0e0),
      backgroundColor: const Color(0xFF162e2e),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white70,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? const Color(0xFF06e0e0) : Colors.white.withOpacity(0.1)),
    );
  }

  Widget _buildArticleCard(_AdminContentEntry content, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162e2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: content.categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(content.icon, color: content.categoryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(content.type, style: TextStyle(color: content.categoryColor, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 6),
                        Text('•', style: TextStyle(color: Colors.grey[400])),
                        const SizedBox(width: 6),
                        Text(content.city, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        const SizedBox(width: 6),
                        Text('•', style: TextStyle(color: Colors.grey[400])),
                        const SizedBox(width: 6),
                        Text(content.timeAgo, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                    if (content.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        content.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: content.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      content.isScheduled
                          ? Icon(Icons.schedule, size: 12, color: content.statusColor)
                          : Container(width: 6, height: 6, decoration: BoxDecoration(color: content.statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        content.status.toUpperCase(),
                        style: TextStyle(color: content.statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF06e0e0), size: 20),
                      tooltip: 'Edit',
                      onPressed: () => _showArticleSheet(existing: content, index: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: const Color(0xFF0f2323),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _sheetDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0f2323),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        dropdownColor: const Color(0xFF162e2e),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          border: InputBorder.none,
        ),
        items: items
            .map((i) => DropdownMenuItem<T>(
                  value: i,
                  child: Text(i.toString(), style: const TextStyle(color: Colors.white)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _AdminContentEntry {
  _AdminContentEntry({
    required this.title,
    required this.type,
    required this.city,
    required this.description,
    required this.categoryColor,
    required this.icon,
    required this.timeAgo,
    required this.status,
    required this.statusColor,
    this.isScheduled = false,
  });

  String title;
  String type;
  String city;
  String description;
  Color categoryColor;
  IconData icon;
  String timeAgo;
  String status;
  Color statusColor;
  bool isScheduled;
}
