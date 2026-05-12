import 'package:cloud_firestore/cloud_firestore.dart';

/// AURA Social – Conversation Model
///
/// Metadata cuộc hội thoại từ Firestore.
/// Schema: /conversations/{conversationId}

/// Loại conversation
enum ConversationType {
  direct('direct'),
  soulConnect('soul_connect');

  const ConversationType(this.value);
  final String value;

  static ConversationType fromString(String value) {
    return ConversationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ConversationType.direct,
    );
  }
}

/// Last message denormalized cho list display
class LastMessage {
  final String content;
  final String senderId;
  final DateTime timestamp;
  final String type;

  const LastMessage({
    required this.content,
    required this.senderId,
    required this.timestamp,
    this.type = 'text',
  });

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      content: map['content'] as String? ?? '',
      senderId: map['sender_id'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: map['type'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'sender_id': senderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
    };
  }
}

class ConversationModel {
  final String id;
  final ConversationType type;
  final List<String> participants;
  final LastMessage? lastMessage;
  final Map<String, int> unreadCounts;
  final String? soulConnectionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Denormalized display fields (from user lookup) ──
  final String? peerName;
  final String? peerAvatarUrl;
  final bool isPeerOnline;
  final Map<String, double>? peerEmotionVector;

  const ConversationModel({
    required this.id,
    this.type = ConversationType.direct,
    required this.participants,
    this.lastMessage,
    this.unreadCounts = const {},
    this.soulConnectionId,
    required this.createdAt,
    required this.updatedAt,
    this.peerName,
    this.peerAvatarUrl,
    this.isPeerOnline = false,
    this.peerEmotionVector,
  });

  /// Từ Firestore document
  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ConversationModel(
      id: doc.id,
      type: ConversationType.fromString(data['type'] as String? ?? 'direct'),
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['last_message'] != null
          ? LastMessage.fromMap(data['last_message'] as Map<String, dynamic>)
          : null,
      unreadCounts: (data['unread_counts'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      soulConnectionId: data['soul_connection_id'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Sang Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.value,
      'participants': participants,
      if (lastMessage != null) 'last_message': lastMessage!.toMap(),
      'unread_counts': unreadCounts,
      if (soulConnectionId != null) 'soul_connection_id': soulConnectionId,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Lấy unread count cho user cụ thể
  int unreadCountFor(String userId) => unreadCounts[userId] ?? 0;

  /// Copy with
  ConversationModel copyWith({
    String? id,
    ConversationType? type,
    List<String>? participants,
    LastMessage? lastMessage,
    Map<String, int>? unreadCounts,
    String? soulConnectionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? peerName,
    String? peerAvatarUrl,
    bool? isPeerOnline,
    Map<String, double>? peerEmotionVector,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      soulConnectionId: soulConnectionId ?? this.soulConnectionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      peerName: peerName ?? this.peerName,
      peerAvatarUrl: peerAvatarUrl ?? this.peerAvatarUrl,
      isPeerOnline: isPeerOnline ?? this.isPeerOnline,
      peerEmotionVector: peerEmotionVector ?? this.peerEmotionVector,
    );
  }
}
