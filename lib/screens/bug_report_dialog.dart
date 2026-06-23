import 'package:flutter/material.dart';
import '../services/bug_report_service.dart';
import '../ui/theme/app_theme.dart';

Future<void> showBugReportDialog(
  BuildContext context, {
  int? lessonId,
  String? lessonName,
  String screen = 'Settings',
}) async {
  await showDialog(
    context: context,
    builder: (_) => _BugReportDialog(
      lessonId: lessonId,
      lessonName: lessonName,
      screen: screen,
    ),
  );
}

class _BugReportDialog extends StatefulWidget {
  final int? lessonId;
  final String? lessonName;
  final String screen;

  const _BugReportDialog({
    this.lessonId,
    this.lessonName,
    required this.screen,
  });

  @override
  State<_BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends State<_BugReportDialog> {
  static const _bugTypes = [
    'Wrong translation',
    'Audio not playing',
    'App crashed',
    'Incorrect lesson content',
    'UI/display issue',
    'Other',
  ];

  String _selectedType = 'Wrong translation';
  final _descController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the bug.')),
      );
      return;
    }

    setState(() => _submitting = true);

    final service = BugReportService();
    final report = BugReport(
      type: _selectedType,
      description: _descController.text.trim(),
      lessonId: widget.lessonId,
      lessonName: widget.lessonName,
      screen: widget.screen,
      appVersion: BugReportService.appVersion,
      userId: service.currentUserId,
      deviceInfo: service.deviceInfo,
    );

    await service.submitReport(report);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Bug reported! Thanks for helping improve Thailingo 🙏'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = BugReportService();
    return AlertDialog(
      title: const Text('Report a Bug 🐛'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bug type',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd)),
              ),
              items: _bugTypes
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t,
                            style: const TextStyle(fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),

            const SizedBox(height: 16),

            const Text(
              'Description',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the bug...',
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd)),
              ),
            ),

            const SizedBox(height: 16),

            if (widget.lessonName != null) ...[
              _InfoRow('Lesson', widget.lessonName!),
              const SizedBox(height: 4),
            ],
            _InfoRow('Screen', widget.screen),
            const SizedBox(height: 4),
            const _InfoRow('Version', BugReportService.appVersion),
            const SizedBox(height: 4),
            _InfoRow('Device', service.deviceInfo),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.thaiNavy,
              foregroundColor: Colors.white),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
