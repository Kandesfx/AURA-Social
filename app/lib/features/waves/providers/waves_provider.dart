import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wave_model.dart';

/// AURA Social – Waves Provider
///
/// Person 3, Task #15
/// Quản lý state cho Emotional Waves.
/// Kết nối Firestore (waves, members) + RTDB (wave_messages).

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Active waves list – stream từ Firestore collection `waves`
/// Query: status != 'archived', order by momentum desc
final activeWavesProvider =
    StreamProvider.autoDispose<List<WaveModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('waves')
      .where('status', whereIn: ['forming', 'active', 'fading'])
      .orderBy('momentum', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => WaveModel.fromFirestore(doc))
        .toList();
  });
});

/// Messages cho 1 wave cụ thể – stream từ RTDB `wave_messages/{waveId}`
final waveMessagesProvider = StreamProvider.family
    .autoDispose<List<WaveMessage>, String>((ref, waveId) {
  final dbRef = FirebaseDatabase.instance
      .ref('wave_messages/$waveId')
      .orderByChild('timestamp')
      .limitToLast(200);

  return dbRef.onValue.map((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return <WaveMessage>[];

    final messages = data.entries.map((entry) {
      final msgData = Map<String, dynamic>.from(entry.value as Map);
      return WaveMessage.fromRtdb(entry.key as String, msgData);
    }).toList();

    // Sort ascending (oldest → newest)
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  });
});

/// Members cho 1 wave – stream từ Firestore subcollection `waves/{waveId}/members`
final waveMembersProvider =
    StreamProvider.family.autoDispose<List<WaveMember>, String>(
        (ref, waveId) {
  return FirebaseFirestore.instance
      .collection('waves')
      .doc(waveId)
      .collection('members')
      .where('status', isEqualTo: 'active')
      .orderBy('joined_at', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => WaveMember.fromFirestore(doc))
        .toList();
  });
});

/// Joined waves (user đã tham gia) – track local + sync Firestore
final joinedWaveIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Total online across waves
final totalWaveUsersProvider = Provider<int>((ref) {
  final wavesAsync = ref.watch(activeWavesProvider);
  return wavesAsync.whenOrNull<int>(
        data: (waves) => waves.fold<int>(0, (sum, w) => sum + w.memberCount),
      ) ??
      0;
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// WAVE ACTIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Provider for wave actions (join, leave, send message)
final waveActionsProvider = Provider<WaveActions>((ref) {
  return WaveActions();
});

class WaveActions {
  final _firestore = FirebaseFirestore.instance;
  final _database = FirebaseDatabase.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// Gửi message vào wave chat (RTDB)
  Future<void> sendMessage({
    required String waveId,
    required String content,
    required String senderName,
    String? senderAvatar,
  }) async {
    final ref = _database.ref('wave_messages/$waveId').push();
    await ref.set({
      'sender_id': _uid,
      'sender_name': senderName,
      if (senderAvatar != null) 'sender_avatar': senderAvatar,
      'content': content,
      'type': 'text',
      'timestamp': ServerValue.timestamp,
    });

    // Update message count trên Firestore wave doc
    await _firestore.collection('waves').doc(waveId).update({
      'message_count': FieldValue.increment(1),
    });

    // Update member message count
    await _firestore
        .collection('waves')
        .doc(waveId)
        .collection('members')
        .doc(_uid)
        .update({
      'message_count': FieldValue.increment(1),
      'last_active_at': FieldValue.serverTimestamp(),
    });
  }

  /// Join wave – tạo member document trong subcollection
  Future<void> joinWave(String waveId) async {
    final user = _auth.currentUser!;

    // Lấy thông tin user từ Firestore
    final userDoc = await _firestore.collection('users').doc(_uid).get();
    final userData = userDoc.data() ?? {};

    // Parse emotion vector
    Map<String, double>? emotionVector;
    if (userData['emotion_vector'] != null) {
      emotionVector = Map<String, dynamic>.from(
        userData['emotion_vector'] as Map,
      ).map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    final member = WaveMember(
      uid: _uid,
      displayName: userData['display_name'] as String? ??
          user.displayName ??
          'User',
      avatarUrl: userData['avatar_url'] as String?,
      auraDominantEmotion: userData['aura_dominant_emotion'] as String?,
      emotionVector: emotionVector,
      joinedAt: DateTime.now(),
    );

    // Tạo member document
    await _firestore
        .collection('waves')
        .doc(waveId)
        .collection('members')
        .doc(_uid)
        .set(member.toFirestore());

    // Increment member count
    await _firestore.collection('waves').doc(waveId).update({
      'member_count': FieldValue.increment(1),
    });
  }

  /// Leave wave – update member status
  Future<void> leaveWave(String waveId) async {
    await _firestore
        .collection('waves')
        .doc(waveId)
        .collection('members')
        .doc(_uid)
        .update({
      'status': 'left',
      'last_active_at': FieldValue.serverTimestamp(),
    });

    // Decrement member count
    await _firestore.collection('waves').doc(waveId).update({
      'member_count': FieldValue.increment(-1),
    });
  }
}
