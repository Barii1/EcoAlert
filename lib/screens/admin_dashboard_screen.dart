import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

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

class _DashboardTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final reports = context.watch<ReportProvider>();
    final pending = reports.pendingReports.take(3).toList();

    return SafeArea(
      child: Column(
        children: [
          _AdminHeader(
            backendOnline: backendOnline,
            checkingBackend: checkingBackend,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _ApiLoadCard(backendOnline: backendOnline, onRefresh: onRefreshHealth),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pending Reports',
                        style: TextStyle(
                            color: _kText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: onViewAllReports,
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

// ── API load chart card ───────────────────────────────────────────────────────

class _ApiLoadCard extends StatefulWidget {
  const _ApiLoadCard({required this.backendOnline, required this.onRefresh});
  final bool backendOnline;
  final VoidCallback onRefresh;

  @override
  State<_ApiLoadCard> createState() => _ApiLoadCardState();
}

class _ApiLoadCardState extends State<_ApiLoadCard> {
  late final List<FlSpot> _spots;

  @override
  void initState() {
    super.initState();
    _spots = _generateSpots();
  }

  List<FlSpot> _generateSpots() {
    final rng = math.Random(7);
    return List.generate(20, (i) {
      final base = 5000 + 8000 * math.sin(i * math.pi / 14);
      final noise = (rng.nextDouble() - 0.5) * 3000;
      return FlSpot(i.toDouble(), (base + noise).clamp(1000, 16000));
    });
  }

  String _formatLoad(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final currentVal = _spots.last.y;
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('System API Load',
                        style: TextStyle(
                            color: _kText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    const Text('Requests / min',
                        style: TextStyle(color: _kSub, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                _formatLoad(currentVal),
                style: const TextStyle(
                    color: _kText, fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5000,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 18000,
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Colors.white,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) => spot.x == _spots.last.x,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
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
