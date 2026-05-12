import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// AURA Social – Chat Provider
///
/// Quản lý state cho conversations và messages.
/// Hiện dùng mock data – khi backend sẵn sàng chỉ cần swap data source.

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MOCK DATA
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const _currentUserId = 'current-user-id';

final _mockConversations = [
  ConversationModel(
    id: 'conv-1',
    participants: [_currentUserId, 'user-minh-anh'],
    lastMessage: LastMessage(
      content: 'Chào bạn! Mình thấy mình match cao ghê 😄',
      senderId: 'user-minh-anh',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    unreadCounts: {_currentUserId: 2},
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    peerName: 'Minh Anh',
    isPeerOnline: true,
    peerEmotionVector: {
      'joy': 0.40,
      'trust': 0.25,
      'anticipation': 0.15,
      'surprise': 0.10,
      'sadness': 0.05,
      'fear': 0.02,
      'anger': 0.01,
      'disgust': 0.02,
    },
  ),
  ConversationModel(
    id: 'conv-2',
    participants: [_currentUserId, 'user-hoang-dung'],
    lastMessage: LastMessage(
      content: 'Bài post hôm nay hay quá!',
      senderId: 'user-hoang-dung',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
    ),
    unreadCounts: {_currentUserId: 0},
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
    peerName: 'Hoàng Dũng',
    isPeerOnline: true,
    peerEmotionVector: {
      'joy': 0.35,
      'anticipation': 0.30,
      'trust': 0.15,
      'surprise': 0.10,
      'sadness': 0.03,
      'fear': 0.02,
      'anger': 0.03,
      'disgust': 0.02,
    },
  ),
  ConversationModel(
    id: 'conv-3',
    participants: [_currentUserId, 'user-thu-ha'],
    lastMessage: LastMessage(
      content: 'Cảm ơn bạn đã chia sẻ 💕',
      senderId: 'user-thu-ha',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    unreadCounts: {_currentUserId: 0},
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    peerName: 'Thu Hà',
    isPeerOnline: false,
    peerEmotionVector: {
      'trust': 0.30,
      'joy': 0.25,
      'anticipation': 0.15,
      'surprise': 0.05,
      'sadness': 0.10,
      'fear': 0.05,
      'anger': 0.05,
      'disgust': 0.05,
    },
  ),
  ConversationModel(
    id: 'conv-4',
    participants: [_currentUserId, 'user-duc-anh'],
    lastMessage: LastMessage(
      content: 'Tối nay đi cafe không?',
      senderId: 'user-duc-anh',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
    unreadCounts: {_currentUserId: 1},
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    peerName: 'Đức Anh',
    isPeerOnline: false,
    peerEmotionVector: {
      'anticipation': 0.35,
      'joy': 0.30,
      'trust': 0.15,
      'surprise': 0.08,
      'sadness': 0.05,
      'fear': 0.03,
      'anger': 0.02,
      'disgust': 0.02,
    },
  ),
  ConversationModel(
    id: 'conv-5',
    type: ConversationType.soulConnect,
    participants: [_currentUserId, 'user-lan-phuong'],
    lastMessage: LastMessage(
      content: 'Mình cũng thích nghe lofi! 🎵',
      senderId: 'user-lan-phuong',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    unreadCounts: {_currentUserId: 3},
    soulConnectionId: 'soul-conn-1',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
    peerName: 'Lan Phương',
    isPeerOnline: true,
    peerEmotionVector: {
      'joy': 0.30,
      'trust': 0.25,
      'sadness': 0.15,
      'anticipation': 0.10,
      'surprise': 0.08,
      'fear': 0.05,
      'anger': 0.04,
      'disgust': 0.03,
    },
  ),
];

final _mockMessages = <String, List<MessageModel>>{
  'conv-1': [
    MessageModel(
      id: 'msg-1-1',
      senderId: 'user-minh-anh',
      content: 'Hey! Mình vừa thấy profile bạn trên Soul Connect 💜',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      readBy: {_currentUserId: true, 'user-minh-anh': true},
      aiSentiment: 'joy',
    ),
    MessageModel(
      id: 'msg-1-2',
      senderId: _currentUserId,
      content: 'Oa thật á! Nice to meet you! 🎉',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
      readBy: {_currentUserId: true, 'user-minh-anh': true},
      aiSentiment: 'joy',
    ),
    MessageModel(
      id: 'msg-1-3',
      senderId: 'user-minh-anh',
      content: 'Mình thấy bạn cũng thích travel và photography. Bạn đã đi đâu chưa?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
      readBy: {_currentUserId: true, 'user-minh-anh': true},
      aiSentiment: 'anticipation',
    ),
    MessageModel(
      id: 'msg-1-4',
      senderId: _currentUserId,
      content: 'Mình vừa đi Đà Lạt tuần trước! Thời tiết mát quá, chụp ảnh tuyệt vời 📸',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      readBy: {_currentUserId: true, 'user-minh-anh': true},
      aiSentiment: 'joy',
    ),
    MessageModel(
      id: 'msg-1-5',
      senderId: 'user-minh-anh',
      content: 'Wow Đà Lạt! Mình cũng muốn đi lắm. Cho mình xem ảnh đi!',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 40)),
      readBy: {_currentUserId: true, 'user-minh-anh': true},
      aiSentiment: 'anticipation',
    ),
    MessageModel(
      id: 'msg-1-6',
      senderId: _currentUserId,
      content: 'Đây nè, hồ Xuân Hương buổi sáng sớm 🌅',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 35)),
      readBy: {_currentUserId: true, 'user-minh-anh': true},
      aiSentiment: 'trust',
    ),
    MessageModel(
      id: 'msg-1-7',
      senderId: 'user-minh-anh',
      content: 'Đẹp quá! 😍 Lần tới mình plan đi cùng nhé',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      readBy: {_currentUserId: true, 'user-minh-anh': true},
      aiSentiment: 'joy',
    ),
    MessageModel(
      id: 'msg-1-8',
      senderId: 'user-minh-anh',
      content: 'Chào bạn! Mình thấy mình match cao ghê 😄',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      readBy: {_currentUserId: false, 'user-minh-anh': true},
      aiSentiment: 'joy',
    ),
  ],
  'conv-2': [
    MessageModel(
      id: 'msg-2-1',
      senderId: 'user-hoang-dung',
      content: 'Bro, bạn có biết Flutter Riverpod ko?',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      readBy: {_currentUserId: true, 'user-hoang-dung': true},
      aiSentiment: 'anticipation',
    ),
    MessageModel(
      id: 'msg-2-2',
      senderId: _currentUserId,
      content: 'Có chứ! Mình đang dùng cho project này nè 💻',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 50)),
      readBy: {_currentUserId: true, 'user-hoang-dung': true},
      aiSentiment: 'trust',
    ),
    MessageModel(
      id: 'msg-2-3',
      senderId: 'user-hoang-dung',
      content: 'Bài post hôm nay hay quá!',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      readBy: {_currentUserId: true, 'user-hoang-dung': true},
      aiSentiment: 'joy',
    ),
  ],
  'conv-3': [
    MessageModel(
      id: 'msg-3-1',
      senderId: _currentUserId,
      content: 'Hôm nay mình đọc được 1 bài viết hay lắm, share cho bạn nè',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      readBy: {_currentUserId: true, 'user-thu-ha': true},
      aiSentiment: 'trust',
    ),
    MessageModel(
      id: 'msg-3-2',
      senderId: 'user-thu-ha',
      content: 'Cảm ơn bạn đã chia sẻ 💕',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      readBy: {_currentUserId: true, 'user-thu-ha': true},
      aiSentiment: 'trust',
    ),
  ],
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Current user ID (mock)
final currentUserIdProvider = Provider<String>((ref) => _currentUserId);

/// Danh sách conversations
final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, List<ConversationModel>>(
        (ref) {
  return ConversationsNotifier();
});

class ConversationsNotifier extends StateNotifier<List<ConversationModel>> {
  ConversationsNotifier() : super(_mockConversations);

  /// Cập nhật last message khi gửi tin nhắn mới
  void updateLastMessage(String conversationId, LastMessage message) {
    state = [
      for (final conv in state)
        if (conv.id == conversationId)
          conv.copyWith(
            lastMessage: message,
            updatedAt: message.timestamp,
          )
        else
          conv,
    ];
    // Re-sort: mới nhất lên đầu
    state = [...state]..sort((a, b) =>
        (b.lastMessage?.timestamp ?? b.updatedAt)
            .compareTo(a.lastMessage?.timestamp ?? a.updatedAt));
  }

  /// Reset unread count
  void markAsRead(String conversationId, String userId) {
    state = [
      for (final conv in state)
        if (conv.id == conversationId)
          conv.copyWith(
            unreadCounts: {...conv.unreadCounts, userId: 0},
          )
        else
          conv,
    ];
  }
}

/// Messages cho 1 conversation cụ thể
final chatMessagesProvider = StateNotifierProvider.family<
    ChatMessagesNotifier, List<MessageModel>, String>(
  (ref, conversationId) {
    return ChatMessagesNotifier(conversationId);
  },
);

class ChatMessagesNotifier extends StateNotifier<List<MessageModel>> {
  ChatMessagesNotifier(this.conversationId)
      : super(_mockMessages[conversationId] ?? []);

  final String conversationId;

  /// Gửi tin nhắn mới (local mock)
  void sendMessage(String content, {MessageType type = MessageType.text}) {
    final newMessage = MessageModel(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUserId,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      readBy: {_currentUserId: true},
    );
    state = [...state, newMessage];
  }
}

/// Tổng unread count cho badge
final totalUnreadCountProvider = Provider<int>((ref) {
  final conversations = ref.watch(conversationsProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  return conversations.fold<int>(
    0,
    (sum, conv) => sum + conv.unreadCountFor(currentUserId),
  );
});
