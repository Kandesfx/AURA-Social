import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wave_model.dart';

/// AURA Social – Waves Provider
///
/// Person 3, Task #15
/// Quản lý state cho Emotional Waves.
/// Mock data – khi backend sẵn sàng swap sang Firestore stream.

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MOCK DATA
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final _mockWaves = [
  WaveModel(
    id: 'wave-1',
    title: 'Đêm Không Ngủ',
    emoji: '🌊',
    description: 'Dành cho những ai đang thức khuya và cần ai đó trò chuyện',
    dominantEmotion: 'sadness',
    status: WaveStatus.active,
    momentum: 0.85,
    memberCount: 32,
    maxMembers: 50,
    messageCount: 245,
    emotionClusterCenter: {
      'sadness': 0.30, 'trust': 0.30, 'joy': 0.05,
      'anticipation': 0.10, 'surprise': 0.05, 'fear': 0.10,
      'anger': 0.05, 'disgust': 0.05,
    },
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    estimatedEndAt: DateTime.now().add(const Duration(hours: 2, minutes: 15)),
  ),
  WaveModel(
    id: 'wave-2',
    title: 'Deadline Warriors',
    emoji: '🔥',
    description: 'Cùng nhau chiến deadline! Động viên nhau không bỏ cuộc 💪',
    dominantEmotion: 'anticipation',
    status: WaveStatus.active,
    momentum: 0.95,
    memberCount: 45,
    maxMembers: 50,
    messageCount: 389,
    emotionClusterCenter: {
      'anticipation': 0.35, 'trust': 0.20, 'fear': 0.15,
      'joy': 0.10, 'sadness': 0.08, 'anger': 0.05,
      'surprise': 0.04, 'disgust': 0.03,
    },
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    estimatedEndAt: DateTime.now().add(const Duration(hours: 4)),
  ),
  WaveModel(
    id: 'wave-3',
    title: 'Friday Vibes',
    emoji: '🌈',
    description: 'Cuối tuần rồi! Chia sẻ niềm vui và kế hoạch thú vị 🎉',
    dominantEmotion: 'joy',
    status: WaveStatus.active,
    momentum: 0.60,
    memberCount: 28,
    maxMembers: 50,
    messageCount: 156,
    emotionClusterCenter: {
      'joy': 0.40, 'anticipation': 0.25, 'trust': 0.15,
      'surprise': 0.10, 'sadness': 0.03, 'fear': 0.02,
      'anger': 0.03, 'disgust': 0.02,
    },
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    estimatedEndAt: DateTime.now().add(const Duration(hours: 6)),
  ),
  WaveModel(
    id: 'wave-4',
    title: 'Monday Motivation',
    emoji: '💪',
    description: 'Bắt đầu tuần mới với năng lượng tích cực!',
    dominantEmotion: 'anticipation',
    status: WaveStatus.fading,
    momentum: 0.30,
    memberCount: 12,
    maxMembers: 50,
    messageCount: 78,
    emotionClusterCenter: {
      'anticipation': 0.30, 'joy': 0.25, 'trust': 0.20,
      'surprise': 0.08, 'sadness': 0.07, 'fear': 0.05,
      'anger': 0.03, 'disgust': 0.02,
    },
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    estimatedEndAt: DateTime.now().add(const Duration(minutes: 30)),
  ),
];

final _mockWaveMessages = <String, List<WaveMessage>>{
  'wave-1': [
    WaveMessage(
      id: 'wm-1', senderId: 'user-1', senderName: 'Minh Anh',
      content: 'Ai cũng đang thức khuya à? 🌙',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    WaveMessage(
      id: 'wm-2', senderId: 'user-2', senderName: 'Hoàng Dũng',
      content: 'Deadline nên thức thôi bạn ơi 😅',
      timestamp: DateTime.now().subtract(const Duration(minutes: 28)),
    ),
    WaveMessage(
      id: 'wm-3', senderId: 'user-3', senderName: 'Thu Hà',
      content: 'Mình đang nghe nhạc chill, ai muốn playlist không?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    WaveMessage(
      id: 'wm-4', senderId: 'user-1', senderName: 'Minh Anh',
      content: 'Share đi share đi! 🎵',
      timestamp: DateTime.now().subtract(const Duration(minutes: 23)),
    ),
    WaveMessage(
      id: 'wm-5', senderId: 'user-4', senderName: 'Khánh Linh',
      content: 'Mình vừa pha xong ly cà phê thứ 3... help 😂',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    WaveMessage(
      id: 'wm-6', senderId: 'user-5', senderName: 'Tuấn Kiệt',
      content: 'Cố lên mọi người! Sáng mai ngủ bù 💪',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ],
};

final _mockMembers = <String, List<WaveMember>>{
  'wave-1': [
    WaveMember(uid: 'user-1', displayName: 'Minh Anh', auraDominantEmotion: 'joy',
      joinedAt: DateTime.now().subtract(const Duration(hours: 2)), messageCount: 8,
      emotionVector: {'joy': 0.4, 'trust': 0.25, 'anticipation': 0.15, 'surprise': 0.1, 'sadness': 0.05, 'fear': 0.02, 'anger': 0.01, 'disgust': 0.02}),
    WaveMember(uid: 'user-2', displayName: 'Hoàng Dũng', auraDominantEmotion: 'anticipation',
      joinedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)), messageCount: 5,
      emotionVector: {'anticipation': 0.35, 'joy': 0.3, 'trust': 0.15, 'surprise': 0.1, 'sadness': 0.03, 'fear': 0.02, 'anger': 0.03, 'disgust': 0.02}),
    WaveMember(uid: 'user-3', displayName: 'Thu Hà', auraDominantEmotion: 'trust',
      joinedAt: DateTime.now().subtract(const Duration(hours: 1)), messageCount: 3,
      emotionVector: {'trust': 0.3, 'joy': 0.25, 'sadness': 0.15, 'anticipation': 0.1, 'surprise': 0.08, 'fear': 0.05, 'anger': 0.04, 'disgust': 0.03}),
    WaveMember(uid: 'user-4', displayName: 'Khánh Linh', auraDominantEmotion: 'surprise',
      joinedAt: DateTime.now().subtract(const Duration(minutes: 45)), messageCount: 2,
      emotionVector: {'surprise': 0.3, 'joy': 0.25, 'anticipation': 0.2, 'trust': 0.1, 'sadness': 0.05, 'fear': 0.04, 'anger': 0.03, 'disgust': 0.03}),
  ],
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Active waves list
final activeWavesProvider =
    FutureProvider.autoDispose<List<WaveModel>>((ref) async {
  // TODO: Replace với Firestore stream khi ready
  await Future.delayed(const Duration(milliseconds: 800));
  return _mockWaves.where((w) => w.status != WaveStatus.archived).toList();
});

/// Messages cho 1 wave cụ thể
final waveMessagesProvider = StateNotifierProvider.family<
    WaveMessagesNotifier, List<WaveMessage>, String>(
  (ref, waveId) => WaveMessagesNotifier(waveId),
);

class WaveMessagesNotifier extends StateNotifier<List<WaveMessage>> {
  WaveMessagesNotifier(this.waveId) : super(_mockWaveMessages[waveId] ?? []);
  final String waveId;

  void sendMessage(String content, String senderName) {
    final newMsg = WaveMessage(
      id: 'wm-${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'current-user-id',
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
    );
    state = [...state, newMsg];
  }
}

/// Members cho 1 wave
final waveMembersProvider =
    FutureProvider.family.autoDispose<List<WaveMember>, String>(
        (ref, waveId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return _mockMembers[waveId] ?? [];
});

/// Joined waves (user đã tham gia)
final joinedWaveIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Total online across waves
final totalWaveUsersProvider = Provider<int>((ref) {
  final wavesAsync = ref.watch(activeWavesProvider);
  return wavesAsync.whenOrNull<int>(
        data: (waves) => waves.fold<int>(0, (sum, w) => sum + w.memberCount),
      ) ??
      0;
});
