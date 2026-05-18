import 'package:cloud_firestore/cloud_firestore.dart';

/// AURA Social – Post Model
///
/// Model đại diện cho document trong Firestore collection `posts`.
/// Chứa nội dung post, AI analysis, engagement metrics, và moderation status.
///
/// ### Firestore path: `/posts/{postId}`
class PostModel {
  final String postId;
  final String userId;

  // Content
  final String content;
  final List<String> mediaUrls;
  final String mediaType; // "none" | "image" | "video" | "audio"

  // AI Analysis (auto-populated bởi Cloud Function → FastAPI)
  final Map<String, double> aiEmotionVector;
  final double aiValence;
  final String? aiSentiment;
  final double aiSentimentScore;
  final double qualityScore;

  // User Expression
  final String? moodExpression;

  // Engagement Metrics
  final int reactionsCount;
  final Map<String, int> reactionsBreakdown;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;
  final int viewsCount;

  // Moderation
  final bool isToxic;
  final bool crisisDetected;
  final String status; // "active" | "hidden" | "removed"

  // Meta
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Denormalized author info (để hiển thị nhanh, không cần query users)
  final String? authorName;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final String? authorDominantEmotion;

  const PostModel({
    required this.postId,
    required this.userId,
    required this.content,
    this.mediaUrls = const [],
    this.mediaType = 'none',
    this.aiEmotionVector = const {},
    this.aiValence = 0.0,
    this.aiSentiment,
    this.aiSentimentScore = 0.0,
    this.qualityScore = 0.0,
    this.moodExpression,
    this.reactionsCount = 0,
    this.reactionsBreakdown = const {},
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.savesCount = 0,
    this.viewsCount = 0,
    this.isToxic = false,
    this.crisisDetected = false,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
    this.authorName,
    this.authorUsername,
    this.authorAvatarUrl,
    this.authorDominantEmotion,
  });

  /// Tạo PostModel từ Firestore DocumentSnapshot.
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PostModel(
      postId: doc.id,
      userId: data['user_id'] ?? '',
      content: data['content'] ?? '',
      mediaUrls: List<String>.from(data['media_urls'] ?? []),
      mediaType: data['media_type'] ?? 'none',
      aiEmotionVector: _parseEmotionVector(data['ai_emotion_vector']),
      aiValence: (data['ai_valence'] ?? 0.0).toDouble(),
      aiSentiment: data['ai_sentiment'],
      aiSentimentScore: (data['ai_sentiment_score'] ?? 0.0).toDouble(),
      qualityScore: (data['quality_score'] ?? 0.0).toDouble(),
      moodExpression: data['mood_expression'],
      reactionsCount: data['reactions_count'] ?? 0,
      reactionsBreakdown: _parseReactionsBreakdown(data['reactions_breakdown']),
      commentsCount: data['comments_count'] ?? 0,
      sharesCount: data['shares_count'] ?? 0,
      savesCount: data['saves_count'] ?? 0,
      viewsCount: data['views_count'] ?? 0,
      isToxic: data['is_toxic'] ?? false,
      crisisDetected: data['crisis_detected'] ?? false,
      status: data['status'] ?? 'active',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      authorName: data['author_name'],
      authorUsername: data['author_username'],
      authorAvatarUrl: data['author_avatar_url'],
      authorDominantEmotion: data['author_dominant_emotion'],
    );
  }

  /// Tạo PostModel từ mock Map data (FeedService mock).
  factory PostModel.fromMockMap(Map<String, dynamic> data) {
    final emotionVector = data['emotionVector'] as Map<String, dynamic>? ?? {};
    final reactions = data['reactions'] as Map<String, dynamic>? ?? {};
    return PostModel(
      postId: data['id'] ?? '',
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      mediaUrls: data['hasImage'] == true && data['imageUrl'] != null
          ? [data['imageUrl'] as String]
          : [],
      mediaType: data['hasImage'] == true ? 'image' : 'none',
      aiEmotionVector: emotionVector.map((k, v) => MapEntry(k, (v as num).toDouble())),
      reactionsBreakdown: reactions.map((k, v) => MapEntry(k, (v as num).toInt())),
      reactionsCount: reactions.values.fold<int>(0, (sum, v) => sum + (v as num).toInt()),
      commentsCount: data['commentCount'] ?? 0,
      createdAt: DateTime.now().subtract(Duration(hours: int.tryParse(data['timeAgo']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '1') ?? 1)),
      authorName: data['userName'],
      authorUsername: data['userHandle']?.replaceAll('@', ''),
      authorAvatarUrl: data['avatarUrl'],
      authorDominantEmotion: _findDominantFromMap(emotionVector),
    );
  }

  static String _findDominantFromMap(Map<String, dynamic> vec) {
    if (vec.isEmpty) return 'explore';
    final sorted = vec.entries.toList()..sort((a, b) => (b.value as num).compareTo(a.value as num));
    return sorted.first.key;
  }

  /// Chuyển thành Map để ghi vào Firestore khi tạo post mới.
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'content': content,
      'media_urls': mediaUrls,
      'media_type': mediaType,
      'mood_expression': moodExpression,
      'reactions_count': 0,
      'reactions_breakdown': {
        'joy': 0, 'trust': 0, 'anticipation': 0, 'surprise': 0,
        'sadness': 0, 'fear': 0, 'anger': 0, 'disgust': 0,
      },
      'comments_count': 0,
      'shares_count': 0,
      'saves_count': 0,
      'views_count': 0,
      'is_toxic': false,
      'crisis_detected': false,
      'status': 'active',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      // Denormalized author info
      'author_name': authorName,
      'author_username': authorUsername,
      'author_avatar_url': authorAvatarUrl,
      'author_dominant_emotion': authorDominantEmotion,
    };
  }

  /// Parse emotion vector từ Firestore (handle dynamic types)
  static Map<String, double> _parseEmotionVector(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }
    return {};
  }

  /// Parse reactions breakdown
  static Map<String, int> _parseReactionsBreakdown(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return {};
  }

  /// Kiểm tra post có media (ảnh/video) hay không
  bool get hasMedia => mediaUrls.isNotEmpty && mediaType != 'none';

  /// Tổng số tương tác (reactions + comments + shares)
  int get totalEngagement => reactionsCount + commentsCount + sharesCount;

  /// Lấy emotion dominant (cao nhất) từ AI vector
  String get dominantEmotion {
    if (aiEmotionVector.isEmpty) return 'explore';
    final sorted = aiEmotionVector.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  PostModel copyWith({
    String? content,
    List<String>? mediaUrls,
    String? mediaType,
    String? moodExpression,
    int? reactionsCount,
    Map<String, int>? reactionsBreakdown,
    int? commentsCount,
    String? authorName,
    String? authorUsername,
    String? authorAvatarUrl,
    String? authorDominantEmotion,
  }) {
    return PostModel(
      postId: postId,
      userId: userId,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      aiEmotionVector: aiEmotionVector,
      aiValence: aiValence,
      aiSentiment: aiSentiment,
      aiSentimentScore: aiSentimentScore,
      qualityScore: qualityScore,
      moodExpression: moodExpression ?? this.moodExpression,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      reactionsBreakdown: reactionsBreakdown ?? this.reactionsBreakdown,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount,
      savesCount: savesCount,
      viewsCount: viewsCount,
      isToxic: isToxic,
      crisisDetected: crisisDetected,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorDominantEmotion: authorDominantEmotion ?? this.authorDominantEmotion,
    );
  }
}

/// Model cho comment trong subcollection `posts/{postId}/comments`
class CommentModel {
  final String commentId;
  final String userId;
  final String content;
  final String? aiSentiment;
  final double aiSentimentScore;
  final int reactionsCount;
  final DateTime? createdAt;

  // Denormalized
  final String? authorName;
  final String? authorAvatarUrl;

  const CommentModel({
    required this.commentId,
    required this.userId,
    required this.content,
    this.aiSentiment,
    this.aiSentimentScore = 0.0,
    this.reactionsCount = 0,
    this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommentModel(
      commentId: doc.id,
      userId: data['user_id'] ?? '',
      content: data['content'] ?? '',
      aiSentiment: data['ai_sentiment'],
      aiSentimentScore: (data['ai_sentiment_score'] ?? 0.0).toDouble(),
      reactionsCount: data['reactions_count'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      authorName: data['author_name'],
      authorAvatarUrl: data['author_avatar_url'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'content': content,
      'reactions_count': 0,
      'created_at': FieldValue.serverTimestamp(),
      'author_name': authorName,
      'author_avatar_url': authorAvatarUrl,
    };
  }
}
