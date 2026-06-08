import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../shared/models/user_model.dart';
import '../shared/models/emotion_profile_model.dart';

/// Stream trạng thái đăng nhập Firebase Auth.
///
/// Emit `User` khi đã login, `null` khi chưa login.
/// Dùng trong router để redirect auth guard.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider quản lý auth actions (login, register, logout).
///
/// Sử dụng StateNotifier để track loading/error states.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Trạng thái Auth
class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});

  AuthState copyWith({bool? isLoading, String? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Auth Notifier – xử lý tất cả auth actions
///
/// ### Các method chính:
/// - [signInWithEmail] – Đăng nhập bằng email + password
/// - [registerWithEmail] – Đăng ký tài khoản mới + tạo Firestore document
/// - [signOut] – Đăng xuất
/// - [resetPassword] – Gửi email reset password
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Đăng nhập bằng Email + Password.
  ///
  /// Returns `true` nếu thành công, `false` nếu thất bại.
  /// Error message được lưu trong [AuthState.error].
  Future<bool> signInWithEmail(String email, String password) async {
    state = const AuthState(isLoading: true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthState(error: _mapAuthError(e.code));
      return false;
    } catch (e) {
      state = AuthState(error: 'Đã xảy ra lỗi: ${e.toString()}');
      return false;
    }
  }

  /// Đăng ký tài khoản mới.
  ///
  /// Tạo Firebase Auth user → tạo Firestore user document với default settings.
  /// [displayName] và [username] được ghi vào Firestore document.
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      // 1. Tạo Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        state = const AuthState(error: 'Không thể tạo tài khoản');
        return false;
      }

      // 2. Update display name trong Firebase Auth
      await user.updateDisplayName(displayName);

      // 3. Tạo Firestore user document
      final userModel = UserModel(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName,
        username: username.trim(),
        aiSettings: UserModel.defaultAiSettings(),
        privacyConsentAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toFirestore());

      // 4. Tạo emotion profile mặc định (subcollection)
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emotion_profile')
          .doc('current')
          .set({
        'current_emotion_vector': EmotionProfileModel.defaultVector,
        'valence': 0.0,
        'arousal': 0.0,
        'dominance': 0.5,
        'emotion_confidence': 0.0,
        'emotion_source': 'inferred',
        'emotional_mode': 'explore',
        'signals_used': [],
        'behavior_signals': {},
        'weekly_pattern': {},
        'weekly_trend': {},
        'updated_at': FieldValue.serverTimestamp(),
        'total_inferences': 0,
      });

      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthState(error: _mapAuthError(e.code));
      return false;
    } catch (e) {
      state = AuthState(error: 'Đã xảy ra lỗi: ${e.toString()}');
      return false;
    }
  }

  /// Đăng xuất.
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut(); // Đảm bảo Google session cũng bị xóa
      await _auth.signOut();
    } catch (e) {
      debugPrint('[Auth] Sign out error: $e');
    }
  }

  /// Đăng nhập / Đăng ký bằng Google.
  ///
  /// Nếu là user mới → tự động tạo Firestore document.
  /// Nếu đã có tài khoản → đăng nhập bình thường.
  Future<bool> signInWithGoogle() async {
    state = const AuthState(isLoading: true);
    try {
      // 1. Hiện Google Account Picker
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User bấm Cancel
        state = const AuthState();
        return false;
      }

      // 2. Lấy Google Auth credentials
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Đăng nhập Firebase
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        state = const AuthState(error: 'Không thể đăng nhập với Google');
        return false;
      }

      // 4. Kiểm tra user mới hay cũ
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        // User mới → tạo Firestore document
        final rawUsername = (user.displayName ?? user.email ?? 'user')
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '_');

        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'AURA User',
          username: rawUsername,
          avatarUrl: user.photoURL,
          aiSettings: UserModel.defaultAiSettings(),
          privacyConsentAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(user.uid).set(userModel.toFirestore());

        // Tạo emotion profile mặc định
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('emotion_profile')
            .doc('current')
            .set({
          'current_emotion_vector': EmotionProfileModel.defaultVector,
          'valence': 0.0,
          'arousal': 0.0,
          'dominance': 0.5,
          'emotion_confidence': 0.0,
          'emotion_source': 'inferred',
          'emotional_mode': 'explore',
          'signals_used': [],
          'behavior_signals': {},
          'weekly_pattern': {},
          'weekly_trend': {},
          'updated_at': FieldValue.serverTimestamp(),
          'total_inferences': 0,
        });
      }

      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthState(error: _mapAuthError(e.code));
      return false;
    } catch (e) {
      state = AuthState(error: 'Lỗi Google Sign-In: ${e.toString()}');
      return false;
    }
  }

  /// Gửi email reset password.
  Future<bool> resetPassword(String email) async {
    state = const AuthState(isLoading: true);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthState(error: _mapAuthError(e.code));
      return false;
    }
  }

  /// Xóa tài khoản vĩnh viễn (GDPR Cascade Delete)
  Future<bool> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      state = const AuthState(error: 'Không tìm thấy người dùng hiện tại');
      return false;
    }
    final uid = user.uid;
    state = const AuthState(isLoading: true);
    try {
      // 1. Xóa tất cả posts của user
      debugPrint('[DeleteAccount] Bước 1: Bắt đầu xóa tất cả posts của user');
      final postsQuery = await _firestore
          .collection('posts')
          .where('user_id', isEqualTo: uid)
          .get();
      for (final doc in postsQuery.docs) {
        debugPrint('[DeleteAccount] Xóa post: ${doc.id}');
        await doc.reference.delete();
      }

      // 2. Xóa các bình luận (comments) của user và cập nhật comments_count bài viết cha
      debugPrint('[DeleteAccount] Bước 2: Bắt đầu xóa các comments của user');
      final commentsQuery = await _firestore
          .collectionGroup('comments')
          .where('user_id', isEqualTo: uid)
          .get();
      for (final doc in commentsQuery.docs) {
        debugPrint('[DeleteAccount] Xóa comment: ${doc.id}');
        await doc.reference.delete();
        final postRef = doc.reference.parent.parent;
        if (postRef != null) {
          debugPrint('[DeleteAccount] Cập nhật comments_count của post: ${postRef.id}');
          await postRef.update({
            'comments_count': FieldValue.increment(-1),
          });
        }
      }

      // 3. Giảm follow & xóa liên kết follow (following)
      debugPrint('[DeleteAccount] Bước 3: Bắt đầu xóa liên kết following');
      final followingQuery = await _firestore
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();
      for (final doc in followingQuery.docs) {
        final targetUid = doc.id;
        debugPrint('[DeleteAccount] Xóa following: $targetUid');
        await doc.reference.delete();
        debugPrint('[DeleteAccount] Xóa follower của target $targetUid');
        await _firestore
            .collection('users')
            .doc(targetUid)
            .collection('followers')
            .doc(uid)
            .delete();
        debugPrint('[DeleteAccount] Cập nhật followers_count của target $targetUid');
        await _firestore.collection('users').doc(targetUid).update({
          'followers_count': FieldValue.increment(-1),
        });
      }

      // 4. Giảm follow & xóa liên kết follow (followers)
      debugPrint('[DeleteAccount] Bước 4: Bắt đầu xóa liên kết followers');
      final followersQuery = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followers')
          .get();
      for (final doc in followersQuery.docs) {
        final sourceUid = doc.id;
        debugPrint('[DeleteAccount] Xóa follower: $sourceUid');
        await doc.reference.delete();
        debugPrint('[DeleteAccount] Xóa following của source $sourceUid');
        await _firestore
            .collection('users')
            .doc(sourceUid)
            .collection('following')
            .doc(uid)
            .delete();
        debugPrint('[DeleteAccount] Cập nhật following_count của source $sourceUid');
        await _firestore.collection('users').doc(sourceUid).update({
          'following_count': FieldValue.increment(-1),
        });
      }

      // 5. Xóa subcollection emotion_profile
      debugPrint('[DeleteAccount] Bước 5: Bắt đầu xóa emotion_profile');
      final emotionProfileQuery = await _firestore
          .collection('users')
          .doc(uid)
          .collection('emotion_profile')
          .get();
      for (final doc in emotionProfileQuery.docs) {
        debugPrint('[DeleteAccount] Xóa emotion profile doc: ${doc.id}');
        await doc.reference.delete();
      }

      // 6. Xóa subcollection behavioral_events
      debugPrint('[DeleteAccount] Bước 6: Bắt đầu xóa behavioral_events');
      final behavioralEventsQuery = await _firestore
          .collection('users')
          .doc(uid)
          .collection('behavioral_events')
          .get();
      for (final doc in behavioralEventsQuery.docs) {
        debugPrint('[DeleteAccount] Xóa behavioral event doc: ${doc.id}');
        await doc.reference.delete();
      }

      // 7. Xóa tư cách thành viên Wave
      debugPrint('[DeleteAccount] Bước 7: Bắt đầu xóa tư cách thành viên Wave');
      final waveMembersQuery = await _firestore
          .collectionGroup('members')
          .where('uid', isEqualTo: uid)
          .get();
      for (final doc in waveMembersQuery.docs) {
        debugPrint('[DeleteAccount] Xóa thành viên wave: ${doc.id}');
        await doc.reference.delete();
        final waveRef = doc.reference.parent.parent;
        if (waveRef != null) {
          debugPrint('[DeleteAccount] Cập nhật member_count của wave: ${waveRef.id}');
          await waveRef.update({
            'member_count': FieldValue.increment(-1),
          });
        }
      }

      // 8. Dọn dẹp Realtime Database
      debugPrint('[DeleteAccount] Bước 8: Bắt đầu dọn dẹp Realtime Database');
      // - Xóa trạng thái online (presence)
      await FirebaseDatabase.instance.ref('presence/$uid').remove();

      // - Dọn dẹp trạng thái đang gõ chữ (typing) trong tất cả conversations
      final conversationsQuery = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .get();
      for (final doc in conversationsQuery.docs) {
        final convId = doc.id;
        debugPrint('[DeleteAccount] Xóa typing status trong conv: $convId');
        await FirebaseDatabase.instance.ref('typing/$convId/$uid').remove();
      }

      // 9. Xóa user document chính trên Firestore
      debugPrint('[DeleteAccount] Bước 9: Bắt đầu xóa user document chính');
      await _firestore.collection('users').doc(uid).delete();

      // 10. Đăng xuất Google Sign-In session
      debugPrint('[DeleteAccount] Bước 10: Sign out Google');
      await GoogleSignIn().signOut();

      // 11. Xóa tài khoản Firebase Auth
      debugPrint('[DeleteAccount] Bước 11: Xóa Firebase Auth user');
      await user.delete();

      debugPrint('[DeleteAccount] Hoàn tất xóa tài khoản thành công!');
      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[DeleteAccount] Lỗi FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'requires-recent-login') {
        state = const AuthState(
          error: 'Hành động này yêu cầu bạn đăng nhập lại gần đây để xác minh.',
        );
      } else {
        state = AuthState(error: _mapAuthError(e.code));
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('[DeleteAccount] Lỗi không xác định: $e');
      debugPrint('[DeleteAccount] StackTrace: $stackTrace');
      state = AuthState(error: 'Lỗi khi xóa tài khoản: ${e.toString()}');
      return false;
    }
  }

  /// Xóa error message.
  void clearError() {
    state = const AuthState();
  }

  /// Map Firebase error code → message tiếng Việt
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được bật trên Firebase';
      default:
        return 'Đã xảy ra lỗi ($code)';
    }
  }
}


