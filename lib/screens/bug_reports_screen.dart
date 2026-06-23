import 'package:flutter/material.dart';
import '../services/bug_report_service.dart';
import '../ui/theme/app_theme.dart';

class BugReportsScreen extends StatelessWidget {
  const BugReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bug Reports',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: StreamBuilder<List<BugReport>>(
        stream: BugReportService().watchReports(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading reports:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            );
          }

          final reports = snap.data ?? [];
          final openCount =
              reports.where((r) => r.status == 'open').length;

          return Column(
            children: [
              // Open count banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 20),
                color: openCount > 0
                    ? AppTheme.danger.withValues(alpha: 0.08)
                    : AppTheme.success.withValues(alpha: 0.08),
                child: Text(
                  openCount > 0
                      ? '🔴  $openCount open bug${openCount == 1 ? '' : 's'}'
                      : '✅  No open bugs',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: openCount > 0
                          ? AppTheme.danger
                          : AppTheme.success),
                ),
              ),
              Expanded(
                child: reports.isEmpty
                    ? const Center(
                        child: Text(
                          'No bug reports yet.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: reports.length,
                        itemBuilder: (_, i) =>
                            _BugReportTile(report: reports[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BugReportTile extends StatelessWidget {
  final BugReport report;
  const _BugReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (report.status) {
      case 'fixed':
        statusColor = AppTheme.success;
      case 'wont_fix':
        statusColor = AppTheme.textSecondary;
      default:
        statusColor = AppTheme.danger;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () => _showStatusMenu(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      report.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.type,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                    ),
                  ),
                  if (report.timestamp != null)
                    Text(
                      _formatDate(report.timestamp!),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textPrimary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (report.lessonName != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Lesson: ${report.lessonName}${report.lessonId != null ? ' (#${report.lessonId})' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${report.screen} · v${report.appVersion} · ${report.deviceInfo} · ${report.userId}',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    if (report.docId == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Update Status',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading:
                  const Icon(Icons.check_circle, color: AppTheme.success),
              title: const Text('Mark as Fixed'),
              onTap: () {
                BugReportService()
                    .updateStatus(report.docId!, 'fixed');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel,
                  color: AppTheme.textSecondary),
              title: const Text("Won't Fix"),
              onTap: () {
                BugReportService()
                    .updateStatus(report.docId!, 'wont_fix');
                Navigator.pop(context);
              },
            ),
            if (report.status != 'open')
              ListTile(
                leading:
                    const Icon(Icons.refresh, color: AppTheme.primary),
                title: const Text('Reopen'),
                onTap: () {
                  BugReportService()
                      .updateStatus(report.docId!, 'open');
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
