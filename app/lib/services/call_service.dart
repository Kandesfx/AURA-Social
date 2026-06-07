import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/chat/models/call_model.dart';
import '../features/chat/providers/chat_provider.dart';

class CallService {
  CallService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Tạo cuộc gọi mới
  Future<CallModel> makeCall({
    required String callerId,
    required String callerName,
    String? callerAvatar,
    required String receiverId,
    required String receiverName,
    String? receiverAvatar,
    required CallType type,
  }) async {
    final docRef = _firestore.collection('calls').doc();
    final call = CallModel(
      id: docRef.id,
      callerId: callerId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverAvatar: receiverAvatar,
      status: CallStatus.ringing,
      type: type,
      createdAt: DateTime.now(),
    );

    await docRef.set(call.toFirestore());
    return call;
  }

  /// Chấp nhận cuộc gọi
  Future<void> acceptCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': CallStatus.connected.value,
      'connected_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Từ chối cuộc gọi
  Future<void> declineCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': CallStatus.declined.value,
    });
  }

  /// Kết thúc cuộc gọi
  Future<void> endCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': CallStatus.ended.value,
    });
  }

  /// Stream thông tin chi tiết 1 cuộc gọi
  Stream<CallModel?> streamCall(String callId) {
    return _firestore.collection('calls').doc(callId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CallModel.fromFirestore(doc);
    });
  }

  /// Stream các cuộc gọi đến hiện tại của user (status == ringing)
  Stream<List<CallModel>> streamIncomingCalls(String userId) {
    return _firestore
        .collection('calls')
        .where('receiver_id', isEqualTo: userId)
        .where('status', isEqualTo: CallStatus.ringing.value)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CallModel.fromFirestore(doc)).toList();
    });
  }
}

/// Provider toàn cục cho CallService
final callServiceProvider = Provider<CallService>((ref) {
  return CallService();
});

/// StreamProvider lắng nghe cuộc gọi đến của user
final incomingCallStreamProvider = StreamProvider<List<CallModel>>((ref) {
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId.isEmpty) return Stream.value([]);
  
  final callService = ref.watch(callServiceProvider);
  return callService.streamIncomingCalls(currentUserId);
});
