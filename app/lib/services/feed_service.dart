import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../providers/api_service_provider.dart';

/// AURA Social – Feed Service
///
/// Person 4, Task #3
/// Service gọi FastAPI /feed/generate để lấy AI-curated feed.
///
/// Khi backend ready → chỉ cần replace _mockForYouFeed() bằng HTTP call.
class FeedService {
  final AuraApiService _apiService;

  FeedService(this._apiService);

  /// Lấy For You feed (AI-curated)
  ///
  /// Gọi FastAPI: POST /feed/generate
  /// Body: { cursor, limit }
  /// Response: FeedResponse (items, next_cursor, emotional_reason)
  Future<FeedResult> getForYouFeed({int page = 0, int limit = 20}) async {
    try {
      final cursor = (page * limit).toString();
      final response = await _apiService.post('/api/v1/feed/generate', data: {
        'cursor': cursor,
        'limit': limit,
      });

      final data = response.data;
      final List<dynamic> items = data['items'] ?? [];

      // Nếu backend trả về empty list → fallback Firestore
      if (items.isEmpty && page == 0) {
        debugPrint('[FeedService] Backend returned 0 items, falling back to Firestore...');
        return _getForYouFeedFromFirestore(page: page, limit: limit);
      }

      final posts = items.map((item) {
        final postData = Map<String, dynamic>.from(item['post_data'] ?? {});
        final reason = item['reason'] as String? ?? '';

        postData['relevance_reason'] = reason;

        final mediaUrls = List<String>.from(postData['media_urls'] ?? []);
        final hasImage = (postData['media_type'] ?? 'none') == 'image' && mediaUrls.isNotEmpty;

        DateTime createdAt = DateTime.now();
        if (postData['created_at'] != null) {
          try {
            createdAt = DateTime.parse(postData['created_at'].toString());
          } catch (_) {}
        }
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
          'id': postData['post_id'] ?? postData['id'] ?? '',
          'userId': postData['user_id'] ?? '',
          'userName': postData['author_name'] ?? 'User',
          'userHandle': postData['author_username'] != null ? '@${postData['author_username']}' : '',
          'timeAgo': timeAgoText,
          'content': postData['content'] ?? '',
          'hasImage': hasImage,
          'imageUrl': hasImage ? mediaUrls.first : null,
          'emotionVector': postData['ai_emotion_vector'] ?? {},
          'reactions': postData['reactions_breakdown'] ?? {},
          'commentCount': postData['comments_count'] ?? 0,
          'avatarUrl': postData['author_avatar_url'],
          'is_breaker': postData['is_breaker'] ?? false,
          'breaker_type': postData['breaker_type'],
          'relevance_reason': reason,
        };
      }).toList();

      final hasMore = data['next_cursor'] != null;
      final emotionalReason = data['emotional_reason'] as String? ?? 'explore';

      return FeedResult(
        posts: posts,
        hasMore: hasMore,
        feedMeta: FeedMeta(
          emotionalMode: emotionalReason,
          diversityScore: 0.75,
          generatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('[FeedService] Backend không kết nối được: $e');
      debugPrint('[FeedService] Đang fallback sang Firestore trực tiếp...');
      // Khi backend offline → lấy thẳng từ Firestore
      return _getForYouFeedFromFirestore(page: page, limit: limit);
    }
  }

  /// Fallback: Lấy For You feed thẳng từ Firestore khi backend không kết nối được.
  /// Query tất cả posts (không lọc status) và sắp xếp theo created_at.
  Future<FeedResult> _getForYouFeedFromFirestore({int page = 0, int limit = 20}) async {
    try {
      // Lấy tất cả posts, không lọc status để hiển thị được nhiều nhất
      // (Backend mới lọc status == active, ở đây ta lấy cả 2 trạng thái)
      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      debugPrint('[FeedService] Firestore fallback: got ${snap.docs.length} posts');

      final posts = snap.docs.map((doc) {
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
          'is_breaker': false,
          'relevance_reason': 'Bài đăng mới nhất',
        };
      }).toList();

      return FeedResult(
        posts: posts,
        hasMore: snap.docs.length == limit,
        feedMeta: FeedMeta(
          emotionalMode: 'explore',
          diversityScore: 0.5,
          generatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('[FeedService] Firestore fallback cũng lỗi: $e');
      return FeedResult(
        posts: [],
        hasMore: false,
        feedMeta: FeedMeta(
          emotionalMode: 'explore',
          diversityScore: 0.0,
          generatedAt: DateTime.now(),
        ),
      );
    }
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
  return FeedService(ref.read(apiServiceProvider));
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



