import 'dart:async';
import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AURA Social – Behavioral Tracker Service
///
/// ★ Core service (Person 4, Task #1)
/// Ghi nhận behavioral events từ user và batch-flush lên Firestore mỗi 30s.
///
/// Event types được track:
/// - `view_post` – user xem post (scroll into viewport)
/// - `scroll` – scroll depth trên feed
/// - `reaction` – user react emoji lên post
/// - `create_post` – user tạo post mới
/// - `view_profile` – user xem profile người khác
/// - `search` – user search
/// - `time_on_screen` – thời gian trên mỗi screen
/// - `app_open` / `app_close` – session tracking
///
/// Architecture:
/// - In-memory queue (LinkedList for O(1) enqueue)
/// - Timer-based batch flush mỗi 30 giây
/// - Firestore subcollection: `users/{uid}/behavioral_events`
/// - Auto-pause khi user logout
class BehavioralTracker {
  BehavioralTracker._();
  static final BehavioralTracker instance = BehavioralTracker._();

  // ── Config ──
  static const _batchInterval = Duration(seconds: 30);
  static const _maxQueueSize = 100; // Flush ngay nếu queue đầy

  // ── State ──
  final Queue<BehavioralEvent> _eventQueue = Queue<BehavioralEvent>();
  Timer? _batchTimer;
  bool _isRunning = false;
  DateTime? _sessionStart;

  // ── Public API ──

  /// Bắt đầu tracking (gọi sau khi user login)
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _sessionStart = DateTime.now();

    // Track app open
    trackEvent(BehavioralEvent(
      type: 'app_open',
      timestamp: DateTime.now(),
    ));

    // Start batch timer
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (_) => _flush());
  }

  /// Dừng tracking (gọi khi user logout)
  void stop() {
    if (!_isRunning) return;

    // Track app close + session duration
    if (_sessionStart != null) {
      final duration = DateTime.now().difference(_sessionStart!);
      trackEvent(BehavioralEvent(
        type: 'app_close',
        timestamp: DateTime.now(),
        metadata: {'session_duration_seconds': duration.inSeconds},
      ));
    }

    // Final flush
    _flush();

    _batchTimer?.cancel();
    _batchTimer = null;
    _isRunning = false;
    _sessionStart = null;
  }

  /// Ghi nhận một behavioral event
  void trackEvent(BehavioralEvent event) {
    if (!_isRunning) return;

    _eventQueue.add(event);

    // Flush ngay nếu queue đầy
    if (_eventQueue.length >= _maxQueueSize) {
      _flush();
    }
  }

  // ── Convenience methods ──

  /// Track user xem post
  void trackViewPost(String postId, {int scrollDepth = 0}) {
    trackEvent(BehavioralEvent(
      type: 'view_post',
      targetId: postId,
      timestamp: DateTime.now(),
      metadata: {'scroll_depth': scrollDepth},
    ));
  }

  /// Track user react lên post
  void trackReaction(String postId, String emotion) {
    trackEvent(BehavioralEvent(
      type: 'reaction',
      targetId: postId,
      timestamp: DateTime.now(),
      metadata: {'emotion': emotion},
    ));
  }

  /// Track user tạo post
  void trackCreatePost(String postId, {String? mood}) {
    trackEvent(BehavioralEvent(
      type: 'create_post',
      targetId: postId,
      timestamp: DateTime.now(),
      metadata: mood != null ? {'mood': mood} : null,
    ));
  }

  /// Track user xem profile
  void trackViewProfile(String userId) {
    trackEvent(BehavioralEvent(
      type: 'view_profile',
      targetId: userId,
      timestamp: DateTime.now(),
    ));
  }

  /// Track user search
  void trackSearch(String query) {
    trackEvent(BehavioralEvent(
      type: 'search',
      timestamp: DateTime.now(),
      metadata: {'query': query},
    ));
  }

  /// Track thời gian trên screen
  void trackTimeOnScreen(String screenName, Duration duration) {
    trackEvent(BehavioralEvent(
      type: 'time_on_screen',
      timestamp: DateTime.now(),
      metadata: {
        'screen': screenName,
        'duration_seconds': duration.inSeconds,
      },
    ));
  }

  /// Track scroll depth trên feed
  void trackScroll(double scrollPosition, double maxScroll) {
    final depth = maxScroll > 0 ? (scrollPosition / maxScroll * 100).round() : 0;
    trackEvent(BehavioralEvent(
      type: 'scroll',
      timestamp: DateTime.now(),
      metadata: {'depth_percent': depth},
    ));
  }

  // ── Private ──

  /// Flush tất cả events trong queue lên Firestore
  Future<void> _flush() async {
    if (_eventQueue.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Snapshot queue rồi clear
    final events = List<BehavioralEvent>.from(_eventQueue);
    _eventQueue.clear();

    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('behavioral_events');

      for (final event in events) {
        final docRef = collection.doc();
        batch.set(docRef, event.toMap());
      }

      await batch.commit();
    } catch (e) {
      // Nếu flush fail → đưa events lại vào queue để retry lần sau
      for (final event in events) {
        _eventQueue.addFirst(event);
      }
    }
  }

  /// Số events đang chờ flush (for debugging/testing)
  int get pendingEventCount => _eventQueue.length;

  /// Tracker đang chạy hay không
  bool get isRunning => _isRunning;
}

/// Model cho một behavioral event
class BehavioralEvent {
  BehavioralEvent({
    required this.type,
    required this.timestamp,
    this.targetId,
    this.metadata,
  });

  final String type;
  final DateTime timestamp;
  final String? targetId;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      if (targetId != null) 'target_id': targetId,
      if (metadata != null) ...metadata!,
    };
  }

  factory BehavioralEvent.fromMap(Map<String, dynamic> map) {
    return BehavioralEvent(
      type: map['type'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      targetId: map['target_id'] as String?,
      metadata: Map<String, dynamic>.from(map)
        ..remove('type')
        ..remove('timestamp')
        ..remove('target_id'),
    );
  }
}
