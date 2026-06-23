import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/lesson.dart';
import '../services/lesson_service.dart';
import '../services/progress_service.dart';
import '../ui/theme/app_theme.dart';
import 'lesson_screen.dart';

const _alphabetMeta = [
  (id: 'A1', emoji: '🅰️', title: 'Consonants 1', sub: '15 consonants'),
  (id: 'A2', emoji: '🔡', title: 'Consonants 2', sub: '15 consonants'),
  (id: 'A3', emoji: '🔤', title: 'Vowels', sub: '15 vowel forms'),
  (id: 'A4', emoji: '🎵', title: 'Tone Marks', sub: '4 tone marks'),
  (id: 'A5', emoji: '📖', title: 'Reading Practice', sub: 'Put it together'),
];

class Stage0Screen extends StatefulWidget {
  const Stage0Screen({super.key});

  @override
  State<Stage0Screen> createState() => _Stage0ScreenState();
}

class _Stage0ScreenState extends State<Stage0Screen> {
  final _lessonService = LessonService();
  final _progressService = ProgressService();

  List<Lesson?> _lessons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessons = <Lesson?>[];
    for (final meta in _alphabetMeta) {
      try {
        final l = await _lessonService.loadAlphabetLesson(meta.id);
        lessons.add(l);
      } catch (_) {
        lessons.add(null);
      }
    }
    if (mounted) {
      setState(() {
        _lessons = lessons;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.thaiNavyDk, AppTheme.thaiNavy, Color(0xFF3D3A8E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stage 0 — Alphabet',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                Text('Optional · Learn to read Thai script',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final progress = _progressService.current;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        children: [
          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Text(
              '📚 These 5 lessons teach you Thai consonants, vowels, tone marks and basic reading. They\'re optional — you can start the main course at any time!',
              style: TextStyle(
                  fontSize: 13, color: Colors.white, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),

          // Lesson bubbles (vertical linear path)
          ..._alphabetMeta.asMap().entries.map((e) {
            final i = e.key;
            final meta = e.value;
            final lesson = i < _lessons.length ? _lessons[i] : null;

            // Unlock rule: A1 always unlocked; An requires A(n-1) completed
            final bool unlocked;
            if (i == 0) {
              unlocked = true;
            } else {
              final prevId = _alphabetLessonDbId(i);
              unlocked = progress.isLessonCompleted(prevId);
            }
            final dbId = _alphabetLessonDbId(i + 1);
            final completed = progress.isLessonCompleted(dbId);
            final stars = progress.lessonStars(dbId);

            return Column(
              children: [
                if (i > 0)
                  _VerticalPath(completed: completed),
                _AlphabetBubble(
                  meta: meta,
                  unlocked: unlocked,
                  completed: completed,
                  stars: stars,
                  onTap: () => lesson != null
                      ? _startLesson(lesson)
                      : _showLockedMsg(),
                ),
              ],
            ).animate().fadeIn(
                duration: 400.ms, delay: Duration(milliseconds: i * 100));
          }),
        ],
      ),
    );
  }

  // Alphabet lessons use DB IDs 101-105
  int _alphabetLessonDbId(int index1Based) => 100 + index1Based;

  Future<void> _startLesson(Lesson lesson) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => LessonScreen(lesson: lesson),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (mounted) _load();
  }

  void _showLockedMsg() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lesson not available yet.'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

// ── Vertical path between bubbles ─────────────────────────────────────
class _VerticalPath extends StatelessWidget {
  final bool completed;
  const _VerticalPath({required this.completed});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(4, 48),
      painter: _VPathPainter(
          color: completed
              ? AppTheme.success
              : Colors.white.withValues(alpha: 0.3)),
    );
  }
}

class _VPathPainter extends CustomPainter {
  final Color color;
  const _VPathPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const dashH = 8.0;
    const gap = 5.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y),
          Offset(size.width / 2, (y + dashH).clamp(0, size.height)), paint);
      y += dashH + gap;
    }
  }

  @override
  bool shouldRepaint(_VPathPainter old) => old.color != color;
}

// ── Single alphabet lesson bubble ─────────────────────────────────────
class _AlphabetBubble extends StatefulWidget {
  final ({String id, String emoji, String title, String sub}) meta;
  final bool unlocked;
  final bool completed;
  final int stars;
  final VoidCallback onTap;

  const _AlphabetBubble({
    required this.meta,
    required this.unlocked,
    required this.completed,
    required this.stars,
    required this.onTap,
  });

  @override
  State<_AlphabetBubble> createState() => _AlphabetBubbleState();
}

class _AlphabetBubbleState extends State<_AlphabetBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    if (widget.unlocked && !widget.completed) _bob.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = widget.unlocked
        ? (widget.completed ? AppTheme.thaiGold : Colors.white)
        : Colors.white.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _bob,
        builder: (_, child) => Transform.translate(
          offset: Offset(
              0,
              widget.unlocked && !widget.completed
                  ? (_bob.value - 0.5) * 8
                  : 0),
          child: child,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bubbleColor,
                boxShadow: widget.unlocked
                    ? [
                        BoxShadow(
                          color: (widget.completed
                                  ? AppTheme.thaiGold
                                  : Colors.white)
                              .withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(widget.meta.emoji,
                      style: const TextStyle(fontSize: 32)),
                  if (!widget.unlocked)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: AppTheme.thaiNavy,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.lock_rounded,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  if (widget.completed)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.meta.title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: widget.unlocked ? Colors.white : Colors.white54),
                ),
                Text(
                  widget.meta.sub,
                  style: TextStyle(
                      fontSize: 13,
                      color: widget.unlocked
                          ? Colors.white70
                          : Colors.white38),
                ),
                if (widget.completed) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      3,
                      (i) => Text(
                        '⭐',
                        style: TextStyle(
                            fontSize: 12,
                            color: i < widget.stars
                                ? null
                                : Colors.grey.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
