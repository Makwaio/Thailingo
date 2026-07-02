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
import 'arcade/skeet_shooter_screen.dart';
import 'arcade/survival_mode_screen.dart';
import 'arcade/word_blitz_screen.dart';

// ── Stage constants ───────────────────────────────────────────────────
const _kStage1Ids = {
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
  15, 16, 17, 18, 19, 20, 21, 22, 29, 30, 31, 32, 33,
};
const _kStage2Ids = {
  23, 24, 25, 26, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43,
  44, 45, 52, 53, 54, 55, 56, 57, 58, 59, 60, 64,
};
const _kStage3Ids = {
  46, 47, 48, 49, 50, 51, 61, 62, 63, 65, 66,
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
  int             _survHighScore = 0;
  String          _survBestGrade = '';
  int             _blitzHighScore = 0;
  String          _blitzBestGrade = '';
  bool            _loading  = true;
  int             _lbTab    = 0; // 0=Speed 1=Survival 2=Blitz

  // Stage selector state
  bool _stage1Available = false;
  bool _stage2Available = false;
  bool _stage3Available = false;
  bool _stage1Selected  = true;
  bool _stage2Selected  = true;
  bool _stage3Selected  = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessons  = await _lessonService.loadAllLessons();
    final progress = await _progressService.load();
    final hs         = await _arcadeService.getHighScore();
    final survHs     = await _arcadeService.getSurvivalBestScore();
    final survGrade  = await _arcadeService.getSurvivalBestGrade();
    final blitzHs    = await _arcadeService.getWordBlitzBestScore();
    final blitzGrade = await _arcadeService.getWordBlitzBestGrade();

    final s1Avail = lessons.any((l) =>
        _kStage1Ids.contains(l.id) &&
        (progress.lessonProgress[l.id]?.timesCompleted ?? 0) >= 1);
    final s2Avail = lessons.any((l) =>
        _kStage2Ids.contains(l.id) &&
        (progress.lessonProgress[l.id]?.timesCompleted ?? 0) >= 1);
    final s3Avail = lessons.any((l) =>
        _kStage3Ids.contains(l.id) &&
        (progress.lessonProgress[l.id]?.timesCompleted ?? 0) >= 1);

    if (mounted) {
      setState(() {
        _lessons          = lessons;
        _progress         = progress;
        _highScore        = hs;
        _survHighScore    = survHs;
        _survBestGrade    = survGrade;
        _blitzHighScore   = blitzHs;
        _blitzBestGrade   = blitzGrade;
        _stage1Available  = s1Avail;
        _stage2Available  = s2Avail;
        _stage3Available  = s3Avail;
        _stage1Selected   = s1Avail;
        _stage2Selected   = s2Avail;
        _stage3Selected   = s3Avail;
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
      final inS3 = _kStage3Ids.contains(lesson.id) && _stage3Selected;
      if (!inS1 && !inS2 && !inS3) continue;

      for (final w in lesson.words) { wordMap[w.id] = w; }
    }
    return wordMap.values.toList();
  }

  int get _wordCount => _buildWordPool().length;

  bool get _canPlay {
    if (!_stage1Selected && !_stage2Selected && !_stage3Selected) return false;
    return _wordCount >= 20;
  }

  int _stageWordCount(Set<int> ids) {
    final wordMap = <String, Word>{};
    for (final lesson in _lessons) {
      final tc = _progress.lessonProgress[lesson.id]?.timesCompleted ?? 0;
      if (tc < 1 || !ids.contains(lesson.id)) continue;
      for (final w in lesson.words) { wordMap[w.id] = w; }
    }
    return wordMap.length;
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

  void _startSkeetShooter() {
    final pool = _buildWordPool();
    if (pool.length < 10) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => SkeetShooterScreen(
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

  void _startSurvivalMode() {
    final pool = _buildWordPool();
    if (pool.length < 8) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            SurvivalModeScreen(wordPool: pool, onGoHome: widget.onGoHome),
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

  void _startWordBlitz() {
    final pool = _buildWordPool();
    if (pool.length < 8) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => WordBlitzScreen(wordPool: pool),
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
                      _buildSkeetShooterCard(),
                      const SizedBox(height: 8),
                      _buildSurvivalModeCard(),
                      const SizedBox(height: 8),
                      _buildWordBlitzCard(),
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

  Widget _buildSkeetShooterCard() {
    final canPlay = _wordCount >= 10;
    return GestureDetector(
      onTap: canPlay ? _startSkeetShooter : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B2500), Color(0xFFD4481F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4481F).withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Skeet Shooter',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(
                    canPlay
                        ? 'Shoot the right words before they fly by!'
                        : 'Complete at least one lesson to unlock',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: canPlay
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                canPlay ? 'PLAY' : '🔒',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: canPlay
                        ? const Color(0xFF8B2500)
                        : Colors.white60),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildSurvivalModeCard() {
    final canPlay = _wordCount >= 8;
    return GestureDetector(
      onTap: canPlay ? _startSurvivalMode : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1a0000), Color(0xFF4a0000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('💀', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Survival Mode',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(
                    canPlay
                        ? (_survHighScore > 0
                            ? 'Best: $_survHighScore  •  $_survBestGrade'
                            : 'One wrong answer and you\'re out!')
                        : 'Complete more lessons to unlock',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: canPlay
                    ? const Color(0xFFB5001C)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                canPlay ? 'SURVIVE' : '🔒',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: canPlay ? Colors.white : Colors.white60),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildWordBlitzCard() {
    final canPlay = _wordCount >= 8;
    return GestureDetector(
      onTap: canPlay ? _startWordBlitz : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1a0033), Color(0xFF4a0078)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
              color: const Color(0xFF9B59B6).withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2FBE).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('⚡', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Word Blitz',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(
                    canPlay
                        ? (_blitzHighScore > 0
                            ? 'Best: $_blitzHighScore pts  •  $_blitzBestGrade'
                            : 'Match pairs — 60 seconds on the clock!')
                        : 'Complete more lessons to unlock',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: canPlay
                    ? const Color(0xFF7B2FBE)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                canPlay ? 'BLITZ' : '🔒',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: canPlay ? Colors.white : Colors.white60),
              ),
            ),
          ],
        ),
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
    final anyAvailable = _stage1Available || _stage2Available || _stage3Available;
    if (!anyAvailable) {
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
              'Complete more lessons to unlock Arcade Mode!\nYou need at least 20 words.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
            ),
          ],
        ),
      );
    }

    final atLeastOneSelected = _stage1Selected || _stage2Selected || _stage3Selected;
    final count = _wordCount;
    final s1Count = _stageWordCount(_kStage1Ids);
    final s2Count = _stageWordCount(_kStage2Ids);
    final s3Count = _stageWordCount(_kStage3Ids);
    final allSelected = _stage1Selected && _stage2Selected && _stage3Selected;

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
                  label: 'Stage 1 ($s1Count)',
                  selected: _stage1Selected,
                  onTap: () {
                    final next = !_stage1Selected;
                    if (!next && !_stage2Selected && !_stage3Selected) return;
                    setState(() => _stage1Selected = next);
                  },
                ),
              if (_stage2Available)
                _StageToggle(
                  label: 'Stage 2 ($s2Count)',
                  selected: _stage2Selected,
                  onTap: () {
                    final next = !_stage2Selected;
                    if (!next && !_stage1Selected && !_stage3Selected) return;
                    setState(() => _stage2Selected = next);
                  },
                ),
              if (_stage3Available)
                _StageToggle(
                  label: 'Stage 3 ($s3Count)',
                  selected: _stage3Selected,
                  onTap: () {
                    final next = !_stage3Selected;
                    if (!next && !_stage1Selected && !_stage2Selected) return;
                    setState(() => _stage3Selected = next);
                  },
                ),
              if (((_stage1Available ? 1 : 0) + (_stage2Available ? 1 : 0) + (_stage3Available ? 1 : 0)) > 1)
                _StageToggle(
                  label: 'All Stages',
                  selected: allSelected,
                  onTap: () {
                    setState(() {
                      _stage1Selected = !allSelected && _stage1Available;
                      _stage2Selected = !allSelected && _stage2Available;
                      _stage3Selected = !allSelected && _stage3Available;
                      if (!_stage1Selected && !_stage2Selected && !_stage3Selected) {
                        _stage1Selected = _stage1Available;
                        _stage2Selected = _stage2Available;
                        _stage3Selected = _stage3Available;
                      }
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
                  color: count >= 20 ? const Color(0xFF4CAF50) : Colors.orange,
                ),
              ),
              const SizedBox(width: 6),
              if (count < 20)
                Text('(need ${20 - count} more)',
                    style: const TextStyle(fontSize: 11, color: Colors.orange)),
            ],
          ),
          if (!atLeastOneSelected)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Select at least one stage',
                style: TextStyle(fontSize: 12, color: Colors.orange.withValues(alpha: 0.8)),
              ),
            ),
          if (count > 0 && count < 20)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Complete more lessons to unlock Arcade Mode.\nYou need at least 20 words.',
                style: TextStyle(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.5), height: 1.4),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }

  // ── Leaderboard ───────────────────────────────────────────────────────

  Widget _buildLeaderboard() {
    final tabs = ['⚡ Speed', '💀 Survival', '⚡ Blitz'];
    final streams = [
      _arcadeService.leaderboardStream(limit: 10),
      _arcadeService.survivalLeaderboardStream(limit: 10),
      _arcadeService.wordBlitzLeaderboardStream(limit: 10),
    ];
    final currentUid = FirebaseService().getUserId();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏆 Leaderboard',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.thaiGold),
        ),
        const SizedBox(height: 10),
        // Tab row
        Row(
          children: List.generate(tabs.length, (i) {
            final sel = i == _lbTab;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _lbTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppTheme.thaiGold
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(tabs[i],
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel
                              ? AppTheme.thaiNavy
                              : Colors.white.withValues(alpha: 0.65))),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: streams[_lbTab],
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
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                ),
              );
            }
            final entries = snap.data!;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < entries.length; i++) ...[
                    if (i > 0)
                      Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.06)),
                    _LbRow(
                      rank: i + 1,
                      entry: entries[i],
                      isMe: entries[i]['uid'] == currentUid,
                      showGrade: _lbTab != 0,
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
  final bool showGrade;
  const _LbRow({
    required this.rank,
    required this.entry,
    required this.isMe,
    this.showGrade = false,
  });

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : null;
    final grade = entry['grade'] as String?;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry['username'] as String? ?? 'Player',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isMe ? AppTheme.thaiGold : Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (showGrade && grade != null && grade.isNotEmpty)
                  Text(
                    grade,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            showGrade ? '${entry['score']}' : '${entry['score']} pts',
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
