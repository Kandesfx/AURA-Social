import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/user_model.dart';

/// Stream user profile từ Firestore cho 1 user cụ thể.
///
/// Lắng nghe realtime changes trên document `users/{uid}`.
/// Khi Firestore data thay đổi (vd: followers_count tăng), UI tự cập nhật.
///
/// ### Cách dùng:
/// ```dart
/// final userAsync = ref.watch(userProfileProvider(someUid));
/// userAsync.when(
///   data: (user) => Text(user.displayName),
///   loading: () => CircularProgressIndicator(),
///   error: (e, s) => Text('Error: $e'),
/// );
/// ```
final userProfileProvider =
    StreamProvider.family<UserModel, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => UserModel.fromFirestore(doc));
});

/// Shortcut: Stream profile của user đang login.
///
/// Tự động lấy UID từ Firebase Auth.
/// Trả về `null` nếu chưa đăng nhập.
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  });
});

/// Stream danh sách followers / following của một user.
/// [type] phải là 'followers' hoặc 'following'
final followListProvider = StreamProvider.family<List<String>, ({String uid, String type})>((ref, arg) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(arg.uid)
      .collection(arg.type)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
});

/// Provider để cập nhật user profile.
///
/// Cung cấp methods để update Firestore document.
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

/// Service cập nhật user profile trên Firestore.
///
/// ### Methods:
/// - [updateProfile] – Update basic info (displayName, bio, etc.)
/// - [updateAvatar] – Update avatar URL
/// - [toggleFollow] – Follow/unfollow user khác
class UserProfileService {
  final _firestore = FirebaseFirestore.instance;

  /// Cập nhật basic profile info.
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? username,
    String? bio,
    List<String>? interests,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (displayName != null) updates['display_name'] = displayName;
    if (username != null) updates['username'] = username;
    if (bio != null) updates['bio'] = bio;
    if (interests != null) updates['interests'] = interests;

    await _firestore.collection('users').doc(uid).update(updates);
  }

  /// Cập nhật avatar URL.
  Future<void> updateAvatar(String uid, String avatarUrl) async {
    await _firestore.collection('users').doc(uid).update({
      'avatar_url': avatarUrl,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Follow/Unfollow một user.
  ///
  /// Tạo/xóa document trong subcollection `following` và update counts.
  /// [myUid] follow [targetUid].
  Future<bool> toggleFollow(String myUid, String targetUid) async {
    final followRef = _firestore
        .collection('users')
        .doc(myUid)
        .collection('following')
        .doc(targetUid);

    final followerRef = _firestore
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(myUid);

    final doc = await followRef.get();
    final isFollowing = doc.exists;

    final batch = _firestore.batch();

    if (isFollowing) {
      // Unfollow
      batch.delete(followRef);
      batch.delete(followerRef);
      batch.update(_firestore.collection('users').doc(myUid), {
        'following_count': FieldValue.increment(-1),
      });
      batch.update(_firestore.collection('users').doc(targetUid), {
        'followers_count': FieldValue.increment(-1),
      });
    } else {
      // Follow
      batch.set(followRef, {
        'followed_at': FieldValue.serverTimestamp(),
      });
      batch.set(followerRef, {
        'followed_at': FieldValue.serverTimestamp(),
      });
      batch.update(_firestore.collection('users').doc(myUid), {
        'following_count': FieldValue.increment(1),
      });
      batch.update(_firestore.collection('users').doc(targetUid), {
        'followers_count': FieldValue.increment(1),
      });
    }

    await batch.commit();
    return !isFollowing; // Return new state: true = now following
  }

  /// Kiểm tra đã follow user chưa.
  Future<bool> isFollowing(String myUid, String targetUid) async {
    final doc = await _firestore
        .collection('users')
        .doc(myUid)
        .collection('following')
        .doc(targetUid)
        .get();
    return doc.exists;
  }
}
