import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_progress.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Getter so FirebaseFirestore.instance isn't accessed at construction time.
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Profile management ───────────────────────────────────────────────

  Future<void> createUserProfile(String uid, String name, String email) async {
    final doc = _db.collection('users').doc(uid);
    final existing = await doc.get();
    if (existing.exists) return;
    final now = Timestamp.now();
    await doc.set({
      'uid': uid,
      'username': name,
      'email': email,
      'avatarEmoji': '',
      'totalXp': 0,
      'currentStreak': 0,
      'longestStreak': 0,
      'lessonsCompleted': 0,
      'weeklyXp': 0,
      'weeklyXpResetDate': now,
      'lastActive': now,
      'joinDate': now,
      'friends': [],
      'stageProgress': {},
    });
  }

  Future<void> setAvatarAndUsername(
      String uid, String avatar, String username) async {
    await _db.collection('users').doc(uid).update({
      'avatarEmoji': avatar,
      'username': username,
    });
    await _updateLeaderboard(uid);
  }

  Future<bool> isProfileSetup(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      return (doc.data()?['avatarEmoji'] as String? ?? '').isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  // ── Progress sync ─────────────────────────────────────────────────────

  Future<void> syncProgressToFirestore(
      String uid, UserProgress progress) async {
    try {
      final lessonsCompleted =
          progress.lessonProgress.values.where((lp) => lp.completed).length;
      await _db.collection('users').doc(uid).update({
        'totalXp': progress.totalXp,
        'currentStreak': progress.streak,
        'longestStreak': progress.longestStreak,
        'lessonsCompleted': lessonsCompleted,
        'lastActive': Timestamp.now(),
      });
      await _updateLeaderboard(uid);
    } catch (_) {}
  }

  Future<void> syncLocalProgress(String uid, UserProgress local) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return;
      final firestoreXp = doc.data()?['totalXp'] as int? ?? 0;
      if (local.totalXp > firestoreXp) {
        final lessonsCompleted =
            local.lessonProgress.values.where((lp) => lp.completed).length;
        await _db.collection('users').doc(uid).update({
          'totalXp': local.totalXp,
          'weeklyXp':
              FieldValue.increment(local.totalXp - firestoreXp),
          'currentStreak': local.streak,
          'longestStreak': local.longestStreak,
          'lessonsCompleted': lessonsCompleted,
          'lastActive': Timestamp.now(),
        });
        await _updateLeaderboard(uid);
      }
    } catch (_) {}
  }

  // ── Leaderboard ───────────────────────────────────────────────────────

  Future<void> _updateLeaderboard(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return;
      final data = userDoc.data()!;
      await _db.collection('leaderboard').doc(uid).set({
        'uid': uid,
        'username': data['username'] ?? '',
        'avatarEmoji': data['avatarEmoji'] ?? '',
        'totalXp': data['totalXp'] ?? 0,
        'weeklyXp': data['weeklyXp'] ?? 0,
        'currentStreak': data['currentStreak'] ?? 0,
        'lessonsCompleted': data['lessonsCompleted'] ?? 0,
        'lastActive': data['lastActive'] ?? Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Stream<List<Map<String, dynamic>>> getLeaderboard() {
    if (kIsWeb) return Stream.value([]);
    return _db
        .collection('leaderboard')
        .orderBy('totalXp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getWeeklyLeaderboard() {
    if (kIsWeb) return Stream.value([]);
    return _db
        .collection('leaderboard')
        .orderBy('weeklyXp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<int?> getUserRank(String uid) async {
    try {
      final userDoc = await _db.collection('leaderboard').doc(uid).get();
      if (!userDoc.exists) return null;
      final userXp = userDoc.data()?['totalXp'] as int? ?? 0;
      final result = await _db
          .collection('leaderboard')
          .where('totalXp', isGreaterThan: userXp)
          .count()
          .get();
      return (result.count ?? 0) + 1;
    } catch (_) {
      return null;
    }
  }

  /// Returns {'rank': int, 'weeklyXp': int} for the user's current weekly
  /// position, or null if the user has 0 weekly XP or on any error.
  Future<Map<String, int>?> getWeeklyRankInfo(String uid) async {
    if (kIsWeb) return null;
    try {
      final userDoc = await _db.collection('leaderboard').doc(uid).get();
      if (!userDoc.exists) return null;
      final weeklyXp = userDoc.data()?['weeklyXp'] as int? ?? 0;
      if (weeklyXp == 0) return null;
      final result = await _db
          .collection('leaderboard')
          .where('weeklyXp', isGreaterThan: weeklyXp)
          .count()
          .get();
      final rank = (result.count ?? 0) + 1;
      return {'rank': rank, 'weeklyXp': weeklyXp};
    } catch (_) {
      return null;
    }
  }

  // ── Weekly reset ──────────────────────────────────────────────────────

  Future<void> resetWeeklyXpIfNeeded(String uid) async {
    try {
      final now = DateTime.now();
      final mondayStart = DateTime(
          now.year, now.month, now.day - (now.weekday - 1));
      final doc = await _db.collection('users').doc(uid).get();
      final resetDate =
          (doc.data()?['weeklyXpResetDate'] as Timestamp?)?.toDate();
      if (resetDate == null || resetDate.isBefore(mondayStart)) {
        await _db.collection('users').doc(uid).update({
          'weeklyXp': 0,
          'weeklyXpResetDate': Timestamp.fromDate(mondayStart),
        });
        await _updateLeaderboard(uid);
      }
    } catch (_) {}
  }

  // ── Friends ───────────────────────────────────────────────────────────

  Future<void> addFriend(String currentUid, String friendUid) async {
    await _db.collection('users').doc(currentUid).update({
      'friends': FieldValue.arrayUnion([friendUid]),
    });
  }

  Future<Map<String, dynamic>?> searchUserByUsername(String username) async {
    try {
      final snap = await _db
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data();
    } catch (_) {
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> getFriends(String uid) {
    return _db.collection('users').doc(uid).snapshots().asyncExpand((snap) {
      final friends =
          List<String>.from(snap.data()?['friends'] ?? []);
      if (friends.isEmpty) return Stream.value([]);
      final batch = friends.take(30).toList();
      return _db
          .collection('leaderboard')
          .where('uid', whereIn: batch)
          .snapshots()
          .map((s) {
        final list = s.docs.map((d) => d.data()).toList();
        list.sort((a, b) =>
            (b['totalXp'] as int? ?? 0)
                .compareTo(a['totalXp'] as int? ?? 0));
        return list;
      });
    });
  }
}
