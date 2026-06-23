import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';

class BugReport {
  final String type;
  final String description;
  final int? lessonId;
  final String? lessonName;
  final String screen;
  final String appVersion;
  final String userId;
  final String deviceInfo;
  final String status;
  final DateTime? timestamp;
  final String? docId;

  const BugReport({
    required this.type,
    required this.description,
    this.lessonId,
    this.lessonName,
    required this.screen,
    required this.appVersion,
    required this.userId,
    required this.deviceInfo,
    this.status = 'open',
    this.timestamp,
    this.docId,
  });

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'type': type,
      'description': description,
      'screen': screen,
      'appVersion': appVersion,
      'userId': userId,
      'deviceInfo': deviceInfo,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (lessonId != null) map['lessonId'] = lessonId;
    if (lessonName != null) map['lessonName'] = lessonName;
    return map;
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'description': description,
    if (lessonId != null) 'lessonId': lessonId,
    if (lessonName != null) 'lessonName': lessonName,
    'screen': screen,
    'appVersion': appVersion,
    'userId': userId,
    'deviceInfo': deviceInfo,
    'status': status,
  };

  factory BugReport.fromJson(Map<String, dynamic> json) => BugReport(
    type: json['type'] as String? ?? '',
    description: json['description'] as String? ?? '',
    lessonId: json['lessonId'] as int?,
    lessonName: json['lessonName'] as String?,
    screen: json['screen'] as String? ?? '',
    appVersion: json['appVersion'] as String? ?? '',
    userId: json['userId'] as String? ?? '',
    deviceInfo: json['deviceInfo'] as String? ?? '',
    status: json['status'] as String? ?? 'open',
  );

  factory BugReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BugReport(
      type: data['type'] as String? ?? '',
      description: data['description'] as String? ?? '',
      lessonId: data['lessonId'] as int?,
      lessonName: data['lessonName'] as String?,
      screen: data['screen'] as String? ?? '',
      appVersion: data['appVersion'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      deviceInfo: data['deviceInfo'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      docId: doc.id,
    );
  }
}

class BugReportService {
  static final BugReportService _instance = BugReportService._internal();
  factory BugReportService() => _instance;
  BugReportService._internal();

  static const _queueKey = 'bug_reports_queue';
  static const appVersion = '1.0.1';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get deviceInfo {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
    } catch (_) {}
    return 'Unknown';
  }

  String get currentUserId => FirebaseService().getUserId() ?? 'guest';

  Future<bool> submitReport(BugReport report) async {
    if (kIsWeb) return false;
    try {
      await _db.collection('bug_reports').add(report.toFirestore());
      return true;
    } catch (_) {
      await _saveToQueue(report);
      return false;
    }
  }

  Future<void> _saveToQueue(BugReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_queueKey) ?? [];
      raw.add(jsonEncode(report.toJson()));
      await prefs.setStringList(_queueKey, raw);
    } catch (_) {}
  }

  Future<void> retryPendingReports() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_queueKey) ?? [];
      if (raw.isEmpty) return;
      final remaining = <String>[];
      for (final item in raw) {
        try {
          final report =
              BugReport.fromJson(jsonDecode(item) as Map<String, dynamic>);
          await _db.collection('bug_reports').add(report.toFirestore());
        } catch (_) {
          remaining.add(item);
        }
      }
      await prefs.setStringList(_queueKey, remaining);
    } catch (_) {}
  }

  Stream<List<BugReport>> watchReports() {
    return _db
        .collection('bug_reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BugReport.fromFirestore).toList());
  }

  Future<void> updateStatus(String docId, String status) async {
    await _db.collection('bug_reports').doc(docId).update({'status': status});
  }
}
