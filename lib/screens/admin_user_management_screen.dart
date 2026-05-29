import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Admin palette (shared) ────────────────────────────────────────────────────
const _kCard   = Color(0xFF111111);
const _kBorder = Color(0xFF1F1F1F);
const _kGreen  = Color(0xFF4ADE80);
const _kRed    = Color(0xFFEF4444);
const _kOrange = Color(0xFFF97316);
const _kText   = Colors.white;
const _kSub    = Color(0xFF9CA3AF);
const _kDim    = Color(0xFF4B5563);

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _searchCtrl = TextEditingController();
  String _search = '';
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
    setState(() { _loading = true; _error = null; });
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
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _setSuspended(_UserRow user, bool suspended) async {
    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx < 0) return;
    setState(() => _users[idx] = user.copyWith(isSuspended: suspended));
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'is_suspended': suspended}).eq('id', user.id);
      _snack(suspended ? '${user.displayName} suspended' : '${user.displayName} reactivated');
    } catch (e) {
      setState(() => _users[idx] = user);
      _snack('Action failed: $e');
    }
  }

  Future<void> _setRole(_UserRow user, String newRole) async {
    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx < 0) return;
    setState(() => _users[idx] = user.copyWith(role: newRole));
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'role': newRole}).eq('id', user.id);
      _snack('Role updated to $newRole');
    } catch (e) {
      setState(() => _users[idx] = user);
      _snack('Update failed: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: _kCard));
  }

  List<_UserRow> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _users;
    return _users.where((u) =>
        u.username.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q) ||
        u.id.toLowerCase().contains(q)).toList();
  }

  int get _activeCount => _users.where((u) => !u.isSuspended).length;

  void _showActions(_UserRow user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            if (!user.isSuspended && user.role != 'admin') ...[
              _SheetTile(
                icon: Icons.block_rounded, label: 'Suspend User', color: _kRed,
                onTap: () { Navigator.pop(context); _setSuspended(user, true); },
              ),
              _SheetTile(
                icon: Icons.workspace_premium_rounded,
                label: user.role == 'premium' ? 'Remove Premium' : 'Grant Premium',
                color: _kGreen,
                onTap: () {
                  Navigator.pop(context);
                  _setRole(user, user.role == 'premium' ? 'registered' : 'premium');
                },
              ),
              _SheetTile(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Make Admin', color: _kSub,
                onTap: () { Navigator.pop(context); _setRole(user, 'admin'); },
              ),
            ] else if (user.isSuspended) ...[
              _SheetTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Reactivate Account', color: _kGreen,
                onTap: () { Navigator.pop(context); _setSuspended(user, false); },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _SimpleHeader(title: 'EcoAlert Admin', statusText: 'System Online'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kGreen))
                : _error != null
                    ? _RetryView(message: _error!, onRetry: _loadUsers)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _SearchBar(
                            controller: _searchCtrl,
                            hint: 'Search users by name, role, or ID…',
                            onChanged: (v) => setState(() => _search = v),
                          ),
                          const SizedBox(height: 16),
                          _UserDirectoryCard(
                            users: _filtered,
                            activeCount: _activeCount,
                            onActionTap: _showActions,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ── User directory card ───────────────────────────────────────────────────────

class _UserDirectoryCard extends StatelessWidget {
  const _UserDirectoryCard({
    required this.users,
    required this.activeCount,
    required this.onActionTap,
  });
  final List<_UserRow> users;
  final int activeCount;
  final ValueChanged<_UserRow> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Text('User Directory',
                    style: TextStyle(
                        color: _kText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('Total: $activeCount Active',
                    style: const TextStyle(color: _kSub, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          if (users.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No users found', style: TextStyle(color: _kSub)),
            )
          else
            ...List.generate(users.length, (i) => Column(
              children: [
                _UserTile(user: users[i], onActionTap: onActionTap),
                if (i < users.length - 1)
                  const Divider(height: 1, indent: 68, color: _kBorder),
              ],
            )),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onActionTap});
  final _UserRow user;
  final ValueChanged<_UserRow> onActionTap;

  @override
  Widget build(BuildContext context) {
    final showMenu = user.role == 'admin' || user.isSuspended || user.role != 'registered';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _Avatar(initials: user.initials, suspended: user.isSuspended),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: TextStyle(
                    color: user.isSuspended ? _kSub : _kText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.isSuspended ? 'Suspended Account' : user.email,
                        style: const TextStyle(color: _kSub, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(' · ', style: TextStyle(color: _kDim)),
                    _RoleBadge(role: user.role, suspended: user.isSuspended),
                  ],
                ),
                const SizedBox(height: 3),
                Text('ID: ${user.shortId}',
                    style: const TextStyle(color: _kDim, fontSize: 11)),
              ],
            ),
          ),
          if (showMenu)
            GestureDetector(
              onTap: () => onActionTap(user),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.more_vert_rounded, color: _kSub, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.suspended});
  final String initials;
  final bool suspended;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: suspended ? _kBorder : const Color(0xFF2A2A2A),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(
                color: suspended ? _kDim : _kText,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.suspended});
  final String role;
  final bool suspended;

  @override
  Widget build(BuildContext context) {
    if (suspended) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _kOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kOrange.withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 5, height: 5,
              decoration: const BoxDecoration(color: _kOrange, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          const Text('Suspended',
              style: TextStyle(color: _kOrange, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    switch (role) {
      case 'premium':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _kGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kGreen.withOpacity(0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 5, height: 5,
                decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('Premium',
                style: TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        );
      case 'admin':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 5, height: 5,
                decoration: const BoxDecoration(color: _kText, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('Admin',
                style: TextStyle(color: _kText, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder),
          ),
          child: const Text('Registered',
              style: TextStyle(color: _kSub, fontSize: 11)),
        );
    }
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SimpleHeader extends StatelessWidget {
  const _SimpleHeader({required this.title, this.statusText});
  final String title;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  color: _kText, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (statusText != null)
            Text(statusText!,
                style: const TextStyle(color: _kSub, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: _kText, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _kDim, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _kDim, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
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
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

class _RetryView extends StatelessWidget {
  const _RetryView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: _kDim, size: 40),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: _kSub, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Try Again', style: TextStyle(color: _kGreen)),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _UserRow {
  const _UserRow({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isSuspended,
    this.city,
  });

  final String id;
  final String username;
  final String email;
  final String role;
  final bool isSuspended;
  final String? city;

  factory _UserRow.fromMap(Map<String, dynamic> m) => _UserRow(
        id: m['id']?.toString() ?? '',
        username: m['username']?.toString() ?? '',
        email: m['email']?.toString() ?? '',
        role: m['role']?.toString() ?? 'registered',
        isSuspended: m['is_suspended'] as bool? ?? false,
        city: m['city']?.toString(),
      );

  _UserRow copyWith({String? role, bool? isSuspended}) => _UserRow(
        id: id, username: username, email: email, city: city,
        role: role ?? this.role,
        isSuspended: isSuspended ?? this.isSuspended,
      );

  String get displayName => username.isNotEmpty ? username : email.split('@').first;
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.substring(0, displayName.length >= 2 ? 2 : 1).toUpperCase();
  }
  String get shortId => id.length > 5 ? id.substring(0, 5).toUpperCase() : id.toUpperCase();
}
