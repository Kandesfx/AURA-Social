import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AURA Social – Feed Service
///
/// Person 4, Task #3
/// Service gọi FastAPI /feed/generate để lấy AI-curated feed.
/// Hiện tại sử dụng mock data (chờ backend deploy).
///
/// Khi backend ready → chỉ cần replace _mockForYouFeed() bằng HTTP call.
class FeedService {
  FeedService();

  /// Lấy For You feed (AI-curated)
  ///
  /// Gọi FastAPI: POST /feed/generate
  /// Body: { user_id, emotion_vector, context }
  /// Response: { posts: [...], feed_meta: {...} }
  Future<FeedResult> getForYouFeed({int page = 0, int limit = 20}) async {
    // TODO: Replace với real API call khi backend ready
    // final response = await _apiService.post('/feed/generate', data: {
    //   'user_id': uid,
    //   'page': page,
    //   'limit': limit,
    // });

    await Future.delayed(const Duration(milliseconds: 800)); // Simulate latency

    return FeedResult(
      posts: _mockForYouPosts,
      hasMore: page < 3, // 3 pages of mock data
      feedMeta: FeedMeta(
        emotionalMode: 'explore',
        diversityScore: 0.75,
        generatedAt: DateTime.now(),
      ),
    );
  }

  /// Lấy Following feed (chronological) từ Firestore (thực tế)
  Future<FeedResult> getFollowingFeed({required String myUid, int page = 0, int limit = 20}) async {
    if (myUid.isEmpty) {
      return FeedResult(
        posts: [],
        hasMore: false,
        feedMeta: FeedMeta(
          emotionalMode: 'following',
          diversityScore: 0.0,
          generatedAt: DateTime.now(),
        ),
      );
    }

    try {
      // 1. Lấy danh sách UID những người đang following
      final followingSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('following')
          .get();

      final followingUids = followingSnap.docs.map((d) => d.id).toList();

      if (followingUids.isEmpty) {
        return FeedResult(
          posts: [],
          hasMore: false,
          feedMeta: FeedMeta(
            emotionalMode: 'following',
            diversityScore: 0.0,
            generatedAt: DateTime.now(),
          ),
        );
      }

      // Firestore limit cho whereIn tối đa là 30
      final queryUids = followingUids.take(30).toList();

      // 2. Lấy posts của những người này
      final postsSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('user_id', whereIn: queryUids)
          .where('status', isEqualTo: 'active')
          .get();

      // 3. Sắp xếp in-memory theo created_at descending để tránh lỗi thiếu chỉ mục (index) của Firestore
      final docs = postsSnap.docs;
      docs.sort((a, b) {
        final aTime = (a.data())['created_at'] as Timestamp?;
        final bTime = (b.data())['created_at'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      // 4. Map sang định dạng map tương thích với feed_screen.dart
      final posts = docs.map((doc) {
        final data = doc.data();
        final mediaUrls = List<String>.from(data['media_urls'] ?? []);
        final hasImage = (data['media_type'] ?? 'none') == 'image' && mediaUrls.isNotEmpty;
        final createdAt = (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
        final diff = DateTime.now().difference(createdAt);
        String timeAgoText = '1h';
        if (diff.inMinutes < 60) {
          timeAgoText = '${diff.inMinutes}m';
        } else if (diff.inHours < 24) {
          timeAgoText = '${diff.inHours}h';
        } else {
          timeAgoText = '${diff.inDays}d';
        }

        return {
          'id': doc.id,
          'userId': data['user_id'] ?? '',
          'userName': data['author_name'] ?? 'User',
          'userHandle': data['author_username'] != null ? '@${data['author_username']}' : '',
          'timeAgo': timeAgoText,
          'content': data['content'] ?? '',
          'hasImage': hasImage,
          'imageUrl': hasImage ? mediaUrls.first : null,
          'emotionVector': data['ai_emotion_vector'] ?? {},
          'reactions': data['reactions_breakdown'] ?? {},
          'commentCount': data['comments_count'] ?? 0,
          'avatarUrl': data['author_avatar_url'],
        };
      }).toList();

      return FeedResult(
        posts: posts,
        hasMore: false,
        feedMeta: FeedMeta(
          emotionalMode: 'following',
          diversityScore: 0.0,
          generatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('[FeedService] Error getting following feed: $e');
      return FeedResult(
        posts: [],
        hasMore: false,
        feedMeta: FeedMeta(
          emotionalMode: 'following',
          diversityScore: 0.0,
          generatedAt: DateTime.now(),
        ),
      );
    }
  }
}

/// Provider cho FeedService
final feedServiceProvider = Provider<FeedService>((ref) {
  return FeedService();
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MODELS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class FeedResult {
  final List<Map<String, dynamic>> posts;
  final bool hasMore;
  final FeedMeta feedMeta;

  FeedResult({
    required this.posts,
    required this.hasMore,
    required this.feedMeta,
  });
}

class FeedMeta {
  final String emotionalMode;
  final double diversityScore;
  final DateTime generatedAt;

  FeedMeta({
    required this.emotionalMode,
    required this.diversityScore,
    required this.generatedAt,
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MOCK DATA
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final List<Map<String, dynamic>> _mockForYouPosts = [
  {
    'id': '1',
    'userName': 'Minh Anh',
    'userHandle': '@minhanh',
    'timeAgo': '2h',
    'content': 'Hôm nay tôi cảm thấy thật tuyệt vời khi được nhìn thấy hoàng hôn trên biển. Có ai cũng thích ngắm hoàng hôn không? 🌅',
    'hasImage': true,
    'imageUrl': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
    'emotionVector': {'joy': 0.45, 'trust': 0.2, 'anticipation': 0.15, 'surprise': 0.1, 'sadness': 0.05, 'fear': 0.02, 'anger': 0.01, 'disgust': 0.02},
    'reactions': {'joy': 24, 'trust': 8, 'anticipation': 5, 'surprise': 3, 'sadness': 0, 'fear': 0, 'anger': 0, 'disgust': 0},
    'commentCount': 12,
  },
  {
    'id': '2',
    'userName': 'Hoàng Dũng',
    'userHandle': '@hoangdung',
    'timeAgo': '4h',
    'content': 'Just shipped a new feature at work! The feeling when your code compiles without errors on the first try 🚀\n\n#coding #developer #happyday',
    'hasImage': false,
    'emotionVector': {'joy': 0.35, 'anticipation': 0.3, 'trust': 0.15, 'surprise': 0.1, 'sadness': 0.03, 'fear': 0.02, 'anger': 0.03, 'disgust': 0.02},
    'reactions': {'joy': 42, 'anticipation': 15, 'trust': 7, 'surprise': 12, 'sadness': 0, 'fear': 0, 'anger': 0, 'disgust': 0},
    'commentCount': 23,
  },
  {
    'id': '3',
    'userName': 'Thu Hà',
    'userHandle': '@thuha_dreamer',
    'timeAgo': '6h',
    'content': 'Nghe playlist lofi chill cả buổi chiều, thời tiết mát mát là lý do hoàn hảo để pha một ly cà phê nóng và đọc sách 📖☕',
    'hasImage': true,
    'imageUrl': 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600',
    'emotionVector': {'trust': 0.3, 'joy': 0.25, 'anticipation': 0.15, 'surprise': 0.05, 'sadness': 0.1, 'fear': 0.05, 'anger': 0.05, 'disgust': 0.05},
    'reactions': {'trust': 18, 'joy': 14, 'anticipation': 3, 'surprise': 1, 'sadness': 2, 'fear': 0, 'anger': 0, 'disgust': 0},
    'commentCount': 8,
  },
  {
    'id': '4',
    'userName': 'Khánh Linh',
    'userHandle': '@khanhlinh',
    'timeAgo': '8h',
    'content': 'Cuối tuần rồi mà vẫn phải làm deadline 😅 Ai đang cùng cảnh ngộ thì comment đi, mình cùng nhau cố lên! 💪',
    'hasImage': false,
    'emotionVector': {'anticipation': 0.35, 'trust': 0.2, 'joy': 0.15, 'fear': 0.1, 'sadness': 0.1, 'surprise': 0.05, 'anger': 0.03, 'disgust': 0.02},
    'reactions': {'anticipation': 31, 'trust': 12, 'joy': 8, 'sadness': 5, 'fear': 3, 'surprise': 0, 'anger': 0, 'disgust': 0},
    'commentCount': 18,
  },
  {
    'id': '5',
    'userName': 'Tuấn Kiệt',
    'userHandle': '@tuankiet',
    'timeAgo': '12h',
    'content': 'Vừa chạy được 5km sáng nay 🏃‍♂️ Cảm giác khoan khoái vô cùng! Ai muốn join running club không?',
    'hasImage': true,
    'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600',
    'emotionVector': {'joy': 0.4, 'anticipation': 0.25, 'trust': 0.15, 'surprise': 0.05, 'sadness': 0.05, 'fear': 0.05, 'anger': 0.03, 'disgust': 0.02},
    'reactions': {'joy': 56, 'anticipation': 20, 'trust': 10, 'surprise': 5, 'sadness': 0, 'fear': 0, 'anger': 0, 'disgust': 0},
    'commentCount': 15,
  },
];

