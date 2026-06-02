import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kCard   = Color(0xFF111111);
const _kBorder = Color(0xFF1F1F1F);
const _kGreen  = Color(0xFF4ADE80);
const _kText   = Colors.white;
const _kSub    = Color(0xFF9CA3AF);
const _kDim    = Color(0xFF4B5563);
const _kOrange = Color(0xFFF97316);

// ── Role definitions ──────────────────────────────────────────────────────────
class _Role {
  const _Role(this.value, this.label, this.color, this.icon);
  final String value;
  final String label;
  final Color  color;
  final IconData icon;
}

const _kRoles = [
  _Role('admin',           'Admin',      Color(0xFFEF4444), Icons.admin_panel_settings_rounded),
  _Role('premium_user',    'Premium',    Color(0xFFFBBF24), Icons.workspace_premium_rounded),
  _Role('registered_user', 'Registered', Color(0xFF3B82F6), Icons.person_rounded),
  _Role('guest',           'Guest',      _kDim,             Icons.person_outline_rounded),
];

String _canonicalRole(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'admin':                              return 'admin';
    case 'premium': case 'premium_user':       return 'premium_user';
    case 'registered': case 'registered_user': return 'registered_user';
    case 'guest': case 'general':              return 'guest';
    default:                                   return 'registered_user';
  }
}

_Role _roleInfo(String canonical) =>
    _kRoles.firstWhere((r) => r.value == canonical, orElse: () => _kRoles[2]);

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
  String? _roleFilter;
  bool    _loading    = true;
  String? _error;
  List<_UserRow> _users = [];
  RealtimeChannel? _channel;

  int get _totalCount  => _users.length;

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

  // ── Data ───────────────────────────────────────────────────────────────────
  Future<void> _loadUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('id, username, email, role, is_suspended, city, created_at')
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _users   = (rows as List).map((r) => _UserRow.fromMap(r as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (e.code == '42703') {
        await _loadUsersBasic();
      } else {
        if (!mounted) return;
        setState(() { _error = e.message; _loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadUsersBasic() async {
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('id, username, email, role, city, created_at')
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _users   = (rows as List).map((r) => _UserRow.fromMap(r as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _startRealtime() {
    _channel = Supabase.instance.client
        .channel('admin_users_view')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (payload) {
            final record = payload.newRecord;
            final id = record['id']?.toString();
            if (id != null && record.isNotEmpty && mounted) {
              final idx = _users.indexWhere((u) => u.id == id);
              if (idx >= 0) {
                setState(() => _users[idx] = _UserRow.fromMap(record));
                return;
              }
            }
            _loadUsers();
          },
        )
        .subscribe();
  }

  // ── Filtering ──────────────────────────────────────────────────────────────
  List<_UserRow> get _filtered {
    var list = _users;
    if (_roleFilter != null) {
      list = list.where((u) => _canonicalRole(u.role) == _roleFilter).toList();
    }
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((u) =>
        u.email.toLowerCase().contains(q) ||
        u.username.toLowerCase().contains(q)).toList();
  }

  // ── User detail bottom sheet (read-only) ───────────────────────────────────
  void _showDetail(_UserRow user) {
    final canonical = _canonicalRole(user.role);
    final role      = _roleInfo(canonical);

    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Avatar + name
              Row(
                children: [
                  _AvatarWidget(initials: user.initials, suspended: user.isSuspended),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName,
                            style: const TextStyle(color: _kText, fontSize: 16,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(user.email,
                            style: const TextStyle(color: _kSub, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: _kBorder, height: 1),
              const SizedBox(height: 20),

              // Detail rows
              _DetailRow(icon: role.icon,         iconColor: role.color,
                          label: 'Role',           value: role.label,      valueColor: role.color),
              const SizedBox(height: 14),
              _DetailRow(icon: Icons.location_on_outlined, iconColor: _kSub,
                          label: 'City',           value: user.city?.isNotEmpty == true ? user.city! : '—'),
              const SizedBox(height: 14),
              _DetailRow(icon: Icons.calendar_today_outlined, iconColor: _kSub,
                          label: 'Joined',         value: _fmtDate(user.createdAt)),
              const SizedBox(height: 14),
              _DetailRow(icon: Icons.fingerprint,  iconColor: _kSub,
                          label: 'User ID',        value: user.id,         mono: true),

              if (user.isSuspended) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kOrange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kOrange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.block_rounded, color: _kOrange, size: 16),
                      SizedBox(width: 8),
                      Text('This account is currently suspended',
                          style: TextStyle(color: _kOrange, fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _kBorder, width: 0.5))),
            child: Row(
              children: [
                const Text('Users',
                    style: TextStyle(color: _kText, fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('$_totalCount registered',
                    style: const TextStyle(color: _kSub, fontSize: 13)),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kGreen))
                : _error != null
                    ? _RetryView(message: _error!, onRetry: _loadUsers)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          // Search bar
                          Container(
                            decoration: BoxDecoration(
                              color: _kCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _kBorder),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) => setState(() => _search = v),
                              style: const TextStyle(color: _kText, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Search by name or email…',
                                hintStyle: TextStyle(color: _kDim, fontSize: 14),
                                prefixIcon: Icon(Icons.search_rounded, color: _kDim, size: 18),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Role filter chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterPill(label: 'All', color: _kGreen,
                                    selected: _roleFilter == null,
                                    onTap: () => setState(() => _roleFilter = null)),
                                const SizedBox(width: 8),
                                ..._kRoles.map((r) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _FilterPill(label: r.label, color: r.color,
                                      selected: _roleFilter == r.value,
                                      onTap: () => setState(() => _roleFilter = r.value)),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Stats row
                          Row(
                            children: _kRoles.map((r) {
                              final count = _users
                                  .where((u) => _canonicalRole(u.role) == r.value)
                                  .length;
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: r.color.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: r.color.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text('$count',
                                          style: TextStyle(color: r.color, fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(r.label,
                                          style: const TextStyle(color: _kDim, fontSize: 9)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // User list
                          if (_filtered.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('No users found',
                                  style: TextStyle(color: _kSub))),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: _kCard,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _kBorder),
                              ),
                              child: Column(
                                children: List.generate(_filtered.length, (i) => Column(
                                  children: [
                                    _UserTile(
                                      user: _filtered[i],
                                      onTap: () => _showDetail(_filtered[i]),
                                    ),
                                    if (i < _filtered.length - 1)
                                      const Divider(height: 1, indent: 68, color: _kBorder),
                                  ],
                                )),
                              ),
                            ),
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
  const _UserTile({required this.user, required this.onTap});
  final _UserRow user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canonical = _canonicalRole(user.role);
    final role      = _roleInfo(canonical);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _AvatarWidget(initials: user.initials, suspended: user.isSuspended),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.email.isNotEmpty ? user.email : user.displayName,
                    style: TextStyle(
                      color: user.isSuspended ? _kSub : _kText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _RolePill(canonical: canonical, suspended: user.isSuspended),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          user.city?.isNotEmpty == true
                              ? user.city!
                              : _fmtDate(user.createdAt),
                          style: const TextStyle(color: _kDim, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(role.icon, color: role.color.withOpacity(0.7), size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Detail row widget ─────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.mono = false,
  });
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   value;
  final Color?   valueColor;
  final bool     mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(label,
              style: const TextStyle(color: _kSub, fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                color: valueColor ?? _kText,
                fontSize: mono ? 11 : 13,
                fontWeight: FontWeight.w500,
                fontFamily: mono ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({required this.initials, required this.suspended});
  final String initials;
  final bool   suspended;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: suspended ? _kBorder : const Color(0xFF2A2A2A),
        shape: BoxShape.circle,
        border: Border.all(color: _kBorder),
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(
                color: suspended ? _kDim : _kText,
                fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.canonical, required this.suspended});
  final String canonical;
  final bool   suspended;

  @override
  Widget build(BuildContext context) {
    if (suspended) return _pill(_kOrange, 'Suspended');
    final r = _roleInfo(canonical);
    return _pill(r.color, r.label);
  }

  Widget _pill(Color color, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.color,
      required this.selected, required this.onTap});
  final String   label;
  final Color    color;
  final bool     selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : _kCard,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
              color: selected ? color.withOpacity(0.5) : _kBorder,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : _kSub,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ),
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
    this.createdAt,
  });

  final String    id, username, email, role;
  final bool      isSuspended;
  final String?   city;
  final DateTime? createdAt;

  factory _UserRow.fromMap(Map<String, dynamic> m) {
    DateTime? dt;
    final raw = m['created_at'];
    if (raw is String) dt = DateTime.tryParse(raw)?.toLocal();
    return _UserRow(
      id:          m['id']?.toString() ?? '',
      username:    m['username']?.toString() ?? '',
      email:       m['email']?.toString() ?? '',
      role:        m['role']?.toString() ?? 'registered_user',
      isSuspended: m['is_suspended'] as bool? ?? false,
      city:        m['city']?.toString(),
      createdAt:   dt,
    );
  }

  String get displayName =>
      username.isNotEmpty ? username : email.split('@').first;

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName.substring(0, displayName.length >= 2 ? 2 : 1).toUpperCase();
  }
}
