import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/lesson.dart';
import '../ui/theme/app_theme.dart';
import 'lesson_screen.dart';

class GameOverScreen extends StatefulWidget {
  final Lesson lesson;
  final int questionsAnswered;

  const GameOverScreen({
    super.key,
    required this.lesson,
    required this.questionsAnswered,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // Scale up to 1.4 then shrink slightly — "shattered" feel
    _heartScale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.4)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.4, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
    ]).animate(_heartCtrl);
    _heartOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
            parent: _heartCtrl,
            curve: const Interval(0.0, 0.3, curve: Curves.easeIn)));
    _heartCtrl.forward();
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  void _tryAgain() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => LessonScreen(lesson: widget.lesson),
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
  }

  void _backToLessons() {
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0008), Color(0xFF3D0010), Color(0xFF1A0008)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Broken heart animation
                        AnimatedBuilder(
                          animation: _heartCtrl,
                          builder: (_, __) => Opacity(
                            opacity: _heartOpacity.value,
                            child: Transform.scale(
                              scale: _heartScale.value,
                              child: const Text('💔',
                                  style: TextStyle(fontSize: 100)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Out of Hearts!',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.danger,
                            letterSpacing: -0.5,
                          ),
                        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),

                        const SizedBox(height: 10),

                        Text(
                          widget.lesson.title,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white60,
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate(delay: 400.ms).fadeIn(),

                        const SizedBox(height: 32),

                        // Stats card
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLg),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatItem(
                                emoji: '📝',
                                label: 'Questions',
                                value: '${widget.questionsAnswered}',
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withOpacity(0.15),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 24),
                              ),
                              const _StatItem(
                                emoji: '💔',
                                label: 'Hearts',
                                value: '0 / 3',
                              ),
                            ],
                          ),
                        ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.3),

                        const SizedBox(height: 14),

                        Text(
                          'Don\'t give up — you\'re getting there!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.55),
                          ),
                        ).animate(delay: 600.ms).fadeIn(),
                      ],
                    ),
                  ),
                ),
              ),

              // Buttons
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 0, 24, MediaQuery.of(context).padding.bottom + 20),
                child: Column(
                  children: [
                    _GameOverButton(
                      label: '🔄  Try Again',
                      color: AppTheme.danger,
                      onTap: _tryAgain,
                    ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.4),
                    const SizedBox(height: 12),
                    _GameOverButton(
                      label: '← Back to Lessons',
                      color: Colors.white.withOpacity(0.12),
                      textColor: Colors.white70,
                      onTap: _backToLessons,
                    ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _StatItem({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }
}

class _GameOverButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _GameOverButton({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: color == AppTheme.danger
              ? [
                  BoxShadow(
                      color: AppTheme.danger.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
