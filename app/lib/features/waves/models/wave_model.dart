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
}

/// Message trong Wave chat
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
}
