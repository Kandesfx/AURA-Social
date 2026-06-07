import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/emotion_profile_model.dart';

/// Stream emotion profile cho 1 user cụ thể.
///
/// Lắng nghe subcollection `users/{uid}/emotion_profile/current`.
/// Data được cập nhật bởi FastAPI backend → Firestore.
///
/// ### Cách dùng:
/// ```dart
/// final emotionAsync = ref.watch(emotionProfileProvider(uid));
/// emotionAsync.when(
///   data: (profile) => AuraRing(emotionVector: profile.currentEmotionVector),
///   loading: () => CircularProgressIndicator(),
///   error: (e, s) => Text('Error'),
/// );
/// ```
final emotionProfileProvider =
    StreamProvider.family<EmotionProfileModel, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('emotion_profile')
      .doc('current')
      .snapshots()
      .map((doc) {
    if (!doc.exists) {
      return const EmotionProfileModel(); // Return default nếu chưa có
    }
    return EmotionProfileModel.fromFirestore(doc);
  });
});

/// Shortcut: Emotion profile của user đang login.
final currentEmotionProfileProvider =
    StreamProvider<EmotionProfileModel>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(const EmotionProfileModel());
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('emotion_profile')
      .doc('current')
      .snapshots()
      .map((doc) {
    if (!doc.exists) return const EmotionProfileModel();
    return EmotionProfileModel.fromFirestore(doc);
  });
});
