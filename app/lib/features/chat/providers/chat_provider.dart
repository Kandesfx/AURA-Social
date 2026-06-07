import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/chat_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// AURA Social – Chat Provider
///
/// Person 3: Quản lý state cho conversations và messages.
/// Kết nối Firebase Firestore (conversations) + RTDB (messages)
/// thông qua ChatService.

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CURRENT USER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Current user ID từ Firebase Auth.
final currentUserIdProvider = Provider<String>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return user?.uid ?? '';
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONVERSATIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Stream danh sách conversations từ Firestore.
/// Tự động enrich với peer info (name, avatar, online status).
final conversationsStreamProvider =
    StreamProvider<List<ConversationModel>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId.isEmpty) return Stream.value([]);

  return chatService.getConversationsStream(userId).asyncMap(
    (conversations) => chatService.enrichConversations(conversations, userId),
  );
});

/// Wrapper provider tương thích với code cũ.
/// Trả `List<ConversationModel>` (empty nếu loading/error).
final conversationsProvider = Provider<List<ConversationModel>>((ref) {
  final asyncConversations = ref.watch(conversationsStreamProvider);
  return asyncConversations.when(
    data: (conversations) => conversations,
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Notifier cho các actions trên conversations.
/// Gọi ChatService thay vì thay đổi local state.
final conversationActionsProvider =
    Provider<ConversationActions>((ref) {
  return ConversationActions(ref);
});

class ConversationActions {
  ConversationActions(this._ref);
  final Ref _ref;

  ChatService get _chatService => _ref.read(chatServiceProvider);

  /// Cập nhật last message (được gọi tự động khi sendMessage).
  /// Không cần gọi manual – ChatService đã xử lý.
  Future<void> updateLastMessage(
    String conversationId,
    LastMessage message,
  ) async {
    // ChatService.sendMessage đã handle update conversation
    // Method này giữ lại cho backward compatibility
  }

  /// Reset unread count khi user vào conversation.
  Future<void> markAsRead(String conversationId, String userId) async {
    await _chatService.markMessagesAsRead(conversationId, userId);
  }

  /// Tìm hoặc tạo conversation với user.
  Future<ConversationModel> getOrCreateConversation(
    String peerId,
  ) async {
    final userId = _ref.read(currentUserIdProvider);
    return _chatService.getOrCreateConversation(userId, peerId);
  }

  Future<ConversationModel> createDemoConversation() async {
    final userId = _ref.read(currentUserIdProvider);
    final conversation = await _chatService.getOrCreateConversation(
      userId,
      ChatService.demoPeerId,
    );

    if (conversation.lastMessage == null) {
      await _chatService.sendMessage(
        conversationId: conversation.id,
        content: 'Xin chao! Day la tin nhan demo cua AURA.',
        participants: conversation.participants,
      );
    }

    return conversation;
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MESSAGES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Stream messages cho 1 conversation từ RTDB.
final chatMessagesStreamProvider =
    StreamProvider.family<List<MessageModel>, String>(
  (ref, conversationId) {
    final chatService = ref.watch(chatServiceProvider);
    return chatService.getMessagesStream(conversationId);
  },
);

/// Wrapper provider tương thích với code cũ.
/// Trả `List<MessageModel>` (empty nếu loading/error).
final chatMessagesProvider =
    Provider.family<List<MessageModel>, String>(
  (ref, conversationId) {
    final asyncMessages = ref.watch(chatMessagesStreamProvider(conversationId));
    return asyncMessages.when(
      data: (messages) => messages,
      loading: () => [],
      error: (_, _) => [],
    );
  },
);

/// Action: gửi tin nhắn mới.
final sendMessageProvider = Provider<SendMessageAction>((ref) {
  return SendMessageAction(ref);
});

class SendMessageAction {
  SendMessageAction(this._ref);
  final Ref _ref;

  /// Gửi tin nhắn text.
  Future<void> send({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    required List<String> participants,
  }) async {
    final chatService = _ref.read(chatServiceProvider);
    await chatService.sendMessage(
      conversationId: conversationId,
      content: content,
      type: type,
      participants: participants,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UNREAD COUNT
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Tổng unread count từ tất cả conversations.
/// Dùng cho badge trên bottom nav.
final totalUnreadCountProvider = Provider<int>((ref) {
  final conversations = ref.watch(conversationsProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId.isEmpty) return 0;

  return conversations.fold<int>(
    0,
    (sum, conv) => sum + conv.unreadCountFor(currentUserId),
  );
});

/// Loading state cho conversations.
final conversationsLoadingProvider = Provider<bool>((ref) {
  final asyncConversations = ref.watch(conversationsStreamProvider);
  return asyncConversations.isLoading;
});

/// Error state cho conversations.
final conversationsErrorProvider = Provider<String?>((ref) {
  final asyncConversations = ref.watch(conversationsStreamProvider);
  return asyncConversations.when(
    data: (_) => null,
    loading: () => null,
    error: (e, _) => e.toString(),
  );
});
