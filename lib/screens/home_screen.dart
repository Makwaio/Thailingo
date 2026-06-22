import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/lesson.dart';
import '../models/user_progress.dart';
import '../services/lesson_service.dart';
import '../services/progress_service.dart';
import '../services/review_service.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/common_widgets.dart';
import 'lesson_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

// ── Stage configuration ────────────────────────────────────────────────
class _StageConfig {
  final int number;
  final String title;
  final Color color;
  final Color darkColor;
  final List<int> lessonIds;

  const _StageConfig(
      this.number, this.title, this.color, this.darkColor, this.lessonIds);
}

const _stages = [
  _StageConfig(1, 'Foundations', Color(0xFF1565C0), Color(0xFF0D47A1),
      [1, 2, 3, 4]),
  _StageConfig(2, 'People & Places', Color(0xFF6A1B9A), Color(0xFF4A148C),
      [5, 6, 7, 8]),
  _StageConfig(3, 'Street Life', Color(0xFFE65100), Color(0xFFBF360C),
      [9, 10, 11, 12]),
  _StageConfig(4, 'Sentences', Color(0xFF2E7D32), Color(0xFF1B5E20),
      [13, 14, 15]),
];

// ── Streak banner status ───────────────────────────────────────────────
enum _StreakStatus { none, playedToday, atRisk, keepAlive }

// ── Home Screen ────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _lessonService = LessonService();
  final _progressService = ProgressService();
  final _scrollCtrl = ScrollController();

  List<Lesson> _lessons = [];
  UserProgress _progress = UserProgress();
  int _reviewCount = 0;
  bool _loading = true;

  // Streak banner
  _StreakStatus _streakStatus = _StreakStatus.none;
  bool _bannerVisible = false;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final lessons = await _lessonService.loadAllLessons();
    final progress = await _progressService.load();
    final reviewCount = await ReviewService().getCount();

    // Compute streak banner status
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    final lastDate = progress.lastPlayedDate;

    _StreakStatus status;
    if (lastDate == today) {
      status = _StreakStatus.playedToday;
    } else if (lastDate == yesterday && progress.streak > 0) {
      status = _StreakStatus.atRisk;
    } else if (progress.streak > 0 || lastDate != null) {
      status = _StreakStatus.keepAlive;
    } else {
      status = _StreakStatus.none;
    }

    if (mounted) {
      _bannerTimer?.cancel();
      setState(() {
        _lessons = lessons;
        _progress = progress;
        _reviewCount = reviewCount;
        _loading = false;
        _streakStatus = status;
        _bannerVisible = status != _StreakStatus.none;
      });

      // Auto-dismiss "played today" green banner after 3 seconds
      if (status == _StreakStatus.playedToday) {
        _bannerTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _bannerVisible = false);
        });
      }
    }
  }

  void _scrollToLessons() {
    _scrollCtrl.animateTo(
      220,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          _buildHeader(),
          if (_bannerVisible)
            SliverToBoxAdapter(
              child: _StreakBanner(
                status: _streakStatus,
                streak: _progress.streak,
                onStartLearning: _scrollToLessons,
                onDismiss: () => setState(() => _bannerVisible = false),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate(_buildItems()),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the flat mixed list: stage banners interleaved with lesson tiles
  List<Widget> _buildItems() {
    final items = <Widget>[];
    int zigzagIdx = 0;
    int animIdx = 0;

    for (final stage in _stages) {
      final firstId = stage.lessonIds.first;
      final stageUnlocked =
          firstId > _lessons.length ? false : _progress.isLessonUnlocked(firstId);
      final stageComplete = stage.lessonIds.every(
          (id) => id <= _lessons.length && _progress.lessonStars(id) >= 3);

      items.add(_StageBanner(
        number: stage.number,
        title: stage.title,
        color: stage.color,
        darkColor: stage.darkColor,
        locked: !stageUnlocked,
        allComplete: stageComplete,
        animDelay: (animIdx * 60).ms,
      ));
      animIdx++;

      for (final lessonId in stage.lessonIds) {
        if (lessonId > _lessons.length) break;
        final lesson = _lessons[lessonId - 1];
        items.add(_buildLessonTile(lesson, zigzagIdx, animIdx));
        zigzagIdx++;
        animIdx++;
      }
    }

    // Review section — always visible below all stages
    items.add(const SizedBox(height: 24));
    items.add(_ReviewSection(
      count: _reviewCount,
      onTap: _startReview,
    ));

    return items;
  }

  Widget _buildLessonTile(Lesson lesson, int zigzagIdx, int animIdx) {
    final unlocked = _progress.isLessonUnlocked(lesson.id);
    final completed = _progress.isLessonCompleted(lesson.id);
    final stars = _progress.lessonStars(lesson.id);
    final lessonColor = HexColor.fromHex(lesson.colorHex);
    final isLeft = zigzagIdx % 2 == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          _LessonBubble(
            lesson: lesson,
            color: lessonColor,
            unlocked: unlocked,
            completed: completed,
            stars: stars,
            onTap: unlocked ? () => _startLesson(lesson) : null,
          ),
        ],
      ),
    )
        .animate(delay: (animIdx * 60).ms)
        .fadeIn(duration: 400.ms)
        .slideX(
            begin: isLeft ? -0.3 : 0.3,
            duration: 400.ms,
            curve: Curves.easeOut);
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🇹🇭 Thai Lab',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          Text('Bangkok Thai',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  letterSpacing: 1)),
                        ],
                      ),
                      const Spacer(),
                      StatPill(
                          emoji: '🔥',
                          value: '${_progress.streak}',
                          color: const Color(0xFFFF9600)),
                      const SizedBox(width: 8),
                      StatPill(
                          emoji: '⭐',
                          value: '${_progress.totalXp}',
                          color: AppTheme.accent),
                      const SizedBox(width: 8),
                      _HeaderIconBtn(
                        icon: Icons.emoji_events_rounded,
                        onTap: _openStats,
                      ),
                      const SizedBox(width: 6),
                      _HeaderIconBtn(
                        icon: Icons.settings_rounded,
                        onTap: _openSettings,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  XpProgressBar(xp: _progress.totalXp, level: _progress.level),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const SettingsScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _openStats() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const StatsScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _startReview() async {
    if (_reviewCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to review yet! Make some mistakes first 😄'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const ReviewScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _startLesson(Lesson lesson) async {
    await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => LessonScreen(lesson: lesson),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (mounted) _load();
  }
}

// ── Header Icon Button ─────────────────────────────────────────────────
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ── Streak Banner ──────────────────────────────────────────────────────
class _StreakBanner extends StatelessWidget {
  final _StreakStatus status;
  final int streak;
  final VoidCallback onStartLearning;
  final VoidCallback onDismiss;

  const _StreakBanner({
    required this.status,
    required this.streak,
    required this.onStartLearning,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    String message;
    bool showButton;

    switch (status) {
      case _StreakStatus.playedToday:
        bg = const Color(0xFFE8F5E9);
        border = const Color(0xFF66BB6A);
        message = '✅ Great work! Streak: $streak ${streak == 1 ? 'day' : 'days'} 🔥';
        showButton = false;
        break;
      case _StreakStatus.atRisk:
        bg = const Color(0xFFFFF8E1);
        border = const Color(0xFFFFB300);
        message = '⚠️ Your $streak day streak is at risk!';
        showButton = true;
        break;
      case _StreakStatus.keepAlive:
        bg = const Color(0xFFFFEBEE);
        border = const Color(0xFFEF5350);
        message = '🔥 Keep your streak alive!';
        showButton = true;
        break;
      case _StreakStatus.none:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
          ),
          if (showButton) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onStartLearning,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Text('Start',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ] else ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded, color: border, size: 18),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.3, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ── Stage Banner ───────────────────────────────────────────────────────
class _StageBanner extends StatelessWidget {
  final int number;
  final String title;
  final Color color;
  final Color darkColor;
  final bool locked;
  final bool allComplete;
  final Duration animDelay;

  const _StageBanner({
    required this.number,
    required this.title,
    required this.color,
    required this.darkColor,
    required this.locked,
    required this.allComplete,
    required this.animDelay,
  });

  @override
  Widget build(BuildContext context) {
    final bannerColor = locked ? const Color(0xFF9E9E9E) : color;
    final bannerDark = locked ? const Color(0xFF616161) : darkColor;

    return Container(
      margin: const EdgeInsets.only(top: 28, bottom: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bannerColor, bannerDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: locked
            ? []
            : [
                BoxShadow(
                  color: color.withOpacity(0.38),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STAGE $number',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  child: Icon(
                    locked
                        ? Icons.lock_rounded
                        : allComplete
                            ? Icons.emoji_events_rounded
                            : Icons.play_arrow_rounded,
                    color: Colors.white.withOpacity(locked ? 0.65 : 0.95),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: animDelay)
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.25, duration: 450.ms, curve: Curves.easeOut);
  }
}

// ── Review Section ─────────────────────────────────────────────────────
class _ReviewSection extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const _ReviewSection({required this.count, required this.onTap});

  @override
  State<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<_ReviewSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _bobble;

  @override
  void initState() {
    super.initState();
    _bobble = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    if (widget.count > 0) _bobble.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_ReviewSection old) {
    super.didUpdateWidget(old);
    if (widget.count > 0 && !_bobble.isAnimating) {
      _bobble.repeat(reverse: true);
    } else if (widget.count == 0 && _bobble.isAnimating) {
      _bobble.stop();
    }
  }

  @override
  void dispose() {
    _bobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.count > 0;
    const activeColor = Color(0xFF7C3AED);
    final bubbleColor = active ? activeColor : AppTheme.locked;

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppTheme.border, thickness: 1.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'REVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: active ? activeColor : AppTheme.textSecondary,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppTheme.border, thickness: 1.5)),
          ],
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _bobble,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, active ? (_bobble.value - 0.5) * 8 : 0),
              child: child,
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bubbleColor,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: activeColor.withOpacity(0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                )
                              ]
                            : [],
                      ),
                      child: const Center(
                        child: Text('📝', style: TextStyle(fontSize: 30)),
                      ),
                    ),
                    if (active)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.danger,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                            border:
                                Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            '${widget.count}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Review Mode',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  active
                      ? '${widget.count} ${widget.count == 1 ? 'word' : 'words'} to practise'
                      : 'All caught up! ✓',
                  style: TextStyle(
                    fontSize: 11,
                    color: active
                        ? AppTheme.textSecondary
                        : const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 100.ms)
        .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ── Lesson Bubble ──────────────────────────────────────────────────────
class _LessonBubble extends StatefulWidget {
  final Lesson lesson;
  final Color color;
  final bool unlocked;
  final bool completed;
  final int stars;
  final VoidCallback? onTap;

  const _LessonBubble({
    required this.lesson,
    required this.color,
    required this.unlocked,
    required this.completed,
    required this.stars,
    this.onTap,
  });

  @override
  State<_LessonBubble> createState() => _LessonBubbleState();
}

class _LessonBubbleState extends State<_LessonBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _bobble;

  @override
  void initState() {
    super.initState();
    _bobble = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    if (widget.unlocked && !widget.completed) {
      _bobble.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bobble.dispose();
    super.dispose();
  }

  String _emoji(int id) {
    const map = {
      1: '👋', 2: '🔢', 3: '🍜', 4: '🥤',
      5: '👨‍👩‍👧', 6: '🎨', 7: '🚕', 8: '🗺️',
      9: '🐘', 10: '🛒', 11: '💬', 12: '🏪',
      13: '📝', 14: '🕐', 15: '😊',
    };
    return map[id] ?? '📚';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete the previous lesson first!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _bobble,
        builder: (_, child) => Transform.translate(
          offset: Offset(
              0,
              widget.unlocked && !widget.completed
                  ? (_bobble.value - 0.5) * 8
                  : 0),
          child: child,
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.unlocked ? widget.color : AppTheme.locked,
                boxShadow: widget.unlocked
                    ? [
                        BoxShadow(
                            color: widget.color.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(_emoji(widget.lesson.id),
                      style: const TextStyle(fontSize: 30)),
                  if (!widget.unlocked)
                    const Positioned(
                      bottom: 6,
                      right: 6,
                      child: Icon(Icons.lock_rounded,
                          color: Colors.white, size: 16),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 100,
              child: Text(
                widget.lesson.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.unlocked
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary),
              ),
            ),
            if (widget.completed) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Text('⭐',
                      style: TextStyle(
                          fontSize: 11,
                          color: i < widget.stars
                              ? null
                              : Colors.grey.withOpacity(0.4))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
