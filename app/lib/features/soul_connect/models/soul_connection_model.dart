// AURA Social – Soul Connection Model
//
// Dữ liệu gợi ý kết nối từ API `/api/v1/soul/suggestions`.
// Schema: /soul_connections/{connectionId}

/// Chi tiết tương thích 5 chiều
class CompatibilityBreakdown {
  final double emotionalPattern;
  final double contentTaste;
  final double complementary;
  final double interests;
  final double activity;

  const CompatibilityBreakdown({
    this.emotionalPattern = 0.0,
    this.contentTaste = 0.0,
    this.complementary = 0.0,
    this.interests = 0.0,
    this.activity = 0.0,
  });

  factory CompatibilityBreakdown.fromMap(Map<String, dynamic> map) {
    return CompatibilityBreakdown(
      emotionalPattern: (map['emotional_pattern'] as num?)?.toDouble() ?? 0.0,
      contentTaste: (map['content_taste'] as num?)?.toDouble() ?? 0.0,
      complementary: (map['complementary'] as num?)?.toDouble() ?? 0.0,
      interests: (map['interests'] as num?)?.toDouble() ?? 0.0,
      activity: (map['activity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'emotional_pattern': emotionalPattern,
        'content_taste': contentTaste,
        'complementary': complementary,
        'interests': interests,
        'activity': activity,
      };
}

/// Thông tin user đối phương (denormalized)
class SoulUser {
  final String uid;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final String? auraDominantEmotion;
  final Map<String, double>? emotionVector;

  const SoulUser({
    required this.uid,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.auraDominantEmotion,
    this.emotionVector,
  });

  factory SoulUser.fromMap(Map<String, dynamic> map) {
    final rawEmotionVector = map['emotion_vector'];
    final emotionVector = rawEmotionVector is Map
        ? Map<String, dynamic>.from(rawEmotionVector)
        : null;
    return SoulUser(
      uid: map['uid'] as String? ?? '',
      displayName: map['display_name'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      auraDominantEmotion: map['aura_dominant_emotion'] as String?,
      emotionVector: emotionVector?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }
}

/// Một gợi ý kết nối Soul
class SoulSuggestion {
  final String connectionId;
  final double soulScore;
  final String connectionType;
  final CompatibilityBreakdown breakdown;
  final SoulUser otherUser;

  const SoulSuggestion({
    required this.connectionId,
    required this.soulScore,
    required this.connectionType,
    required this.breakdown,
    required this.otherUser,
  });

  factory SoulSuggestion.fromMap(Map<String, dynamic> map) {
    final rawBreakdown = map['breakdown'];
    final rawOtherUser = map['other_user'];
    return SoulSuggestion(
      connectionId: map['connection_id'] as String? ?? '',
      soulScore: (map['soul_score'] as num?)?.toDouble() ?? 0.0,
      connectionType: map['connection_type'] as String? ?? 'Unknown',
      breakdown: CompatibilityBreakdown.fromMap(
        rawBreakdown is Map ? Map<String, dynamic>.from(rawBreakdown) : {},
      ),
      otherUser: SoulUser.fromMap(
        rawOtherUser is Map ? Map<String, dynamic>.from(rawOtherUser) : {},
      ),
    );
  }
}
