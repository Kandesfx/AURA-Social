import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AURA Social – Notification Provider
///
/// Person 4, Task #6
/// Quản lý state cho notifications.
/// Sử dụng mock data (chờ Firestore stream từ Cloud Functions).
///
/// Khi backend ready → replace mock bằng:
/// ```dart
/// FirebaseFirestore.instance
///   .collection('users').doc(uid)
///   .collection('notifications')
///   .orderBy('created_at', descending: true)
///   .limit(50)
///   .snapshots()
/// ```

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MODEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum NotificationType {
  reaction,
  follow,
  message,
  soulConnect,
  waveInvite,
  system,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? avatarUrl;
  final String? targetId;
  final String senderName;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, double>? senderEmotionVector;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.avatarUrl,
    this.targetId,
    required this.senderName,
    required this.createdAt,
    this.isRead = false,
    this.senderEmotionVector,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      body: body,
      avatarUrl: avatarUrl,
      targetId: targetId,
      senderName: senderName,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      senderEmotionVector: senderEmotionVector,
    );
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map, String id) {
    final rawEmotion = map['sender_emotion_vector'];
    final emotionVector = rawEmotion is Map
        ? Map<String, dynamic>.from(rawEmotion).map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          )
        : null;

    DateTime parsedDate = DateTime.now();
    if (map['created_at'] is Timestamp) {
      parsedDate = (map['created_at'] as Timestamp).toDate();
    } else if (map['created_at'] is String) {
      parsedDate = DateTime.tryParse(map['created_at']) ?? DateTime.now();
    }

    return NotificationItem(
      id: id,
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.system,
      ),
      title: map['title'] as String? ?? 'Thông báo',
      body: map['body'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      targetId: map['target_id'] as String?,
      senderName: map['sender_name'] as String? ?? 'Hệ thống',
      createdAt: parsedDate,
      isRead: map['is_read'] as bool? ?? false,
      senderEmotionVector: emotionVector,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STATE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class NotificationState {
  final List<NotificationItem> notifications;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NOTIFIER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class NotificationNotifier extends StateNotifier<NotificationState> {
  StreamSubscription? _subscription;

  NotificationNotifier() : super(const NotificationState(isLoading: true)) {
    _loadNotifications();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      state = const NotificationState(notifications: [], isLoading: false);
      return;
    }

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationItem.fromMap(data, doc.id);
      }).toList();

      state = NotificationState(
        notifications: notifications,
        isLoading: false,
      );
    }, onError: (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    });
  }

  /// Đánh dấu một notification là đã đọc
  Future<void> markAsRead(String notificationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final updated = state.notifications.map((n) {
      if (n.id == notificationId) return n.copyWith(isRead: true);
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'is_read': true});
    } catch (e) {
      // Bỏ qua lỗi hoặc revert nếu cần
    }
  }

  /// Đánh dấu tất cả là đã đọc
  Future<void> markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final unreadList = state.notifications.where((n) => !n.isRead).toList();
    if (unreadList.isEmpty) return;

    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var n in unreadList) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc(n.id);
        batch.update(docRef, {'is_read': true});
      }
      await batch.commit();
    } catch (e) {
      // Bỏ qua lỗi hoặc revert nếu cần
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadNotifications();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

/// Convenient provider cho unread count (dùng cho badge)
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});


