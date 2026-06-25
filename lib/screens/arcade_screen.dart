import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/lesson.dart';
import '../models/user_progress.dart';
import '../models/word.dart';
import '../services/lesson_service.dart';
import '../services/progress_service.dart';
import '../services/arcade_service.dart';
import '../services/firebase_service.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/thai_mascot.dart';
import 'arcade/speed_mode_screen.dart';

// ── Stage constants matching home_screen ──────────────────────────────
const _kStage1Ids = {
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
  15, 16, 17, 18, 19, 20, 21, 22, 38, 39, 40, 41, 42, 43
};
const _kStage2Ids = {
  23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
};

class ArcadeScreen extends StatefulWidget {
  final VoidCallback? onGoHome;

  const ArcadeScreen({super.key, this.onGoHome});

  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen> {
  final _lessonService   = LessonService();
  final _progressService = ProgressService();
  final _arcadeService   = ArcadeService();

  List<Lesson>    _lessons  = [];
  UserProgress    _progress = UserProgress();
  int             _highScore = 0;
  bool            _loading  = true;

  // Stage selector state
  bool _stage1Available = false;
  bool _stage2Available = false;
  bool _stage1Selected  = true;
  bool _stage2Selected  = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessons  = await _lessonService.loadAllLessons();
    final progress = await _progressService.load();
    final hs       = await _arcadeService.getHighScore();

    final s1Avail = lessons.any((l) =>
        _kStage1Ids.contains(l.id) &&
        (progress.lessonProgress[l.id]?.timesCompleted ?? 0) >= 1);
    final s2Avail = lessons.any((l) =>
        _kStage2Ids.contains(l.id) &&
        (progress.lessonProgress[l.id]?.timesCompleted ?? 0) >= 1);

    if (mounted) {
      setState(() {
        _lessons          = lessons;
        _progress         = progress;
        _highScore        = hs;
        _stage1Available  = s1Avail;
        _stage2Available  = s2Avail;
        _stage1Selected   = s1Avail;
        _stage2Selected   = s2Avail;
        _loading          = false;
      });
    }
  }

  // ── Word pool helpers ─────────────────────────────────────────────────

  List<Word> _buildWordPool() {
    final wordMap = <String, Word>{};
    for (final lesson in _lessons) {
      final tc = _progress.lessonProgress[lesson.id]?.timesCompleted ?? 0;
      if (tc < 1) continue;

      final inS1 = _kStage1Ids.contains(lesson.id) && _stage1Selected;
      final inS2 = _kStage2Ids.contains(lesson.id) && _stage2Selected;
      if (!inS1 && !inS2) continue;

      for (final w in lesson.words) { wordMap[w.id] = w; }
    }
    return wordMap.values.toList();
  }

  int get _wordCount => _buildWordPool().length;

  bool get _canPlay {
    if (!_stage1Selected && !_stage2Selected) return false;
    return _wordCount >= 20;
  }

  // ── Navigation ────────────────────────────────────────────────────────

  void _startSpeedMode() {
    final pool = _buildWordPool();
    if (pool.length < 20) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => SpeedModeScreen(
          wordPool: pool,
          onGoHome: widget.onGoHome,
        ),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ).then((_) => _load());
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.thaiGold),
            )
          : CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSpeedModeCard(),
                      const SizedBox(height: 12),
                      _buildLockedCard('Survival Mode', '💀',
                          'How long can you last with only 1 heart?'),
                      const SizedBox(height: 8),
                      _buildLockedCard('Word Blitz', '🌪️',
                          'Match as many pairs as possible in 60 seconds'),
                      const SizedBox(height: 8),
                      _buildLockedCard('Thai Typhoon', '🌊',
                          'Words rain from the sky — tap the correct translation before they hit the ground'),
                      const SizedBox(height: 24),
                      _buildStageSelector(),
                      const SizedBox(height: 24),
                      _buildLeaderboard(),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  SliverAppBar _buildHeader() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF12162B),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF12162B), Color(0xFF1A1F3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Arcade 🕹️',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.thaiGold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Test your Thai skills!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_highScore > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.thaiGold.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusFull),
                              border: Border.all(
                                  color: AppTheme.thaiGold.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '🏆 Best: $_highScore pts',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.thaiGold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const BobbingMascot(size: 64, mood: MascotMood.excited),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Speed Mode Card ───────────────────────────────────────────────────

  Widget _buildSpeedModeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB5001C), Color(0xFF7A0012)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.thaiRed.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Speed Mode',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    Text('Race against the clock!',
                        style: TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  _highScore > 0 ? 'Best: $_highScore pts' : 'No score yet',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Answer as fast as you can! Combos multiply your score.',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _canPlay ? _startSpeedMode : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: _canPlay ? Colors.white : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                _canPlay ? 'PLAY ⚡' : 'Select stages below to play',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _canPlay ? AppTheme.thaiRed : Colors.white60,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildLockedCard(String name, String emoji, String description) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(emoji,
              style: TextStyle(
                  fontSize: 28,
                  color: Colors.white.withValues(alpha: 0.3))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.35))),
                const SizedBox(height: 3),
                Text(description,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.25)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text('Coming Soon 🔒',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.4))),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  // ── Stage Selector ────────────────────────────────────────────────────

  Widget _buildStageSelector() {
    if (!_stage1Available && !_stage2Available) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Column(
          children: [
            Text('🔒', style: TextStyle(fontSize: 32)),
            SizedBox(height: 12),
            Text(
              'Complete more lessons to unlock Speed Mode!\nYou need at least 20 words.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final atLeastOneSelected = _stage1Selected || _stage2Selected;
    final count = _wordCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your word pool:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_stage1Available)
                _StageToggle(
                  label: 'Stage 1',
                  selected: _stage1Selected,
                  onTap: () {
                    final next = !_stage1Selected;
                    if (!next && !_stage2Selected) return;
                    setState(() => _stage1Selected = next);
                  },
                ),
              if (_stage2Available)
                _StageToggle(
                  label: 'Stage 2',
                  selected: _stage2Selected,
                  onTap: () {
                    final next = !_stage2Selected;
                    if (!next && !_stage1Selected) return;
                    setState(() => _stage2Selected = next);
                  },
                ),
              if (_stage1Available && _stage2Available)
                _StageToggle(
                  label: 'All Stages',
                  selected: _stage1Selected && _stage2Selected,
                  onTap: () {
                    final allSelected = _stage1Selected && _stage2Selected;
                    setState(() {
                      _stage1Selected = !allSelected;
                      _stage2Selected = !allSelected;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Words available: $count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: count >= 20
                      ? const Color(0xFF4CAF50)
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: 6),
              if (count < 20)
                Text(
                  '(need ${20 - count} more)',
                  style: const TextStyle(fontSize: 11, color: Colors.orange),
                ),
            ],
          ),
          if (!atLeastOneSelected)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Select at least one stage',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.withValues(alpha: 0.8),
                ),
              ),
            ),
          if (count > 0 && count < 20)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Complete more lessons to unlock Speed Mode!\nYou need at least 20 words.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }

  // ── Leaderboard ───────────────────────────────────────────────────────

  Widget _buildLeaderboard() {
    final currentUid = FirebaseService().getUserId();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏆 Speed Mode Leaderboard',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppTheme.thaiGold,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _arcadeService.leaderboardStream(limit: 10),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: AppTheme.thaiGold, strokeWidth: 2),
                ),
              );
            }
            if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Text(
                  'No scores yet — be the first! 🏅',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            final entries = snap.data!;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < entries.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                    _LbRow(
                      rank: i + 1,
                      entry: entries[i],
                      isMe: entries[i]['uid'] == currentUid,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }
}

// ── Stage Toggle Button ────────────────────────────────────────────────
class _StageToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _StageToggle({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.thaiGold : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: selected
                ? AppTheme.thaiGold
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppTheme.thaiNavy : Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

// ── Leaderboard Row ────────────────────────────────────────────────────
class _LbRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;
  final bool isMe;
  const _LbRow({required this.rank, required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: isMe
          ? BoxDecoration(
              color: AppTheme.thaiGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              medal ?? '#$rank',
              style: TextStyle(
                fontSize: medal != null ? 18 : 13,
                fontWeight: FontWeight.w800,
                color: isMe ? AppTheme.thaiGold : Colors.white.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Text(entry['avatarEmoji'] as String? ?? '🧑',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry['username'] as String? ?? 'Player',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isMe ? AppTheme.thaiGold : Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${entry['score']} pts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isMe ? AppTheme.thaiGold : Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
