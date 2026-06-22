import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/common_widgets.dart';

class ReviewCompleteScreen extends StatelessWidget {
  final int wordsCleared;
  final int xpGained;

  const ReviewCompleteScreen({
    super.key,
    required this.wordsCleared,
    required this.xpGained,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0045), Color(0xFF2E0066), Color(0xFF4A0080)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),

                // Trophy emoji
                const Text('🎉', style: TextStyle(fontSize: 80))
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 20),

                const Text(
                  'Review Complete!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOut),

                const SizedBox(height: 12),

                Text(
                  wordsCleared > 0
                      ? 'You cleared $wordsCleared ${wordsCleared == 1 ? 'word' : 'words'} from your queue!'
                      : 'Great effort — keep practising!',
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOut),

                const SizedBox(height: 36),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatCard(emoji: '📝', label: 'Cleared', value: '$wordsCleared'),
                    const SizedBox(width: 16),
                    _StatCard(emoji: '⭐', label: 'XP Earned', value: '+$xpGained'),
                  ],
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOut),

                const Spacer(),

                // Back button
                PrimaryButton(
                  label: 'Back to Lessons',
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.of(context).pop(true),
                )
                    .animate(delay: 650.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.4, curve: Curves.easeOut),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
