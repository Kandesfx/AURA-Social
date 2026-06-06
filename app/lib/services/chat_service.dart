import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/chat/models/conversation_model.dart';
import '../features/chat/models/message_model.dart';
import '../features/chat/providers/presence_provider.dart';

/// AURA Social – Chat Service
///
/// Person 3: Service layer kết nối Firebase cho Chat.
/// - Firestore: conversations metadata (list, create, update)
/// - RTDB: messages (send, stream), typing, presence
///
/// Tất cả screens/providers gọi qua service này,
/// không gọi Firebase trực tiếp.
class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static const demoPeerId = 'aura_demo_peer';

  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  /// Current user ID (shortcut)
  String get _uid => _auth.currentUser!.uid;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CONVERSATIONS (Firestore)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Stream danh sách conversations mà user tham gia.
  /// Sorted by updated_at desc.
  Stream<List<ConversationModel>> getConversationsStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) => ConversationModel.fromFirestore(doc))
          .toList();

      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return conversations;
    });
  }

  /// Tìm conversation giữa 2 user. Nếu chưa có → tạo mới.
  Future<ConversationModel> getOrCreateConversation(
    String userId1,
    String userId2,
  ) async {
    // Tìm existing conversation
    final query = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId1)
        .get();

    for (final doc in query.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(userId2) && participants.length == 2) {
        return ConversationModel.fromFirestore(doc);
      }
    }

    // Tạo mới
    final now = DateTime.now();
    final newConv = ConversationModel(
      id: '', // Firestore auto-generate
      participants: [userId1, userId2],
      createdAt: now,
      updatedAt: now,
    );

    final docRef = await _firestore
        .collection('conversations')
        .add(newConv.toFirestore());

    final createdDoc = await docRef.get();
    return ConversationModel.fromFirestore(createdDoc);
  }

  /// Cập nhật last_message + updated_at + increment unread cho peer.
  Future<void> updateConversationOnNewMessage({
    required String conversationId,
    required String senderId,
    required String content,
    required String messageType,
    required List<String> participants,
  }) async {
    // Tìm peer (người nhận)
    final peerId = participants.firstWhere(
      (p) => p != senderId,
      orElse: () => '',
    );

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .update({
      'last_message': {
        'content': content,
        'sender_id': senderId,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'type': messageType,
      },
      'updated_at': Timestamp.fromDate(DateTime.now()),
      // Increment unread count cho peer
      if (peerId.isNotEmpty) 'unread_counts.$peerId': FieldValue.increment(1),
    });
  }

  /// Reset unread count khi user đã đọc conversation.
  Future<void> resetUnreadCount(String conversationId, String userId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .update({'unread_counts.$userId': 0});
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // MESSAGES (RTDB)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Stream messages cho 1 conversation (ordered by timestamp).
  /// Limit last 100 messages, load more khi scroll up.
  Stream<List<MessageModel>> getMessagesStream(
    String conversationId, {
    int limit = 100,
  }) {
    final ref = _database
        .ref('messages/$conversationId')
        .orderByChild('timestamp')
        .limitToLast(limit);

    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <MessageModel>[];

      final messages = data.entries.map((entry) {
        final msgData = Map<String, dynamic>.from(entry.value as Map);
        return MessageModel.fromJson(entry.key as String, msgData);
      }).toList();

      // Sort ascending (oldest → newest)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  /// Gửi tin nhắn mới.
  /// 1. Push message lên RTDB
  /// 2. Update conversation metadata trên Firestore
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    required List<String> participants,
  }) async {
    final message = MessageModel(
      id: '', // RTDB auto-generate key
      senderId: _uid,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      readBy: {_uid: true},
    );

    // 1. Push to RTDB
    final ref = _database.ref('messages/$conversationId').push();
    await ref.set(message.toJson());

    // 2. Update Firestore conversation
    await updateConversationOnNewMessage(
      conversationId: conversationId,
      senderId: _uid,
      content: content,
      messageType: type.value,
      participants: participants,
    );
  }

  /// Đánh dấu tất cả messages đã đọc bởi user.
  Future<void> markMessagesAsRead(
    String conversationId,
    String userId,
  ) async {
    // Get recent messages
    final snapshot = await _database
        .ref('messages/$conversationId')
        .orderByChild('timestamp')
        .limitToLast(50)
        .get();

    if (!snapshot.exists) return;

    final data = snapshot.value as Map<dynamic, dynamic>;
    final updates = <String, dynamic>{};

    for (final entry in data.entries) {
      final msgData = Map<String, dynamic>.from(entry.value as Map);
      final readBy =
          Map<String, dynamic>.from(msgData['read_by'] as Map? ?? {});

      if (readBy[userId] != true) {
        updates['${entry.key}/read_by/$userId'] = true;
      }
    }

    if (updates.isNotEmpty) {
      await _database.ref('messages/$conversationId').update(updates);
    }

    // Reset unread count on Firestore
    await resetUnreadCount(conversationId, userId);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TYPING (RTDB)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Set typing status cho current user trong conversation.
  Future<void> setTypingStatus(
    String conversationId,
    bool isTyping,
  ) async {
    final ref = _database.ref('typing/$conversationId/$_uid');

    if (isTyping) {
      await ref.set({
        'is_typing': true,
        'timestamp': ServerValue.timestamp,
      });
      // Auto-clear sau 10s (phòng trường hợp quên clear)
      ref.onDisconnect().remove();
    } else {
      await ref.remove();
    }
  }

  /// Stream typing status của người khác trong conversation.
  /// Trả TypingStatus của peer (nếu đang typing).
  Stream<TypingStatus> getTypingStream(
    String conversationId,
    String currentUserId,
  ) {
    return _database
        .ref('typing/$conversationId')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return const TypingStatus();

      // Tìm user khác đang typing
      for (final entry in data.entries) {
        final userId = entry.key as String;
        if (userId == currentUserId) continue;

        final typingData = Map<String, dynamic>.from(entry.value as Map);
        final isTyping = typingData['is_typing'] as bool? ?? false;

        if (isTyping) {
          return TypingStatus(
            isTyping: true,
            userId: userId,
            timestamp: DateTime.now(),
          );
        }
      }

      return const TypingStatus();
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PRESENCE (RTDB)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Đặt current user online + setup onDisconnect để tự offline.
  Future<void> setOnline() async {
    final ref = _database.ref('presence/$_uid');

    await ref.set({
      'is_online': true,
      'last_seen': ServerValue.timestamp,
      'active_screen': 'app',
    });

    // Khi disconnect → tự set offline
    await ref.onDisconnect().set({
      'is_online': false,
      'last_seen': ServerValue.timestamp,
    });
  }

  /// Cập nhật active screen (cho biết user đang ở đâu).
  Future<void> updateActiveScreen(String screen) async {
    await _database.ref('presence/$_uid/active_screen').set(screen);
  }

  /// Set current user offline (khi thoát app).
  Future<void> setOffline() async {
    await _database.ref('presence/$_uid').set({
      'is_online': false,
      'last_seen': ServerValue.timestamp,
    });
  }

  /// Stream presence cho 1 user cụ thể.
  Stream<UserPresence> getPresenceStream(String userId) {
    return _database.ref('presence/$userId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return const UserPresence(isOnline: false);
      }

      final map = Map<String, dynamic>.from(data);
      return UserPresence(
        isOnline: map['is_online'] as bool? ?? false,
        lastSeen: map['last_seen'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['last_seen'] as int)
            : null,
        activeScreen: map['active_screen'] as String?,
      );
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // USER LOOKUP (Firestore) – for enriching conversations
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Lấy thông tin user từ Firestore (display_name, avatar_url).
  /// Cache locally để tránh query nhiều lần.
  final Map<String, Map<String, dynamic>> _userCache = {};

  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data() ??
        (userId == demoPeerId
            ? {
                'display_name': 'AURA Demo',
                'username': 'aura_demo',
                'aura_dominant_emotion': 'joy',
                'emotion_vector': {'joy': 0.6, 'trust': 0.3},
              }
            : {});
    _userCache[userId] = data;
    return data;
  }

  /// Enrich conversations với peer info (name, avatar, emotion vector).
  Future<List<ConversationModel>> enrichConversations(
    List<ConversationModel> conversations,
    String currentUserId,
  ) async {
    final enriched = <ConversationModel>[];

    for (final conv in conversations) {
      final peerId = conv.participants.firstWhere(
        (p) => p != currentUserId,
        orElse: () => '',
      );

      if (peerId.isEmpty) {
        enriched.add(conv);
        continue;
      }

      try {
        final userInfo = await getUserInfo(peerId);
        final presence = await _database.ref('presence/$peerId').get();
        final presenceData = presence.value as Map<dynamic, dynamic>?;
        final isOnline =
            (presenceData?['is_online'] as bool?) ?? false;

        enriched.add(conv.copyWith(
          peerName: userInfo['display_name'] as String? ??
              userInfo['username'] as String? ??
              'User',
          peerAvatarUrl: userInfo['avatar_url'] as String?,
          isPeerOnline: isOnline,
          peerEmotionVector: _parseEmotionVector(userInfo['emotion_vector']),
        ));
      } catch (_) {
        enriched.add(conv);
      }
    }

    return enriched;
  }

  /// Parse emotion vector từ Firestore data.
  Map<String, double>? _parseEmotionVector(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return Map<String, dynamic>.from(data).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    }
    return null;
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Global ChatService provider.
/// Tất cả providers/screens inject qua đây.
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});
