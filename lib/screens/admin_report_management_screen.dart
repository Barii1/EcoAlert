import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String _selectedFilter = 'All Reports';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final allReports = reportProvider.reports;

    List<HazardReportModel> filteredReports = allReports;
    if (_selectedFilter == 'Pending') {
      filteredReports =
          allReports.where((r) => r.status == ReportStatus.pending).toList();
    } else if (_selectedFilter == 'Verified') {
      filteredReports =
          allReports.where((r) => r.status == ReportStatus.approved).toList();
    } else if (_selectedFilter == 'Resolved') {
      filteredReports = allReports
          .where((r) => r.status == ReportStatus.resolved)
          .toList();
    }

    final pendingCount = allReports
        .where((r) => r.status == ReportStatus.pending)
        .length;
    final verifiedCount = allReports
        .where((r) => r.status == ReportStatus.approved)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF0f2323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f2323),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white70),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark()),
                  child: child!,
                ),
              );
              if (range == null) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${range.start} to ${range.end}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by location, user, or ID...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF162e2e),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Reports', _selectedFilter == 'All Reports'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending ($pendingCount)',
                      _selectedFilter == 'Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Verified ($verifiedCount)',
                      _selectedFilter == 'Verified'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Resolved',
                      _selectedFilter == 'Resolved'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredReports.length,
              itemBuilder: (context, index) {
                final report = filteredReports[index];
                return _buildReportCard(context, report);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label.split(' ')[0];
        });
      },
      selectedColor: const Color(0xFF06e0e0),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: const Color(0xFF162e2e),
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF06e0e0)
            : Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, HazardReportModel report) {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final timeAgo = _formatTimeAgo(report.createdAt);

    Color statusColor;
    String statusText;
    switch (report.status) {
      case ReportStatus.pending:
        statusColor = Colors.orange;
        statusText = 'PENDING';
        break;
      case ReportStatus.approved:
        statusColor = Colors.green;
        statusText = 'VERIFIED';
        break;
      case ReportStatus.rejected:
        statusColor = Colors.red;
        statusText = 'REJECTED';
        break;
      case ReportStatus.resolved:
        statusColor = Colors.green;
        statusText = 'RESOLVED';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162e2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getHazardColor(report.hazardType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getHazardIcon(report.hazardType),
                  color: _getHazardColor(report.hazardType),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.hazardType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${report.locationLabel} • $timeAgo',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                onPressed: () {},
              ),
            ],
          ),
          // Reporter name
          if (report.reporterName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 48),
                const Icon(Icons.person_outline, size: 14, color: Colors.white38),
                const SizedBox(width: 4),
                Text(
                  'Reported by ${report.reporterName}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            report.details,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          // Report images from Firebase Storage
          if (report.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: report.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      report.imageUrls[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.white10,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.white10,
                        child: const Icon(Icons.broken_image, color: Colors.white24),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (report.status == ReportStatus.pending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      reportProvider.reject(report.id);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, size: 18),
                        SizedBox(width: 4),
                        Text('Reject'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      reportProvider.approve(report.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06e0e0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 18),
                        SizedBox(width: 4),
                        Text('Approve'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else if (report.status == ReportStatus.approved) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => reportProvider.resolve(report.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 18),
                    SizedBox(width: 4),
                    Text('Mark as Resolved'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getHazardIcon(String hazardType) {
    if (hazardType.toLowerCase().contains('flood')) {
      return Icons.water_drop;
    } else if (hazardType.toLowerCase().contains('smog') ||
        hazardType.toLowerCase().contains('aqi')) {
      return Icons.air;
    } else if (hazardType.toLowerCase().contains('cloud')) {
      return Icons.cloud;
    }
    return Icons.warning;
  }

  Color _getHazardColor(String hazardType) {
    if (hazardType.toLowerCase().contains('flood')) {
      return const Color(0xFF06e0e0);
    } else if (hazardType.toLowerCase().contains('smog') ||
        hazardType.toLowerCase().contains('aqi')) {
      return Colors.orange;
    } else if (hazardType.toLowerCase().contains('cloud')) {
      return Colors.blue;
    }
    return Colors.red;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

