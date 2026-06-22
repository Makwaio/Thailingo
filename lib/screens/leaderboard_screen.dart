import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../services/user_service.dart';
import '../ui/theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _firebaseService = FirebaseService();
  final _userService = UserService();
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _currentUid = _firebaseService.getUserId();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '🏆 Leaderboard',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        ),
                        const Spacer(),
                        if (_currentUid == null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Text('Guest',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TabBar(
                    controller: _tabs,
                    indicatorColor: AppTheme.thaiGold,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [
                      Tab(text: '🌍 Global'),
                      Tab(text: '📅 Weekly'),
                      Tab(text: '👥 Friends'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _LeaderboardTab(
                  stream: _userService.getLeaderboard(),
                  xpField: 'totalXp',
                  label: 'Total XP',
                  currentUid: _currentUid,
                  userService: _userService,
                ),
                _LeaderboardTab(
                  stream: _userService.getWeeklyLeaderboard(),
                  xpField: 'weeklyXp',
                  label: 'Weekly XP',
                  currentUid: _currentUid,
                  userService: _userService,
                ),
                _FriendsTab(
                  currentUid: _currentUid,
                  userService: _userService,
                  firebaseService: _firebaseService,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leaderboard Tab ────────────────────────────────────────────────────
class _LeaderboardTab extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> stream;
  final String xpField;
  final String label;
  final String? currentUid;
  final UserService userService;

  const _LeaderboardTab({
    required this.stream,
    required this.xpField,
    required this.label,
    required this.currentUid,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingSkeleton();
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading leaderboard\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
          );
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🏆', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('No entries yet!\nBe the first to earn XP.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15, color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        final userIndex =
            entries.indexWhere((e) => e['uid'] == currentUid);
        final userInTop = userIndex != -1;

        return RefreshIndicator(
          color: AppTheme.thaiNavy,
          onRefresh: () async {},
          child: ListView.builder(
            padding:
                EdgeInsets.fromLTRB(12, 8, 12, userInTop ? 12 : 80),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              final rank = i + 1;
              final isMe = e['uid'] == currentUid;
              return _EntryRow(
                rank: rank,
                entry: e,
                xpField: xpField,
                isMe: isMe,
                isPodium: rank <= 3,
              )
                  .animate(delay: Duration(milliseconds: i * 40))
                  .fadeIn(duration: 300.ms)
                  .slideX(
                      begin: rank <= 3 ? 0 : 0.05,
                      duration: 300.ms);
            },
          ),
        );
      },
    );
  }
}

// ── Friends Tab ────────────────────────────────────────────────────────
class _FriendsTab extends StatefulWidget {
  final String? currentUid;
  final UserService userService;
  final FirebaseService firebaseService;

  const _FriendsTab({
    required this.currentUid,
    required this.userService,
    required this.firebaseService,
  });

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
  void _showAddFriendDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Friend',
            style:
                TextStyle(fontWeight: FontWeight.w800, color: AppTheme.thaiNavy)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Enter their username',
            prefixIcon: Icon(Icons.person_search_rounded),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.thaiNavy,
                foregroundColor: Colors.white),
            onPressed: () async {
              final username = ctrl.text.trim();
              if (username.isEmpty) return;
              Navigator.pop(ctx);
              final result =
                  await widget.userService.searchUserByUsername(username);
              if (!mounted) return;
              if (result == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User "$username" not found')),
                );
              } else {
                final friendUid = result['uid'] as String;
                await widget.userService
                    .addFriend(widget.currentUid!, friendUid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '${result['username']} added as friend!')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUid == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('👥', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              Text(
                'Sign in to add friends and compare progress!',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 15, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.userService.getFriends(widget.currentUid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingSkeleton();
        }
        final friends = snapshot.data ?? [];

        return Stack(
          children: [
            friends.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('👥', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text(
                            'No friends yet!\nTap + to add a friend by username.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    itemCount: friends.length,
                    itemBuilder: (_, i) => _EntryRow(
                      rank: i + 1,
                      entry: friends[i],
                      xpField: 'totalXp',
                      isMe: friends[i]['uid'] == widget.currentUid,
                      isPodium: i < 3,
                    )
                        .animate(delay: Duration(milliseconds: i * 40))
                        .fadeIn(duration: 300.ms),
                  ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _showAddFriendDialog,
                backgroundColor: AppTheme.thaiNavy,
                foregroundColor: Colors.white,
                child: const Icon(Icons.person_add_rounded),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Single Leaderboard Row ─────────────────────────────────────────────
class _EntryRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;
  final String xpField;
  final bool isMe;
  final bool isPodium;

  const _EntryRow({
    required this.rank,
    required this.entry,
    required this.xpField,
    required this.isMe,
    required this.isPodium,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = entry['avatarEmoji'] as String? ?? '👤';
    final username = entry['username'] as String? ?? 'Unknown';
    final xp = entry[xpField] as int? ?? 0;
    final streak = entry['currentStreak'] as int? ?? 0;
    final lessons = entry['lessonsCompleted'] as int? ?? 0;

    final rankLabel = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : '$rank';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.thaiGold.withValues(alpha: 0.15)
            : isPodium
                ? AppTheme.thaiNavy.withValues(alpha: 0.04)
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? AppTheme.thaiGold
              : isPodium
                  ? AppTheme.thaiNavy.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.15),
          width: isMe ? 2 : 1,
        ),
        boxShadow: isPodium || isMe
            ? [
                BoxShadow(
                  color: (isMe ? AppTheme.thaiGold : AppTheme.thaiNavy)
                      .withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 36,
              child: Text(
                rankLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: rank <= 3 ? 22 : 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.thaiNavy,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Avatar
            Text(avatar, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            // Name & stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isMe
                              ? AppTheme.thaiNavy
                              : AppTheme.textPrimary,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.thaiGold,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull),
                          ),
                          child: const Text('You',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.thaiNavy)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('🔥 $streak',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary)),
                      const SizedBox(width: 10),
                      Text('📚 $lessons',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            // XP
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatXp(xp),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color:
                        isMe ? AppTheme.thaiNavy : AppTheme.textPrimary,
                  ),
                ),
                const Text('XP',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}k';
    return '$xp';
  }
}

// ── Loading Skeleton ───────────────────────────────────────────────────
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 8,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        height: 64,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
      ).animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms, color: Colors.white54),
    );
  }
}
