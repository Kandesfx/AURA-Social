import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

// AURA Social – Wave Model
//
// Dữ liệu Emotional Wave từ Firestore.
// Schema: /waves/{waveId}

/// Trạng thái Wave
enum WaveStatus {
  forming('forming'),
  active('active'),
  fading('fading'),
  archived('archived');

  const WaveStatus(this.value);
  final String value;

  static WaveStatus fromString(String value) {
    return WaveStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WaveStatus.active,
    );
  }
}

class WaveModel {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final String dominantEmotion;
  final WaveStatus status;
  final double momentum;
  final int memberCount;
  final int maxMembers;
  final int messageCount;
  final Map<String, double>? emotionClusterCenter;
  final DateTime createdAt;
  final DateTime? estimatedEndAt;

  const WaveModel({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.dominantEmotion,
    this.status = WaveStatus.active,
    this.momentum = 0.5,
    this.memberCount = 0,
    this.maxMembers = 50,
    this.messageCount = 0,
    this.emotionClusterCenter,
    required this.createdAt,
    this.estimatedEndAt,
  });

  /// Factory từ Firestore document
  factory WaveModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WaveModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '🌊',
      description: data['description'] as String? ?? '',
      dominantEmotion: data['dominant_emotion'] as String? ?? 'joy',
      status: WaveStatus.fromString(data['status'] as String? ?? 'active'),
      momentum: (data['momentum'] as num?)?.toDouble() ?? 0.5,
      memberCount: (data['member_count'] as num?)?.toInt() ?? 0,
      maxMembers: (data['max_members'] as num?)?.toInt() ?? 50,
      messageCount: (data['message_count'] as num?)?.toInt() ?? 0,
      emotionClusterCenter: _parseEmotionMap(data['emotion_cluster_center']),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedEndAt: (data['estimated_end_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Parse emotion map từ dynamic Firestore data
  static Map<String, double>? _parseEmotionMap(dynamic data) {
    if (data == null || data is! Map) return null;
    return Map<String, dynamic>.from(data).map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
  }

  /// Thời gian còn lại
  Duration? get timeRemaining {
    if (estimatedEndAt == null) return null;
    final remaining = estimatedEndAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Format thời gian còn lại
  String get timeRemainingText {
    final remaining = timeRemaining;
    if (remaining == null) return '';
    if (remaining.inHours > 0) return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    if (remaining.inMinutes > 0) return '${remaining.inMinutes}m';
    return 'Sắp kết thúc';
  }
}

/// Member trong Wave
class WaveMember {
  final String uid;
  final String displayName;
  final String? avatarUrl;
  final String? auraDominantEmotion;
  final Map<String, double>? emotionVector;
  final DateTime joinedAt;
  final int messageCount;

  const WaveMember({
    required this.uid,
    required this.displayName,
    this.avatarUrl,
    this.auraDominantEmotion,
    this.emotionVector,
    required this.joinedAt,
    this.messageCount = 0,
  });

  /// Factory từ Firestore subcollection document (waves/{waveId}/members/{uid})
  factory WaveMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WaveMember(
      uid: doc.id,
      displayName: data['display_name'] as String? ?? '',
      avatarUrl: data['avatar_url'] as String?,
      auraDominantEmotion: data['aura_dominant_emotion'] as String?,
      emotionVector: WaveModel._parseEmotionMap(data['emotion_vector']),
      joinedAt: (data['joined_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageCount: (data['message_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Serialize to Firestore map (khi join wave)
  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'aura_dominant_emotion': auraDominantEmotion,
    'emotion_vector': emotionVector,
    'joined_at': FieldValue.serverTimestamp(),
    'last_active_at': FieldValue.serverTimestamp(),
    'message_count': messageCount,
    'status': 'active',
  };
}

/// Message trong Wave chat (RTDB)
class WaveMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;
  final Map<String, String>? reactions;

  const WaveMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.timestamp,
    this.reactions,
  });

  /// Factory từ RTDB snapshot (wave_messages/{waveId}/{messageId})
  factory WaveMessage.fromRtdb(String id, Map<String, dynamic> data) {
    return WaveMessage(
      id: id,
      senderId: data['sender_id'] as String? ?? '',
      senderName: data['sender_name'] as String? ?? '',
      senderAvatar: data['sender_avatar'] as String?,
      content: data['content'] as String? ?? '',
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int)
          : DateTime.now(),
      reactions: data['reactions'] != null
          ? Map<String, String>.from(data['reactions'] as Map)
          : null,
    );
  }

  /// Serialize to RTDB map (khi gửi message)
  Map<String, dynamic> toRtdb() => {
    'sender_id': senderId,
    'sender_name': senderName,
    if (senderAvatar != null) 'sender_avatar': senderAvatar,
    'content': content,
    'type': 'text',
    'timestamp': ServerValue.timestamp,
  };
}

