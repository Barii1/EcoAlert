import 'package:flutter/material.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  String _selectedFilter = 'All Users';

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
                  const Expanded(
                    child: Text(
                      'User Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF06e0e0),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06e0e0).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: Color(0xFF0f2323),
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
                    // Search
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF162e2e),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
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
                          _buildFilterChip('All Users', 'All Users'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Active', 'Active'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Suspended', 'Suspended'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Moderators', 'Moderators'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF162e2e).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Users',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '12,450',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF162e2e).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New This Week',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '+128',
                                  style: TextStyle(
                                    color: const Color(0xFF06e0e0),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Recent Users
                    Text(
                      'RECENT USERS',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // User Cards
                    _buildUserCard(
                      name: 'Ahmed Malik',
                      email: 'ahmed.m@gmail.com',
                      status: 'Active',
                      statusColor: Colors.green,
                      timeAgo: 'Joined 2h ago',
                      initials: 'AM',
                      gradientColors: [Colors.blue, Colors.blue.shade600],
                    ),
                    const SizedBox(height: 12),
                    _buildUserCard(
                      name: 'User_7822',
                      email: 'unknown@temp.mail',
                      status: 'Suspended',
                      statusColor: Colors.red,
                      timeAgo: 'Oct 12',
                      isSuspended: true,
                    ),
                    const SizedBox(height: 12),
                    _buildUserCard(
                      name: 'Fatima Khan',
                      email: 'f.khan.dev@yahoo.com',
                      status: 'Active',
                      statusColor: Colors.green,
                      timeAgo: 'Joined Yesterday',
                      initials: 'FK',
                      gradientColors: [
                        const Color(0xFF04b2b2),
                        const Color(0xFF06e0e0),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildUserCard(
                      name: 'Admin Support',
                      email: 'support@ecoalert.pk',
                      status: 'STAFF',
                      statusColor: Colors.purple,
                      timeAgo: 'Online',
                      isStaff: true,
                    ),
                    const SizedBox(height: 12),
                    _buildUserCard(
                      name: 'M. Zahid',
                      email: 'zahid123@gmail.com',
                      status: 'Offline',
                      statusColor: Colors.grey,
                      timeAgo: '3d ago',
                      initials: 'MZ',
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
                    _buildNavItem(Icons.settings, 'Settings', true, () {}),
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
      selectedColor: isSelected
          ? Colors.grey[900]
          : const Color(0xFF162e2e),
      backgroundColor: const Color(0xFF162e2e),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected
            ? Colors.white
            : Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildUserCard({
    required String name,
    required String email,
    required String status,
    required Color statusColor,
    required String timeAgo,
    String? initials,
    List<Color>? gradientColors,
    bool isSuspended = false,
    bool isStaff = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF162e2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradientColors != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    )
                  : null,
              color: gradientColors == null
                  ? (isSuspended ? Colors.grey[700] : Colors.grey[200])
                  : null,
              shape: BoxShape.circle,
            ),
            child: isSuspended
                ? Icon(
                    Icons.person_off,
                    color: Colors.grey[400],
                    size: 24,
                  )
                : isStaff
                    ? Icon(
                        Icons.verified_user,
                        color: Colors.white,
                        size: 24,
                      )
                    : Center(
                        child: Text(
                          initials ?? name.substring(0, 2).toUpperCase(),
                          style: TextStyle(
                            color: gradientColors != null
                                ? Colors.white
                                : Colors.grey[600],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isSuspended ? Colors.grey[300] : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (status == 'Active')
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      )
                    else if (status == 'STAFF')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isSuspended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'SUSPENDED',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (status == 'Active' || status == 'Offline') ...[
                      const SizedBox(width: 6),
                      Text(
                        '$status • $timeAgo',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                    ] else if (!isSuspended && status != 'STAFF') ...[
                      const SizedBox(width: 6),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                    ] else if (status == 'STAFF') ...[
                      const SizedBox(width: 6),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // More Button
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
            onPressed: () {},
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
