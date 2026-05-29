import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hazard_report_model.dart';
import '../providers/report_provider.dart';

// ── Admin palette ─────────────────────────────────────────────────────────────
const _kCard   = Color(0xFF111111);
const _kBorder = Color(0xFF1F1F1F);
const _kGreen  = Color(0xFF4ADE80);
const _kRed    = Color(0xFFEF4444);
const _kText   = Colors.white;
const _kSub    = Color(0xFF9CA3AF);
const _kDim    = Color(0xFF4B5563);

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  String _filter = 'all';

  List<HazardReportModel> _applyFilter(List<HazardReportModel> all) {
    switch (_filter) {
      case 'pending':
        return all.where((r) => r.status == ReportStatus.pending).toList();
      case 'resolved':
        return all.where((r) => r.status == ReportStatus.resolved).toList();
      case 'approved':
        return all.where((r) => r.status == ReportStatus.approved).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReportProvider>();
    final filtered = _applyFilter(rp.reports);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportsHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const SizedBox(height: 20),
                const Text('Reports',
                    style: TextStyle(
                        color: _kText,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  'Monitor and manage environmental anomaly reports across all sensor networks. '
                  'Review high-priority incidents flagged by the AI detection protocol.',
                  style: TextStyle(color: _kSub, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 20),
                _FilterChips(
                  current: _filter,
                  onSelect: (f) => setState(() => _filter = f),
                ),
                const SizedBox(height: 20),
                if (rp.isLoading)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(color: _kGreen),
                  ))
                else if (filtered.isEmpty)
                  _EmptyReports(filter: _filter)
                else
                  ...filtered.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ReportCard(report: r),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reports header ────────────────────────────────────────────────────────────

class _ReportsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          const Text('EcoAlert Admin',
              style: TextStyle(
                  color: _kText, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          Icon(Icons.menu_rounded, color: _kSub, size: 22),
        ],
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.current, required this.onSelect});
  final String current;
  final ValueChanged<String> onSelect;

  static const _filters = [
    ('all', Icons.check_rounded, 'All Reports'),
    ('pending', Icons.pending_outlined, 'Pending'),
    ('resolved', Icons.check_circle_outline_rounded, 'Resolved'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final selected = current == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _kGreen.withOpacity(0.15) : _kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected ? _kGreen.withOpacity(0.5) : _kBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f.$2,
                        size: 13,
                        color: selected ? _kGreen : _kSub),
                    const SizedBox(width: 6),
                    Text(f.$3,
                        style: TextStyle(
                            color: selected ? _kGreen : _kSub,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Report card ───────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final HazardReportModel report;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  _BadgeStyle _badge() {
    switch (report.status) {
      case ReportStatus.pending:
        return _BadgeStyle('Pending', _kSub, const Color(0xFF1C1C1C));
      case ReportStatus.approved:
        final isCritical = report.aqi > 150 ||
            report.hazardType.toLowerCase().contains('flood') ||
            report.hazardType.toLowerCase().contains('fire');
        return isCritical
            ? _BadgeStyle('Critical', _kRed, _kRed.withOpacity(0.15))
            : _BadgeStyle('Normal', _kGreen, _kGreen.withOpacity(0.1));
      case ReportStatus.rejected:
        return _BadgeStyle('Rejected', _kRed, _kRed.withOpacity(0.1));
      case ReportStatus.resolved:
        return _BadgeStyle('Resolved', _kSub, const Color(0xFF1C1C1C), outlined: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge();
    final hasImage = report.imageUrls.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image area
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Image.network(
                    report.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ImagePlaceholder(
                        hazardType: report.hazardType),
                  )
                else
                  _ImagePlaceholder(hazardType: report.hazardType),
                // subtle dark overlay for text readability
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x80000000)],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Content area
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        report.hazardType,
                        style: const TextStyle(
                            color: _kText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(style: badge),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  report.details,
                  style: const TextStyle(
                      color: _kSub, fontSize: 13, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: _kDim, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.locationLabel,
                        style: const TextStyle(color: _kDim, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.access_time_rounded,
                        color: _kDim, size: 13),
                    const SizedBox(width: 4),
                    Text(_timeAgo(report.createdAt),
                        style: const TextStyle(color: _kDim, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle(this.label, this.color, this.bg,
      {this.outlined = false});
  final String label;
  final Color color;
  final Color bg;
  final bool outlined;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.style});
  final _BadgeStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.outlined ? Colors.transparent : style.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: style.outlined ? style.color.withOpacity(0.5) : style.bg),
      ),
      child: Text(
        style.label,
        style: TextStyle(
            color: style.color,
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.hazardType});
  final String hazardType;

  IconData _icon() {
    final t = hazardType.toLowerCase();
    if (t.contains('flood') || t.contains('water')) return Icons.water_rounded;
    if (t.contains('air') || t.contains('aqi') || t.contains('smog')) {
      return Icons.air_rounded;
    }
    if (t.contains('fire')) return Icons.local_fire_department_rounded;
    if (t.contains('heat')) return Icons.thermostat_rounded;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Icon(_icon(), color: const Color(0xFF333333), size: 48),
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports({required this.filter});
  final String filter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.flag_outlined, color: _kDim, size: 40),
          const SizedBox(height: 12),
          Text(
            filter == 'all'
                ? 'No reports yet'
                : 'No $filter reports',
            style: const TextStyle(color: _kSub, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
