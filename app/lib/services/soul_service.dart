import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/soul_connect/models/soul_connection_model.dart';

/// AURA Social – Soul Connect Service
///
/// Person 3, Task #10
/// Service gọi FastAPI /api/v1/soul/suggestions để lấy AI-curated suggestions.
/// Hiện tại sử dụng mock data (chờ backend deploy).
///
/// Khi backend ready → chỉ cần replace mock bằng HTTP call.
class SoulConnectService {
  SoulConnectService();

  /// Lấy danh sách suggestions
  ///
  /// API: POST /api/v1/soul/suggestions
  /// Body: { limit: 10 }
  /// Response: { suggestions: [...] }
  Future<List<SoulSuggestion>> getSuggestions({int limit = 10}) async {
    // TODO: Replace với real API call khi backend ready
    // final response = await _api.dio.post('/api/v1/soul/suggestions', data: {
    //   'limit': limit,
    // });
    // return (response.data['suggestions'] as List)
    //     .map((s) => SoulSuggestion.fromMap(s))
    //     .toList();

    await Future.delayed(const Duration(milliseconds: 1000)); // Simulate latency
    return _mockSuggestions;
  }

  /// Accept hoặc Reject connection
  ///
  /// Update trực tiếp Firestore soul_connections document.
  /// Cloud Function sẽ handle việc create conversation khi cả hai accept.
  Future<void> respondToConnection(String connectionId, String action) async {
    // TODO: Replace với Firestore call khi ready
    // final uid = FirebaseAuth.instance.currentUser!.uid;
    // final doc = await FirebaseFirestore.instance
    //     .collection('soul_connections').doc(connectionId).get();
    // final data = doc.data()!;
    // final field = data['user_a_id'] == uid ? 'user_a_action' : 'user_b_action';
    // await doc.reference.update({
    //   field: action,
    //   'updated_at': FieldValue.serverTimestamp(),
    // });

    await Future.delayed(const Duration(milliseconds: 500));
  }
}

/// Provider cho SoulConnectService
final soulConnectServiceProvider = Provider<SoulConnectService>((ref) {
  return SoulConnectService();
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MOCK DATA
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final _mockSuggestions = [
  SoulSuggestion(
    connectionId: 'soul-conn-1',
    soulScore: 0.87,
    connectionType: 'Kindred Spirit',
    breakdown: const CompatibilityBreakdown(
      emotionalPattern: 0.92,
      contentTaste: 0.85,
      complementary: 0.90,
      interests: 0.78,
      activity: 0.80,
    ),
    otherUser: const SoulUser(
      uid: 'user-minh-anh',
      displayName: 'Trần Minh Anh',
      bio: 'Just vibing through life ✨',
      auraDominantEmotion: 'joy',
      emotionVector: {
        'joy': 0.40, 'trust': 0.25, 'anticipation': 0.15,
        'surprise': 0.10, 'sadness': 0.05, 'fear': 0.02,
        'anger': 0.01, 'disgust': 0.02,
      },
    ),
  ),
  SoulSuggestion(
    connectionId: 'soul-conn-2',
    soulScore: 0.82,
    connectionType: 'Creative Ally',
    breakdown: const CompatibilityBreakdown(
      emotionalPattern: 0.80,
      contentTaste: 0.90,
      complementary: 0.75,
      interests: 0.85,
      activity: 0.78,
    ),
    otherUser: const SoulUser(
      uid: 'user-hoang-dung',
      displayName: 'Hoàng Dũng',
      bio: 'Code & coffee ☕💻',
      auraDominantEmotion: 'anticipation',
      emotionVector: {
        'anticipation': 0.35, 'joy': 0.30, 'trust': 0.15,
        'surprise': 0.10, 'sadness': 0.03, 'fear': 0.02,
        'anger': 0.03, 'disgust': 0.02,
      },
    ),
  ),
  SoulSuggestion(
    connectionId: 'soul-conn-3',
    soulScore: 0.79,
    connectionType: 'Emotional Mirror',
    breakdown: const CompatibilityBreakdown(
      emotionalPattern: 0.88,
      contentTaste: 0.72,
      complementary: 0.82,
      interests: 0.70,
      activity: 0.75,
    ),
    otherUser: const SoulUser(
      uid: 'user-thu-ha',
      displayName: 'Thu Hà',
      bio: 'Dreamer • Book lover 📚',
      auraDominantEmotion: 'trust',
      emotionVector: {
        'trust': 0.30, 'joy': 0.25, 'sadness': 0.15,
        'anticipation': 0.10, 'surprise': 0.08, 'fear': 0.05,
        'anger': 0.04, 'disgust': 0.03,
      },
    ),
  ),
  SoulSuggestion(
    connectionId: 'soul-conn-4',
    soulScore: 0.75,
    connectionType: 'Vibe Partner',
    breakdown: const CompatibilityBreakdown(
      emotionalPattern: 0.78,
      contentTaste: 0.68,
      complementary: 0.80,
      interests: 0.72,
      activity: 0.82,
    ),
    otherUser: const SoulUser(
      uid: 'user-khanh-linh',
      displayName: 'Khánh Linh',
      bio: 'Sunset chaser 🌅 Music lover 🎶',
      auraDominantEmotion: 'surprise',
      emotionVector: {
        'surprise': 0.30, 'joy': 0.25, 'anticipation': 0.20,
        'trust': 0.10, 'sadness': 0.05, 'fear': 0.04,
        'anger': 0.03, 'disgust': 0.03,
      },
    ),
  ),
  SoulSuggestion(
    connectionId: 'soul-conn-5',
    soulScore: 0.71,
    connectionType: 'Growth Buddy',
    breakdown: const CompatibilityBreakdown(
      emotionalPattern: 0.70,
      contentTaste: 0.75,
      complementary: 0.72,
      interests: 0.68,
      activity: 0.70,
    ),
    otherUser: const SoulUser(
      uid: 'user-tuan-kiet',
      displayName: 'Tuấn Kiệt',
      bio: 'Runner 🏃 Early bird 🌄',
      auraDominantEmotion: 'anticipation',
      emotionVector: {
        'anticipation': 0.30, 'joy': 0.28, 'trust': 0.18,
        'surprise': 0.08, 'sadness': 0.06, 'fear': 0.04,
        'anger': 0.03, 'disgust': 0.03,
      },
    ),
  ),
];
