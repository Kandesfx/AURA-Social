// AURA Social – Message Model
//
// Dữ liệu tin nhắn trong RTDB.
// Schema: /messages/{conversationId}/{messageId}

/// Loại tin nhắn
enum MessageType {
  text('text'),
  image('image'),
  sticker('sticker'),
  reaction('reaction'),
  system('system'),
  aiSuggestion('ai_suggestion');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Thông tin reply (trích dẫn tin nhắn)
class ReplyInfo {
  final String messageId;
  final String senderId;
  final String senderName;
  final String content;

  const ReplyInfo({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.content,
  });

  factory ReplyInfo.fromJson(Map<String, dynamic> json) {
    return ReplyInfo(
      messageId: json['message_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'message_id': messageId,
    'sender_id': senderId,
    'sender_name': senderName,
    'content': content,
  };
}

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final Map<String, bool> readBy;
  final String? aiSentiment;

  /// Reactions: { userId: emotionType } (e.g. {"user1": "joy", "user2": "trust"})
  final Map<String, String> reactions;

  /// Reply/Quote: info về tin nhắn được trích dẫn
  final ReplyInfo? replyTo;

  /// URL ảnh/media (cho image messages)
  final String? mediaUrl;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.readBy = const {},
    this.aiSentiment,
    this.reactions = const {},
    this.replyTo,
    this.mediaUrl,
  });

  /// Từ RTDB JSON
  factory MessageModel.fromJson(String id, Map<String, dynamic> json) {
    return MessageModel(
      id: id,
      senderId: json['sender_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: MessageType.fromString(json['type'] as String? ?? 'text'),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] as num?)?.toInt() ?? 0,
      ),
      readBy: json['read_by'] != null
          ? Map.from(json['read_by'] as Map).map(
              (key, value) => MapEntry(key.toString(), value == true),
            )
          : {},
      aiSentiment: json['ai_sentiment'] as String?,
      reactions: json['reactions'] != null
          ? Map.from(json['reactions'] as Map).map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : {},
      replyTo: json['reply_to'] != null
          ? ReplyInfo.fromJson(Map<String, dynamic>.from(json['reply_to'] as Map))
          : null,
      mediaUrl: json['media_url'] as String?,
    );
  }

  /// Sang RTDB JSON
  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'content': content,
      'type': type.value,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'read_by': readBy,
      if (aiSentiment != null) 'ai_sentiment': aiSentiment,
      if (reactions.isNotEmpty) 'reactions': reactions,
      if (replyTo != null) 'reply_to': replyTo!.toJson(),
      if (mediaUrl != null) 'media_url': mediaUrl,
    };
  }

  /// Kiểm tra tin nhắn của mình
  bool isMine(String currentUserId) => senderId == currentUserId;

  /// Tổng hợp reactions theo emotion type
  Map<String, int> get reactionCounts {
    final counts = <String, int>{};
    for (final emotion in reactions.values) {
      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }
    return counts;
  }

  /// Copy with
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    Map<String, bool>? readBy,
    String? aiSentiment,
    Map<String, String>? reactions,
    ReplyInfo? replyTo,
    String? mediaUrl,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      readBy: readBy ?? this.readBy,
      aiSentiment: aiSentiment ?? this.aiSentiment,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }
}
