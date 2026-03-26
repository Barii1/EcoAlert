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

  @override
  Widget build(BuildContext context) {
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
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'Content Manager',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                      border: Border.all(
                        color: const Color(0xFF06e0e0).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF06e0e0),
                      size: 24,
                    ),
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
                    // Total Articles Card
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
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06e0e0).withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Articles',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  const Text(
                                    '24',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF06e0e0).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '+2 this week',
                                      style: TextStyle(
                                        color: Color(0xFF06e0e0),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Add new article
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Add new article (Demo)'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_circle, size: 20),
                            label: const Text(
                              'Add New',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06e0e0),
                              foregroundColor: const Color(0xFF0f2323),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: const Color(0xFF06e0e0).withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search title, category...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF162e2e),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        // TODO: Implement search
                      },
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('All Content', 'All Content'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Published', 'Published'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Drafts', 'Drafts'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Archived', 'Archived'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Recent Updates
                    Text(
                      'RECENT UPDATES',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Article Cards
                    _buildArticleCard(
                      title: 'Surviving Flash Floods',
                      category: 'Safety Guide',
                      categoryColor: Colors.blue,
                      icon: Icons.flood,
                      timeAgo: 'Updated 2h ago',
                      status: 'Published',
                      statusColor: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildArticleCard(
                      title: 'Understanding AQI Levels',
                      category: 'Educational',
                      categoryColor: Colors.orange,
                      icon: Icons.masks,
                      timeAgo: '1 day ago',
                      status: 'Published',
                      statusColor: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildArticleCard(
                      title: 'Emergency Kit Checklist',
                      category: 'Preparedness',
                      categoryColor: Colors.grey,
                      icon: Icons.medical_services,
                      timeAgo: 'Edited 4m ago',
                      status: 'Draft',
                      statusColor: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    _buildArticleCard(
                      title: 'Monsoon Warning System',
                      category: 'Announcement',
                      categoryColor: Colors.purple,
                      icon: Icons.campaign,
                      timeAgo: 'By Admin',
                      status: 'Scheduled',
                      statusColor: Colors.yellow,
                      isScheduled: true,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0f2323).withOpacity(0.95),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                  top: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.dashboard, 'Home', false, () {
                      Navigator.pop(context);
                    }),
                    _buildNavItem(Icons.map, 'Map', false, () {}),
                    _buildNavItem(Icons.assignment, 'Reports', false, () {}, hasNotification: true),
                    _buildNavItem(Icons.article, 'Content', true, () {}),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: const Color(0xFF06e0e0),
      backgroundColor: const Color(0xFF162e2e),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white70,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF06e0e0)
            : Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildArticleCard({
    required String title,
    required String category,
    required Color categoryColor,
    required IconData icon,
    required String timeAgo,
    required String status,
    required Color statusColor,
    bool isScheduled = false,
  }) {
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
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: categoryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isScheduled)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: statusColor,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () {},
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

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap, {
    bool hasNotification = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF06e0e0) : Colors.grey[400],
                  size: 24,
                ),
                if (hasNotification && !isSelected)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF06e0e0),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF06e0e0) : Colors.grey[400],
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
