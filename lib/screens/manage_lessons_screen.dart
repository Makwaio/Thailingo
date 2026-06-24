import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/word.dart';
import '../services/lesson_service.dart';
import '../ui/theme/app_theme.dart';

class ManageLessonsScreen extends StatefulWidget {
  const ManageLessonsScreen({super.key});

  @override
  State<ManageLessonsScreen> createState() => _ManageLessonsScreenState();
}

class _ManageLessonsScreenState extends State<ManageLessonsScreen> {
  List<Lesson> _lessons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('lessons')
          .orderBy('id')
          .get();
      final lessons = snap.docs.map((d) => Lesson.fromJson(d.data())).toList();
      setState(() { _lessons = lessons; _loading = false; });
    } catch (e) {
      // Firestore unavailable — fall back to local service cache
      try {
        final lessons = await LessonService().loadAllLessons();
        setState(() { _lessons = lessons; _loading = false; });
      } catch (_) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  Future<void> _uploadLesson(Lesson lesson) async {
    final docId = 'lesson_${lesson.id.toString().padLeft(2, '0')}';
    await FirebaseFirestore.instance
        .collection('lessons')
        .doc(docId)
        .set(lesson.toJson()
          ..['lastUpdated'] = FieldValue.serverTimestamp());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded $docId to Firestore')),
      );
    }
  }

  Future<void> _uploadAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upload All Lessons?'),
        content: Text(
            'This will upload/overwrite all ${_lessons.length} lessons to Firestore.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Upload All',
                  style: TextStyle(color: AppTheme.thaiNavy))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _loading = true);
    for (final lesson in _lessons) {
      await _uploadLesson(lesson);
    }
    await _load();
  }

  Future<void> _openAddLesson() async {
    final result = await showDialog<Lesson>(
      context: context,
      builder: (_) => const _AddLessonDialog(),
    );
    if (result == null) return;
    await _uploadLesson(result);
    LessonService().clearCache();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        title: const Text('Manage Lessons',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF58A6FF))),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_rounded),
            tooltip: 'Upload all to Firestore',
            onPressed: _uploadAll,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddLesson,
        backgroundColor: AppTheme.thaiNavy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Lesson',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $_error',
                        style: const TextStyle(color: AppTheme.danger)),
                  ),
                )
              : _lessons.isEmpty
                  ? const Center(
                      child: Text(
                        'No lessons in Firestore yet.\nTap ↑ to upload from local assets.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _lessons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final l = _lessons[i];
                        return _LessonTile(
                          lesson: l,
                          onUpload: () => _uploadLesson(l),
                        );
                      },
                    ),
    );
  }
}

// ── Lesson tile ───────────────────────────────────────────────────────────
class _LessonTile extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onUpload;

  const _LessonTile({required this.lesson, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: HexColor.fromHex(lesson.colorHex).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${lesson.id}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: HexColor.fromHex(lesson.colorHex)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text('${lesson.words.length} words · ${lesson.subtitle}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload_rounded,
                color: AppTheme.thaiNavy),
            tooltip: 'Upload to Firestore',
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }
}

// ── Add Lesson dialog ─────────────────────────────────────────────────────
class _AddLessonDialog extends StatefulWidget {
  const _AddLessonDialog();

  @override
  State<_AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends State<_AddLessonDialog> {
  final _idCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _colorCtrl = TextEditingController(text: '#1565C0');
  final _xpCtrl = TextEditingController(text: '30');
  final List<Map<String, String>> _words = [];

  @override
  void dispose() {
    _idCtrl.dispose();
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _colorCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  Future<void> _addWord() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _AddWordDialog(),
    );
    if (result != null) setState(() => _words.add(result));
  }

  void _submit() {
    final id = int.tryParse(_idCtrl.text.trim());
    if (id == null || _titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID and title are required')));
      return;
    }
    final lesson = Lesson(
      id: id,
      title: _titleCtrl.text.trim(),
      subtitle: _subtitleCtrl.text.trim(),
      icon: '',
      colorHex: _colorCtrl.text.trim(),
      xpReward: int.tryParse(_xpCtrl.text.trim()) ?? 30,
      words: _words
          .map((w) => Word(
                id: w['id'] ?? '',
                thai: w['thai'] ?? '',
                phonetic: w['phonetic'] ?? '',
                english: w['english'] ?? '',
                image: '',
                audio: w['audio'] ?? '',
                example: '',
              ))
          .toList(),
    );
    Navigator.pop(context, lesson);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Lesson'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('Lesson ID (number)', _idCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              _field('Title', _titleCtrl),
              const SizedBox(height: 8),
              _field('Subtitle', _subtitleCtrl),
              const SizedBox(height: 8),
              _field('Color Hex (e.g. #1565C0)', _colorCtrl),
              const SizedBox(height: 8),
              _field('XP Reward', _xpCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Words (${_words.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextButton.icon(
                    onPressed: _addWord,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Word'),
                  ),
                ],
              ),
              ..._words.map((w) => ListTile(
                    dense: true,
                    title: Text(w['thai'] ?? ''),
                    subtitle: Text(w['english'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () =>
                          setState(() => _words.remove(w)),
                    ),
                  )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: _submit,
            child: const Text('Create Lesson')),
      ],
    );
  }

  Widget _field(String hint, TextEditingController ctrl,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

// ── Add Word dialog ───────────────────────────────────────────────────────
class _AddWordDialog extends StatelessWidget {
  const _AddWordDialog();

  @override
  Widget build(BuildContext context) {
    final idCtrl = TextEditingController();
    final thaiCtrl = TextEditingController();
    final phoneticCtrl = TextEditingController();
    final englishCtrl = TextEditingController();
    final audioCtrl = TextEditingController();

    return AlertDialog(
      title: const Text('Add Word'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _wordField('Word ID (e.g. dly_01)', idCtrl),
            const SizedBox(height: 8),
            _wordField('Thai text', thaiCtrl),
            const SizedBox(height: 8),
            _wordField('Phonetic', phoneticCtrl),
            const SizedBox(height: 8),
            _wordField('English', englishCtrl),
            const SizedBox(height: 8),
            _wordField('Audio filename (e.g. dly_01.mp3)', audioCtrl),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'id': idCtrl.text.trim(),
            'thai': thaiCtrl.text.trim(),
            'phonetic': phoneticCtrl.text.trim(),
            'english': englishCtrl.text.trim(),
            'audio': audioCtrl.text.trim(),
          }),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _wordField(String hint, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

