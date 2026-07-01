import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class PatchNote {
  final String version;
  final String title;
  final DateTime date;
  final String type; // 'major', 'minor', 'patch'
  final List<String> notes;
  final String? docId;

  const PatchNote({
    required this.version,
    required this.title,
    required this.date,
    required this.type,
    required this.notes,
    this.docId,
  });

  factory PatchNote.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PatchNote(
      version: d['version'] as String? ?? '',
      title: d['title'] as String? ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: d['type'] as String? ?? 'patch',
      notes: List<String>.from(d['notes'] as List? ?? []),
      docId: doc.id,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'version': version,
        'title': title,
        'date': Timestamp.fromDate(date),
        'type': type,
        'notes': notes,
      };
}

class PatchNotesService {
  static final PatchNotesService _instance = PatchNotesService._internal();
  factory PatchNotesService() => _instance;
  PatchNotesService._internal();

  static const _readKey = 'patch_notes_read_v1';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<List<PatchNote>> getLatestPatchNotes({int limit = 20}) async {
    if (kIsWeb) return [];
    try {
      final snap = await _db
          .collection('patch_notes')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      final notes = snap.docs.map(PatchNote.fromFirestore).toList();
      // Secondary sort by semantic version to handle equal/missing dates
      notes.sort((a, b) => _compareVersions(b.version, a.version));
      return notes;
    } catch (_) {
      return [];
    }
  }

  /// Compares semantic versions: "1.2.5" > "1.2.1" > "1.1.0"
  int _compareVersions(String a, String b) {
    final ap = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final bp = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (ap.length < 3) { ap.add(0); }
    while (bp.length < 3) { bp.add(0); }
    for (int i = 0; i < 3; i++) {
      final c = ap[i].compareTo(bp[i]);
      if (c != 0) return c;
    }
    return 0;
  }

  Future<bool> hasUnreadNotes() async {
    if (kIsWeb) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final read = prefs.getStringList(_readKey) ?? [];
      final notes = await getLatestPatchNotes(limit: 1);
      if (notes.isEmpty) return false;
      return !read.contains(notes.first.version);
    } catch (_) {
      return false;
    }
  }

  Future<List<PatchNote>> getUnreadNotes() async {
    if (kIsWeb) return [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final read = prefs.getStringList(_readKey) ?? [];
      final all = await getLatestPatchNotes(limit: 5);
      return all.where((n) => !read.contains(n.version)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> markAsRead(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final read = prefs.getStringList(_readKey) ?? [];
    if (!read.contains(version)) {
      read.add(version);
      await prefs.setStringList(_readKey, read);
    }
  }

  Future<void> markAllAsRead(List<String> versions) async {
    final prefs = await SharedPreferences.getInstance();
    final read = prefs.getStringList(_readKey) ?? [];
    for (final v in versions) {
      if (!read.contains(v)) read.add(v);
    }
    await prefs.setStringList(_readKey, read);
  }

  Future<void> addPatchNote(PatchNote note) async {
    if (kIsWeb) return;
    await _db
        .collection('patch_notes')
        .doc(note.version)
        .set(note.toFirestore());
  }

  Future<void> seedInitialPatchNotes() async {
    if (kIsWeb) return;
    try {
      final v1doc = await _db.collection('patch_notes').doc('1.0.0').get();
      if (!v1doc.exists) {
        await _db.collection('patch_notes').doc('1.0.0').set({
          'version': '1.0.0',
          'title': 'Initial Release 🎉',
          'date': Timestamp.now(),
          'type': 'major',
          'notes': [
            'Thailingo launches with 22 Stage 1 lessons',
            '7 game types: Multiple Choice, Match Pairs, Listen & Choose, Speed Tap, Sentence Builder, Conversation Mode, Typing Challenge',
            'Thai flag themed UI with mascot character',
            'XP system, streaks, and 3-star ratings per lesson',
            'Review queue for words you got wrong',
            'Guide book with tones, alphabet and survival phrases',
            'Google Sign In and Firestore leaderboard',
            'Shorebird OTA updates',
          ],
        });
      }
      final v2doc = await _db.collection('patch_notes').doc('1.0.1').get();
      if (!v2doc.exists) {
        await _db.collection('patch_notes').doc('1.0.1').set({
          'version': '1.0.1',
          'title': 'Fixes & Polish',
          'date': Timestamp.now(),
          'type': 'patch',
          'notes': [
            'Fixed conversation mode audio playing wrong sounds',
            'Added in-app bug reporting — tap 🐛 in any lesson',
            'Weekly XP rank banner on home screen',
            'Star system rework — easier to earn stars, based on play count',
            'Match Pairs now scores each pair individually',
            'Typing Challenge now accepts common spelling variations',
            'Typing Challenge hints — tap 💡 if you\'re stuck',
            'What\'s New screen — see what changed in each update',
          ],
        });
      }
      final v5doc = await _db.collection('patch_notes').doc('1.0.4').get();
      if (!v5doc.exists) {
        await _db.collection('patch_notes').doc('1.0.4').set({
          'version': '1.0.4',
          'title': 'Cloud Content & Auto Audio 🌐',
          'date': Timestamp.now(),
          'type': 'major',
          'notes': [
            'Lessons now load from the cloud — new content appears without app updates',
            'Audio auto-fetches from Google TTS for any missing pronunciation',
            'All fetched audio cached to device for offline playback',
            'New lessons 38-43 now have full audio: Daily Life, Going Out, Street Ordering, Goodbyes, Advanced Numbers, Slang',
            '7 new Bangkok conversation scenarios',
            'New hamburger menu in the header replaces icon buttons',
            'Sign out, leaderboard, guide book and settings all in one place',
            'Dev mode: Manage Lessons screen to add or upload lessons to Firestore',
          ],
        });
      }
      final v6doc = await _db.collection('patch_notes').doc('1.0.5').get();
      if (!v6doc.exists) {
        await _db.collection('patch_notes').doc('1.0.5').set({
          'version': '1.0.5',
          'title': 'Major UI & Content Update 🎨',
          'date': Timestamp.now(),
          'type': 'major',
          'notes': [
            'Stage 1 expanded to 28 lessons with new beginner-friendly unlock order',
            'Hexagons redesigned as octagons with layered star borders (bronze/silver/gold)',
            'Smooth green→indigo color gradient across Stage 1',
            'Stage 1 phonetic-only mode — learn sounds before English translations',
            'No conversation exercises in Stage 1 — stays focused on vocabulary',
            'Stage 1 star tally card shows bronze/silver/gold progress',
            'Missed Questions review mode — practice words you never saw in a session',
            'Lessons now pad to 20 questions minimum for longer practice sessions',
            'Words Learned shown prominently in stats',
            'Keyboard no longer blocks typing challenge input field',
          ],
        });
      }
      final v4doc = await _db.collection('patch_notes').doc('1.0.3').get();
      if (!v4doc.exists) {
        await _db.collection('patch_notes').doc('1.0.3').set({
          'version': '1.0.3',
          'title': 'Real Bangkok Thai Content 🏙️',
          'date': Timestamp.now(),
          'type': 'minor',
          'notes': [
            '6 new lessons added from real Bangkok daily life',
            'Daily life sentences (going to kitchen, bathroom and more)',
            'Going out and making plans phrases',
            'Street ordering and shopping (kao man gai, som tam and more)',
            'Goodbyes and conversation endings',
            'Numbers 11 to 1,000,000',
            'Bangkok slang and useful fillers',
            '7 new conversation scenarios based on real situations',
            'Ordering kao man gai, som tam, 7-Eleven run and more',
          ],
        });
      }
      final v3doc = await _db.collection('patch_notes').doc('1.0.2').get();
      if (!v3doc.exists) {
        await _db.collection('patch_notes').doc('1.0.2').set({
          'version': '1.0.2',
          'title': 'Muay Thai Mascot Update 🥊',
          'date': Timestamp.now(),
          'type': 'minor',
          'notes': [
            'Mascot redesigned as a Muay Thai fighter with mongkol headband and hand wraps',
            'Mascot repositioned to the right of the header for better readability on small screens',
            'Speech bubble moved to the left of the mascot',
            'Various bug fixes and UI polish',
          ],
        });
      }
      await _db.collection('patch_notes').doc('1.0.9').set({
        'version': '1.0.9',
        'title': 'Learning English Fix ✅',
        'date': Timestamp.now(),
        'type': 'patch',
        'notes': [
          'Fixed feedback bar showing wrong language after wrong answer',
          'Typing wrong answer now shows English meaning in English mode',
          'Sentence Builder shows English sentence in English mode',
          'Review screen now uses consistent direction per language setting',
          'If you see this note the patch worked!',
        ],
      });
      final v11doc = await _db.collection('patch_notes').doc('1.1.0').get();
      if (!v11doc.exists) {
        await _db.collection('patch_notes').doc('1.1.0').set({
          'version': '1.1.0',
          'title': 'Full Thai UI + Profile Menu 🎉',
          'date': Timestamp.now(),
          'type': 'major',
          'notes': [
            'Complete Thai UI — when in Learning English mode, the entire app switches to Thai',
            'Stage names, row labels, drawer menus and settings all translated to Thai',
            'Profile icon replaces hamburger menu button for non-signed-in users',
            'XP bar and mascot moved up for a cleaner header layout',
            'Result screen stats (XP, Accuracy, Time) now show in Thai',
            'Game Over screen fully translated',
            'Guide Book tabs translated to Thai in Learning English mode',
            'Stats & Trophies section labels translated',
          ],
        });
      }
      final v111doc = await _db.collection('patch_notes').doc('1.1.1').get();
      if (!v111doc.exists) {
        await _db.collection('patch_notes').doc('1.1.1').set({
          'version': '1.1.1',
          'title': 'Thai Lesson Names + English Alphabet 🔤',
          'date': Timestamp.now(),
          'type': 'minor',
          'notes': [
            'Lesson names now show in Thai when in Learning English mode',
            'Stage 0 switches to English Alphabet (A-Z) mode for Thai speakers',
            '5 new English Alphabet lessons: Consonants 1 & 2, Vowels, Pronunciation Rules, Common Words',
            'Complete UI shown in Thai throughout Learning English mode',
          ],
        });
      }
      final v112doc = await _db.collection('patch_notes').doc('1.1.2').get();
      if (!v112doc.exists) {
        await _db.collection('patch_notes').doc('1.1.2').set({
          'version': '1.1.2',
          'title': 'Major Bug Fixes + Skeet Shooter 🎯',
          'date': Timestamp.fromDate(DateTime(2026, 6, 30)),
          'type': 'major',
          'notes': [
            'Fixed Stage 0 not switching content for English learning mode',
            'New arcade game: Skeet Shooter 🎯 — shoot the right words before they fly by',
            'New Stage 3 lesson: Real Life Conversations 🗣️ (pharmacy, 7-Eleven, Grab, salon, hotel, café)',
            'Fixed game type toggles (Match Pairs, Listen, Speed Tap etc.) not actually saving',
            'Fixed later lessons showing only one exercise type — all types now cycle correctly',
            'Fixed star count: first completion now always gives exactly 1 star',
            'Fixed Stage 0 Listen exercise showing the answer before you listen',
          ],
        });
      }
      final v121doc = await _db.collection('patch_notes').doc('1.2.1').get();
      if (!v121doc.exists) {
        await _db.collection('patch_notes').doc('1.2.1').set({
          'version': '1.2.1',
          'title': '15 New Focused Lessons 🎯',
          'date': Timestamp.fromDate(DateTime(2026, 7, 1)),
          'type': 'major',
          'notes': [
            '9 new Stage 2 lessons: Taxis 🚕, BTS/MRT 🚆, Restaurant 🍽️, Market 🛍️, Money 💰, Hospital 🏥, Hotel 🏨, Bank 🏦, Etiquette 🙏',
            '1 new Stage 2 lesson: Office & Workplace 💼',
            '5 new Stage 3 lessons: Your Life 👤, Feelings ❤️, Weather ⛅, Friends 👫, Food You Like 😋',
            'All new lessons feature full audio, phonetics, and native Thai example sentences',
            'Rotate your phone into landscape mode for a split-screen exercise layout',
          ],
        });
      }
    } catch (_) {}
  }
}
