import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../services/user_service.dart';
import '../ui/theme/app_theme.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';
import 'stats_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firebaseService = FirebaseService();
  final _userService = UserService();
  Map<String, dynamic>? _profile;
  int? _globalRank;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _firebaseService.getUserId();
    if (uid != null) {
      final profile = await _userService.getUserProfile(uid);
      final rank = await _userService.getUserRank(uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          _globalRank = rank;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Your progress is saved to the cloud.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.thaiRed,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _firebaseService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _changeAvatar() async {
    final uid = _firebaseService.getUserId();
    if (uid == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(
          uid: uid,
          name: _profile?['username'] as String? ?? '',
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = !_firebaseService.isSignedIn();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.thaiNavyDk, AppTheme.thaiNavy,
                    Color(0xFF3D3A8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Profile',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    if (!isGuest && !_loading) ...[
                      GestureDetector(
                        onTap: _changeAvatar,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppTheme.thaiGold, width: 3),
                              ),
                              child: Center(
                                child: Text(
                                  _profile?['avatarEmoji'] as String? ??
                                      '👤',
                                  style:
                                      const TextStyle(fontSize: 46),
                                ),
                              ),
                            ),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppTheme.thaiGold,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppTheme.thaiNavy, width: 2),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  size: 13, color: AppTheme.thaiNavy),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _profile?['username'] as String? ?? 'Learner',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _firebaseService.getUserEmail() ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white54),
                      ),
                    ] else if (isGuest) ...[
                      const Text('👤',
                          style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 8),
                      const Text('Guest',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Body
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.thaiNavy))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.thaiNavy,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (isGuest) ...[
                          _GuestBanner(),
                          const SizedBox(height: 16),
                        ],
                        if (!isGuest) ...[
                          // Rank cards
                          _RankRow(globalRank: _globalRank),
                          const SizedBox(height: 16),
                          // Stats section
                          _StatCards(profile: _profile),
                          const SizedBox(height: 16),
                          // Member since
                          if (_profile?['joinDate'] != null)
                            _InfoTile(
                              icon: Icons.calendar_today_rounded,
                              label: 'Member since',
                              value: _formatDate(
                                  _profile!['joinDate']),
                            ),
                          const SizedBox(height: 8),
                          _InfoTile(
                            icon: Icons.people_rounded,
                            label: 'Friends',
                            value:
                                '${(_profile?['friends'] as List?)?.length ?? 0}',
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Detailed stats button
                        _ActionButton(
                          icon: Icons.bar_chart_rounded,
                          label: 'Detailed Stats',
                          color: AppTheme.thaiNavy,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const StatsScreen()),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!isGuest)
                          _ActionButton(
                            icon: Icons.logout_rounded,
                            label: 'Sign Out',
                            color: AppTheme.thaiRed,
                            onTap: _signOut,
                          )
                        else
                          _ActionButton(
                            icon: Icons.login_rounded,
                            label: 'Sign In to Save Progress',
                            color: AppTheme.thaiNavy,
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic ts) {
    try {
      final date = (ts as dynamic).toDate() as DateTime;
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Unknown';
    }
  }
}

// ── Rank Row ───────────────────────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final int? globalRank;
  const _RankRow({this.globalRank});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RankCard(
            emoji: '🌍',
            label: 'Global Rank',
            value: globalRank != null ? '#$globalRank' : '--',
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _RankCard(
            emoji: '📅',
            label: 'Weekly',
            value: '--',
          ),
        ),
      ],
    );
  }
}

class _RankCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _RankCard(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.thaiNavy, Color(0xFF3D3A8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
                color: AppTheme.thaiGold),
          ),
          Text(
            label,
            style:
                const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

// ── Stat Cards ─────────────────────────────────────────────────────────
class _StatCards extends StatelessWidget {
  final Map<String, dynamic>? profile;
  const _StatCards({this.profile});

  @override
  Widget build(BuildContext context) {
    final xp = profile?['totalXp'] as int? ?? 0;
    final streak = profile?['currentStreak'] as int? ?? 0;
    final lessons = profile?['lessonsCompleted'] as int? ?? 0;
    final weekly = profile?['weeklyXp'] as int? ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _MiniStat(emoji: '⭐', label: 'Total XP', value: '$xp'),
        _MiniStat(emoji: '🔥', label: 'Streak', value: '$streak days'),
        _MiniStat(emoji: '📚', label: 'Lessons', value: '$lessons'),
        _MiniStat(emoji: '📅', label: 'Weekly XP', value: '$weekly'),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _MiniStat(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Info Tile ──────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.thaiNavy),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ── Action Button ──────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Guest Banner ───────────────────────────────────────────────────────
class _GuestBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.thaiNavy, Color(0xFF3D3A8E)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          const Text(
            'Create an account to save your progress and compete on the leaderboard!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.thaiGold,
              foregroundColor: AppTheme.thaiNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
            child: const Text('Sign In',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
