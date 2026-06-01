import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hazard_report_model.dart';
import '../providers/report_provider.dart';

// ── Admin palette ─────────────────────────────────────────────────────────────
const _kCard   = Color(0xFF111111);
const _kBorder = Color(0xFF1F1F1F);
const _kGreen  = Color(0xFF4ADE80);
const _kRed    = Color(0xFFEF4444);
const _kOrange = Color(0xFFF97316);
const _kBlue   = Color(0xFF3B82F6);
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
      case 'approved':
        return all.where((r) => r.status == ReportStatus.approved).toList();
      case 'rejected':
        return all.where((r) => r.status == ReportStatus.rejected).toList();
      case 'resolved':
        return all.where((r) => r.status == ReportStatus.resolved).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReportProvider>();
    final all = rp.reports;
    final filtered = _applyFilter(all);

    final pendingCount  = all.where((r) => r.status == ReportStatus.pending).length;
    final approvedCount = all.where((r) => r.status == ReportStatus.approved).length;
    final rejectedCount = all.where((r) => r.status == ReportStatus.rejected).length;
    final resolvedCount = all.where((r) => r.status == ReportStatus.resolved).length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
            ),
            child: Row(
              children: [
                const Text('Reports Log',
                    style: TextStyle(
                        color: _kText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${all.length} total',
                    style: const TextStyle(color: _kSub, fontSize: 13)),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Stats row
                Row(
                  children: [
                    _StatChip('Pending',  pendingCount,  _kOrange),
                    const SizedBox(width: 8),
                    _StatChip('Approved', approvedCount, _kGreen),
                    const SizedBox(width: 8),
                    _StatChip('Rejected', rejectedCount, _kRed),
                    const SizedBox(width: 8),
                    _StatChip('Resolved', resolvedCount, _kBlue),
                  ],
                ),
                const SizedBox(height: 16),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'All',      value: 'all',      current: _filter, count: all.length,       onTap: () => setState(() => _filter = 'all')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Pending',  value: 'pending',  current: _filter, count: pendingCount,  color: _kOrange, onTap: () => setState(() => _filter = 'pending')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Approved', value: 'approved', current: _filter, count: approvedCount, color: _kGreen,  onTap: () => setState(() => _filter = 'approved')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Rejected', value: 'rejected', current: _filter, count: rejectedCount, color: _kRed,    onTap: () => setState(() => _filter = 'rejected')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Resolved', value: 'resolved', current: _filter, count: resolvedCount, color: _kBlue,   onTap: () => setState(() => _filter = 'resolved')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Report list
                if (rp.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: CircularProgressIndicator(color: _kGreen),
                    ),
                  )
                else if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined, color: _kDim, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          _filter == 'all' ? 'No reports yet' : 'No $_filter reports',
                          style: const TextStyle(color: _kSub, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ReportLogCard(report: r),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: _kSub, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.count,
    required this.onTap,
    this.color = _kGreen,
  });
  final String label, value, current;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.14) : _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color.withOpacity(0.5) : _kBorder,
              width: selected ? 1.5 : 1),
        ),
        child: Text('$label ($count)',
            style: TextStyle(
                color: selected ? color : _kSub,
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }
}

// ── Report log card ───────────────────────────────────────────────────────────

class _ReportLogCard extends StatelessWidget {
  const _ReportLogCard({required this.report});
  final HazardReportModel report;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month - 1]}';
  }

  Color _statusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.pending:  return _kOrange;
      case ReportStatus.approved: return _kGreen;
      case ReportStatus.rejected: return _kRed;
      case ReportStatus.resolved: return _kBlue;
    }
  }

  IconData _hazardIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('flood') || t.contains('water')) return Icons.water_rounded;
    if (t.contains('air') || t.contains('aqi') || t.contains('smog')) return Icons.air_rounded;
    if (t.contains('fire')) return Icons.local_fire_department_rounded;
    if (t.contains('heat')) return Icons.thermostat_rounded;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.read<ReportProvider>();
    final isPending  = report.status == ReportStatus.pending;
    final isApproved = report.status == ReportStatus.approved;
    final statusColor = _statusColor(report.status);

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? _kOrange.withOpacity(0.3)
              : _kBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image preview (if any) ────────────────────────────────
          if (report.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Image.network(
                  report.imageUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF1A1A1A),
                    child: Center(
                      child: Icon(_hazardIcon(report.hazardType),
                          color: _kDim, size: 36),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: icon + hazard type + time + status badge ─
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_hazardIcon(report.hazardType),
                          color: statusColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(report.hazardType,
                              style: const TextStyle(
                                  color: _kText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            report.reporterName.isNotEmpty
                                ? 'by ${report.reporterName}'
                                : 'Anonymous',
                            style: const TextStyle(
                                color: _kDim, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_timeAgo(report.createdAt),
                            style: const TextStyle(
                                color: _kDim, fontSize: 11)),
                        const SizedBox(height: 4),
                        _StatusBadge(
                            label: report.status.name[0].toUpperCase() +
                                report.status.name.substring(1),
                            color: statusColor),
                      ],
                    ),
                  ],
                ),

                if (report.details.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(report.details,
                      style: const TextStyle(
                          color: _kSub, fontSize: 13, height: 1.45),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],

                const SizedBox(height: 10),

                // ── Location row ──────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: _kDim, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(report.locationLabel,
                          style: const TextStyle(
                              color: _kDim, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (report.aqi > 0) ...[
                      const Icon(Icons.air_rounded,
                          color: _kDim, size: 13),
                      const SizedBox(width: 4),
                      Text('AQI ${report.aqi}',
                          style: const TextStyle(
                              color: _kDim, fontSize: 12)),
                    ],
                  ],
                ),

                // ── Action buttons (only for actionable statuses) ─────
                if (isPending || isApproved) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: _kBorder),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (isPending) ...[
                        Expanded(
                          child: _ActionButton(
                            label: 'Approve',
                            icon: Icons.check_rounded,
                            color: _kGreen,
                            onTap: () => rp.approve(report.id),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: 'Reject',
                            icon: Icons.close_rounded,
                            color: _kRed,
                            outlined: true,
                            onTap: () => rp.reject(report.id),
                          ),
                        ),
                      ] else if (isApproved) ...[
                        Expanded(
                          child: _ActionButton(
                            label: 'Mark Resolved',
                            icon: Icons.done_all_rounded,
                            color: _kBlue,
                            onTap: () => rp.resolve(report.id),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: 'Reject',
                            icon: Icons.close_rounded,
                            color: _kRed,
                            outlined: true,
                            onTap: () => rp.reject(report.id),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: outlined ? color.withOpacity(0.4) : color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
