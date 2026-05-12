import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AURA Social – Presence Provider
///
/// Quản lý trạng thái online/offline và typing indicator.
/// Mock data – khi backend sẵn sàng swap sang RTDB stream.

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MODELS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class UserPresence {
  final bool isOnline;
  final DateTime? lastSeen;
  final String? activeScreen;

  const UserPresence({
    this.isOnline = false,
    this.lastSeen,
    this.activeScreen,
  });
}

class TypingStatus {
  final bool isTyping;
  final String? userId;
  final String? userName;
  final DateTime? timestamp;

  const TypingStatus({
    this.isTyping = false,
    this.userId,
    this.userName,
    this.timestamp,
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MOCK DATA
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final _mockPresence = <String, UserPresence>{
  'user-minh-anh': UserPresence(
    isOnline: true,
    lastSeen: DateTime.now(),
    activeScreen: 'chat',
  ),
  'user-hoang-dung': UserPresence(
    isOnline: true,
    lastSeen: DateTime.now(),
    activeScreen: 'feed',
  ),
  'user-thu-ha': UserPresence(
    isOnline: false,
    lastSeen: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  'user-duc-anh': UserPresence(
    isOnline: false,
    lastSeen: DateTime.now().subtract(const Duration(hours: 8)),
  ),
  'user-lan-phuong': UserPresence(
    isOnline: true,
    lastSeen: DateTime.now(),
    activeScreen: 'feed',
  ),
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Online/Offline status cho 1 user
final userPresenceProvider =
    Provider.family<UserPresence, String>((ref, userId) {
  return _mockPresence[userId] ?? const UserPresence();
});

/// Typing status cho 1 conversation
/// Dùng StateNotifier để simulate typing on/off
final typingStatusProvider = StateNotifierProvider.family<
    TypingStatusNotifier, TypingStatus, String>(
  (ref, conversationId) => TypingStatusNotifier(),
);

class TypingStatusNotifier extends StateNotifier<TypingStatus> {
  TypingStatusNotifier() : super(const TypingStatus());

  /// Simulate đối phương đang gõ
  void setTyping({
    required String userId,
    required String userName,
  }) {
    state = TypingStatus(
      isTyping: true,
      userId: userId,
      userName: userName,
      timestamp: DateTime.now(),
    );
  }

  /// Ngưng gõ
  void clearTyping() {
    state = const TypingStatus();
  }
}

/// Format last seen text
String formatLastSeen(DateTime? lastSeen) {
  if (lastSeen == null) return 'Offline';

  final diff = DateTime.now().difference(lastSeen);
  if (diff.inMinutes < 1) return 'Vừa mới';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return '${lastSeen.day}/${lastSeen.month}';
}
