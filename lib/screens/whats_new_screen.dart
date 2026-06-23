import 'package:flutter/material.dart';
import '../services/patch_notes_service.dart';
import '../ui/theme/app_theme.dart';

// ── Full screen ────────────────────────────────────────────────────────

class WhatsNewScreen extends StatefulWidget {
  const WhatsNewScreen({super.key});

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  List<PatchNote> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await PatchNotesService().getLatestPatchNotes();
    if (mounted) setState(() { _notes = notes; _loading = false; });
  }

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
          "What's New 📋",
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(
                  child: Text('No patch notes yet.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notes.length,
                  itemBuilder: (_, i) => _PatchNoteCard(note: _notes[i]),
                ),
    );
  }
}

// ── Popup dialog (for unread notes on app open) ────────────────────────

class WhatsNewDialog extends StatelessWidget {
  final List<PatchNote> notes;
  const WhatsNewDialog({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                color: AppTheme.thaiNavy,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusXl)),
              ),
              child: Column(
                children: [
                  const Text('🇹🇭', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  const Text(
                    "What's New",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  Text(
                    notes.length == 1
                        ? 'v${notes.first.version}'
                        : '${notes.length} new updates',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white60),
                  ),
                ],
              ),
            ),
            // Notes list
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                children: notes
                    .map((n) => _PatchNoteCard(note: n, compact: true))
                    .toList(),
              ),
            ),
            // Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.thaiNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull)),
                  ),
                  child: const Text(
                    "Got it! Let's play 🇹🇭",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Patch note card ────────────────────────────────────────────────────

class _PatchNoteCard extends StatelessWidget {
  final PatchNote note;
  final bool compact;

  const _PatchNoteCard({required this.note, this.compact = false});

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    switch (note.type) {
      case 'major':
        typeColor = AppTheme.thaiNavy;
      case 'minor':
        typeColor = AppTheme.primary;
      default:
        typeColor = AppTheme.textSecondary;
    }

    final dateStr = _formatDate(note.date);

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: compact ? [] : AppTheme.shadowSm,
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    'v${note.version}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: typeColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary),
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...note.notes.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.5)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}

// ── Developer: Add Patch Note form ─────────────────────────────────────

Future<void> showAddPatchNoteDialog(BuildContext context) async {
  final versionCtrl = TextEditingController();
  final titleCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  String selectedType = 'patch';

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: const Text('Add Patch Note',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: versionCtrl,
                decoration: const InputDecoration(
                    labelText: 'Version (e.g. 1.0.2)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Type', border: OutlineInputBorder()),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'major', child: Text('Major')),
                      DropdownMenuItem(value: 'minor', child: Text('Minor')),
                      DropdownMenuItem(value: 'patch', child: Text('Patch')),
                    ],
                    onChanged: (v) => setSt(() => selectedType = v ?? 'patch'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: 'Notes (one per line)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final version = versionCtrl.text.trim();
              final title = titleCtrl.text.trim();
              final notes = notesCtrl.text
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              if (version.isEmpty || title.isEmpty || notes.isEmpty) return;
              await PatchNotesService().addPatchNote(PatchNote(
                version: version,
                title: title,
                date: DateTime.now(),
                type: selectedType,
                notes: notes,
              ));
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content: Text('Patch note v$version added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}
