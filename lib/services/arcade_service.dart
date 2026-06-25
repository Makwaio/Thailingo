import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class ArcadeService {
  static final ArcadeService _instance = ArcadeService._internal();
  factory ArcadeService() => _instance;
  ArcadeService._internal();

  static const _hsKey  = 'speedMode_highScore';
  static const _bcKey  = 'speedMode_bestCombo';
  static const _gpKey  = 'speedMode_gamesPlayed';
  static const _tcKey  = 'speedMode_totalCorrect';
  static const _lsKey  = 'speedMode_lastScore';

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
