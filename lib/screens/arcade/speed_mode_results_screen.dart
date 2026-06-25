import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/word.dart';
import '../../services/arcade_service.dart';
import '../../services/firebase_service.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/thai_mascot.dart';
import 'speed_mode_screen.dart';

class SpeedModeResultsScreen extends StatefulWidget {
  final int score;
  final int correct;
  final int bestCombo;
  final double? fastestAnswerSeconds;
  final bool isNewHighScore;
  final int previousBest;
  final List<Word> wordPool;
  final VoidCallback? onGoHome;

  const SpeedModeResultsScreen({
    super.key,
    required this.score,
    required this.correct,
    required this.bestCombo,
    this.fastestAnswerSeconds,
    required this.isNewHighScore,
    required this.previousBest,
    required this.wordPool,
    this.onGoHome,
  });

  @override
  State<SpeedModeResultsScreen> createState() => _SpeedModeResultsScreenState();
}

class _SpeedModeResultsScreenState extends State<SpeedModeResultsScreen> {
  final _arcadeService = ArcadeService();
  final _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _top3 = [];
  bool _loadingLb = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final snap = await _arcadeService.leaderboardStream(limit: 3).first;
      setState(() {
        _top3 = snap;
        _loadingLb = false;
      });
    } catch (_) {
      setState(() => _loadingLb = false);
    }
  }

  int get _accuracy => (widget.correct / 20 * 100).round();

  @override
  Widget build(BuildContext context) {
    final isNewHigh = widget.isNewHighScore;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            children: [
              _buildHeader(isNewHigh),
              const SizedBox(height: 28),
              _buildScoreCard(isNewHigh),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 20),
              _buildLeaderboardPreview(),
              const SizedBox(height: 28),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isNewHigh) {
    return Column(
      children: [
        BobbingMascot(size: 80, mood: isNewHigh ? MascotMood.excited : MascotMood.happy),
        const SizedBox(height: 16),
        Text(
          isNewHigh ? 'New High Score! 🏆' : 'Round Complete! 🎉',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        if (isNewHigh) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.thaiGold, Color(0xFFFFD700)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: const Text(
              'NEW RECORD! 🏆',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.thaiNavy,
                letterSpacing: 1,
              ),
            ),
          )
              .animate()
              .scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut, duration: 600.ms)
              .fadeIn(duration: 300.ms),
        ],
      ],
    );
  }

  Widget _buildScoreCard(bool isNewHigh) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNewHigh
              ? [const Color(0xFF3D3200), const Color(0xFF2A2200)]
              : [const Color(0xFF252A4A), const Color(0xFF1A1F3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isNewHigh
              ? AppTheme.thaiGold.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            '${widget.score}',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: isNewHigh ? AppTheme.thaiGold : Colors.white,
              height: 1,
            ),
          )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 4),
          Text(
            'points',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ScoreLine(
                label: 'Personal Best',
                value: '${isNewHigh ? widget.score : widget.previousBest} pts',
                color: AppTheme.thaiGold,
              ),
              if (!isNewHigh && widget.previousBest > 0)
                _ScoreLine(
                  label: 'Previous Best',
                  value: '${widget.previousBest} pts',
                  color: Colors.white54,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            emoji: '✅',
            value: '${widget.correct}/20',
            label: 'Correct',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            emoji: '🔥',
            value: 'x${widget.bestCombo}',
            label: 'Best Combo',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            emoji: '💯',
            value: '$_accuracy%',
            label: 'Accuracy',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            emoji: '⚡',
            value: widget.fastestAnswerSeconds != null
                ? '${widget.fastestAnswerSeconds!.toStringAsFixed(1)}s'
                : '—',
            label: 'Fastest',
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildLeaderboardPreview() {
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
          const Text(
            '🏆 Speed Mode Leaderboard',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.thaiGold,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingLb)
            const Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.thaiGold,
                ),
              ),
            )
          else if (_top3.isEmpty)
            Text(
              'No scores yet — you could be first!',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            )
          else ...[
            for (int i = 0; i < _top3.length; i++)
              _LeaderboardRow(
                rank: i + 1,
                entry: _top3[i],
                isMe: _top3[i]['uid'] == _firebaseService.getUserId(),
              ),
          ],
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'See full leaderboard →',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.thaiGold.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 400.ms);
  }

  Widget _buildActions() {
    return Column(
      children: [
        _ActionBtn(
          label: 'Play Again ⚡',
          color: AppTheme.thaiGold,
          textColor: AppTheme.thaiNavy,
          onTap: () {
              Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SpeedModeScreen(
                  wordPool: widget.wordPool,
                  onGoHome: widget.onGoHome,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _ActionBtn(
          label: 'Change Stages 🎯',
          color: Colors.white.withValues(alpha: 0.12),
          textColor: Colors.white,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(height: 12),
        _ActionBtn(
          label: 'Home 🏠',
          color: Colors.transparent,
          textColor: Colors.white54,
          onTap: () {
            if (widget.onGoHome != null) {
              widget.onGoHome!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ],
    ).animate().fadeIn(delay: 450.ms, duration: 400.ms);
  }
}

class _ScoreLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ScoreLine({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatCard({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;
  final bool isMe;
  const _LeaderboardRow({required this.rank, required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final rankEmoji = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.thaiGold.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: isMe
            ? Border.all(color: AppTheme.thaiGold.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(rankEmoji,
                style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 8),
          Text(entry['avatarEmoji'] as String? ?? '🧑',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry['username'] as String? ?? 'Player',
              style: TextStyle(
                fontSize: 13,
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

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: color == Colors.transparent
              ? Border.all(color: Colors.white.withValues(alpha: 0.15))
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
