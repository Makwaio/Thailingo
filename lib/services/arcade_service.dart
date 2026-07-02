import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class ArcadeService {
  static final ArcadeService _instance = ArcadeService._internal();
  factory ArcadeService() => _instance;
  ArcadeService._internal();

  // Speed Mode
  static const _hsKey  = 'speedMode_highScore';
  static const _bcKey  = 'speedMode_bestCombo';
  static const _gpKey  = 'speedMode_gamesPlayed';
  static const _tcKey  = 'speedMode_totalCorrect';
  static const _lsKey  = 'speedMode_lastScore';

  // Survival Mode
  static const _survHsKey    = 'survival_bestScore';
  static const _survGradeKey = 'survival_bestGrade';
  static const _survGpKey    = 'survival_gamesPlayed';

  // Word Blitz
  static const _blitzHsKey    = 'wordBlitz_bestScore';
  static const _blitzGradeKey = 'wordBlitz_bestGrade';
  static const _blitzGpKey    = 'wordBlitz_gamesPlayed';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Map<String, int>> getAllStats() async {
    final p = await _prefs;
    return {
      'highScore':    p.getInt(_hsKey) ?? 0,
      'bestCombo':    p.getInt(_bcKey) ?? 0,
      'gamesPlayed':  p.getInt(_gpKey) ?? 0,
      'totalCorrect': p.getInt(_tcKey) ?? 0,
      'lastScore':    p.getInt(_lsKey) ?? 0,
    };
  }

  Future<int> getHighScore() async => (await _prefs).getInt(_hsKey) ?? 0;

  /// Saves score locally and returns whether it is a new high score.
  /// Uploads to Firestore in the background if signed in and new high score.
  Future<bool> saveScore({
    required int score,
    required int combo,
    required int correct,
  }) async {
    final p = await _prefs;
    final oldHigh     = p.getInt(_hsKey) ?? 0;
    final oldBestCombo= p.getInt(_bcKey) ?? 0;
    final isNewHigh   = score > oldHigh;

    await p.setInt(_lsKey, score);
    await p.setInt(_gpKey, (p.getInt(_gpKey) ?? 0) + 1);
    await p.setInt(_tcKey, (p.getInt(_tcKey) ?? 0) + correct);
    if (isNewHigh)          await p.setInt(_hsKey, score);
    if (combo > oldBestCombo) await p.setInt(_bcKey, combo);

    if (isNewHigh) {
      final fs = FirebaseService();
      if (fs.isSignedIn()) _uploadToFirestore(fs.getUserId()!, score, combo);
    }
    return isNewHigh;
  }

  void _uploadToFirestore(String uid, int score, int combo) {
    Future.microtask(() async {
      try {
        final fb = FirebaseFirestore.instance;
        final data = {
          'speedModeHighScore': score,
          'speedModeBestCombo': combo,
          'lastPlayed': FieldValue.serverTimestamp(),
        };
        await fb.collection('arcade_scores').doc(uid).set(data, SetOptions(merge: true));

        final userDoc = await fb.collection('users').doc(uid).get();
        final username    = userDoc.data()?['username']    as String? ?? 'Player';
        final avatarEmoji = userDoc.data()?['avatarEmoji'] as String? ?? '🧑';
        await fb.collection('arcade_leaderboard').doc(uid).set(
          {...data, 'username': username, 'avatarEmoji': avatarEmoji},
          SetOptions(merge: true),
        );
      } catch (_) {}
    });
  }

  // ── Survival Mode ─────────────────────────────────────────────────────

  Future<int> getSurvivalBestScore() async => (await _prefs).getInt(_survHsKey) ?? 0;
  Future<String> getSurvivalBestGrade() async => (await _prefs).getString(_survGradeKey) ?? '';

  Future<bool> saveSurvivalScore({required int score, required String grade}) async {
    final p = await _prefs;
    final old = p.getInt(_survHsKey) ?? 0;
    final isNew = score > old;
    await p.setInt(_survGpKey, (p.getInt(_survGpKey) ?? 0) + 1);
    if (isNew) {
      await p.setInt(_survHsKey, score);
      await p.setString(_survGradeKey, grade);
      final fs = FirebaseService();
      if (fs.isSignedIn()) _uploadSurvivalToFirestore(fs.getUserId()!, score, grade);
    }
    return isNew;
  }

  void _uploadSurvivalToFirestore(String uid, int score, String grade) {
    Future.microtask(() async {
      try {
        final fb = FirebaseFirestore.instance;
        final userDoc = await fb.collection('users').doc(uid).get();
        final username    = userDoc.data()?['username']    as String? ?? 'Player';
        final avatarEmoji = userDoc.data()?['avatarEmoji'] as String? ?? '🧑';
        await fb.collection('survival_leaderboard').doc(uid).set({
          'survivalBestScore': score,
          'survivalBestGrade': grade,
          'username': username,
          'avatarEmoji': avatarEmoji,
          'lastPlayed': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    });
  }

  Stream<List<Map<String, dynamic>>> survivalLeaderboardStream({int limit = 10}) {
    return FirebaseFirestore.instance
        .collection('survival_leaderboard')
        .orderBy('survivalBestScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return {
                'uid':         doc.id,
                'username':    d['username']         as String? ?? 'Player',
                'avatarEmoji': d['avatarEmoji']      as String? ?? '🧑',
                'score':       d['survivalBestScore'] as int?   ?? 0,
                'grade':       d['survivalBestGrade'] as String? ?? '',
              };
            }).toList());
  }

  // ── Word Blitz ────────────────────────────────────────────────────────

  Future<int> getWordBlitzBestScore() async => (await _prefs).getInt(_blitzHsKey) ?? 0;
  Future<String> getWordBlitzBestGrade() async => (await _prefs).getString(_blitzGradeKey) ?? '';

  Future<bool> saveWordBlitzScore({required int score, required String grade}) async {
    final p = await _prefs;
    final old = p.getInt(_blitzHsKey) ?? 0;
    final isNew = score > old;
    await p.setInt(_blitzGpKey, (p.getInt(_blitzGpKey) ?? 0) + 1);
    if (isNew) {
      await p.setInt(_blitzHsKey, score);
      await p.setString(_blitzGradeKey, grade);
      final fs = FirebaseService();
      if (fs.isSignedIn()) _uploadBlitzToFirestore(fs.getUserId()!, score, grade);
    }
    return isNew;
  }

  void _uploadBlitzToFirestore(String uid, int score, String grade) {
    Future.microtask(() async {
      try {
        final fb = FirebaseFirestore.instance;
        final userDoc = await fb.collection('users').doc(uid).get();
        final username    = userDoc.data()?['username']    as String? ?? 'Player';
        final avatarEmoji = userDoc.data()?['avatarEmoji'] as String? ?? '🧑';
        await fb.collection('wordblitz_leaderboard').doc(uid).set({
          'wordBlitzBestScore': score,
          'wordBlitzBestGrade': grade,
          'username': username,
          'avatarEmoji': avatarEmoji,
          'lastPlayed': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    });
  }

  Stream<List<Map<String, dynamic>>> wordBlitzLeaderboardStream({int limit = 10}) {
    return FirebaseFirestore.instance
        .collection('wordblitz_leaderboard')
        .orderBy('wordBlitzBestScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return {
                'uid':         doc.id,
                'username':    d['username']          as String? ?? 'Player',
                'avatarEmoji': d['avatarEmoji']       as String? ?? '🧑',
                'score':       d['wordBlitzBestScore'] as int?   ?? 0,
                'grade':       d['wordBlitzBestGrade'] as String? ?? '',
              };
            }).toList());
  }

  Stream<List<Map<String, dynamic>>> leaderboardStream({int limit = 10}) {
    return FirebaseFirestore.instance
        .collection('arcade_leaderboard')
        .orderBy('speedModeHighScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return {
                'uid':         doc.id,
                'username':    d['username']           as String? ?? 'Player',
                'avatarEmoji': d['avatarEmoji']        as String? ?? '🧑',
                'score':       d['speedModeHighScore'] as int?    ?? 0,
                'combo':       d['speedModeBestCombo'] as int?    ?? 0,
              };
            }).toList());
  }
}
