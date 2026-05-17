import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/chat_service.dart';
import 'chat_provider.dart';

/// AURA Social – Presence Provider
///
/// Person 3: Quản lý trạng thái online/offline và typing indicator.
/// Kết nối RTDB thông qua ChatService.

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
// PRESENCE PROVIDERS (RTDB Streams)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Stream presence (online/offline) cho 1 user từ RTDB.
final userPresenceStreamProvider =
    StreamProvider.family<UserPresence, String>((ref, userId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getPresenceStream(userId);
});

/// Wrapper tương thích code cũ – trả UserPresence synchronous.
final userPresenceProvider =
    Provider.family<UserPresence, String>((ref, userId) {
  final asyncPresence = ref.watch(userPresenceStreamProvider(userId));
  return asyncPresence.when(
    data: (presence) => presence,
    loading: () => const UserPresence(),
    error: (_, _) => const UserPresence(),
  );
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TYPING PROVIDERS (RTDB Streams)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Stream typing status cho 1 conversation từ RTDB.
final typingStatusStreamProvider =
    StreamProvider.family<TypingStatus, String>((ref, conversationId) {
  final chatService = ref.watch(chatServiceProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  return chatService.getTypingStream(conversationId, currentUserId);
});

/// Wrapper tương thích code cũ – trả TypingStatus synchronous.
final typingStatusProvider =
    Provider.family<TypingStatus, String>((ref, conversationId) {
  final asyncTyping =
      ref.watch(typingStatusStreamProvider(conversationId));
  return asyncTyping.when(
    data: (status) => status,
    loading: () => const TypingStatus(),
    error: (_, _) => const TypingStatus(),
  );
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MY PRESENCE INIT
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Init presence cho current user.
/// Gọi 1 lần khi app start (trong main.dart hoặc app.dart).
final myPresenceProvider = FutureProvider<void>((ref) async {
  final chatService = ref.watch(chatServiceProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId.isEmpty) return;

  await chatService.setOnline();
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TYPING ACTIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Action: set typing status.
final typingActionProvider = Provider<TypingAction>((ref) {
  return TypingAction(ref);
});

class TypingAction {
  TypingAction(this._ref);
  final Ref _ref;

  Future<void> setTyping(String conversationId, bool isTyping) async {
    final chatService = _ref.read(chatServiceProvider);
    await chatService.setTypingStatus(conversationId, isTyping);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HELPERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
