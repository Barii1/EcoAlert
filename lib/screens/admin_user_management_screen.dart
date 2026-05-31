// Hassaan/Bilal: run this SQL in Supabase SQL Editor:
//
// ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role text DEFAULT 'registered_user';
// ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_suspended bool DEFAULT false;
// Possible role values: 'admin', 'premium_user', 'registered_user', 'guest'
// (The app also understands legacy values: 'premium' → premium_user,
//  'registered' → registered_user, 'general' → guest)
//
// ── RLS policy so admins can update any profile's role/suspension ─────────────
// Without this policy the Supabase client will silently reject role updates.
//
// -- Drop the default "users can only update their own row" policy first if it
// -- exists, then add the admin-aware one:
// DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
//
// CREATE POLICY "admin_or_own_update" ON profiles
// FOR UPDATE TO authenticated
// USING (
//   auth.uid() = id
//   OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
// )
// WITH CHECK (
//   auth.uid() = id
//   OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
// );

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

// ── Role definitions ──────────────────────────────────────────────────────────

class _RoleOption {
  const _RoleOption(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color  color;
}

const _kRoles = [
  _RoleOption('admin',           'Admin',          _kRed),
  _RoleOption('premium_user',    'Premium User',   Color(0xFFFBBF24)),
  _RoleOption('registered_user', 'Registered User',Color(0xFF3B82F6)),
  _RoleOption('guest',           'Guest',          _kDim),
];

/// Maps legacy / variant Supabase role strings to the canonical spec values.
String _canonicalRole(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'admin':                        return 'admin';
    case 'premium': case 'premium_user': return 'premium_user';
    case 'registered': case 'registered_user': return 'registered_user';
    case 'guest': case 'general':        return 'guest';
    default:                             return 'registered_user';
  }
}

String _roleLabel(String canonical) =>
    _kRoles.firstWhere((r) => r.value == canonical,
        orElse: () => _kRoles[2]).label;

Color _roleColor(String canonical) =>
    _kRoles.firstWhere((r) => r.value == canonical,
        orElse: () => _kRoles[2]).color;

IconData _roleIcon(String canonical) {
  switch (canonical) {
    case 'admin':           return Icons.admin_panel_settings_rounded;
    case 'premium_user':    return Icons.workspace_premium_rounded;
    case 'registered_user': return Icons.person_rounded;
    case 'guest':           return Icons.person_outline_rounded;
    default:                return Icons.person_outline_rounded;
  }
}

// ── Date formatter ────────────────────────────────────────────────────────────

String _fmtDate(DateTime? dt) {
  if (dt == null) return '—';
  const m = ['Jan','Feb','Mar','Apr','May','Jun',
              'Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _searchCtrl = TextEditingController();
  String  _search     = '';
  String? _roleFilter;          // null = All
  bool    _loading    = true;
  String? _error;
  List<_UserRow> _users = [];
  RealtimeChannel? _channel;

  String? get _currentUid => Supabase.instance.client.auth.currentUser?.id;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _startRealtime();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  // ── Supabase ───────────────────────────────────────────────────────────────

  Future<void> _loadUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('id, username, email, role, is_suspended, city, created_at')
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

  void _startRealtime() {
    _channel = Supabase.instance.client
        .channel('admin_users_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (_) => _loadUsers(),
        )
        .subscribe();
  }

  Future<void> _setSuspended(_UserRow user, bool suspended) async {
    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx < 0) return;
    setState(() => _users[idx] = user.copyWith(isSuspended: suspended));
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'is_suspended': suspended}).eq('id', user.id);
      _snack(suspended
          ? '${user.displayName} suspended'
          : '${user.displayName} reactivated');
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
      _snack('Role updated to ${_roleLabel(newRole)}');
    } catch (e) {
      setState(() => _users[idx] = user);
      _snack('Update failed: $e');
    }
  }

  Future<void> _confirmRoleChange(_UserRow user, String newRole) async {
    final oldLabel = _roleLabel(_canonicalRole(user.role));
    final newLabel = _roleLabel(newRole);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Role?',
            style: TextStyle(color: _kText, fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Text(
          'Change ${user.email}\nfrom $oldLabel → $newLabel?',
          style: const TextStyle(color: _kSub, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: _kSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm',
                style: TextStyle(
                    color: _kGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _setRole(user, newRole);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: _kCard));
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<_UserRow> get _filtered {
    var list = _users;

    // Role chip filter
    if (_roleFilter != null) {
      list = list.where((u) => _canonicalRole(u.role) == _roleFilter).toList();
    }

    // Search filter (email, username, ID)
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((u) =>
        u.email.toLowerCase().contains(q) ||
        u.username.toLowerCase().contains(q) ||
        u.id.toLowerCase().contains(q)).toList();
  }

  int get _activeCount => _users.where((u) => !u.isSuspended).length;

  // ── Bottom-sheet actions (suspend / unsuspend) ─────────────────────────────

  void _showActions(_UserRow user) {
    final canonical = _canonicalRole(user.role);

    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),

            // ── User info header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _Avatar(initials: user.initials, suspended: user.isSuspended),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email.isNotEmpty ? user.email : user.displayName,
                          style: const TextStyle(
                              color: _kText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _RoleBadge(
                            canonical: canonical,
                            suspended: user.isSuspended),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: _kBorder),

            // ── Change Role section ────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CHANGE ROLE',
                  style: TextStyle(
                      color: _kDim,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),

            ..._kRoles.map((r) {
              final isCurrent = r.value == canonical;
              return ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                leading: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: r.color.withOpacity(isCurrent ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCurrent ? Icons.check_rounded : _roleIcon(r.value),
                    color: r.color,
                    size: 15,
                  ),
                ),
                title: Text(
                  r.label,
                  style: TextStyle(
                    color: isCurrent ? r.color : _kText,
                    fontSize: 13,
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: isCurrent
                    ? const Text('Current',
                        style: TextStyle(color: _kDim, fontSize: 11))
                    : const Icon(Icons.chevron_right_rounded,
                        color: _kDim, size: 16),
                onTap: isCurrent
                    ? null
                    : () {
                        Navigator.pop(sheetCtx);
                        _confirmRoleChange(user, r.value);
                      },
              );
            }),

            const Divider(height: 1, color: _kBorder),

            // ── Suspend / Reactivate ───────────────────────────────────
            if (!user.isSuspended && canonical != 'admin')
              _SheetTile(
                icon: Icons.block_rounded,
                label: 'Suspend User',
                color: _kRed,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _setSuspended(user, true);
                },
              )
            else if (user.isSuspended)
              _SheetTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Reactivate Account',
                color: _kGreen,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _setSuspended(user, false);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _SimpleHeader(
              title: 'User Management',
              statusText: '$_activeCount active'),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _kGreen))
                : _error != null
                    ? _RetryView(message: _error!, onRetry: _loadUsers)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          // ── Search bar ─────────────────────────────────────
                          _SearchBar(
                            controller: _searchCtrl,
                            hint: 'Search by email, name or ID…',
                            onChanged: (v) =>
                                setState(() => _search = v),
                          ),
                          const SizedBox(height: 12),

                          // ── Role filter chips ──────────────────────────────
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'All',
                                  color: _kGreen,
                                  selected: _roleFilter == null,
                                  onTap: () => setState(
                                      () => _roleFilter = null),
                                ),
                                const SizedBox(width: 8),
                                ..._kRoles.map((r) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: _FilterChip(
                                        label: r.label,
                                        color: r.color,
                                        selected: _roleFilter == r.value,
                                        onTap: () => setState(
                                            () => _roleFilter = r.value),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── User directory ─────────────────────────────────
                          _UserDirectoryCard(
                            users: _filtered,
                            activeCount: _activeCount,
                            currentUid: _currentUid ?? '',
                            onActionTap: _showActions,
                            onRoleChange: _confirmRoleChange,
                          ),
                        ],
                      ),
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
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : _kCard,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? color.withOpacity(0.5) : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : _kSub,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── User directory card ───────────────────────────────────────────────────────

class _UserDirectoryCard extends StatelessWidget {
  const _UserDirectoryCard({
    required this.users,
    required this.activeCount,
    required this.currentUid,
    required this.onActionTap,
    required this.onRoleChange,
  });
  final List<_UserRow> users;
  final int activeCount;
  final String currentUid;
  final ValueChanged<_UserRow> onActionTap;
  final void Function(_UserRow, String) onRoleChange;

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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Text('User Directory',
                    style: TextStyle(
                        color: _kText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${users.length} shown',
                    style: const TextStyle(color: _kSub, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          if (users.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No users found',
                  style: TextStyle(color: _kSub)),
            )
          else
            ...List.generate(
              users.length,
              (i) => Column(
                children: [
                  _UserTile(
                    user: users[i],
                    isOwnRow: users[i].id == currentUid,
                    onActionTap: onActionTap,
                    onRoleChange: onRoleChange,
                  ),
                  if (i < users.length - 1)
                    const Divider(height: 1, indent: 68, color: _kBorder),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── User tile ─────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.isOwnRow,
    required this.onActionTap,
    required this.onRoleChange,
  });
  final _UserRow user;
  final bool isOwnRow;
  final ValueChanged<_UserRow> onActionTap;
  final void Function(_UserRow, String) onRoleChange;

  @override
  Widget build(BuildContext context) {
    final canonical = _canonicalRole(user.role);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          _Avatar(initials: user.initials, suspended: user.isSuspended),
          const SizedBox(width: 12),

          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email
                Text(
                  user.email.isNotEmpty ? user.email : user.displayName,
                  style: TextStyle(
                    color: user.isSuspended ? _kSub : _kText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                // Created date + role badge
                Row(
                  children: [
                    Text(
                      'Joined ${_fmtDate(user.createdAt)}',
                      style: const TextStyle(
                          color: _kDim, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    _RoleBadge(
                        canonical: canonical,
                        suspended: user.isSuspended),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Role DropdownButton
          Tooltip(
            message: isOwnRow ? 'Cannot change your own role' : '',
            child: Opacity(
              opacity: isOwnRow ? 0.35 : 1.0,
              child: IgnorePointer(
                ignoring: isOwnRow,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBorder),
                  ),
                  child: DropdownButton<String>(
                    value: canonical,
                    dropdownColor: _kCard,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    icon: const Icon(Icons.expand_more_rounded,
                        color: _kSub, size: 14),
                    style: const TextStyle(
                        color: _kText, fontSize: 11),
                    items: _kRoles.map((r) => DropdownMenuItem(
                          value: r.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                    color: r.color,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(r.label,
                                  style: TextStyle(
                                      color: r.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )).toList(),
                    onChanged: (newRole) {
                      if (newRole != null && newRole != canonical) {
                        onRoleChange(user, newRole);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Three-dots menu (suspend / reactivate)
          if (!isOwnRow)
            GestureDetector(
              onTap: () => onActionTap(user),
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.more_vert_rounded,
                    color: _kSub, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

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
  const _RoleBadge({required this.canonical, required this.suspended});
  final String canonical;
  final bool suspended;

  @override
  Widget build(BuildContext context) {
    if (suspended) {
      return _badge(_kOrange, 'Suspended');
    }
    final color = _roleColor(canonical);
    final label = _roleLabel(canonical);
    return _badge(color, label);
  }

  Widget _badge(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 5, height: 5,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Shared reusable widgets ───────────────────────────────────────────────────

class _SimpleHeader extends StatelessWidget {
  const _SimpleHeader({required this.title, this.statusText});
  final String title;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  color: _kText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
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
          prefixIcon: const Icon(Icons.search_rounded,
              color: _kDim, size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14),
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
          style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
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
            child: const Text('Try Again',
                style: TextStyle(color: _kGreen)),
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
    this.createdAt,
  });

  final String id;
  final String username;
  final String email;
  final String role;
  final bool isSuspended;
  final String? city;
  final DateTime? createdAt;

  factory _UserRow.fromMap(Map<String, dynamic> m) {
    DateTime? createdAt;
    final raw = m['created_at'];
    if (raw is String) createdAt = DateTime.tryParse(raw)?.toLocal();

    return _UserRow(
      id:          m['id']?.toString() ?? '',
      username:    m['username']?.toString() ?? '',
      email:       m['email']?.toString() ?? '',
      role:        m['role']?.toString() ?? 'registered_user',
      isSuspended: m['is_suspended'] as bool? ?? false,
      city:        m['city']?.toString(),
      createdAt:   createdAt,
    );
  }

  _UserRow copyWith({String? role, bool? isSuspended}) => _UserRow(
        id: id, username: username, email: email,
        city: city, createdAt: createdAt,
        role:        role        ?? this.role,
        isSuspended: isSuspended ?? this.isSuspended,
      );

  String get displayName =>
      username.isNotEmpty ? username : email.split('@').first;

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName
        .substring(0, displayName.length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  String get shortId =>
      id.length > 5 ? id.substring(0, 5).toUpperCase() : id.toUpperCase();
}
