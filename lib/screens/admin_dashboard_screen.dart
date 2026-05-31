import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/hazard_report_model.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import 'admin_report_management_screen.dart';
import 'admin_system_settings_screen.dart';
import 'admin_user_management_screen.dart';

// ── Shared admin palette ──────────────────────────────────────────────────────
const _kBg     = Color(0xFF000000);
const _kCard   = Color(0xFF111111);
const _kBorder = Color(0xFF1F1F1F);
const _kGreen  = Color(0xFF4ADE80);
const _kRed    = Color(0xFFEF4444);
const _kOrange = Color(0xFFF97316);
const _kText   = Colors.white;
const _kSub    = Color(0xFF9CA3AF);
const _kDim    = Color(0xFF4B5563);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tab = 0;
  bool _backendOnline = false;
  bool _checkingBackend = true;

  @override
  void initState() {
    super.initState();
    _checkHealth();
    // Hassaan: please also gate the admin route in main.dart as a second
    // layer of protection (e.g. check role before pushing '/admin').
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifyAdminAccess());
  }

  Future<void> _verifyAdminAccess() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) { _redirectUnauthorized(); return; }

    bool isAdmin = context.read<AuthProvider>().isAdmin;

    // Re-verify against Supabase for an authoritative check, in case the
    // cached role is stale.
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      final role = row?['role'] as String? ?? '';
      isAdmin = role == 'admin';
    } catch (_) {
      // On network error fall back to the cached AuthProvider role.
    }

    if (!isAdmin && mounted) _redirectUnauthorized();
  }

  void _redirectUnauthorized() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/navigation');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Unauthorized access'),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _checkHealth() async {
    setState(() => _checkingBackend = true);
    try {
      final res = await http
          .get(Uri.parse('${AppConfig.uploadApiBaseUrl}/health'))
          .timeout(const Duration(seconds: 8));
      if (mounted) setState(() => _backendOnline = res.statusCode == 200);
    } catch (_) {
      if (mounted) setState(() => _backendOnline = false);
    } finally {
      if (mounted) setState(() => _checkingBackend = false);
    }
  }

  static const _icons = [
    Icons.grid_view_rounded,
    Icons.person_outline_rounded,
    Icons.flag_outlined,
    Icons.settings_outlined,
  ];
  static const _labels = ['Dashboard', 'Users', 'Reports', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: _kBg,
      body: IndexedStack(
        index: _tab,
        children: [
          _DashboardTab(
            backendOnline: _backendOnline,
            checkingBackend: _checkingBackend,
            onRefreshHealth: _checkHealth,
            onViewAllReports: () => setState(() => _tab = 2),
          ),
          const AdminUsersTab(),
          const AdminReportsTab(),
          AdminSettingsTab(auth: auth),
        ],
      ),
      bottomNavigationBar: _AdminNav(
        current: _tab,
        icons: _icons,
        labels: _labels,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _AdminNav extends StatelessWidget {
  const _AdminNav({
    required this.current,
    required this.icons,
    required this.labels,
    required this.onTap,
  });
  final int current;
  final List<IconData> icons;
  final List<String> labels;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _kBorder, width: 0.5)),
          ),
          child: Row(
            children: List.generate(icons.length, (i) {
              final selected = i == current;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[i],
                          size: 22,
                          color: selected ? _kGreen : Colors.white54),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? _kGreen : Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2,
                        width: selected ? 28 : 0,
                        decoration: BoxDecoration(
                          color: _kGreen,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  const _DashboardTab({
    required this.backendOnline,
    required this.checkingBackend,
    required this.onRefreshHealth,
    required this.onViewAllReports,
  });
  final bool backendOnline;
  final bool checkingBackend;
  final VoidCallback onRefreshHealth;
  final VoidCallback onViewAllReports;

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  // ── Summary stat state ────────────────────────────────────────────────────
  int _userCount    = 0;
  int _reportCount  = 0;
  int _postCount    = 0;
  bool _statsLoading = true;
  String? _statsError;

  RealtimeChannel? _usersChannel;
  RealtimeChannel? _reportsChannel;
  RealtimeChannel? _postsChannel;

  SupabaseClient get _db => Supabase.instance.client;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _startStatStreams();
  }

  @override
  void dispose() {
    _usersChannel?.unsubscribe();
    _reportsChannel?.unsubscribe();
    _postsChannel?.unsubscribe();
    super.dispose();
  }

  // ── Supabase ───────────────────────────────────────────────────────────────

  Future<void> _fetchStats() async {
    setState(() { _statsLoading = true; _statsError = null; });
    try {
      final results = await Future.wait([
        _db.from('profiles').select('id'),
        _db.from('reports').select('id'),
        _db.from('community_posts').select('id'),
      ]);
      if (mounted) {
        setState(() {
          _userCount   = (results[0] as List).length;
          _reportCount = (results[1] as List).length;
          _postCount   = (results[2] as List).length;
          _statsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminDashboard] stats fetch error: $e');
      if (mounted) setState(() { _statsLoading = false; _statsError = 'Failed'; });
    }
  }

  void _startStatStreams() {
    // Re-fetch all counts whenever any relevant table changes.
    _usersChannel = _db.channel('admin_stat_users')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (_) => _fetchStats(),
        )
        .subscribe();

    _reportsChannel = _db.channel('admin_stat_reports')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reports',
          callback: (_) => _fetchStats(),
        )
        .subscribe();

    _postsChannel = _db.channel('admin_stat_posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_posts',
          callback: (_) => _fetchStats(),
        )
        .subscribe();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportProvider>();
    final pending = reports.pendingReports.take(3).toList();

    return SafeArea(
      child: Column(
        children: [
          _AdminHeader(
            backendOnline: widget.backendOnline,
            checkingBackend: widget.checkingBackend,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // ── Stat cards ───────────────────────────────────────────
                _StatsRow(
                  userCount:    _userCount,
                  reportCount:  _reportCount,
                  postCount:    _postCount,
                  loading:      _statsLoading,
                  error:        _statsError,
                  onRetry:      _fetchStats,
                ),
                const SizedBox(height: 16),

                // ── Reports-per-day chart ────────────────────────────────
                _ReportsChartCard(
                  backendOnline: widget.backendOnline,
                  onRefresh:     widget.onRefreshHealth,
                ),
                const SizedBox(height: 28),

                // ── Pending reports list ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pending Reports',
                        style: TextStyle(
                            color: _kText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: widget.onViewAllReports,
                      child: const Text('View All',
                          style: TextStyle(color: _kSub, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (reports.isLoading)
                  const Center(
                      child: CircularProgressIndicator(color: _kGreen))
                else if (pending.isEmpty)
                  _EmptyState(
                    icon: Icons.check_circle_outline_rounded,
                    message: 'No pending reports',
                  )
                else
                  ...pending.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PendingReportCard(report: r),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary stat cards row ────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.userCount,
    required this.reportCount,
    required this.postCount,
    required this.loading,
    required this.onRetry,
    this.error,
  });

  final int userCount;
  final int reportCount;
  final int postCount;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          icon: Icons.person_outline_rounded,
          label: 'Users',
          value: loading ? '—' : (error != null ? '!' : _fmt(userCount)),
          color: _kGreen,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon: Icons.flag_outlined,
          label: 'Reports',
          value: loading ? '—' : (error != null ? '!' : _fmt(reportCount)),
          color: _kOrange,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon: Icons.people_outline_rounded,
          label: 'Posts',
          value: loading ? '—' : (error != null ? '!' : _fmt(postCount)),
          color: const Color(0xFF60A5FA),
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: _kText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: _kSub, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Shared admin header ───────────────────────────────────────────────────────

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    this.backendOnline,
    this.checkingBackend,
  });
  final bool? backendOnline;
  final bool? checkingBackend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          const Text(
            'EcoAlert Admin',
            style: TextStyle(
                color: _kText, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/navigation'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kBorder),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_android_rounded, color: _kSub, size: 13),
                  SizedBox(width: 5),
                  Text('User App',
                      style: TextStyle(color: _kSub, fontSize: 12)),
                ],
              ),
            ),
          ),
          if (backendOnline != null)
            _StatusPill(
              online: backendOnline!,
              checking: checkingBackend ?? false,
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.online, required this.checking});
  final bool online;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final color = checking ? _kSub : (online ? _kGreen : _kRed);
    final label = checking ? 'Checking…' : (online ? 'System Online' : 'System Offline');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Reports-per-day chart card ────────────────────────────────────────────────
// Replaces the former "System API Load" card (which used fake sine-wave data).
// Now shows real reports submitted per day for the last 7 days from Supabase.
// Chart library: fl_chart — LineChart / FlSpot (unchanged styling).

class _ReportsChartCard extends StatefulWidget {
  const _ReportsChartCard({
    required this.backendOnline,
    required this.onRefresh,
  });
  final bool backendOnline;
  final VoidCallback onRefresh;

  @override
  State<_ReportsChartCard> createState() => _ReportsChartCardState();
}

class _ReportsChartCardState extends State<_ReportsChartCard> {
  List<FlSpot> _spots = [];
  bool _isLoading = true;
  String? _errorMessage;
  RealtimeChannel? _channel;

  SupabaseClient get _db => Supabase.instance.client;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  // ── Data fetching ──────────────────────────────────────────────────────────

  /// Fetches reports from the last 7 days, groups by calendar date in Dart,
  /// and maps the result to FlSpot (x = day index 0–6, y = daily count).
  Future<void> _fetchData() async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));

      final data = await _db
          .from('reports')
          .select('created_at')
          .gte('created_at', cutoff.toIso8601String())
          .order('created_at', ascending: true);

      // Build a map: 'YYYY-MM-DD' → count, pre-filled with zeros for all 7 days.
      final Map<String, int> byDay = {};
      for (var i = 6; i >= 0; i--) {
        final d = DateTime.now().subtract(Duration(days: i));
        byDay[_dateKey(d)] = 0;
      }

      for (final row in (data as List)) {
        final raw = row['created_at'] as String?;
        final dt  = raw != null ? DateTime.tryParse(raw) : null;
        if (dt != null) {
          final k = _dateKey(dt.toLocal());
          if (byDay.containsKey(k)) byDay[k] = byDay[k]! + 1;
        }
      }

      // Oldest day → x=0, today → x=6 (matches the sorted insertion order).
      final entries = byDay.entries.toList();
      final spots = <FlSpot>[];
      for (var i = 0; i < entries.length; i++) {
        spots.add(FlSpot(i.toDouble(), entries[i].value.toDouble()));
      }

      if (mounted) setState(() { _spots = spots; _isLoading = false; });
    } catch (e) {
      debugPrint('[AdminDashboard] chart fetch error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load chart data';
          _isLoading    = false;
        });
      }
    }
  }

  void _startRealtime() {
    _channel = _db
        .channel('admin_chart_reports')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reports',
          callback: (_) => _fetchData(),
        )
        .subscribe();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Helpers ────────────────────────────────────────────────────────────────

  int get _totalThisWeek =>
      _spots.fold(0, (s, p) => s + p.y.toInt());

  /// Dynamic Y ceiling: at least 5, 25 % headroom above max.
  double get _maxY {
    if (_spots.isEmpty) return 5;
    final peak = _spots.map((s) => s.y).reduce(math.max);
    return math.max(peak * 1.25, 5).ceilToDouble();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reports This Week',
                      style: TextStyle(
                          color: _kText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'New submissions / day',
                      style: TextStyle(color: _kSub, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Big number: total reports in the last 7 days
              if (_isLoading)
                const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                      color: _kGreen, strokeWidth: 2),
                )
              else
                Text(
                  '$_totalThisWeek',
                  style: const TextStyle(
                      color: _kText,
                      fontSize: 36,
                      fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Chart / loading / error ────────────────────────────────────
          SizedBox(
            height: 100,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _kGreen, strokeWidth: 2))
                : _errorMessage != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_errorMessage!,
                              style: const TextStyle(
                                  color: _kSub, fontSize: 12)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _fetchData,
                            child: const Text(
                              'Retry',
                              style: TextStyle(
                                  color: _kGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: math.max(_maxY / 4, 1),
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: Colors.white.withOpacity(0.05),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minY: 0,
                          maxY: _maxY,
                          lineBarsData: [
                            LineChartBarData(
                              // Same styling as the previous fake-data chart
                              spots: _spots.isEmpty
                                  ? [const FlSpot(0, 0)]
                                  : _spots,
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: Colors.white,
                              barWidth: 2,
                              dotData: FlDotData(
                                show: true,
                                checkToShowDot: (spot, _) =>
                                    _spots.isNotEmpty &&
                                    spot.x == _spots.last.x,
                                getDotPainter: (_, __, ___, ____) =>
                                    FlDotCirclePainter(
                                  radius: 5,
                                  color: _kGreen,
                                  strokeWidth: 0,
                                ),
                              ),
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Pending report card ───────────────────────────────────────────────────────

class _PendingReportCard extends StatelessWidget {
  const _PendingReportCard({required this.report});
  final HazardReportModel report;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  bool get _isCritical {
    final t = report.hazardType.toLowerCase();
    return t.contains('flood') || t.contains('air') ||
        report.aqi > 150 || t.contains('fire') || t.contains('seismic');
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.read<ReportProvider>();
    final critical = _isCritical;
    final severityColor = critical ? _kOrange : _kGreen;
    final severityIcon = critical ? Icons.warning_amber_rounded : Icons.info_outline_rounded;
    final severityLabel = critical ? 'Critical' : 'Notice';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(severityIcon, color: severityColor, size: 14),
              const SizedBox(width: 5),
              Text(severityLabel,
                  style: TextStyle(
                      color: severityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(_timeAgo(report.createdAt),
                  style: const TextStyle(color: _kSub, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report.hazardType,
            style: const TextStyle(
                color: _kText, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${report.locationLabel} — ${report.details}',
            style: const TextStyle(color: _kSub, fontSize: 13, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: 'Approve',
                  filled: true,
                  onTap: () => rp.approve(report.id),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionBtn(
                  label: 'Reject',
                  filled: false,
                  onTap: () => rp.reject(report.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: filled ? null : Border.all(color: _kBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: filled ? Colors.black : _kText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared empty state ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, color: _kDim, size: 40),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: _kSub, fontSize: 14)),
        ],
      ),
    );
  }
}
