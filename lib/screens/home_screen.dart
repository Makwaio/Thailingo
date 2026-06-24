import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson.dart';
import '../models/user_progress.dart';
import '../services/lesson_service.dart';
import '../services/progress_service.dart';
import '../services/review_service.dart';
import '../services/firebase_service.dart';
import '../services/user_service.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/common_widgets.dart';
import '../ui/widgets/thai_mascot.dart';
import '../services/patch_notes_service.dart';
import 'lesson_screen.dart';
import 'login_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'guide_book_screen.dart';
import 'stage0_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'whats_new_screen.dart';
import 'bug_report_dialog.dart';

// ── Row groupings ──────────────────────────────────────────────────────
class _RowConfig {
  final String label;
  final List<int> lessonIds;
  const _RowConfig(this.label, this.lessonIds);
}

const _stage1Rows = [
  _RowConfig('First Steps', [1, 22, 11]),
  _RowConfig('Numbers & Money', [2, 10, 12]),
  _RowConfig('Food & Drinks', [3, 4, 9]),
  _RowConfig('Language Basics', [13, 14, 6]),
  _RowConfig('People & Feelings', [5, 15, 19]),
  _RowConfig('Getting Around', [7, 8, 17, 18]),
  _RowConfig('Home & Learning', [16, 20, 21]),
  _RowConfig('Real Bangkok Life', [38, 39, 40]),
  _RowConfig('Finishing Stage 1', [41, 42, 43]),
];

const _stage2Rows = [
  _RowConfig('Food & Social', [23, 24, 31, 33]),
  _RowConfig('Help & Health', [25, 26, 35]),
  _RowConfig('Planning & Self', [27, 28, 29]),
  _RowConfig('Language Tools', [30, 32, 36, 34]),
  _RowConfig('Getting Around Advanced', [37]),
];

// ── Stage 1 lesson unlock chain (old IDs in unlock order) ─────────────
const _stage1Chain = [1, 22, 11, 2, 3, 4, 13, 14, 6, 5, 7, 8, 10, 12, 15, 9, 16, 17, 18, 19, 20, 21, 38, 39, 40, 41, 42, 43];

// ── Stage color anchors for smooth progression ─────────────────────────
const _s1ColorAnchors = <(int, Color)>[
  (1,  Color(0xFF4CAF50)),
  (4,  Color(0xFF2E7D32)),
  (7,  Color(0xFF00796B)),
  (10, Color(0xFF00838F)),
  (13, Color(0xFF0277BD)),
  (16, Color(0xFF1565C0)),
  (19, Color(0xFF283593)),
  (22, Color(0xFF3949AB)),
  (25, Color(0xFF4527A0)),
  (28, Color(0xFF311B92)),
];

const _s2ColorAnchors = <(int, Color)>[
  (1,  Color(0xFF6A1B9A)),
  (5,  Color(0xFF880E4F)),
  (9,  Color(0xFFC62828)),
  (12, Color(0xFFBF360C)),
  (15, Color(0xFFE65100)),
];

Color _lerpAnchors(int pos, List<(int, Color)> anchors) {
  if (pos <= anchors.first.$1) return anchors.first.$2;
  if (pos >= anchors.last.$1) return anchors.last.$2;
  for (int i = 0; i < anchors.length - 1; i++) {
    final (p1, c1) = anchors[i];
    final (p2, c2) = anchors[i + 1];
    if (pos >= p1 && pos <= p2) {
      return Color.lerp(c1, c2, (pos - p1) / (p2 - p1))!;
    }
  }
  return anchors.last.$2;
}

Color _lessonFillColor(int lessonId) {
  final s1Idx = _stage1Chain.indexOf(lessonId);
  if (s1Idx >= 0) return _lerpAnchors(s1Idx + 1, _s1ColorAnchors);
  const s2Ids = [23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37];
  final s2Idx = s2Ids.indexOf(lessonId);
  if (s2Idx >= 0) return _lerpAnchors(s2Idx + 1, _s2ColorAnchors);
  return AppTheme.primary;
}

// ── Stage color themes ─────────────────────────────────────────────────
const _s1Bg     = Color(0xFFE8EAF6); // light indigo
const _s1Accent = AppTheme.thaiNavy;
const _s2Bg     = Color(0xFFE8F5E9); // light green
const _s2Accent = Color(0xFF1B5E20);
const _s3Bg     = Color(0xFFFFF3E0); // light orange
const _s3Accent = Color(0xFFE65100);

// ── Emoji map ──────────────────────────────────────────────────────────
String _lessonEmoji(int id) {
  const map = {
    1: '👋', 2: '🔢', 3: '🍜', 4: '🥤',
    5: '👨‍👩‍👧', 6: '🎨', 7: '🚕', 8: '🗺️',
    9: '🐘', 10: '🛒', 11: '💬', 12: '🏪',
    13: '📝', 14: '🕐', 15: '😊', 16: '💪',
    17: '⛈️', 18: '🏛️', 19: '👔', 20: '🏠',
    21: '📚', 22: '🙏', 23: '🍽️', 24: '💰',
    25: '🆘', 26: '🏥', 27: '📅', 28: '👤',
    29: '⏰', 30: '🔢', 31: '😎', 32: '💯',
    33: '❤️', 34: '📱', 35: '🏯', 36: '💼',
    37: '🗺️',
    38: '📅', 39: '🎬', 40: '🛒',
    41: '👋', 42: '💯', 43: '😎',
  };
  return map[id] ?? '📚';
}

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
  _StreakStatus _streakStatus = _StreakStatus.none;
  bool _bannerVisible = false;
  Timer? _bannerTimer;
  String _avatarEmoji = '';
  bool _isSignedIn = false;

  int? _weeklyRank;
  int? _weeklyXp;
  bool _weeklyBannerVisible = false;
  Timer? _weeklyBannerTimer;
  static const _weeklyRankPrefKey = 'weekly_rank_last';

  bool _whatsNewChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load().then((_) {
      if (!_whatsNewChecked) {
        _whatsNewChecked = true;
        _checkForWhatsNew();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerTimer?.cancel();
    _weeklyBannerTimer?.cancel();
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

    // Load Firebase profile + weekly rank if signed in
    final firebaseService = FirebaseService();
    String avatarEmoji = '';
    bool isSignedIn = firebaseService.isSignedIn();
    int? weeklyRank;
    int? weeklyXp;
    bool showWeeklyBanner = false;

    if (isSignedIn) {
      final uid = firebaseService.getUserId()!;
      final profile = await UserService().getUserProfile(uid);
      avatarEmoji = profile?['avatarEmoji'] as String? ?? '';

      final rankInfo = await UserService().getWeeklyRankInfo(uid);
      if (rankInfo != null) {
        final rank = rankInfo['rank']!;
        final xp = rankInfo['weeklyXp']!;
        final prefs = await SharedPreferences.getInstance();
        final lastRank = prefs.getInt(_weeklyRankPrefKey) ?? 9999;
        if (rank < lastRank) {
          weeklyRank = rank;
          weeklyXp = xp;
          showWeeklyBanner = true;
          await prefs.setInt(_weeklyRankPrefKey, rank);
        }
      }
    }

    if (mounted) {
      _bannerTimer?.cancel();
      _weeklyBannerTimer?.cancel();
      setState(() {
        _lessons = lessons;
        _progress = progress;
        _reviewCount = reviewCount;
        _loading = false;
        _streakStatus = status;
        _bannerVisible = status != _StreakStatus.none;
        _avatarEmoji = avatarEmoji;
        _isSignedIn = isSignedIn;
        if (weeklyRank != null) {
          _weeklyRank = weeklyRank;
          _weeklyXp = weeklyXp;
          _weeklyBannerVisible = showWeeklyBanner;
        }
      });
      if (status == _StreakStatus.playedToday) {
        _bannerTimer = Timer(const Duration(seconds: 3),
            () { if (mounted) setState(() => _bannerVisible = false); });
      }
      if (showWeeklyBanner) {
        _weeklyBannerTimer = Timer(const Duration(seconds: 6),
            () { if (mounted) setState(() => _weeklyBannerVisible = false); });
      }
    }
  }

  Future<void> _checkForWhatsNew() async {
    if (!mounted) return;
    final hasUnread = await PatchNotesService().hasUnreadNotes();
    if (!mounted || !hasUnread) return;
    final unread = await PatchNotesService().getUnreadNotes();
    if (!mounted || unread.isEmpty) return;
    await PatchNotesService()
        .markAllAsRead(unread.map((n) => n.version).toList());
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => WhatsNewDialog(notes: unread),
    );
  }

  void _scrollToLessons() {
    _scrollCtrl.animateTo(280,
        duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.thaiNavy)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
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
          if (_weeklyBannerVisible && _weeklyRank != null)
            SliverToBoxAdapter(
              child: _WeeklyRankBanner(
                rank: _weeklyRank!,
                weeklyXp: _weeklyXp ?? 0,
                onViewLeaderboard: () {
                  setState(() => _weeklyBannerVisible = false);
                  _weeklyBannerTimer?.cancel();
                  _openLeaderboard();
                },
                onDismiss: () => setState(() => _weeklyBannerVisible = false),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate(_buildItems()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Item list ────────────────────────────────────────────────────────

  List<Widget> _buildItems() {
    final items = <Widget>[];

    // Entry cards
    items.add(_buildEntryCards());
    items.add(const SizedBox(height: 16));

    // ── Stage 1 section ──
    items.add(_buildStageSection(
      bgColor: _s1Bg,
      accentColor: _s1Accent,
      stageNum: 1,
      title: 'Foundations 🇹🇭',
      subtitle: '28 lessons · Bangkok Thai basics',
      locked: false,
      allComplete: _progress.allStage1Complete,
      rows: _stage1Rows,
    ));

    // Stage 1 star tally
    items.add(_Stage1TallyCard(progress: _progress));

    // Gradient divider s1 → s2
    items.add(const _GradientDivider(from: _s1Bg, to: _s2Bg));

    // ── Stage 2 section ──
    final stage2Unlocked = _progress.allStage1Complete;
    items.add(_buildStageSection(
      bgColor: _s2Bg,
      accentColor: _s2Accent,
      stageNum: 2,
      title: 'Survival Thai 🏙️',
      subtitle: stage2Unlocked
          ? '15 lessons · Real-world Thai'
          : 'Complete all Stage 1 lessons to unlock',
      locked: !stage2Unlocked,
      allComplete: _progress.allStage2Complete,
      rows: stage2Unlocked ? _stage2Rows : const [],
    ));

    // Gradient divider s2 → s3
    items.add(const _GradientDivider(from: _s2Bg, to: _s3Bg));

    // ── Stage 3 placeholder ──
    items.add(_Stage3Placeholder());

    // ── Review ──
    items.add(const SizedBox(height: 24));
    items.add(_ReviewSection(count: _reviewCount, onTap: _startReview));

    return items;
  }

  Widget _buildStageSection({
    required Color bgColor,
    required Color accentColor,
    required int stageNum,
    required String title,
    required String subtitle,
    required bool locked,
    required bool allComplete,
    required List<_RowConfig> rows,
  }) {
    final rowWidgets = <Widget>[];
    for (final row in rows) {
      final rowLessons = row.lessonIds
          .where((id) => id <= _lessons.length)
          .map((id) => _lessons[id - 1])
          .toList();
      if (rowLessons.isEmpty) continue;
      rowWidgets.add(_LessonRow(
        label: row.label,
        labelColor: accentColor,
        lessons: rowLessons,
        progress: _progress,
        onTap: _startLesson,
        emojiFor: _lessonEmoji,
      ));
      rowWidgets.add(const SizedBox(height: 8));
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        children: [
          _StageBanner(
            stageNum: stageNum,
            title: title,
            subtitle: subtitle,
            accentColor: accentColor,
            locked: locked,
            allComplete: allComplete,
          ),
          if (rowWidgets.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...rowWidgets,
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  // ── Entry cards ──────────────────────────────────────────────────────

  Widget _buildEntryCards() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Alphabet card (40%)
          Expanded(
            flex: 40,
            child: GestureDetector(
              onTap: _openStage0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.thaiNavy, AppTheme.thaiNavyDk],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.thaiNavy.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('📚', style: TextStyle(fontSize: 22)),
                    SizedBox(height: 4),
                    Text('Alphabet',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    SizedBox(height: 2),
                    Text('Stage 0 · Optional',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white60)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Main course card (55%)
          Expanded(
            flex: 55,
            child: GestureDetector(
              onTap: _scrollToLessons,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.thaiRed, AppTheme.thaiRedDk],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.thaiRed.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🇹🇭', style: TextStyle(fontSize: 22)),
                    SizedBox(height: 4),
                    Text('Main Course',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    SizedBox(height: 2),
                    Text('Stages 1-3 · Start Here →',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  // ── Header ───────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final streak = _progress.streak;
    final mood = streak >= 7
        ? MascotMood.excited
        : streak > 0
            ? MascotMood.happy
            : MascotMood.neutral;

    final speechText = streak == 0
        ? 'สวัสดี! 🇹🇭'
        : streak >= 7
            ? '${streak}d streak! 🔥'
            : 'Day $streak! 🔥';

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.thaiNavyDk, AppTheme.thaiNavy, Color(0xFF3D3A8E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Left: info ─────────────────────────────────────
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + action buttons
                        Row(
                          children: [
                            // Avatar / profile button
                            GestureDetector(
                              onTap: _openProfile,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: _isSignedIn
                                          ? AppTheme.thaiGold
                                          : Colors.white.withValues(alpha: 0.3),
                                      width: _isSignedIn ? 1.5 : 1),
                                ),
                                child: Center(
                                  child: _isSignedIn && _avatarEmoji.isNotEmpty
                                      ? Text(_avatarEmoji,
                                          style: const TextStyle(fontSize: 16))
                                      : const Icon(Icons.person_rounded,
                                          color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Thailingo',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                            const Spacer(),
                            _HeaderIconBtn(
                                icon: Icons.menu_rounded,
                                onTap: _openMenu),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text('Bangkok Thai',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 10),
                        Row(children: [
                          StatPill(
                              emoji: '🔥',
                              value: '$streak',
                              color: const Color(0xFFFF9600)),
                          const SizedBox(width: 8),
                          StatPill(
                              emoji: '⭐',
                              value: '${_progress.totalXp}',
                              color: AppTheme.thaiGold),
                        ]),
                        const SizedBox(height: 10),
                        XpProgressBar(
                            xp: _progress.totalXp,
                            level: _progress.level,
                            onDark: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // ── Right: speech bubble + mascot ──────────────────
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Speech bubble to the left of mascot
                      Container(
                        constraints: const BoxConstraints(maxWidth: 80),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.thaiGold, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          speechText,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Right-pointing tail toward mascot
                      CustomPaint(
                        size: const Size(6, 10),
                        painter: _BubbleTailRightPainter(),
                      ),
                      const SizedBox(width: 2),
                      // Mascot character — flush to right edge
                      BobbingMascot(size: 64, mood: mood),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const ProfileScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _openLeaderboard() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const LeaderboardScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Future<void> _openGuideBook() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const GuideBookScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Future<void> _openStage0() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const Stage0Screen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const SettingsScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
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
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MenuSheet(
        isSignedIn: _isSignedIn,
        avatarEmoji: _avatarEmoji,
        onProfile: () { Navigator.pop(context); _openProfile(); },
        onStats: () { Navigator.pop(context); _openStats(); },
        onLeaderboard: () { Navigator.pop(context); _openLeaderboard(); },
        onGuideBook: () { Navigator.pop(context); _openGuideBook(); },
        onSettings: () { Navigator.pop(context); _openSettings(); },
        onBugReport: () {
          Navigator.pop(context);
          showBugReportDialog(context, screen: 'Home');
        },
        onWhatsNew: () {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const WhatsNewScreen()));
        },
        onSignOut: () { Navigator.pop(context); _signOut(); },
        onSignIn: () { Navigator.pop(context); _openSignIn(); },
      ),
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your progress is saved to the cloud.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign Out',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await FirebaseService().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openSignIn() async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _startLesson(Lesson lesson) async {
    if (!_progress.isLessonUnlocked(lesson.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the previous lesson first!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => LessonScreen(lesson: lesson),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (mounted) _load();
  }
}

// ── Menu bottom sheet ──────────────────────────────────────────────────
class _MenuSheet extends StatelessWidget {
  final bool isSignedIn;
  final String avatarEmoji;
  final VoidCallback onProfile;
  final VoidCallback onStats;
  final VoidCallback onLeaderboard;
  final VoidCallback onGuideBook;
  final VoidCallback onSettings;
  final VoidCallback onBugReport;
  final VoidCallback onWhatsNew;
  final VoidCallback onSignOut;
  final VoidCallback onSignIn;

  const _MenuSheet({
    required this.isSignedIn,
    required this.avatarEmoji,
    required this.onProfile,
    required this.onStats,
    required this.onLeaderboard,
    required this.onGuideBook,
    required this.onSettings,
    required this.onBugReport,
    required this.onWhatsNew,
    required this.onSignOut,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.thaiNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          0, 12, 0, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Profile header
          if (isSignedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.thaiGold, width: 2),
                    ),
                    child: Center(
                      child: avatarEmoji.isNotEmpty
                          ? Text(avatarEmoji,
                              style: const TextStyle(fontSize: 22))
                          : const Icon(Icons.person_rounded,
                              color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('My Account',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
          if (isSignedIn) const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          // Menu items
          _MenuItem(icon: '👤', label: 'Profile & Stats', onTap: onProfile),
          _MenuItem(icon: '🏆', label: 'Leaderboard', onTap: onLeaderboard),
          _MenuItem(icon: '📖', label: 'Guide Book', onTap: onGuideBook),
          _MenuItem(icon: '⚙️', label: 'Settings', onTap: onSettings),
          _MenuItem(icon: '🐛', label: 'Report a Bug', onTap: onBugReport),
          _MenuItem(icon: '📋', label: "What's New", onTap: onWhatsNew),
          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          if (isSignedIn)
            _MenuItem(
              icon: '🚪',
              label: 'Sign Out',
              onTap: onSignOut,
              labelColor: Colors.redAccent.shade100,
            )
          else
            _MenuItem(
              icon: '🔑',
              label: 'Sign In with Google',
              onTap: onSignIn,
              labelColor: AppTheme.thaiGold,
            ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? Colors.white),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Bubble tail — right-pointing (speech bubble left of mascot) ────────
class _BubbleTailRightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.thaiGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_BubbleTailRightPainter _) => false;
}

// ── Lesson Row ─────────────────────────────────────────────────────────
class _LessonRow extends StatelessWidget {
  final String label;
  final Color labelColor;
  final List<Lesson> lessons;
  final UserProgress progress;
  final void Function(Lesson) onTap;
  final String Function(int) emojiFor;

  const _LessonRow({
    required this.label,
    required this.labelColor,
    required this.lessons,
    required this.progress,
    required this.onTap,
    required this.emojiFor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider with label
        Row(
          children: [
            Expanded(child: Divider(color: labelColor.withValues(alpha: 0.3), thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: labelColor),
              ),
            ),
            Expanded(child: Divider(color: labelColor.withValues(alpha: 0.3), thickness: 1)),
          ],
        ),
        const SizedBox(height: 12),
        // Hex bubbles
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 12,
          children: lessons.asMap().entries.map((e) {
            final i = e.key;
            final lesson = e.value;
            final unlocked = progress.isLessonUnlocked(lesson.id);
            final completed = progress.isLessonCompleted(lesson.id);
            final stars = progress.lessonStars(lesson.id);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (i > 0) _DottedLine(
                    color: completed ? AppTheme.success : labelColor.withValues(alpha: 0.3)),
                _HexBubble(
                  lesson: lesson,
                  unlocked: unlocked,
                  completed: completed,
                  stars: stars,
                  emoji: emojiFor(lesson.id),
                  onTap: () => onTap(lesson),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Octagon Painter ────────────────────────────────────────────────────
class _OctagonPainter extends CustomPainter {
  final Color fillColor;
  final int stars;
  final double shimmer; // 0.0–1.0 for gold border shimmer
  final bool completed;

  _OctagonPainter({
    required this.fillColor,
    this.stars = 0,
    this.shimmer = 0,
    this.completed = false,
  });

  Path _oct(Size size, double inset) {
    final l = inset;
    final t = inset;
    final w = size.width - inset * 2;
    final h = size.height - inset * 2;
    if (w <= 2 || h <= 2) return Path();
    return Path()
      ..moveTo(l + w * 0.29, t)
      ..lineTo(l + w * 0.71, t)
      ..lineTo(l + w, t + h * 0.29)
      ..lineTo(l + w, t + h * 0.71)
      ..lineTo(l + w * 0.71, t + h)
      ..lineTo(l + w * 0.29, t + h)
      ..lineTo(l, t + h * 0.71)
      ..lineTo(l, t + h * 0.29)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    double fillInset;
    if (stars >= 3) {
      // Gold outer + Silver middle + Bronze inner
      final goldColor =
          Color.lerp(const Color(0xFFD4A017), Colors.white, shimmer * 0.4)!;
      canvas.drawPath(_oct(size, 2.0), Paint()
        ..color = goldColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0);
      canvas.drawPath(_oct(size, 5.5), Paint()
        ..color = const Color(0xFFB0BEC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0);
      canvas.drawPath(_oct(size, 8.5), Paint()
        ..color = const Color(0xFFCD7F32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0);
      fillInset = 10.5;
    } else if (stars >= 2) {
      // Silver outer + Bronze inner
      canvas.drawPath(_oct(size, 1.5), Paint()
        ..color = const Color(0xFFB0BEC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0);
      canvas.drawPath(_oct(size, 4.5), Paint()
        ..color = const Color(0xFFCD7F32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0);
      fillInset = 6.5;
    } else if (stars >= 1) {
      // Bronze border only
      canvas.drawPath(_oct(size, 1.5), Paint()
        ..color = const Color(0xFFCD7F32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0);
      fillInset = 3.5;
    } else {
      fillInset = 0.0;
    }

    canvas.drawPath(_oct(size, fillInset), Paint()..color = fillColor);

    // Glossy highlight for completed lessons
    if (completed) {
      final glossRect = Rect.fromLTWH(
          fillInset, fillInset,
          size.width - fillInset * 2, size.height - fillInset * 2);
      canvas.drawPath(
        _oct(size, fillInset),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: const Alignment(0.4, 1),
            colors: [
              Colors.white.withValues(alpha: 0.25),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55],
          ).createShader(glossRect),
      );
    }
  }

  @override
  bool shouldRepaint(_OctagonPainter old) =>
      old.fillColor != fillColor ||
      old.stars != stars ||
      old.shimmer != shimmer ||
      old.completed != completed;
}

// ── Octagon Bubble (lesson node) ───────────────────────────────────────
class _HexBubble extends StatefulWidget {
  final Lesson lesson;
  final bool unlocked;
  final bool completed;
  final int stars;
  final String emoji;
  final VoidCallback onTap;

  const _HexBubble({
    required this.lesson,
    required this.unlocked,
    required this.completed,
    required this.stars,
    required this.emoji,
    required this.onTap,
  });

  @override
  State<_HexBubble> createState() => _HexBubbleState();
}

class _HexBubbleState extends State<_HexBubble>
    with TickerProviderStateMixin {
  late AnimationController _bobble;
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _bobble = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _shimmer = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));
    if (widget.unlocked && !widget.completed) _bobble.repeat(reverse: true);
    if (widget.stars >= 3) _shimmer.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bobble.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const hexW = 68.0;
    const hexH = 78.0;

    final baseColor = _lessonFillColor(widget.lesson.id);
    final fillColor = widget.unlocked
        ? (widget.completed
            ? Color.lerp(baseColor, Colors.black, 0.18)!
            : baseColor)
        : AppTheme.locked;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bobble, _shimmer]),
        builder: (_, child) => Transform.translate(
          offset: Offset(
              0,
              widget.unlocked && !widget.completed
                  ? (_bobble.value - 0.5) * 8
                  : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: hexW,
                height: hexH,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Octagon shape with star borders
                    CustomPaint(
                      size: const Size(hexW, hexH),
                      painter: _OctagonPainter(
                        fillColor: fillColor,
                        stars: widget.unlocked ? widget.stars : 0,
                        shimmer: _shimmer.value,
                        completed: widget.completed,
                      ),
                    ),
                    // Emoji
                    Text(widget.emoji,
                        style: const TextStyle(fontSize: 22)),
                    // Lock overlay
                    if (!widget.unlocked)
                      Positioned(
                        bottom: 12,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                              color: Colors.white54, shape: BoxShape.circle),
                          child: const Icon(Icons.lock_rounded,
                              color: AppTheme.textSecondary, size: 11),
                        ),
                      ),
                    // Completed checkmark badge
                    if (widget.completed)
                      Positioned(
                        top: 5,
                        right: 7,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                              color: AppTheme.success, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: 76,
                child: Text(
                  widget.lesson.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: widget.unlocked
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary),
                ),
              ),
              if (widget.unlocked) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Text('⭐',
                        style: TextStyle(
                            fontSize: 9,
                            color: i < widget.stars
                                ? null
                                : Colors.grey.withValues(alpha: 0.25))),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dotted path line ──────────────────────────────────────────────────
class _DottedLine extends StatelessWidget {
  final Color color;
  const _DottedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(20, 4), painter: _DottedPainter(color));
  }
}

class _DottedPainter extends CustomPainter {
  final Color color;
  const _DottedPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset(x + 4, size.height / 2), paint);
      x += 7;
    }
  }

  @override
  bool shouldRepaint(_DottedPainter old) => old.color != color;
}

// ── Gradient divider between stages ───────────────────────────────────
class _GradientDivider extends StatelessWidget {
  final Color from;
  final Color to;
  const _GradientDivider({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [from, to],
        ),
      ),
    );
  }
}

// ── Stage 1 Star Tally Card ────────────────────────────────────────────
class _Stage1TallyCard extends StatelessWidget {
  final UserProgress progress;
  const _Stage1TallyCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    const stage1Ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
        17, 18, 19, 20, 21, 22, 38, 39, 40, 41, 42, 43];
    int totalStars = 0, bronze = 0, silver = 0, gold = 0;
    for (final id in stage1Ids) {
      final s = progress.lessonStars(id);
      totalStars += s;
      if (s >= 1) bronze++;
      if (s >= 2) silver++;
      if (s >= 3) gold++;
    }
    const maxStars = 28 * 3; // 84

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _s1Bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _s1Accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Stage 1 Stars',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              Text('$totalStars / $maxStars ⭐',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                      color: _s1Accent)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: maxStars > 0 ? totalStars / maxStars : 0,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.thaiGold),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TallyBadge('🥉', '$bronze/28', 'Bronze', const Color(0xFFCD7F32)),
              _TallyBadge('🥈', '$silver/28', 'Silver', const Color(0xFF90A4AE)),
              _TallyBadge('🥇', '$gold/28', 'Gold', const Color(0xFFD4A017)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TallyBadge extends StatelessWidget {
  final String icon;
  final String count;
  final String label;
  final Color color;
  const _TallyBadge(this.icon, this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$icon $count',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

// ── Stage Banner ──────────────────────────────────────────────────────
class _StageBanner extends StatelessWidget {
  final int stageNum;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool locked;
  final bool allComplete;

  const _StageBanner({
    required this.stageNum,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.locked,
    required this.allComplete,
  });

  @override
  Widget build(BuildContext context) {
    final bannerColor = locked ? const Color(0xFF9E9E9E) : accentColor;
    final darkBanner = Color.lerp(bannerColor, Colors.black, 0.25)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bannerColor, darkBanner],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: locked
            ? []
            : [
                BoxShadow(
                  color: bannerColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            // Stage number circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Center(
                child: Text('$stageNum',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STAGE $stageNum',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0)),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11)),
                ],
              ),
            ),
            // Only show lock icon when locked; trophy when fully complete
            if (locked)
              Icon(Icons.lock_rounded,
                  color: Colors.white.withValues(alpha: 0.6), size: 22)
            else if (allComplete)
              const Icon(Icons.emoji_events_rounded,
                  color: AppTheme.thaiGold, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Stage 3 Placeholder ────────────────────────────────────────────────
class _Stage3Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _s3Bg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _s3Accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('3',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _s3Accent)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STAGE 3',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: _s3Accent)),
                    const Text('Conversational Thai 🗣️',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary)),
                    Text('Coming Soon 🔒',
                        style: TextStyle(
                            fontSize: 12, color: _s3Accent.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Icon(Icons.lock_rounded,
                  color: _s3Accent.withValues(alpha: 0.5), size: 22),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Advanced conversations, Thai script reading, proverbs, tone mastery and more!',
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
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
        message =
            '✅ Great work! Streak: $streak ${streak == 1 ? 'day' : 'days'} 🔥';
        showButton = false;
      case _StreakStatus.atRisk:
        bg = const Color(0xFFFFF8E1);
        border = const Color(0xFFFFB300);
        message = '⚠️ Your $streak day streak is at risk!';
        showButton = true;
      case _StreakStatus.keepAlive:
        bg = const Color(0xFFFFEBEE);
        border = AppTheme.thaiRed;
        message = '🔥 Keep your streak alive!';
        showButton = true;
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
            child: Text(message,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ),
          if (showButton) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onStartLearning,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: border,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull)),
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

// ── Weekly Rank Banner ─────────────────────────────────────────────────
class _WeeklyRankBanner extends StatelessWidget {
  final int rank;
  final int weeklyXp;
  final VoidCallback onViewLeaderboard;
  final VoidCallback onDismiss;

  const _WeeklyRankBanner({
    required this.rank,
    required this.weeklyXp,
    required this.onViewLeaderboard,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    String emoji;
    String headline;

    if (rank == 1) {
      emoji = '🥇';
      headline = 'You\'re #1 on the weekly leaderboard!';
    } else if (rank <= 3) {
      emoji = '🏆';
      headline = 'You\'re #$rank on the weekly leaderboard!';
    } else if (rank <= 10) {
      emoji = '🔥';
      headline = 'Top 10 this week — you\'re #$rank!';
    } else {
      emoji = '📈';
      headline = 'You climbed to #$rank this week!';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
                Text(
                  '$weeklyXp XP earned this week',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onViewLeaderboard,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: const Text(
                'View',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.3, duration: 350.ms, curve: Curves.easeOut);
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
    final bubbleColor = active ? const Color(0xFF7C3AED) : AppTheme.locked;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: Divider(
                    color: (active
                            ? const Color(0xFF7C3AED)
                            : AppTheme.textSecondary)
                        .withValues(alpha: 0.3),
                    thickness: 1.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'REVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: active
                      ? const Color(0xFF7C3AED)
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            Expanded(
                child: Divider(
                    color: (active
                            ? const Color(0xFF7C3AED)
                            : AppTheme.textSecondary)
                        .withValues(alpha: 0.3),
                    thickness: 1.5)),
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
                    // Hex shape for review bubble
                    SizedBox(
                      width: 72,
                      height: 82,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(72, 82),
                            painter: _OctagonPainter(
                              fillColor: bubbleColor,
                            ),
                          ),
                          const Text('📝',
                              style: TextStyle(fontSize: 28)),
                        ],
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
                            color: AppTheme.thaiRed,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull),
                            border: Border.all(
                                color: Colors.white, width: 1.5),
                          ),
                          child: Text('${widget.count}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Review Mode',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary)),
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
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
  }
}
