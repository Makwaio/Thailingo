import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/lesson.dart';
import '../models/user_progress.dart';
import '../services/lesson_service.dart';
import '../services/progress_service.dart';
import '../ui/theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  final bool isTab;
  const StatsScreen({super.key, this.isTab = false});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Lesson> _lessons = [];
  UserProgress _progress = UserProgress();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessons = await LessonService().loadAllLessons();
    final progress = await ProgressService().load();
    if (mounted) {
      setState(() {
        _lessons = lessons;
        _progress = progress;
        _loading = false;
      });
    }
  }

  // ── Computed stats ─────────────────────────────────────────────────

  int get _totalCompleted =>
      _progress.lessonProgress.values.where((lp) => lp.completed).length;

  int get _totalWordsLearned => _lessons
      .where((l) => _progress.isLessonCompleted(l.id))
      .fold(0, (sum, l) => sum + l.words.length);

  int get _perfectLessons => _progress.lessonProgress.values
      .where((lp) => lp.bestAccuracy == 100)
      .length;

  double get _avgAccuracy {
    final completed =
        _progress.lessonProgress.values.where((lp) => lp.completed).toList();
    if (completed.isEmpty) return 0;
    return completed.fold(0.0, (sum, lp) => sum + lp.bestAccuracy) /
        completed.length;
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Stats & Trophies',
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
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(context).padding.bottom + 32),
              children: [
                _buildSummary(),
                const SizedBox(height: 28),
                _buildAchievements(),
                const SizedBox(height: 28),
                _buildLessonBests(),
              ],
            ),
    );
  }

  // ── Summary section ────────────────────────────────────────────────

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('OVERVIEW'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: [
            _StatCard('⭐', 'Total XP', '${_progress.totalXp}', AppTheme.accent),
            _StatCard('📊', 'Level', '${_progress.level}', AppTheme.primary),
            _StatCard('🔥', 'Best Streak', '${_progress.longestStreak}d',
                const Color(0xFFFF9600)),
            _StatCard('✅', 'Lessons Done',
                '$_totalCompleted / ${_lessons.length}', AppTheme.success),
            _StatCard('📚', 'Words Learned', '$_totalWordsLearned',
                const Color(0xFF7C3AED)),
            _StatCard('💯', 'Perfect', '$_perfectLessons', AppTheme.success),
            _StatCard('🎯', 'Avg Accuracy', '${_avgAccuracy.round()}%',
                AppTheme.primary),
            _StatCard('⚡', 'Best Combo', '${_progress.maxCombo}×',
                const Color(0xFFFF9600)),
            _StatCard('📝', 'Words Reviewed', '${_progress.totalWordsReviewed}',
                const Color(0xFF7C3AED)),
          ],
        ),

        const SizedBox(height: 12),

        // XP progress bar to next level
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Level ${_progress.level}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  Text('${_progress.xpInLevel} / 200 XP',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                child: LinearProgressIndicator(
                  value: _progress.xpInLevel / 200.0,
                  minHeight: 12,
                  backgroundColor: AppTheme.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${200 - _progress.xpInLevel} XP to Level ${_progress.level + 1}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.15, curve: Curves.easeOut);
  }

  // ── Achievements section ───────────────────────────────────────────

  Widget _buildAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('ACHIEVEMENTS'),
        const SizedBox(height: 10),
        ...kAchievements.asMap().entries.map((e) {
          final i = e.key;
          final def = e.value;
          final unlocked =
              isAchievementUnlocked(def.id, _progress, _totalWordsLearned);
          final dateStr = _progress.achievementsUnlocked[def.id];
          return _AchievementTile(
            def: def,
            unlocked: unlocked,
            dateStr: dateStr,
          )
              .animate(delay: (i * 50).ms)
              .fadeIn(duration: 350.ms)
              .slideX(begin: 0.1, curve: Curves.easeOut);
        }),
      ],
    );
  }

  // ── Per-lesson personal bests ─────────────────────────────────────

  Widget _buildLessonBests() {
    final completed =
        _lessons.where((l) => _progress.isLessonCompleted(l.id)).toList();

    if (completed.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('PERSONAL BESTS'),
          SizedBox(height: 12),
          Center(
            child: Text(
              'Complete a lesson to see your bests here!',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('PERSONAL BESTS'),
        const SizedBox(height: 10),
        ...completed.asMap().entries.map((e) {
          final i = e.key;
          final lesson = e.value;
          final lp = _progress.lessonProgress[lesson.id]!;
          return _LessonBestTile(lesson: lesson, lp: lp)
              .animate(delay: (i * 40).ms)
              .fadeIn(duration: 350.ms)
              .slideX(begin: 0.1, curve: Curves.easeOut);
        }),
      ],
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _StatCard(this.emoji, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Achievement Tile ──────────────────────────────────────────────────
class _AchievementTile extends StatelessWidget {
  final AchievementDef def;
  final bool unlocked;
  final String? dateStr;

  const _AchievementTile({
    required this.def,
    required this.unlocked,
    this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: unlocked
              ? AppTheme.accent.withValues(alpha: 0.4)
              : AppTheme.border,
          width: unlocked ? 1.5 : 1,
        ),
        boxShadow: unlocked ? AppTheme.shadowSm : [],
      ),
      child: Row(
        children: [
          Text(
            unlocked ? def.emoji : '🔒',
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: unlocked
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary),
                ),
                Text(
                  def.description,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (unlocked)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: const Text('Unlocked',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.success)),
                ),
                if (dateStr != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(dateStr!,
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Lesson Personal Best Tile ─────────────────────────────────────────
class _LessonBestTile extends StatelessWidget {
  final Lesson lesson;
  final LessonProgress lp;

  const _LessonBestTile({required this.lesson, required this.lp});

  String _fmtTime(int s) {
    if (s == 0) return '—';
    return s < 60 ? '${s}s' : '${s ~/ 60}m ${s % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    final lessonColor = HexColor.fromHex(lesson.colorHex);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: lessonColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('${lesson.id}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: lessonColor)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    Text(lesson.subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Text('⭐',
                      style: TextStyle(
                          fontSize: 14,
                          color: i < lp.stars
                              ? null
                              : Colors.grey.withValues(alpha: 0.3))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat('🎯', '${lp.bestAccuracy}%', 'Best'),
              _MiniStat('⏱️', _fmtTime(lp.bestTimeSeconds), 'Best time'),
              _MiniStat('🔁', '${lp.timesPlayed}×', 'Played'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  const _MiniStat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$icon $value',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: AppTheme.textSecondary),
    );
  }
}
