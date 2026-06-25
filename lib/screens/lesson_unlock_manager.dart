import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/user_progress.dart';
import '../services/lesson_service.dart';
import '../services/progress_service.dart';

const _s1Chain = [1, 22, 11, 2, 10, 12, 3, 4, 9, 13, 14, 6, 5, 15, 19, 7, 8, 17, 18, 16, 20, 21, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48];
const _s2Chain = [23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37];

String _emoji(int id) {
  const m = {
    1: '👋', 2: '🔢', 3: '🍜', 4: '🥤', 5: '👨‍👩‍👧', 6: '🎨', 7: '🚕', 8: '🗺️',
    9: '🐘', 10: '🛒', 11: '💬', 12: '🏪', 13: '📝', 14: '🕐', 15: '😊', 16: '💪',
    17: '⛈️', 18: '🏛️', 19: '👔', 20: '🏠', 21: '📚', 22: '🙏', 23: '🍽️', 24: '💰',
    25: '🆘', 26: '🏥', 27: '📅', 28: '👤', 29: '⏰', 30: '🔢', 31: '😎', 32: '💯',
    33: '❤️', 34: '📱', 35: '🏯', 36: '💼', 37: '🗺️',
    38: '📅', 39: '🎬', 40: '🛒', 41: '👋', 42: '💯', 43: '😎',
    44: '🔷', 45: '📏', 46: '↔️', 47: '👕', 48: '🪨',
  };
  return m[id] ?? '📚';
}

class LessonUnlockManagerScreen extends StatefulWidget {
  const LessonUnlockManagerScreen({super.key});

  @override
  State<LessonUnlockManagerScreen> createState() => _LessonUnlockManagerScreenState();
}

class _LessonUnlockManagerScreenState extends State<LessonUnlockManagerScreen> {
  Map<int, Lesson> _lessonMap = {};
  UserProgress _progress = UserProgress();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final lessons = await LessonService().loadAllLessons();
    final progress = await ProgressService().load();
    if (mounted) {
      setState(() {
        _lessonMap = {for (final l in lessons) l.id: l};
        _progress = progress;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    final progress = await ProgressService().load();
    if (mounted) setState(() => _progress = progress);
  }

  bool _isUnlocked(int id) => (_progress.lessonProgress[id]?.stars ?? 0) >= 1;

  int get _unlockedCount =>
      [..._s1Chain, ..._s2Chain].where(_isUnlocked).length;

  Future<void> _toggle(int lessonId, bool newValue, List<int> chain) async {
    final idx = chain.indexOf(lessonId);
    if (idx < 0) return;

    if (newValue) {
      // Unlock this lesson + all prerequisites in chain
      final s1Prereqs = (chain == _s2Chain)
          ? _s1Chain.where((id) => !_isUnlocked(id)).toList()
          : <int>[];
      final chainPrereqs = chain
          .sublist(0, idx + 1)
          .where((id) => !_isUnlocked(id))
          .toList();
      final allToUnlock = [...s1Prereqs, ...chainPrereqs];
      if (allToUnlock.isEmpty) return;

      if (allToUnlock.length > 1) {
        final extra = allToUnlock.length - 1;
        final ok = await _confirmCascade(
          'This will also unlock $extra prerequisite lesson${extra == 1 ? '' : 's'}. Continue?',
          actionLabel: 'Unlock All',
        );
        if (ok != true) return;
      }
      await ProgressService().setLessonsAccessible(allToUnlock, true);
    } else {
      // Lock this lesson + all subsequent in chain
      final toLock = chain.sublist(idx).where(_isUnlocked).toList();
      if (toLock.isEmpty) return;

      if (toLock.length > 1) {
        final extra = toLock.length - 1;
        final ok = await _confirmCascade(
          'This will also lock $extra subsequent lesson${extra == 1 ? '' : 's'}. Continue?',
          actionLabel: 'Lock All',
        );
        if (ok != true) return;
      }
      await ProgressService().setLessonsAccessible(toLock, false);
    }

    await _refresh();
  }

  Future<bool?> _confirmCascade(String message, {required String actionLabel}) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cascade Change'),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(actionLabel)),
          ],
        ),
      );

  Future<void> _applyPreset(String preset) async {
    switch (preset) {
      case 'unlock_s1':
        await ProgressService().setLessonsAccessible(_s1Chain.toList(), true);
      case 'unlock_all':
        await ProgressService().setLessonsAccessible(
            [..._s1Chain, ..._s2Chain], true);
      case 'lock_all':
        await ProgressService().setLessonsAccessible(
            [..._s1Chain.skip(1), ..._s2Chain], false);
      case 'reset_default':
        await ProgressService().setLessonsAccessible(
            [..._s1Chain.skip(1), ..._s2Chain], false);
        await ProgressService().setLessonsAccessible([_s1Chain[0]], true);
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lesson Unlock Manager',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF58A6FF)),
            ),
            Text(
              'Developer Mode Only',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF58A6FF)))
          : Column(
              children: [
                _buildPresets(),
                Expanded(child: _buildList()),
                _buildFooter(),
              ],
            ),
    );
  }

  Widget _buildPresets() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: const Color(0xFF161B22),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PresetChip(
              label: '🔓 Unlock Stage 1',
              onTap: () => _applyPreset('unlock_s1')),
          _PresetChip(
              label: '🔓 Unlock All',
              onTap: () => _applyPreset('unlock_all')),
          _PresetChip(
              label: '🔒 Lock All',
              danger: true,
              onTap: () => _applyPreset('lock_all')),
          _PresetChip(
              label: '🔒 Reset to Default',
              danger: true,
              onTap: () => _applyPreset('reset_default')),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      children: [
        _StageHeader('Stage 1 — ${_s1Chain.length} Lessons'),
        ..._s1Chain.asMap().entries.map((e) => _LessonRow(
              position: e.key + 1,
              lessonId: e.value,
              title: _lessonMap[e.value]?.title ?? 'Lesson ${e.value}',
              emoji: _emoji(e.value),
              stars: _progress.lessonProgress[e.value]?.stars ?? 0,
              isUnlocked: _isUnlocked(e.value),
              onToggle: (v) => _toggle(e.value, v, _s1Chain),
            )),
        const SizedBox(height: 16),
        _StageHeader('Stage 2 — ${_s2Chain.length} Lessons'),
        ..._s2Chain.asMap().entries.map((e) => _LessonRow(
              position: e.key + 1,
              lessonId: e.value,
              title: _lessonMap[e.value]?.title ?? 'Lesson ${e.value}',
              emoji: _emoji(e.value),
              stars: _progress.lessonProgress[e.value]?.stars ?? 0,
              isUnlocked: _isUnlocked(e.value),
              onToggle: (v) => _toggle(e.value, v, _s2Chain),
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF161B22),
      child: Center(
        child: Text(
          '$_unlockedCount of ${_s1Chain.length + _s2Chain.length} lessons unlocked',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF58A6FF),
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _StageHeader extends StatelessWidget {
  final String label;
  const _StageHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF58A6FF),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final int position;
  final int lessonId;
  final String title;
  final String emoji;
  final int stars;
  final bool isUnlocked;
  final ValueChanged<bool> onToggle;

  const _LessonRow({
    required this.position,
    required this.lessonId,
    required this.title,
    required this.emoji,
    required this.stars,
    required this.isUnlocked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isUnlocked
            ? const Color(0xFF1A2532)
            : const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked
              ? const Color(0xFF58A6FF).withValues(alpha: 0.25)
              : const Color(0xFF30363D),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$position',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isUnlocked
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
          if (stars > 0) ...[
            Text('⭐' * stars, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 6),
          ],
          Switch(
            value: isUnlocked,
            onChanged: onToggle,
            activeThumbColor: const Color(0xFF58A6FF),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _PresetChip({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: danger
              ? const Color(0xFF2D1117)
              : const Color(0xFF1A2532),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: danger
                ? Colors.red.shade900
                : const Color(0xFF30363D),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: danger
                ? Colors.red.shade400
                : const Color(0xFF58A6FF),
          ),
        ),
      ),
    );
  }
}
