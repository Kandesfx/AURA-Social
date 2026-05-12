# 🚀 AURA Social – Hướng Dẫn Bắt Đầu Cho Thành Viên

> **Cập nhật:** 20/04/2026  
> **API URL:** `https://aura-backend-736756685022.asia-southeast1.run.app`  
> **Swagger Docs:** `https://aura-backend-736756685022.asia-southeast1.run.app/docs`

---

## 1. Clone & Chạy App

```bash
# Clone repo
git clone https://github.com/Kandesfx/AURA-Social.git

# Chuyển sang nhánh dev
cd AURA-Social
git checkout dev

# Cài dependencies Flutter
cd app
flutter pub get

# Chạy app
flutter run
```

> ⚠️ Build lần đầu mất ~5 phút. Các lần sau nhanh hơn.

---

## 2. API Backend Đã Deploy

Server AI đã chạy 24/7. Flutter gọi API qua URL sau:

```
Base URL: https://aura-backend-736756685022.asia-southeast1.run.app
```

### Các API có sẵn:

| Method | Endpoint | Auth | Mô tả |
|--------|----------|------|--------|
| `GET` | `/health` | Không | Kiểm tra server sống |
| `GET` | `/docs` | Không | Swagger UI (xem tất cả API) |
| `POST` | `/api/v1/emotion/infer` | Firebase Token | Phân tích cảm xúc user |
| `POST` | `/api/v1/feed/generate` | Firebase Token | Gợi ý bài viết theo cảm xúc |
| `POST` | `/api/v1/content/analyze` | Internal Key | Phân tích nội dung bài post |
| `POST` | `/api/v1/upload/avatar` | Firebase Token | Upload ảnh đại diện |
| `POST` | `/api/v1/upload/post-image/{id}` | Firebase Token | Upload ảnh bài viết |

### Test nhanh (mở trình duyệt):
- Health: https://aura-backend-736756685022.asia-southeast1.run.app/health
- Docs: https://aura-backend-736756685022.asia-southeast1.run.app/docs

---

## 3. Cách Gọi API Từ Flutter

### Bước 1: Thêm package `dio` (đã có trong pubspec.yaml)

### Bước 2: Tạo API Service

```dart
// lib/core/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuraApiService {
  static const String baseUrl =
      'https://aura-backend-736756685022.asia-southeast1.run.app';

  late final Dio _dio;

  AuraApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Tự động gắn Firebase Token vào mỗi request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // ── Emotion ──
  Future<Map<String, dynamic>> inferEmotion({
    String? text,
    List<Map<String, dynamic>>? behavioralEvents,
  }) async {
    final response = await _dio.post('/api/v1/emotion/infer', data: {
      'text': text,
      'behavioral_events': behavioralEvents,
    });
    return response.data;
  }

  // ── Feed ──
  Future<Map<String, dynamic>> generateFeed({
    String? cursor,
    int limit = 20,
    Map<String, double>? emotionContext,
  }) async {
    final response = await _dio.post('/api/v1/feed/generate', data: {
      'cursor': cursor,
      'limit': limit,
      'emotion_context': emotionContext,
    });
    return response.data;
  }

  // ── Upload ──
  Future<String> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/api/v1/upload/avatar', data: formData);
    return response.data['url'];
  }

  Future<String> uploadPostImage(String postId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(
      '/api/v1/upload/post-image/$postId',
      data: formData,
    );
    return response.data['url'];
  }
}
```

### Bước 3: Sử dụng trong Screen

```dart
// Ví dụ: Gọi API phân tích cảm xúc
final api = AuraApiService();
final result = await api.inferEmotion(text: 'Hôm nay tôi rất vui!');
print(result);
// → {emotion_vector: {joy: 0.35, trust: 0.20, ...}, dominant_emotion: "joy", ...}
```

---

## 4. Firebase – Cách Sử Dụng Trong Flutter

### Authentication (Person 2)

```dart
import 'package:firebase_auth/firebase_auth.dart';

// Đăng ký
final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: 'test@example.com',
  password: '123456',
);
// → Cloud Function on_user_created sẽ TỰ ĐỘNG tạo user profile

// Đăng nhập
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: 'test@example.com',
  password: '123456',
);

// Lấy user hiện tại
final user = FirebaseAuth.instance.currentUser;

// Đăng xuất
await FirebaseAuth.instance.signOut();

// Lắng nghe trạng thái login
FirebaseAuth.instance.authStateChanges().listen((user) {
  if (user != null) {
    print('Đã đăng nhập: ${user.uid}');
  } else {
    print('Chưa đăng nhập');
  }
});
```

### Firestore – Đọc/Ghi Dữ Liệu (Person 2, 3, 4)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

final db = FirebaseFirestore.instance;

// ── Tạo bài viết ──
await db.collection('posts').add({
  'authorId': FirebaseAuth.instance.currentUser!.uid,
  'text': 'Bài viết đầu tiên!',
  'mediaUrls': [],
  'reactionCounts': {},
  'commentCount': 0,
  'createdAt': FieldValue.serverTimestamp(),
});
// → Cloud Function on_new_post sẽ TỰ ĐỘNG phân tích cảm xúc

// ── Đọc Feed (real-time) ──
db.collection('posts')
  .orderBy('createdAt', descending: true)
  .limit(20)
  .snapshots()
  .listen((snapshot) {
    for (var doc in snapshot.docs) {
      print('${doc.id}: ${doc.data()['text']}');
    }
  });

// ── Đọc Profile ──
final userDoc = await db.collection('users').doc(uid).get();
final userData = userDoc.data();

// ── Follow ──
await db.collection('users').doc(targetUserId)
  .collection('followers').doc(myUid).set({
    'followedAt': FieldValue.serverTimestamp(),
  });
// → Cloud Function on_follow sẽ TỰ ĐỘNG cập nhật counts + notification
```

### Realtime Database – Chat (Person 3)

```dart
import 'package:firebase_database/firebase_database.dart';

final rtdb = FirebaseDatabase.instance.ref();

// ── Gửi tin nhắn ──
await rtdb.child('messages/$conversationId').push().set({
  'senderId': myUid,
  'text': 'Xin chào!',
  'timestamp': ServerValue.timestamp,
});

// ── Nhận tin nhắn real-time ──
rtdb.child('messages/$conversationId')
  .orderByChild('timestamp')
  .limitToLast(50)
  .onChildAdded
  .listen((event) {
    final msg = event.snapshot.value as Map;
    print('${msg['senderId']}: ${msg['text']}');
  });

// ── Cập nhật presence (online/offline) ──
rtdb.child('presence/$myUid').set({
  'isOnline': true,
  'lastSeen': ServerValue.timestamp,
});

// ── Typing indicator ──
rtdb.child('typing/$conversationId/$myUid').set(true);
// Sau 3 giây:
rtdb.child('typing/$conversationId/$myUid').set(false);
```

---

## 5. Firestore Collections (Schema)

| Collection | Mô tả | Fields chính |
|---|---|---|
| `users/{uid}` | Thông tin user | `displayName`, `email`, `photoURL`, `bio`, `followersCount`, `followingCount` |
| `users/{uid}/emotion_profile/current` | Cảm xúc hiện tại (AI cập nhật) | `emotionVector` (8D), `dominantEmotion`, `emotionalMode` |
| `users/{uid}/behavioral_events/{id}` | Hành vi lướt app (Person 4 ghi) | `event_type`, `target_id`, `duration_ms`, `timestamp` |
| `posts/{postId}` | Bài viết | `authorId`, `text`, `mediaUrls`, `emotionVector`, `createdAt` |
| `comments/{commentId}` | Bình luận | `postId`, `authorId`, `text`, `createdAt` |
| `conversations/{id}` | Metadata hội thoại | `memberIds`, `lastMessage`, `lastMessageSenderId`, `updatedAt` |
| `soul_connections/{id}` | Kết nối Soul | `userId1`, `userId2`, `compatibilityScore`, `status` |
| `waves/{waveId}` | Nhóm cảm xúc tạm | `emotion`, `memberCount`, `momentum`, `createdAt` |
| `notifications/{id}` | Thông báo | `recipientId`, `senderId`, `type`, `message`, `isRead` |

---

## 6. Quy Tắc Git

```bash
# Luôn làm việc trên nhánh dev
git checkout dev

# Tạo branch cho task của mình
git checkout -b feature/P2-login-screen

# Code xong → commit → push
git add -A
git commit -m "[P2] Implement login screen with Google Sign-In"
git push origin feature/P2-login-screen

# Tạo Pull Request trên GitHub → Leader review → Merge vào dev
```

**Naming convention:**
- Branch: `feature/P2-tên-task`, `feature/P3-tên-task`, `feature/P4-tên-task`
- Commit: `[P2] Mô tả ngắn`, `[P3] Mô tả`, `[P4] Mô tả`

---

## 7. Cloud Functions Tự Động

Các function sau đã chạy trên cloud, **KHÔNG CẦN code gì thêm**:

| Sự kiện | Function tự chạy | Kết quả |
|---|---|---|
| User đăng ký | `on_user_created` | Tạo `/users/{uid}` + emotion profile mặc định |
| User đăng bài | `on_new_post` | Gọi AI → gắn `emotionVector` vào post |
| Tin nhắn mới | `on_conversation_updated` | Push notification lên điện thoại người nhận |
| Follow ai đó | `on_follow` | Tăng counts + tạo notification |

---

## 8. Checklist Bắt Đầu

### Person 2 (Auth + Feed + Post + Profile):
- [ ] Clone repo, chạy `flutter pub get`, `flutter run`
- [ ] Tạo file `lib/core/services/api_service.dart` (copy ở mục 3)
- [ ] Code màn hình Login/Register (Firebase Auth)
- [ ] Code trang Create Post (Firestore + upload ảnh qua API)
- [ ] Code Feed (đọc posts từ Firestore)

### Person 3 (Chat + Soul Connect + Waves):
- [ ] Clone repo, chạy `flutter pub get`, `flutter run`
- [ ] Code màn hình Chat (RTDB real-time)
- [ ] Code Conversations List (Firestore)
- [ ] Code Soul Connect UI (gọi API sau)

### Person 4 (Tracking + Notifications + Settings):
- [ ] Clone repo, chạy `flutter pub get`, `flutter run`
- [ ] Code Behavioral Tracker (ghi events vào Firestore)
- [ ] Code Notifications Screen (đọc từ Firestore)
- [ ] Code Settings screens

---

## 9. Liên Hệ & Hỗ Trợ

- **Gặp lỗi Firebase:** Chạy `flutter clean` rồi `flutter pub get`
- **Gặp lỗi build Android:** Xóa `.gradle` → rebuild
- **API trả lỗi 401:** Kiểm tra đã đăng nhập Firebase chưa
- **Cần API mới hoặc thay đổi schema:** Báo Leader

**Leader sẽ:**
- Review tất cả Pull Requests
- Cập nhật AI model (thay mock data bằng AI thật)
- Hỗ trợ debug khi cần
