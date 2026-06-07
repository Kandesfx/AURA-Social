import 'package:cloud_firestore/cloud_firestore.dart';

/// AURA Social – User Model
///
/// Model đại diện cho document trong Firestore collection `users`.
/// Chứa thông tin cá nhân, social stats, emotion state, và AI settings.
///
/// ### Firestore path: `/users/{userId}`
///
/// ### Cách dùng:
/// ```dart
/// final user = UserModel.fromFirestore(snapshot);
/// final map = user.toFirestore();
/// ```
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final List<String> interests;

  // Social stats
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int connectionsCount;

  // Emotion state (summary – chi tiết trong emotion_profile subcollection)
  final String auraDominantEmotion;
  final double auraValence;
  final double auraConfidence;
  final String emotionalMode;

  // AI settings
  final Map<String, dynamic> aiSettings;

  // Status
  final bool isOnline;
  final DateTime? lastActiveAt;
  final String accountStatus;

  // System
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? privacyConsentAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.interests = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.connectionsCount = 0,
    this.auraDominantEmotion = 'explore',
    this.auraValence = 0.0,
    this.auraConfidence = 0.0,
    this.emotionalMode = 'explore',
    this.aiSettings = const {},
    this.isOnline = false,
    this.lastActiveAt,
    this.accountStatus = 'active',
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
    this.privacyConsentAt,
  });

  /// Tạo UserModel từ Firestore DocumentSnapshot.
  ///
  /// Parse tất cả fields, sử dụng giá trị mặc định nếu field thiếu.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['display_name'] ?? '',
      username: data['username'] ?? '',
      avatarUrl: data['avatar_url'],
      bio: data['bio'],
      interests: List<String>.from(data['interests'] ?? []),
      followersCount: data['followers_count'] ?? 0,
      followingCount: data['following_count'] ?? 0,
      postsCount: data['posts_count'] ?? 0,
      connectionsCount: data['connections_count'] ?? 0,
      auraDominantEmotion: data['aura_dominant_emotion'] ?? 'explore',
      auraValence: (data['aura_valence'] ?? 0.0).toDouble(),
      auraConfidence: (data['aura_confidence'] ?? 0.0).toDouble(),
      emotionalMode: data['emotional_mode'] ?? 'explore',
      aiSettings: Map<String, dynamic>.from(data['ai_settings'] ?? {}),
      isOnline: data['is_online'] ?? false,
      lastActiveAt: (data['last_active_at'] as Timestamp?)?.toDate(),
      accountStatus: data['account_status'] ?? 'active',
      fcmToken: data['fcm_token'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      privacyConsentAt: (data['privacy_consent_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Chuyển đổi thành Map để ghi vào Firestore.
  ///
  /// Dùng khi tạo mới hoặc cập nhật user document.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'username': username,
      'avatar_url': avatarUrl,
      'bio': bio,
      'interests': interests,
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
      'connections_count': connectionsCount,
      'aura_dominant_emotion': auraDominantEmotion,
      'aura_valence': auraValence,
      'aura_confidence': auraConfidence,
      'emotional_mode': emotionalMode,
      'ai_settings': aiSettings,
      'is_online': isOnline,
      'last_active_at': lastActiveAt != null
          ? Timestamp.fromDate(lastActiveAt!)
          : FieldValue.serverTimestamp(),
      'account_status': accountStatus,
      'fcm_token': fcmToken,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'privacy_consent_at': privacyConsentAt != null
          ? Timestamp.fromDate(privacyConsentAt!)
          : null,
    };
  }

  /// Tạo bản sao với một số field thay đổi.
  UserModel copyWith({
    String? displayName,
    String? username,
    String? avatarUrl,
    String? bio,
    List<String>? interests,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    String? auraDominantEmotion,
    double? auraValence,
    double? auraConfidence,
    String? emotionalMode,
    Map<String, dynamic>? aiSettings,
    bool? isOnline,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      connectionsCount: connectionsCount,
      auraDominantEmotion: auraDominantEmotion ?? this.auraDominantEmotion,
      auraValence: auraValence ?? this.auraValence,
      auraConfidence: auraConfidence ?? this.auraConfidence,
      emotionalMode: emotionalMode ?? this.emotionalMode,
      aiSettings: aiSettings ?? this.aiSettings,
      isOnline: isOnline ?? this.isOnline,
      lastActiveAt: lastActiveAt,
      accountStatus: accountStatus,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: updatedAt,
      privacyConsentAt: privacyConsentAt,
    );
  }

  /// Default AI settings khi tạo user mới
  static Map<String, dynamic> defaultAiSettings() {
    return {
      'emotion_inference_enabled': true,
      'behavioral_tracking_enabled': true,
      'mood_expression_enabled': true,
      'wellbeing_guard_enabled': true,
      'soul_connect_enabled': true,
      'aura_ring_visible': true,
      'fer_enabled': false,
      'keystroke_enabled': false,
    };
  }
}
