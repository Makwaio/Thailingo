import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/review_service.dart';
import '../services/missed_questions_service.dart';
import '../ui/theme/app_theme.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'review_screen.dart';
import 'missed_review_screen.dart';
import 'arcade_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void switchTab(int index) {
    if (mounted) setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // ── Tab 0: Home ───────────────────────────────────────────
          HomeScreen(
            onSwitchToArcade: () => switchTab(3),
          ),
          // ── Tab 1: Stats ──────────────────────────────────────────
          const StatsScreen(isTab: true),
          // ── Tab 2: Review Hub ─────────────────────────────────────
          _ReviewHubTab(onBackToHome: () => switchTab(0)),
          // ── Tab 3: Arcade ─────────────────────────────────────────
          ArcadeScreen(
            onGoHome: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              switchTab(0);
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    const items = [
      BottomNavigationBarItem(
        icon:      Text('🏠', style: TextStyle(fontSize: 22)),
        activeIcon: Text('🏠', style: TextStyle(fontSize: 24)),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon:      Text('📊', style: TextStyle(fontSize: 22)),
        activeIcon: Text('📊', style: TextStyle(fontSize: 24)),
        label: 'Stats',
      ),
      BottomNavigationBarItem(
        icon:      Text('🔁', style: TextStyle(fontSize: 22)),
        activeIcon: Text('🔁', style: TextStyle(fontSize: 24)),
        label: 'Review',
      ),
      BottomNavigationBarItem(
        icon:      Text('🕹️', style: TextStyle(fontSize: 22)),
        activeIcon: Text('🕹️', style: TextStyle(fontSize: 24)),
        label: 'Arcade',
      ),
    ];

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap:        (i) => setState(() => _currentIndex = i),
      backgroundColor:    AppTheme.thaiNavy,
      selectedItemColor:  AppTheme.thaiGold,
      unselectedItemColor: Colors.white60,
      type:               BottomNavigationBarType.fixed,
      selectedFontSize:   11,
      unselectedFontSize: 10,
      enableFeedback:     true,
      items:              items,
    );
  }
}

// ── Review Hub Tab ─────────────────────────────────────────────────────
class _ReviewHubTab extends StatefulWidget {
  final VoidCallback onBackToHome;
  const _ReviewHubTab({required this.onBackToHome});

  @override
  State<_ReviewHubTab> createState() => _ReviewHubTabState();
}

class _ReviewHubTabState extends State<_ReviewHubTab>
    with WidgetsBindingObserver {
  int  _reviewCount = 0;
  int  _missedCount = 0;
  bool _loading     = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final r = await ReviewService().getCount();
    final m = await MissedQuestionsService().getMissedCount();
    if (mounted) {
      setState(() {
        _reviewCount = r;
        _missedCount = m;
        _loading     = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.thaiNavy))
            : CustomScrollView(
                slivers: [
                  const SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: AppTheme.thaiNavy,
                    title: Text(
                      'Review 🔁',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    centerTitle: false,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildReviewCard(),
                        const SizedBox(height: 16),
                        _buildMissedCard(),
                        const SizedBox(height: 32),
                        if (_reviewCount == 0 && _missedCount == 0)
                          _buildAllClearBanner(),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildReviewCard() {
    final active = _reviewCount > 0;
    return GestureDetector(
      onTap: active
          ? () async {
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
              _load();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : AppTheme.locked.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('📝', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Mode',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: active ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    active
                        ? '$_reviewCount ${_reviewCount == 1 ? 'word' : 'words'} ready for review'
                        : 'All caught up! ✓',
                    style: TextStyle(
                      fontSize: 13,
                      color: active
                          ? Colors.white.withValues(alpha: 0.8)
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Text(
                  'START',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildMissedCard() {
    final active = _missedCount > 0;
    return GestureDetector(
      onTap: active
          ? () async {
              await Navigator.push<bool>(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, anim, __) => const MissedReviewScreen(),
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
              _load();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFBF360C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : AppTheme.locked.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFFE65100).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('❓', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Missed Words',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: active ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    active
                        ? '$_missedCount ${_missedCount == 1 ? 'word' : 'words'} to catch up'
                        : 'All Clear ✅',
                    style: TextStyle(
                      fontSize: 13,
                      color: active
                          ? Colors.white.withValues(alpha: 0.8)
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Text(
                  'START',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.1);
  }

  Widget _buildAllClearBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: const Color(0xFF66BB6A)),
      ),
      child: const Column(
        children: [
          Text('🎉', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text(
            'All caught up!',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B5E20)),
          ),
          SizedBox(height: 6),
          Text(
            'Make some mistakes in lessons to build your review queue.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 150.ms);
  }
}
