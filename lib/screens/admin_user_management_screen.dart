import 'package:flutter/material.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  String _selectedFilter = 'All Users';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_AdminUserEntry> _allUsers = [
    _AdminUserEntry(
      name: 'Ahmed Malik',
      email: 'ahmed.m@gmail.com',
      status: 'Active',
      timeAgo: 'Joined 2h ago',
      initials: 'AM',
      gradientColors: [Color(0xFF2196F3), Color(0xFF1E88E5)],
    ),
    _AdminUserEntry(
      name: 'User_7822',
      email: 'unknown@temp.mail',
      status: 'Suspended',
      timeAgo: 'Oct 12',
      isSuspended: true,
    ),
    _AdminUserEntry(
      name: 'Fatima Khan',
      email: 'f.khan.dev@yahoo.com',
      status: 'Active',
      timeAgo: 'Joined Yesterday',
      initials: 'FK',
      gradientColors: [Color(0xFF04B2B2), Color(0xFF06E0E0)],
    ),
    _AdminUserEntry(
      name: 'Admin Support',
      email: 'support@ecoalert.pk',
      status: 'STAFF',
      timeAgo: 'Online',
      isStaff: true,
    ),
    _AdminUserEntry(
      name: 'M. Zahid',
      email: 'zahid123@gmail.com',
      status: 'Offline',
      timeAgo: '3d ago',
      initials: 'MZ',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserActions(_AdminUserEntry user, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162e2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF06e0e0).withOpacity(0.15),
                  child: Text(
                    (user.initials ?? user.name.substring(0, 2)).toUpperCase(),
                    style: const TextStyle(color: Color(0xFF06e0e0), fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(user.email, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ),
              const Divider(color: Colors.white12),
              _actionTile(Icons.info_outline, 'View Profile', Colors.white70, () {
                Navigator.pop(context);
                _showProfileDialog(user);
              }),
              if (!user.isStaff) ...[
                user.isSuspended
                    ? _actionTile(Icons.check_circle_outline, 'Activate Account', Colors.green, () {
                        setState(() => _allUsers[index].isSuspended = false);
                        Navigator.pop(context);
                        _snack('${user.name} activated');
                      })
                    : _actionTile(Icons.block, 'Suspend Account', Colors.orange, () {
                        setState(() => _allUsers[index].isSuspended = true);
                        Navigator.pop(context);
                        _snack('${user.name} suspended');
                      }),
                _actionTile(Icons.delete_outline, 'Remove User', Colors.red, () {
                  Navigator.pop(context);
                  _confirmRemove(index);
                }),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showProfileDialog(_AdminUserEntry user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF162e2e),
        title: Text(user.name, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileRow('Email', user.email),
            _profileRow('Status', user.isSuspended ? 'Suspended' : (user.isStaff ? 'Staff' : user.status)),
            _profileRow('Joined', user.timeAgo),
            _profileRow('Role', user.isStaff ? 'Administrator' : 'User'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF06e0e0))),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }

  void _confirmRemove(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF162e2e),
        title: const Text('Remove User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${_allUsers[index].name}" permanently?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _allUsers.removeAt(index));
              Navigator.pop(context);
              _snack('User removed');
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162e2e),
        title: const Text('Add User', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(nameCtrl, 'Name'),
            const SizedBox(height: 12),
            _dialogField(emailCtrl, 'Email'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06e0e0), foregroundColor: Colors.black),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final email = emailCtrl.text.trim();
              if (name.isEmpty || email.isEmpty) return;
              setState(() {
                _allUsers.insert(0, _AdminUserEntry(
                  name: name,
                  email: email,
                  status: 'Active',
                  timeAgo: 'Just added',
                  initials: name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
                ));
              });
              Navigator.pop(ctx);
              _snack('$name added');
            },
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: const Color(0xFF0f2323),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }

  List<_AdminUserEntry> get _filteredUsers {
    final query = _searchQuery.trim().toLowerCase();
    return _allUsers.where((user) {
      final matchesFilter = _matchesFilter(user);
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  bool _matchesFilter(_AdminUserEntry user) {
    switch (_selectedFilter) {
      case 'Active':
        return user.status == 'Active';
      case 'Suspended':
        return user.isSuspended;
      case 'Moderators':
        return user.isStaff;
      default:
        return true;
    }
  }

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
                  GestureDetector(
                    onTap: _showAddUserDialog,
                    child: Container(
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
                      child: const Icon(Icons.person_add, color: Color(0xFF0f2323), size: 24),
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
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              ),
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
                        setState(() {
                          _searchQuery = value;
                        });
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

                    if (_filteredUsers.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162e2e),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: const Text(
                          'No users found',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._filteredUsers.map((user) {
                        final realIndex = _allUsers.indexOf(user);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildUserCard(user, realIndex),
                        );
                      }),
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

  Widget _buildUserCard(_AdminUserEntry user, int realIndex) {
    final statusColor = user.statusColor;
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
              gradient: user.gradientColors != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: user.gradientColors!,
                    )
                  : null,
              color: user.gradientColors == null
                  ? (user.isSuspended ? Colors.grey[700] : Colors.grey[200])
                  : null,
              shape: BoxShape.circle,
            ),
            child: user.isSuspended
                ? Icon(Icons.person_off, color: Colors.grey[400], size: 24)
                : user.isStaff
                    ? const Icon(Icons.verified_user, color: Colors.white, size: 24)
                    : Center(
                        child: Text(
                          (user.initials ?? user.name.substring(0, 2)).toUpperCase(),
                          style: TextStyle(
                            color: user.gradientColors != null ? Colors.white : Colors.grey[600],
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
                  user.name,
                  style: TextStyle(
                    color: user.isSuspended ? Colors.grey[300] : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (user.isSuspended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('SUSPENDED',
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else if (user.isStaff)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('STAFF',
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      user.isSuspended || user.isStaff ? user.timeAgo : '${user.status} • ${user.timeAgo}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // More Button
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
            onPressed: () => _showUserActions(user, realIndex),
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

class _AdminUserEntry {
  _AdminUserEntry({
    required this.name,
    required this.email,
    required this.status,
    required this.timeAgo,
    this.initials,
    this.gradientColors,
    this.isSuspended = false,
    this.isStaff = false,
  });

  final String name;
  final String email;
  final String status;
  final String timeAgo;
  final String? initials;
  final List<Color>? gradientColors;
  bool isSuspended;
  final bool isStaff;

  Color get statusColor {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Suspended':
        return Colors.red;
      case 'STAFF':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
