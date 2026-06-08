import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/soul_connect/models/soul_connection_model.dart';
import '../core/services/api_service.dart';
import '../providers/api_service_provider.dart';

/// AURA Social – Soul Connect Service
///
/// Person 3, Task #10
/// Service kết nối Firestore collection `soul_connections` để lấy AI-curated suggestions.
/// - getSuggestions(): Gọi FastAPI `/api/v1/soul/suggestions` và fallback Firestore.
/// - respondToConnection(): Update user_a_action / user_b_action trên Firestore
class SoulConnectService {
  final AuraApiService _apiService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SoulConnectService({
    required AuraApiService apiService,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _apiService = apiService,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Lấy danh sách suggestions từ FastAPI backend (hoặc fallback Firestore).
  Future<List<SoulSuggestion>> getSuggestions({int limit = 10}) async {
    final uid = _uid;
    if (uid == null) return []; // Chưa login

    try {
      final response = await _apiService.post('/api/v1/soul/suggestions', data: {
        'limit': limit,
      });

      final List<dynamic> list = response.data['suggestions'] ?? [];
      final suggestions = list.map((item) {
        final rawBreakdown = item['breakdown'] ?? {};
        final rawOtherUser = item['otherUser'] ?? {};

        final breakdown = CompatibilityBreakdown(
          emotionalPattern: (rawBreakdown['emotionalPattern'] as num?)?.toDouble() ?? 0.0,
          contentTaste: (rawBreakdown['contentTaste'] as num?)?.toDouble() ?? 0.0,
          complementary: (rawBreakdown['complementary'] as num?)?.toDouble() ?? 0.0,
          interests: (rawBreakdown['interests'] as num?)?.toDouble() ?? 0.0,
          activity: (rawBreakdown['activity'] as num?)?.toDouble() ?? 0.0,
        );

        final rawVector = rawOtherUser['emotionVector'] ?? {};
        final Map<String, double> emotionVector = Map<String, dynamic>.from(rawVector)
            .map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));

        final otherUser = SoulUser(
          uid: rawOtherUser['uid'] as String? ?? '',
          displayName: rawOtherUser['displayName'] as String? ?? 'User',
          avatarUrl: rawOtherUser['avatarUrl'] as String?,
          bio: rawOtherUser['bio'] as String?,
          auraDominantEmotion: rawOtherUser['auraDominantEmotion'] as String?,
          emotionVector: emotionVector,
        );

        return SoulSuggestion(
          connectionId: item['connectionId'] as String? ?? '',
          soulScore: (item['soulScore'] as num?)?.toDouble() ?? 0.0,
          connectionType: item['connectionType'] as String? ?? 'Unknown',
          breakdown: breakdown,
          otherUser: otherUser,
        );
      }).toList();

      return suggestions;
    } catch (e) {
      // ignore: avoid_print
      print('[SoulConnectService] Error getting suggestions from backend: $e');

      // Fallback: Query soul_connections where current user is a participant and status is 'suggested'
      final snapshot = await _firestore
          .collection('soul_connections')
          .where('participants', arrayContains: uid)
          .where('status', isEqualTo: 'suggested')
          .limit(limit)
          .get();

      if (snapshot.docs.isEmpty) {
        return _getClientMockSuggestions(uid);
      }

      final suggestions = <SoulSuggestion>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Xác định peer user ID
        final userAId = data['user_a_id'] as String? ?? '';
        final userBId = data['user_b_id'] as String? ?? '';
        final otherUid = userAId == uid ? userBId : userAId;

        // Kiểm tra xem current user đã action chưa (skip nếu đã reject)
        final myActionField = userAId == uid ? 'user_a_action' : 'user_b_action';
        final myAction = data[myActionField] as String?;
        if (myAction != null) continue; // Đã action rồi → skip

        if (otherUid.isEmpty) continue;

        // Lấy thông tin user đối phương
        final otherUserDoc = await _firestore.collection('users').doc(otherUid).get();
        final otherUserData = otherUserDoc.data() ?? {};

        // Parse emotion vector
        Map<String, double>? emotionVector;
        if (otherUserData['emotion_vector'] != null) {
          emotionVector = Map<String, dynamic>.from(
            otherUserData['emotion_vector'] as Map,
          ).map((k, v) => MapEntry(k, (v as num).toDouble()));
        }

        suggestions.add(SoulSuggestion(
          connectionId: doc.id,
          soulScore: (data['soul_score'] as num?)?.toDouble() ?? 0.0,
          connectionType: data['connection_type'] as String? ?? 'Unknown',
          breakdown: CompatibilityBreakdown.fromMap(
            Map<String, dynamic>.from(data['compatibility_breakdown'] as Map? ?? {}),
          ),
          otherUser: SoulUser(
            uid: otherUid,
            displayName: otherUserData['display_name'] as String? ?? 'User',
            avatarUrl: otherUserData['avatar_url'] as String?,
            bio: otherUserData['bio'] as String?,
            auraDominantEmotion: otherUserData['aura_dominant_emotion'] as String?,
            emotionVector: emotionVector,
          ),
        ));
      }

      // Sort client-side by soul_score (thay cho Firestore orderBy)
      suggestions.sort((a, b) => b.soulScore.compareTo(a.soulScore));
      return suggestions;
    }
  }

  /// Accept hoặc Reject connection.
  ///
  /// Update trực tiếp Firestore soul_connections document.
  /// - Xác định field dựa trên user_a_id == uid → user_a_action, ngược lại user_b_action
  /// - Nếu cả 2 accept → update status thành 'active'
  /// - Cloud Function sẽ handle việc create conversation khi status chuyển sang 'active'
  Future<void> respondToConnection(String connectionId, String action) async {
    final uid = _uid;
    if (uid == null) return;
    
    // Nếu là connection ảo (mock client side), chỉ cần return thành công
    if (connectionId.startsWith('soul-conn-fall-')) {
      return;
    }
    
    final docRef = _firestore.collection('soul_connections').doc(connectionId);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final isUserA = data['user_a_id'] == uid;
    final myField = isUserA ? 'user_a_action' : 'user_b_action';
    final peerField = isUserA ? 'user_b_action' : 'user_a_action';
    final peerAction = data[peerField] as String?;

    // Xác định status mới
    String newStatus;
    if (action == 'reject') {
      newStatus = 'rejected';
    } else if (action == 'accept' && peerAction == 'accept') {
      // Cả 2 đều accept → active
      newStatus = 'active';
    } else {
      // Mới 1 người accept → pending
      newStatus = 'pending';
    }

    await docRef.update({
      myField: action,
      'status': newStatus,
      'updated_at': FieldValue.serverTimestamp(),
      if (newStatus == 'active') 'connected_at': FieldValue.serverTimestamp(),
    });
  }

  List<SoulSuggestion> _getClientMockSuggestions(String currentUid) {
    final mockUsers = [
      {
        'uid': 'user_fall_1',
        'displayName': 'Linh Nguyễn',
        'bio': 'Yêu thích đọc sách và nhạc chill chill ☕✨',
        'auraDominantEmotion': 'joy',
        'emotionVector': {
          'joy': 0.45, 'trust': 0.25, 'anticipation': 0.15, 'surprise': 0.05,
          'sadness': 0.04, 'fear': 0.02, 'anger': 0.02, 'disgust': 0.02
        }
      },
      {
        'uid': 'user_fall_2',
        'displayName': 'Quang Huy',
        'bio': 'Đam mê công nghệ, chạy bộ 🏃‍♂️🚀',
        'auraDominantEmotion': 'anticipation',
        'emotionVector': {
          'anticipation': 0.40, 'joy': 0.30, 'trust': 0.15, 'surprise': 0.05,
          'sadness': 0.05, 'fear': 0.02, 'anger': 0.02, 'disgust': 0.01
        }
      },
      {
        'uid': 'user_fall_3',
        'displayName': 'Phan Đăng',
        'bio': 'Tâm trí tĩnh lặng, cuộc sống bình yên 🧘‍♂️📖',
        'auraDominantEmotion': 'trust',
        'emotionVector': {
          'trust': 0.50, 'joy': 0.20, 'anticipation': 0.10, 'surprise': 0.05,
          'sadness': 0.10, 'fear': 0.02, 'anger': 0.01, 'disgust': 0.02
        }
      }
    ];

    final prefix = currentUid.substring(0, currentUid.length > 4 ? 4 : currentUid.length);

    return List.generate(mockUsers.length, (index) {
      final u = mockUsers[index];
      final score = 0.85 - index * 0.06;
      final rawVector = Map<String, double>.from(u['emotionVector'] as Map);
      
      return SoulSuggestion(
        connectionId: 'soul-conn-fall-$prefix-${(u['uid'] as String).substring(10)}',
        soulScore: score,
        connectionType: score < 0.8 ? 'Vibe Partner' : 'Soulmate',
        breakdown: CompatibilityBreakdown(
          emotionalPattern: 0.88 - index * 0.05,
          contentTaste: 0.85 - index * 0.04,
          complementary: 0.90 - index * 0.06,
          interests: 0.75 - index * 0.02,
          activity: 0.80 - index * 0.03,
        ),
        otherUser: SoulUser(
          uid: u['uid'] as String,
          displayName: u['displayName'] as String,
          bio: u['bio'] as String,
          auraDominantEmotion: u['auraDominantEmotion'] as String,
          emotionVector: rawVector,
        ),
      );
    });
  }
}

/// Provider cho SoulConnectService
final soulConnectServiceProvider = Provider<SoulConnectService>((ref) {
  return SoulConnectService(apiService: ref.read(apiServiceProvider));
});
