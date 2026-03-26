import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import 'alerts_screen.dart';
import 'guide_detail_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int _selectedCategory = 0;
  String _searchQuery = '';
  final List<String> _categories = ['All', 'Flood', 'Smog', 'Heatwave'];

  final List<_GuideItem> _guides = [
    _GuideItem(
      title: 'Smog & Air Quality',
      subtitle: 'Protect yourself from poor air quality',
      icon: Icons.air,
      color: AppColors.warning,
      duration: '5 min read',
      category: 'Smog',
    ),
    _GuideItem(
      title: 'Flood Safety',
      subtitle: 'What to do before, during, and after',
      icon: Icons.flood,
      color: AppColors.info,
      duration: '8 min read',
      category: 'Flood',
    ),
    _GuideItem(
      title: 'Heatwave Preparedness',
      subtitle: 'Stay cool and hydrated in extreme heat',
      icon: Icons.wb_sunny,
      color: AppColors.danger,
      duration: '6 min read',
      category: 'Heatwave',
    ),
    _GuideItem(
      title: 'Cloudburst Response',
      subtitle: 'Understanding sudden heavy rainfall',
      icon: Icons.thunderstorm,
      color: AppColors.info,
      duration: '4 min read',
      category: 'Flood',
    ),
  ];

  List<_GuideItem> get _filteredGuides {
    final selected = _categories[_selectedCategory];
    var list = selected == 'All' ? _guides : _guides.where((g) => g.category == selected).toList();
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((g) => g.title.toLowerCase().contains(q) || g.subtitle.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        children: [
          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Learn',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search, color: AppColors.textPrimary),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: AppColors.bgCard,
                                builder: (_) => Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: TextField(
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: 'Search guides...',
                                      hintStyle: TextStyle(color: AppColors.textSecondary),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onChanged: (v) => setState(() => _searchQuery = v),
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AlertsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Safety Guides & Preparedness',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          // Category Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategory == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_categories[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = index;
                      });
                    },
                    backgroundColor: AppColors.bgCard,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured Guide
                  GestureDetector(
                    onTap: () {
                      _openGuide(
                        const _GuideItem(
                          title: 'Flood Safety',
                          subtitle: 'What to do before, during, and after',
                          icon: Icons.flood,
                          color: AppColors.info,
                          duration: '8 min read',
                          category: 'Flood',
                        ),
                      );
                    },
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryDim],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Icon(
                              Icons.school,
                              size: 150,
                              color: AppColors.borderSubtle,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.textPrimary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Complete Flood\nSafety Guide',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.textPrimary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 12,
                                            color: AppColors.textPrimary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '8 min read',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.textPrimary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward,
                                        size: 20,
                                        color: AppColors.primary,
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
                  ),
                  const SizedBox(height: 24),
                  // Guides Grid
                  const Text(
                    'Safety Guides',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final guide in _filteredGuides) ...[
                    _buildGuideCard(guide),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 24),
                  // Emergency Contacts
                  GestureDetector(
                    onTap: () {
                      _showEmergencyContactsDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: AppColors.textPrimary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Emergency Contacts',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Always ready to help',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildEmergencyContact('Rescue 1122', '1122'),
                          const SizedBox(height: 8),
                          _buildEmergencyContact('Police Emergency', '15'),
                          const SizedBox(height: 8),
                          _buildEmergencyContact('Ambulance', '115'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(
    _GuideItem guide,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: guide.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            guide.icon,
            color: guide.color,
            size: 28,
          ),
        ),
        title: Text(
          guide.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              guide.subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: AppColors.textDisabled),
                const SizedBox(width: 4),
                Text(
                  guide.duration,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textDisabled,
        ),
        onTap: () {
          _openGuide(guide);
        },
      ),
    );
  }

  void _openGuide(_GuideItem guide) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuideDetailScreen(
          title: guide.title,
          category: guide._detailCategory,
          readTimeLabel: guide.duration,
        ),
      ),
    );
  }

  void _showEmergencyContactsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEmergencyContactRow('Rescue 1122', '1122', Icons.local_hospital),
            const Divider(color: AppColors.borderSubtle),
            _buildEmergencyContactRow('Police Emergency', '15', Icons.local_police),
            const Divider(color: AppColors.borderSubtle),
            _buildEmergencyContactRow('Ambulance', '115', Icons.local_hospital),
            const Divider(color: AppColors.borderSubtle),
            _buildEmergencyContactRow('Fire Brigade', '16', Icons.fire_truck),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactRow(String label, String number, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.danger, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Dial $number',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(String label, String number) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary.withOpacity(0.85),
          ),
        ),
        Text(
          number,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _GuideItem {
  const _GuideItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.duration,
    required this.category,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String duration;
  final String category;

  String get _detailCategory {
    if (category == 'Smog') return 'Smog/AQI';
    return category;
  }
}
