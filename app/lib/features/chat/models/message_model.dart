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

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final Map<String, bool> readBy;
  final String? aiSentiment;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.readBy = const {},
    this.aiSentiment,
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
    };
  }

  /// Kiểm tra tin nhắn của mình
  bool isMine(String currentUserId) => senderId == currentUserId;

  /// Copy with
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    Map<String, bool>? readBy,
    String? aiSentiment,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      readBy: readBy ?? this.readBy,
      aiSentiment: aiSentiment ?? this.aiSentiment,
    );
  }
}
