import 'package:cloud_firestore/cloud_firestore.dart';

enum CallStatus {
  ringing,
  connected,
  ended,
  declined;

  String get value => name;

  static CallStatus fromValue(String val) {
    return CallStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => CallStatus.ended,
    );
  }
}

enum CallType {
  audio,
  video;

  String get value => name;

  static CallType fromValue(String val) {
    return CallType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => CallType.audio,
    );
  }
}

class CallModel {
  CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    required this.status,
    required this.type,
    required this.createdAt,
    this.connectedAt,
  });

  final String id;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final CallStatus status;
  final CallType type;
  final DateTime createdAt;
  final DateTime? connectedAt;

  CallModel copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? callerAvatar,
    String? receiverId,
    String? receiverName,
    String? receiverAvatar,
    CallStatus? status,
    CallType? type,
    DateTime? createdAt,
    DateTime? connectedAt,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverAvatar: receiverAvatar ?? this.receiverAvatar,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'caller_id': callerId,
      'caller_name': callerName,
      'caller_avatar': callerAvatar,
      'receiver_id': receiverId,
      'receiver_name': receiverName,
      'receiver_avatar': receiverAvatar,
      'status': status.value,
      'type': type.value,
      'created_at': Timestamp.fromDate(createdAt),
      'connected_at': connectedAt != null ? Timestamp.fromDate(connectedAt!) : null,
    };
  }

  factory CallModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallModel(
      id: doc.id,
      callerId: data['caller_id'] as String? ?? '',
      callerName: data['caller_name'] as String? ?? '',
      callerAvatar: data['caller_avatar'] as String?,
      receiverId: data['receiver_id'] as String? ?? '',
      receiverName: data['receiver_name'] as String? ?? '',
      receiverAvatar: data['receiver_avatar'] as String?,
      status: CallStatus.fromValue(data['status'] as String? ?? 'ended'),
      type: CallType.fromValue(data['type'] as String? ?? 'audio'),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      connectedAt: (data['connected_at'] as Timestamp?)?.toDate(),
    );
  }
}
