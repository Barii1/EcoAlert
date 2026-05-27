import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_colors.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState
    extends State<AdminUserManagementScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _filter = 'all'; // all | registered | premium | admin | suspended
  bool _loading = true;
  String? _error;
  List<_UserRow> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _users = (rows as List)
            .map((r) => _UserRow.fromMap(r as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<_UserRow> get _filtered {
    final q = _search.trim().toLowerCase();
    return _users.where((u) {
      final matchFilter = switch (_filter) {
        'registered' => u.role == 'registered' && !u.isSuspended,
        'premium' => u.role == 'premium' && !u.isSuspended,
        'admin' => u.role == 'admin',
        'suspended' => u.isSuspended,
        _ => true,
      };
      if (!matchFilter) return false;
      if (q.isEmpty) return true;
      return u.username.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          (u.city ?? '').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  int _count(String f) => switch (f) {
        'registered' => _users.where((u) => u.role == 'registered' && !u.isSuspended).length,
        'premium' => _users.where((u) => u.role == 'premium' && !u.isSuspended).length,
        'admin' => _users.where((u) => u.role == 'admin').length,
        'suspended' => _users.where((u) => u.isSuspended).length,
        _ => _users.length,
      };

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _setSuspended(int idx, bool suspended) async {
    final user = _filtered[idx];
    final realIdx = _users.indexWhere((u) => u.id == user.id);
    if (realIdx < 0) return;

    setState(() => _users[realIdx] = user.copyWith(isSuspended: suspended));

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'is_suspended': suspended})
          .eq('id', user.id);
      _snack(suspended ? '${user.displayName} suspended' : '${user.displayName} activated');
    } catch (e) {
      // roll back
      setState(() => _users[realIdx] = user);
      _snack('Action failed: $e');
    }
  }

  Future<void> _setRole(int idx, String newRole) async {
    final user = _filtered[idx];
    final realIdx = _users.indexWhere((u) => u.id == user.id);
    if (realIdx < 0) return;

    setState(() => _users[realIdx] = user.copyWith(role: newRole));

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'role': newRole})
          .eq('id', user.id);
      _snack('Role updated to $newRole for ${user.displayName}');
    } catch (e) {
      setState(() => _users[realIdx] = user);
      _snack('Role update failed: $e');
    }
  }

  void _showActions(_UserRow user, int filteredIdx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: _Avatar(user: user, size: 40),
              title: Text(
                user.displayName,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                user.email,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),
            _ActionTile(
              icon: Icons.info_outline,
              label: 'View Profile',
              color: AppColors.textSecondary,
              onTap: () {
                Navigator.pop(context);
                _showProfile(user);
              },
            ),
            if (user.role != 'premium' && user.role != 'admin')
              _ActionTile(
                icon: Icons.workspace_premium,
                label: 'Grant Premium',
                color: AppColors.info,
                onTap: () {
                  Navigator.pop(context);
                  _setRole(filteredIdx, 'premium');
                },
              ),
            if (user.role == 'premium')
              _ActionTile(
                icon: Icons.person_outline,
                label: 'Downgrade to Registered',
                color: AppColors.warning,
                onTap: () {
                  Navigator.pop(context);
                  _setRole(filteredIdx, 'registered');
                },
              ),
            if (user.role != 'admin')
              _ActionTile(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Promote to Admin',
                color: AppColors.danger,
                onTap: () {
                  Navigator.pop(context);
                  _setRole(filteredIdx, 'admin');
                },
              ),
            if (user.role == 'admin')
              _ActionTile(
                icon: Icons.person_outline,
                label: 'Revoke Admin → Registered',
                color: AppColors.warning,
                onTap: () {
                  Navigator.pop(context);
                  _setRole(filteredIdx, 'registered');
                },
              ),
            if (!user.isSuspended)
              _ActionTile(
                icon: Icons.block,
                label: 'Suspend Account',
                color: AppColors.warning,
                onTap: () {
                  Navigator.pop(context);
                  _setSuspended(filteredIdx, true);
                },
              )
            else
              _ActionTile(
                icon: Icons.check_circle_outline,
                label: 'Activate Account',
                color: AppColors.success,
                onTap: () {
                  Navigator.pop(context);
                  _setSuspended(filteredIdx, false);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showProfile(_UserRow user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(user.displayName,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProfileRow('Email', user.email),
            _ProfileRow('Role', user.role[0].toUpperCase() + user.role.substring(1)),
            _ProfileRow('Status', user.isSuspended ? 'Suspended' : 'Active'),
            if (user.city != null) _ProfileRow('City', user.city!),
            if (user.province != null)
              _ProfileRow('Province', user.province!),
            _ProfileRow(
              'Joined',
              user.createdAt != null
                  ? _formatDate(user.createdAt!)
                  : 'Unknown',
            ),
            _ProfileRow('ID', '${user.id.substring(0, 8)}…'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.bgElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
          'User Management',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Refresh',
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadUsers)
              : _Body(
                  users: _filtered,
                  filter: _filter,
                  search: _search,
                  searchCtrl: _searchCtrl,
                  totalUsers: _users.length,
                  adminCount: _count('admin'),
                  suspendedCount: _count('suspended'),
                  onFilterChanged: (f) => setState(() => _filter = f),
                  onSearchChanged: (v) => setState(() => _search = v),
                  onShowActions: _showActions,
                  countFor: _count,
                ),
    );
  }
}

// ── Body widget ─────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.users,
    required this.filter,
    required this.search,
    required this.searchCtrl,
    required this.totalUsers,
    required this.adminCount,
    required this.suspendedCount,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onShowActions,
    required this.countFor,
  });

  final List<_UserRow> users;
  final String filter;
  final String search;
  final TextEditingController searchCtrl;
  final int totalUsers;
  final int adminCount;
  final int suspendedCount;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final void Function(_UserRow user, int idx) onShowActions;
  final int Function(String) countFor;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Stats row
        Row(
          children: [
            _StatCard(label: 'Total', value: '$totalUsers'),
            const SizedBox(width: 8),
            _StatCard(label: 'Premium', value: '${countFor('premium')}', color: AppColors.info),
            const SizedBox(width: 8),
            _StatCard(label: 'Admins', value: '$adminCount', color: AppColors.warning),
            const SizedBox(width: 8),
            _StatCard(label: 'Suspended', value: '$suspendedCount', color: AppColors.danger),
          ],
        ),
        const SizedBox(height: 16),

        // Search
        TextField(
          controller: searchCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search name, email, city…',
            hintStyle:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            prefixIcon: const Icon(Icons.search,
                color: AppColors.textSecondary, size: 18),
            suffixIcon: search.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary, size: 18),
                    onPressed: () {
                      searchCtrl.clear();
                      onSearchChanged('');
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
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),

        // Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                  label: 'All',
                  count: countFor('all'),
                  selected: filter == 'all',
                  onTap: () => onFilterChanged('all')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Registered',
                  count: countFor('registered'),
                  selected: filter == 'registered',
                  onTap: () => onFilterChanged('registered')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Premium',
                  count: countFor('premium'),
                  selected: filter == 'premium',
                  color: AppColors.info,
                  onTap: () => onFilterChanged('premium')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Admins',
                  count: countFor('admin'),
                  selected: filter == 'admin',
                  color: AppColors.warning,
                  onTap: () => onFilterChanged('admin')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Suspended',
                  count: countFor('suspended'),
                  selected: filter == 'suspended',
                  color: AppColors.danger,
                  onTap: () => onFilterChanged('suspended')),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section label
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            '${users.length} ${users.length == 1 ? 'USER' : 'USERS'} SHOWN',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),

        if (users.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Center(
              child: Text('No users match your search',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...users.asMap().entries.map((entry) {
            final idx = entry.key;
            final user = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _UserCard(
                user: user,
                onTap: () => onShowActions(user, idx),
              ),
            );
          }),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ── User card ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap});
  final _UserRow user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = user.isSuspended
        ? (AppColors.danger, 'SUSPENDED')
        : user.role == 'admin'
            ? (AppColors.warning, 'ADMIN')
            : user.role == 'premium'
                ? (AppColors.info, 'PREMIUM')
                : (AppColors.success, 'REGISTERED');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          _Avatar(user: user, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (user.city != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.location_on_outlined,
                          size: 10, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        user.city!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert,
                color: AppColors.textSecondary, size: 20),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

// ── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.size});
  final _UserRow user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';
    final color =
        user.isSuspended ? AppColors.warning : AppColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
              color: color,
              fontSize: size * 0.42,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ── Filter chip ──────────────────────────────────────────────────────────────

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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.15) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.withOpacity(0.5) : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: selected ? c : AppColors.textSecondary,
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: c,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ── Profile row ───────────────────────────────────────────────────────────────

class _ProfileRow extends StatelessWidget {
  const _ProfileRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label,
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

// ── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                color: AppColors.textSecondary, size: 40),
            const SizedBox(height: 12),
            const Text('Failed to load users',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color: AppColors.primary.withOpacity(0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _UserRow {
  _UserRow({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.city,
    this.province,
    this.createdAt,
    this.isSuspended = false,
  });

  final String id;
  final String username;
  final String email;
  final String role;
  final String? city;
  final String? province;
  final DateTime? createdAt;
  final bool isSuspended;

  String get displayName => username.isNotEmpty ? username : email.split('@').first;

  factory _UserRow.fromMap(Map<String, dynamic> m) {
    return _UserRow(
      id: m['id'] as String? ?? '',
      username: m['username'] as String? ?? '',
      email: m['email'] as String? ?? '',
      role: m['role'] as String? ?? 'user',
      city: m['city'] as String?,
      province: m['province'] as String?,
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'] as String)
          : null,
      isSuspended: m['is_suspended'] as bool? ?? false,
    );
  }

  _UserRow copyWith({String? role, bool? isSuspended}) {
    return _UserRow(
      id: id,
      username: username,
      email: email,
      role: role ?? this.role,
      city: city,
      province: province,
      createdAt: createdAt,
      isSuspended: isSuspended ?? this.isSuspended,
    );
  }
}
