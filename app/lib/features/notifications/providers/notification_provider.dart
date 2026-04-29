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
  NotificationNotifier() : super(const NotificationState(isLoading: true)) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // TODO: Replace với Firestore stream
    await Future.delayed(const Duration(milliseconds: 500));

    state = NotificationState(
      notifications: _mockNotifications,
      isLoading: false,
    );
  }

  /// Đánh dấu một notification là đã đọc
  void markAsRead(String notificationId) {
    final updated = state.notifications.map((n) {
      if (n.id == notificationId) return n.copyWith(isRead: true);
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  /// Đánh dấu tất cả là đã đọc
  void markAllAsRead() {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MOCK DATA
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final _now = DateTime.now();

final _mockNotifications = [
  NotificationItem(
    id: 'n1',
    type: NotificationType.reaction,
    title: 'Reaction mới',
    body: 'đã react 😊 Joy lên bài viết của bạn',
    senderName: 'Minh Anh',
    targetId: 'post_1',
    createdAt: _now.subtract(const Duration(minutes: 5)),
    senderEmotionVector: {'joy': 0.4, 'trust': 0.25, 'anticipation': 0.15, 'surprise': 0.1, 'sadness': 0.05, 'fear': 0.02, 'anger': 0.01, 'disgust': 0.02},
  ),
  NotificationItem(
    id: 'n2',
    type: NotificationType.follow,
    title: 'Người theo dõi mới',
    body: 'đã bắt đầu theo dõi bạn',
    senderName: 'Hoàng Dũng',
    targetId: 'user_2',
    createdAt: _now.subtract(const Duration(minutes: 30)),
    senderEmotionVector: {'anticipation': 0.35, 'joy': 0.25, 'trust': 0.2, 'surprise': 0.1, 'sadness': 0.03, 'fear': 0.02, 'anger': 0.03, 'disgust': 0.02},
  ),
  NotificationItem(
    id: 'n3',
    type: NotificationType.soulConnect,
    title: 'Soul Connect 💜',
    body: 'Bạn có một Soul Connection mới!',
    senderName: 'Thu Hà',
    targetId: 'soul_1',
    createdAt: _now.subtract(const Duration(hours: 1)),
    senderEmotionVector: {'trust': 0.35, 'joy': 0.3, 'anticipation': 0.15, 'surprise': 0.05, 'sadness': 0.05, 'fear': 0.05, 'anger': 0.03, 'disgust': 0.02},
  ),
  NotificationItem(
    id: 'n4',
    type: NotificationType.message,
    title: 'Tin nhắn mới',
    body: 'đã gửi cho bạn một tin nhắn',
    senderName: 'Khánh Linh',
    targetId: 'conv_1',
    createdAt: _now.subtract(const Duration(hours: 2)),
    isRead: true,
    senderEmotionVector: {'joy': 0.3, 'trust': 0.2, 'anticipation': 0.2, 'surprise': 0.1, 'sadness': 0.1, 'fear': 0.05, 'anger': 0.03, 'disgust': 0.02},
  ),
  NotificationItem(
    id: 'n5',
    type: NotificationType.waveInvite,
    title: 'Wave mới 🌊',
    body: 'Bạn đã được mời tham gia wave "Đêm Không Ngủ"',
    senderName: 'System',
    targetId: 'wave_1',
    createdAt: _now.subtract(const Duration(hours: 3)),
    isRead: true,
  ),
  NotificationItem(
    id: 'n6',
    type: NotificationType.reaction,
    title: 'Reaction mới',
    body: 'đã react 🤗 Trust lên bài viết của bạn',
    senderName: 'Tuấn Kiệt',
    targetId: 'post_2',
    createdAt: _now.subtract(const Duration(hours: 5)),
    isRead: true,
    senderEmotionVector: {'trust': 0.35, 'joy': 0.25, 'anticipation': 0.2, 'surprise': 0.1, 'sadness': 0.05, 'fear': 0.02, 'anger': 0.01, 'disgust': 0.02},
  ),
  NotificationItem(
    id: 'n7',
    type: NotificationType.follow,
    title: 'Người theo dõi mới',
    body: 'đã bắt đầu theo dõi bạn',
    senderName: 'Đức Minh',
    targetId: 'user_5',
    createdAt: _now.subtract(const Duration(hours: 8)),
    isRead: true,
    senderEmotionVector: {'joy': 0.3, 'anticipation': 0.25, 'trust': 0.2, 'surprise': 0.15, 'sadness': 0.03, 'fear': 0.02, 'anger': 0.03, 'disgust': 0.02},
  ),
  NotificationItem(
    id: 'n8',
    type: NotificationType.system,
    title: 'Wellbeing Check 🌟',
    body: 'Wellbeing score tuần này: 72/100. Bạn đang làm rất tốt!',
    senderName: 'AURA AI',
    createdAt: _now.subtract(const Duration(days: 1)),
    isRead: true,
  ),
];
