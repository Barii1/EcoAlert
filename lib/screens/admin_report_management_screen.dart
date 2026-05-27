import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../providers/report_provider.dart';
import '../models/hazard_report_model.dart';

class AdminReportManagementScreen extends StatefulWidget {
  const AdminReportManagementScreen({super.key});

  @override
  State<AdminReportManagementScreen> createState() =>
      _AdminReportManagementScreenState();
}

class _AdminReportManagementScreenState
    extends State<AdminReportManagementScreen> {
  String _filter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HazardReportModel> _applyFilters(List<HazardReportModel> all) {
    var list = all;
    switch (_filter) {
      case 'pending':
        list = list.where((r) => r.status == ReportStatus.pending).toList();
        break;
      case 'approved':
        list = list.where((r) => r.status == ReportStatus.approved).toList();
        break;
      case 'rejected':
        list = list.where((r) => r.status == ReportStatus.rejected).toList();
        break;
      case 'resolved':
        list = list.where((r) => r.status == ReportStatus.resolved).toList();
        break;
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((r) =>
              r.locationLabel.toLowerCase().contains(q) ||
              r.reporterName.toLowerCase().contains(q) ||
              r.hazardType.toLowerCase().contains(q) ||
              r.details.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final all = reportProvider.reports;
    final filtered = _applyFilters(all.toList());

    final pendingCount =
        all.where((r) => r.status == ReportStatus.pending).length;
    final approvedCount =
        all.where((r) => r.status == ReportStatus.approved).length;
    final rejectedCount =
        all.where((r) => r.status == ReportStatus.rejected).length;
    final resolvedCount =
        all.where((r) => r.status == ReportStatus.resolved).length;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reports',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              '${all.length} total · $pendingCount pending',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by location, reporter, type…',
                hintStyle:
                    const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textSecondary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textSecondary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                      label: 'All',
                      count: all.length,
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all')),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: 'Pending',
                      count: pendingCount,
                      selected: _filter == 'pending',
                      color: AppColors.warning,
                      onTap: () => setState(() => _filter = 'pending')),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: 'Approved',
                      count: approvedCount,
                      selected: _filter == 'approved',
                      color: AppColors.success,
                      onTap: () => setState(() => _filter = 'approved')),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: 'Rejected',
                      count: rejectedCount,
                      selected: _filter == 'rejected',
                      color: AppColors.danger,
                      onTap: () => setState(() => _filter = 'rejected')),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: 'Resolved',
                      count: resolvedCount,
                      selected: _filter == 'resolved',
                      color: AppColors.info,
                      onTap: () => setState(() => _filter = 'resolved')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_outlined,
                            color: AppColors.textSecondary.withOpacity(0.4),
                            size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No reports match "$_searchQuery"'
                              : 'No reports in this category',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _ReportCard(report: filtered[i]),
                  ),
          ),
        ],
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
    final accent = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.15) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? accent : AppColors.textSecondary,
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withOpacity(0.25)
                    : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? accent : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Report card ──────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final HazardReportModel report;

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    final statusInfo = _statusInfo(report.status);
    final hazardColor = _hazardColor(report.hazardType);
    final hazardIcon = _hazardIcon(report.hazardType);
    final timeAgo = _timeAgo(report.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: hazardColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(hazardIcon, color: hazardColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.hazardType,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${report.locationLabel} · $timeAgo',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        statusInfo.$1.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusInfo.$1.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusInfo.$2,
                    style: TextStyle(
                        color: statusInfo.$1,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                // More options
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () =>
                      _showActions(context, reportProvider),
                ),
              ],
            ),
          ),

          // Reporter
          if (report.reporterName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(52, 4, 14, 0),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('Reported by ${report.reporterName}',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11)),
                ],
              ),
            ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              report.details,
              style: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.8),
                  fontSize: 13,
                  height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Images
          if (report.imageUrls.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.imageUrls.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      report.imageUrls[i],
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) =>
                          progress == null
                              ? child
                              : Container(
                                  width: 72,
                                  height: 72,
                                  color: AppColors.bgElevated,
                                  child: const Center(
                                      child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child:
                                              CircularProgressIndicator(
                                                  strokeWidth: 2))),
                                ),
                      errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: AppColors.bgElevated,
                          child: const Icon(Icons.broken_image,
                              color: AppColors.textSecondary,
                              size: 20)),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Action buttons
          if (report.status == ReportStatus.pending) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => reportProvider.reject(report.id),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(
                            color: AppColors.danger.withOpacity(0.5)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          reportProvider.approve(report.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (report.status == ReportStatus.approved) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      reportProvider.resolve(report.id),
                  icon: const Icon(Icons.check_circle_outline,
                      size: 16),
                  label: const Text('Mark as Resolved'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: BorderSide(
                        color: AppColors.info.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  void _showActions(
      BuildContext context, ReportProvider reportProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.hazardType,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text('${report.locationLabel} · ${_timeAgo(report.createdAt)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12)),
                ],
              ),
            ),
            const Divider(
                color: AppColors.borderSubtle, height: 20),
            if (report.status == ReportStatus.pending) ...[
              _ActionTile(
                icon: Icons.check_circle_outline,
                label: 'Approve Report',
                color: AppColors.success,
                onTap: () {
                  Navigator.pop(context);
                  reportProvider.approve(report.id);
                },
              ),
              _ActionTile(
                icon: Icons.cancel_outlined,
                label: 'Reject Report',
                color: AppColors.danger,
                onTap: () {
                  Navigator.pop(context);
                  reportProvider.reject(report.id);
                },
              ),
            ] else if (report.status == ReportStatus.approved) ...[
              _ActionTile(
                icon: Icons.check_circle,
                label: 'Mark as Resolved',
                color: AppColors.info,
                onTap: () {
                  Navigator.pop(context);
                  reportProvider.resolve(report.id);
                },
              ),
            ],
            _ActionTile(
              icon: Icons.info_outline,
              label: 'View Full Details',
              color: AppColors.textSecondary,
              onTap: () {
                Navigator.pop(context);
                _showDetailDialog(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(report.hazardType,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('Location', report.locationLabel),
              _DetailRow('Reporter', report.reporterName.isNotEmpty
                  ? report.reporterName
                  : 'Anonymous'),
              _DetailRow('Submitted', _timeAgo(report.createdAt)),
              _DetailRow('Status', report.status.name.toUpperCase()),
              if (report.aqi > 0)
                _DetailRow('AQI at Time', report.aqi.toString()),
              const SizedBox(height: 8),
              const Text('Details',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(report.details,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  (Color, String) _statusInfo(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return (AppColors.warning, 'PENDING');
      case ReportStatus.approved:
        return (AppColors.success, 'APPROVED');
      case ReportStatus.rejected:
        return (AppColors.danger, 'REJECTED');
      case ReportStatus.resolved:
        return (AppColors.info, 'RESOLVED');
    }
  }

  IconData _hazardIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('flood')) return Icons.water_drop;
    if (t.contains('smog') || t.contains('aqi')) return Icons.air;
    if (t.contains('cloud') || t.contains('burst')) return Icons.thunderstorm;
    if (t.contains('fire')) return Icons.local_fire_department;
    return Icons.warning_amber;
  }

  Color _hazardColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('flood')) return AppColors.info;
    if (t.contains('smog') || t.contains('aqi')) return AppColors.warning;
    if (t.contains('fire')) return AppColors.danger;
    return AppColors.primary;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

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
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: color),
        title:
            Text(label, style: TextStyle(color: color, fontSize: 14)),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
