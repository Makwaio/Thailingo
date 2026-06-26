import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../services/review_service.dart';
import '../services/lesson_service.dart';
import '../services/missed_questions_service.dart';
import '../ui/theme/app_theme.dart';
import 'bug_report_dialog.dart';
import 'bug_reports_screen.dart';
import 'whats_new_screen.dart';
import 'manage_lessons_screen.dart';
import 'lesson_unlock_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  String _versionDisplay = 'v1.0.2';
  bool _devUnlocked = false;

  static const _snapshotPrefKey = 'dev_unlock_snapshot';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadDevUnlockedState();
  }

  Future<void> _loadVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final patch = prefs.getInt('patch_number') ?? 6;
    if (mounted) setState(() => _versionDisplay = 'v1.0.2-$patch');
  }

  Future<void> _loadDevUnlockedState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSnapshot = prefs.containsKey(_snapshotPrefKey);
    if (mounted) setState(() => _devUnlocked = hasSnapshot);
  }

  bool get _sound => _settings.soundEnabled;
  bool get _music => _settings.musicEnabled;
  bool get _dev => _settings.devMode;

  // Game type getters
  bool get _gtMatchPairs      => _settings.gtMatchPairs;
  bool get _gtListen          => _settings.gtListen;
  bool get _gtSpeedTap        => _settings.gtSpeedTap;
  bool get _gtSentence        => _settings.gtSentenceBuilder;
  bool get _gtConversation    => _settings.gtConversation;
  bool get _gtTyping          => _settings.gtTyping;
  bool get _gtVisualSpotter   => _settings.gtVisualSpotter;
  bool get _gtOpposites       => _settings.gtOpposites;

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
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
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).padding.bottom + 32),
        children: [
          // ── Audio ──────────────────────────────────────────────
          const _SectionHeader('Audio'),
          _SettingsCard(
            children: [
              _ToggleTile(
                icon: Icons.volume_up_rounded,
                label: 'Sound Effects',
                value: _sound,
                onChanged: (v) async {
                  await _settings.setSoundEnabled(v);
                  setState(() {});
                },
              ),
              const _Divider(),
              _ToggleTile(
                icon: Icons.music_note_rounded,
                label: 'Background Music',
                subtitle: 'Coming soon',
                value: _music,
                onChanged: (v) async {
                  await _settings.setMusicEnabled(v);
                  setState(() {});
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Game Types ─────────────────────────────────────────
          const _SectionHeader('Game Types 🎮'),
          _SettingsCard(
            children: [
              _ToggleTile(
                icon: Icons.shuffle_rounded,
                label: 'Multiple Choice',
                subtitle: 'Always enabled',
                value: true,
                onChanged: (_) {}, // always on
              ),
              const _Divider(),
              _ToggleTile(
                icon: Icons.grid_view_rounded,
                label: 'Match Pairs',
                value: _gtMatchPairs,
                onChanged: (v) => _setGameType('gt_match_pairs_v1', v),
              ),
              const _Divider(),
              _ToggleTile(
                icon: Icons.volume_up_rounded,
                label: 'Listen & Choose',
                value: _gtListen,
                onChanged: (v) => _setGameType('gt_listen_v1', v),
              ),
              const _Divider(),
              _ToggleTile(
                icon: Icons.bolt_rounded,
                label: 'Speed Tap',
                subtitle: 'Race against the clock',
                value: _gtSpeedTap,
                onChanged: (v) => _setGameType('gt_speed_tap_v1', v),
              ),
              const _Divider(),
              _ToggleTile(
                icon: Icons.sort_rounded,
                label: 'Sentence Builder',
                subtitle: 'Arrange word chips',
                value: _gtSentence,
                onChanged: (v) => _setGameType('gt_sentence_builder_v1', v),
              ),
              const _Divider(),
              _ToggleTile(
                icon: Icons.chat_bubble_rounded,
                label: 'Conversation Mode',
                subtitle: 'Real Thai dialogue',
                value: _gtConversation,
                onChanged: (v) => _setGameType('gt_conversation_v1', v),
              ),
              const _Divider(),
              _ToggleTile(
                icon: Icons.keyboard_rounded,
                label: 'Typing Challenge',
                subtitle: 'Type the phonetic spelling',
                value: _gtTyping,
                onChanged: (v) => _setGameType('gt_typing_v1', v),
              ),
              const _Divider(),
              _ToggleTile(
                icon: Icons.remove_red_eye_rounded,
                label: 'Visual Spotter',
                subtitle: 'See it, say it in Thai',
                value: _gtVisualSpotter,
                onChanged: (v) => _setGameType('visualSpotter', v),
              ),
              const _Divider(),
              _ToggleTile(
                icon: Icons.swap_horiz_rounded,
                label: 'Opposites Challenge',
                subtitle: 'Match words with their opposites',
                value: _gtOpposites,
                onChanged: (v) => _setGameType('opposites', v),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Language ───────────────────────────────────────────
          const _SectionHeader('Language'),
          const _SettingsCard(
            children: [
              _InfoTile(
                icon: Icons.language_rounded,
                label: 'Learning',
                value: 'Bangkok Thai 🇹🇭',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Learning Direction ─────────────────────────────────
          const _SectionHeader('Learning Direction 🔁'),
          _SettingsCard(
            children: [
              _DirectionTile(
                emoji: '🇬🇧→🇹🇭',
                label: 'English to Thai',
                description: 'See English, learn to write Thai (default)',
                selected: _settings.learningDirection == LearningDirection.englishToThai,
                onTap: () async {
                  await _settings.setLearningDirection(LearningDirection.englishToThai);
                  if (mounted) setState(() {});
                },
              ),
              const _Divider(),
              _DirectionTile(
                emoji: '🇹🇭→🇬🇧',
                label: 'Thai to English',
                description: 'See Thai script, recall the English meaning',
                selected: _settings.learningDirection == LearningDirection.thaiToEnglish,
                onTap: () async {
                  await _settings.setLearningDirection(LearningDirection.thaiToEnglish);
                  if (mounted) setState(() {});
                },
              ),
              const _Divider(),
              _DirectionTile(
                emoji: '🔀',
                label: 'Mixed',
                description: 'Random mix of both directions',
                selected: _settings.learningDirection == LearningDirection.mixed,
                onTap: () async {
                  await _settings.setLearningDirection(LearningDirection.mixed);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Account ────────────────────────────────────────────
          const _SectionHeader('Account'),
          _SettingsCard(
            children: [
              _ActionTile(
                icon: Icons.new_releases_rounded,
                label: "What's New 📋",
                color: AppTheme.textPrimary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WhatsNewScreen()),
                ),
              ),
              const _Divider(),
              _ActionTile(
                icon: Icons.bug_report_rounded,
                label: 'Report a Bug 🐛',
                color: AppTheme.textPrimary,
                onTap: () => showBugReportDialog(context, screen: 'Settings'),
              ),
              const _Divider(),
              _ActionTile(
                icon: Icons.refresh_rounded,
                label: 'Reset Progress',
                color: AppTheme.danger,
                onTap: _confirmReset,
              ),
            ],
          ),

          const SizedBox(height: 40),

          // ── App info ───────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  'Thailingo  $_versionDisplay',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2026 Thailingo',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Developer Mode ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: const Color(0xFF30363D), width: 1.5),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🛠️',
                        style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    const Text(
                      'Developer Mode',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF58A6FF),
                          fontFamily: 'monospace'),
                    ),
                    const Spacer(),
                    Switch(
                      value: _dev,
                      activeThumbColor: const Color(0xFF58A6FF),
                      onChanged: (v) async {
                        await _settings.setDevMode(v);
                        setState(() {});
                      },
                    ),
                  ],
                ),
                if (_dev) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: const Color(0xFF30363D),
                  ),
                  const SizedBox(height: 12),
                  _DevButton(
                    label: _devUnlocked
                        ? '🔒 Revert to Previous State'
                        : '🔓 Unlock All',
                    onTap: _toggleUnlockAll,
                  ),
                  const SizedBox(height: 8),
                  _DevButton(
                    label: '📚 Reset Lessons Only',
                    danger: true,
                    onTap: _confirmResetLessonsOnly,
                  ),
                  const SizedBox(height: 8),
                  _DevButton(
                    label: '🔓 Manage Unlocked Lessons',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LessonUnlockManagerScreen()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DevButton(
                    label: '🗑️ Clear Review Queue',
                    onTap: _clearReviewQueue,
                  ),
                  const SizedBox(height: 8),
                  _DevButton(
                    label: '🐛 View Bug Reports',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BugReportsScreen()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DevButton(
                    label: '📋 Add Patch Note',
                    onTap: () => showAddPatchNoteDialog(context),
                  ),
                  const SizedBox(height: 8),
                  _DevButton(
                    label: '📚 Manage Lessons',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ManageLessonsScreen()),
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────

  Future<void> _confirmReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Progress?'),
        content: const Text(
            'This will erase ALL your XP, stars, streaks, and review words. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset',
                style: TextStyle(
                    color: AppTheme.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ProgressService().clearAll();
    await ReviewService().clearQueue();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress reset.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _setGameType(String key, bool v) async {
    final ok = await _settings.setGameType(key, v);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 game types must remain enabled.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _toggleUnlockAll() async {
    final prefs = await SharedPreferences.getInstance();
    if (_devUnlocked) {
      // Restore snapshot
      final snapshot = prefs.getString(_snapshotPrefKey);
      await prefs.remove(_snapshotPrefKey);
      if (snapshot != null) {
        await ProgressService().restoreFromJson(snapshot);
      }
      if (mounted) {
        setState(() => _devUnlocked = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress restored to previous state.')),
        );
      }
    } else {
      // Save snapshot and unlock all
      final current = await ProgressService().exportJson();
      await prefs.setString(_snapshotPrefKey, current);
      await ProgressService().unlockAllLessons(LessonService.totalLessons);
      if (mounted) {
        setState(() => _devUnlocked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All ${LessonService.totalLessons} lessons unlocked! Tap again to revert.')),
        );
      }
    }
  }

  Future<void> _confirmResetLessonsOnly() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset all lesson progress?'),
        content: const Text(
          'This will clear all stars, completions and unlock progress. '
          'Your XP and streak will be kept. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset Lessons',
                style: TextStyle(
                    color: AppTheme.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ProgressService().resetLessonsOnly();
    await ReviewService().clearQueue();
    await MissedQuestionsService().clearAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lessons reset! Your stats have been kept ✅'),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _clearReviewQueue() async {
    await ReviewService().clearQueue();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review queue cleared.')),
      );
    }
  }
}

// ── Reusable widgets ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppTheme.textSecondary),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DirectionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _DirectionTile({
    required this.emoji,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected ? AppTheme.primary : AppTheme.textPrimary)),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 22),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 52),
      child: Divider(height: 1, color: AppTheme.border),
    );
  }
}

class _DevButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _DevButton({required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: danger ? const Color(0xFF2D1117) : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: danger ? const Color(0xFF6E1212) : const Color(0xFF30363D),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: danger ? Colors.red.shade400 : const Color(0xFF58A6FF),
              fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
