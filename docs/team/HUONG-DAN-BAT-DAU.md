# 🚀 AURA Social – Hướng Dẫn Bắt Đầu Cho Thành Viên

> **Cập nhật:** 18/05/2026  
> **Nhánh chính:** `main` (đã merge tất cả)  
> **Firebase Project:** `aura-social-vn`  
> **API URL:** `https://aura-backend-736756685022.asia-southeast1.run.app`

---

## ⚡ CẬP NHẬT QUAN TRỌNG (18/05/2026)

> **Đây là thay đổi lớn – tất cả thành viên cần đọc trước khi pull code!**

### Những gì đã thay đổi:
1. ✅ **Tất cả nhánh đã được merge vào `main`** – không còn làm việc trên nhánh riêng nữa
2. ✅ **Google Sign-In đã được tích hợp** – cần cấu hình thêm trên Firebase Console (xem mục 0)
3. ✅ **Sửa toàn bộ lỗi biên dịch** – app có thể build và chạy bình thường
4. ✅ **Auth flow đã sửa** – Đăng nhập / Đăng ký hoạt động đúng

### Lệnh cập nhật code mới nhất:
```bash
cd AURA-Social
git checkout main
git pull origin main
cd app
flutter pub get
flutter run
```

---

## 0. Cấu Hình Bắt Buộc Trước Khi Test (Firebase Console)

> Bỏ qua bước này → **đăng nhập/đăng ký sẽ KHÔNG hoạt động**

### Bước 0.1 – Bật Email/Password Provider
1. Vào [Firebase Console](https://console.firebase.google.com) → project **`aura-social-vn`**
2. **Authentication** → **Sign-in method**
3. Bật **Email/Password** → Save

### Bước 0.2 – Bật Google Sign-In
1. Cùng trang **Sign-in method**
2. Bật **Google** → chọn Support email → Save

### Bước 0.3 – Thêm SHA-1 fingerprint của máy bạn (BẮT BUỘC cho Google Sign-In Android)

Chạy lệnh sau để lấy SHA-1 của máy bạn:

```powershell
# Windows – dùng keytool từ Android Studio
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" `
  -list -v `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -alias androiddebugkey `
  -storepass android `
  -keypass android
```

```bash
# macOS / Linux
~/.jenv/shims/keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android
```

Sau đó:
1. Firebase Console → **⚙️ Project Settings** → tab **General**
2. Cuộn xuống **"Your apps"** → chọn Android app
3. Click **"Add fingerprint"** → dán SHA-1 của máy bạn vào → Save

> 💡 Mỗi thành viên có debug keystore riêng → mỗi người cần thêm SHA-1 của **máy mình**.

---

## 1. Clone & Chạy App (Lần Đầu)

```bash
# Clone repo
git clone https://github.com/Kandesfx/AURA-Social.git
cd AURA-Social

# Checkout nhánh main (nhánh duy nhất cần dùng)
git checkout main

# Cài dependencies Flutter
cd app
flutter pub get

# Chạy app
flutter run
```

> ⚠️ Build lần đầu mất ~5-10 phút. Các lần sau nhanh hơn.

---

## 2. Quy Trình Làm Việc (Workflow)

> **Quan trọng:** Tất cả đã merge vào `main`. Từ nay làm việc trực tiếp trên `main` hoặc tạo nhánh feature riêng.

### Cách cập nhật code mới nhất:
```bash
git checkout main
git pull origin main
cd app
flutter pub get  # Chạy khi có package mới
```

### Khi cần thêm tính năng mới:
```bash
# Tạo nhánh từ main
git checkout -b feature/ten-tinh-nang

# Code xong → commit → push
git add -A
git commit -m "[P2/P3/P4] Mô tả thay đổi"
git push origin feature/ten-tinh-nang

# Tạo Pull Request trên GitHub → Leader review → Merge vào main
```

---

## 3. Kiến Trúc App Hiện Tại

```
lib/
├── main.dart                    # Entry point (Firebase init)
├── app.dart                     # MaterialApp + Theme
├── firebase_options.dart        # Firebase config
├── core/
│   ├── router/app_router.dart   # GoRouter + Auth guard
│   └── theme/                   # Colors, Typography
├── features/
│   ├── auth/screens/            # Login, Register, Onboarding
│   ├── feed/                    # Feed screens + PostCard
│   ├── post/                    # Create post, Post detail
│   ├── profile/                 # My profile, User profile, Edit
│   ├── chat/                    # Conversations, Chat screen
│   ├── soul_connect/            # Soul connect + Swipe card
│   ├── waves/                   # Waves list + Wave chat
│   ├── compass/                 # Emotional compass
│   ├── wellbeing/               # Wellbeing screen
│   ├── search/                  # Search screen
│   ├── notifications/           # Notifications
│   └── settings/                # Settings, AI settings, Privacy
├── providers/
│   ├── auth_state_provider.dart # Auth (Email + Google)
│   ├── user_profile_provider.dart
│   └── emotion_profile_provider.dart
├── services/
│   ├── feed_service.dart        # Mock feed data (AI sau)
│   ├── soul_service.dart        # Mock soul data (AI sau)
│   └── behavioral_tracker.dart  # Ghi events → Firestore
└── shared/
    ├── widgets/
    │   ├── aura_ring_widget.dart  # Avatar + Emotion ring
    │   └── main_scaffold.dart     # Bottom navigation
    └── models/
        ├── user_model.dart
        └── emotion_profile_model.dart
```

---

## 4. Authentication – Cách Hoạt Động

App dùng **Firebase Auth + Riverpod + GoRouter** với auth guard tự động.

### Đăng nhập bằng Email:
```dart
// Trong bất kỳ ConsumerWidget nào
final ok = await ref.read(authNotifierProvider.notifier)
    .signInWithEmail(email, password);
// Router tự redirect về /feed khi thành công
```

### Đăng ký bằng Email:
```dart
await ref.read(authNotifierProvider.notifier).registerWithEmail(
  email: email,
  password: password,
  displayName: 'Tên hiển thị',
  username: 'username',
);
// Tự động tạo Firestore document + emotion profile
```

### Đăng nhập / Đăng ký bằng Google:
```dart
await ref.read(authNotifierProvider.notifier).signInWithGoogle();
// Nếu user mới → tự động tạo Firestore document
// Router tự redirect về /feed
```

### Đăng xuất:
```dart
await ref.read(authNotifierProvider.notifier).signOut();
// Router tự redirect về /login
```

---

## 5. Firestore – Cách Đọc/Ghi Dữ Liệu

### Đọc profile user hiện tại (real-time):
```dart
// Trong ConsumerWidget
final userAsync = ref.watch(currentUserProfileProvider);
userAsync.when(
  data: (user) => Text(user?.displayName ?? ''),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Lỗi: $e'),
);
```

### Tạo bài viết:
```dart
await FirebaseFirestore.instance.collection('posts').add({
  'user_id': FirebaseAuth.instance.currentUser!.uid,
  'content': 'Nội dung bài viết',
  'media_urls': [],
  'media_type': 'none',
  'reactions_count': 0,
  'reactions_breakdown': {},
  'comments_count': 0,
  'status': 'active',
  'created_at': FieldValue.serverTimestamp(),
  // Denormalized author info
  'author_name': 'Tên User',
  'author_username': 'username',
  'author_avatar_url': null,
});
```

### Đọc feed (real-time):
```dart
FirebaseFirestore.instance
    .collection('posts')
    .where('status', isEqualTo: 'active')
    .orderBy('created_at', descending: true)
    .limit(20)
    .snapshots()
    .listen((snap) {
  final posts = snap.docs.map((d) => PostModel.fromFirestore(d)).toList();
});
```

---

## 6. Chat – Realtime Database

```dart
import 'package:firebase_database/firebase_database.dart';

final rtdb = FirebaseDatabase.instance.ref();

// Gửi tin nhắn
await rtdb.child('messages/$conversationId').push().set({
  'sender_id': FirebaseAuth.instance.currentUser!.uid,
  'text': 'Xin chào!',
  'timestamp': ServerValue.timestamp,
  'read': false,
});

// Nhận tin nhắn real-time
rtdb.child('messages/$conversationId')
  .orderByChild('timestamp')
  .limitToLast(50)
  .onChildAdded
  .listen((event) {
    final msg = event.snapshot.value as Map;
    print('${msg['sender_id']}: ${msg['text']}');
  });
```

---

## 7. Services – Mock Data (AI chưa sẵn sàng)

> Hiện tại các service sau đang dùng **mock data** thay vì gọi FastAPI.  
> Khi backend AI hoàn thiện, Leader sẽ cập nhật để gọi API thật.

| Service | File | Trạng thái |
|---|---|---|
| `FeedService` | `lib/services/feed_service.dart` | 🟡 Mock data |
| `SoulConnectService` | `lib/services/soul_service.dart` | 🟡 Mock data |
| `WellbeingService` | `lib/services/wellbeing_service.dart` | 🟡 Mock data |
| `BehavioralTracker` | `lib/services/behavioral_tracker.dart` | ✅ Ghi Firestore thật |

**Bạn KHÔNG cần sửa các service này** – chúng sẽ tự hoạt động với mock data cho đến khi AI sẵn sàng.

---

## 8. Xử Lý Lỗi Thường Gặp

### Lỗi build / compile:
```bash
flutter clean
flutter pub get
flutter run
```

### Lỗi "operation-not-allowed" khi đăng nhập:
→ Chưa bật Email/Password hoặc Google Sign-In trên Firebase Console (xem mục 0)

### Lỗi Google Sign-In "PlatformException sign_in_failed":
→ Chưa thêm SHA-1 fingerprint vào Firebase Console (xem mục 0.3)

### Lỗi "permission-denied" từ Firestore:
→ Firestore Security Rules chưa cấu hình. Báo Leader.

### Lỗi "CERTIFICATE_VERIFY_FAILED" (iOS):
→ Chạy: `cd ios && pod install && cd ..`

### Lỗi Gradle Android:
```bash
cd android
./gradlew clean  # macOS/Linux
gradlew.bat clean  # Windows
cd ..
flutter run
```

---

## 9. Firestore Schema (Collections)

| Collection | Mô tả | Fields chính |
|---|---|---|
| `users/{uid}` | Thông tin user | `display_name`, `email`, `username`, `avatar_url`, `bio`, `followers_count`, `following_count`, `posts_count` |
| `users/{uid}/emotion_profile/current` | Cảm xúc AI | `current_emotion_vector` (8D), `valence`, `arousal`, `emotional_mode` |
| `users/{uid}/following/{targetUid}` | Danh sách đang follow | `followed_at` |
| `posts/{postId}` | Bài viết | `user_id`, `content`, `media_urls`, `reactions_breakdown`, `comments_count`, `status` |
| `posts/{postId}/comments/{id}` | Bình luận | `user_id`, `content`, `created_at` |
| `conversations/{id}` | Hội thoại | `member_ids`, `last_message`, `updated_at` |
| `soul_connections/{id}` | Kết nối Soul | `user_id_1`, `user_id_2`, `compatibility_score`, `status` |
| `waves/{waveId}` | Nhóm cảm xúc | `emotion`, `member_count`, `momentum` |
| `notifications/{id}` | Thông báo | `recipient_id`, `sender_id`, `type`, `is_read` |

---

## 10. Liên Hệ & Hỗ Trợ

- **Gặp lỗi không tự sửa được:** Tạo issue trên GitHub hoặc liên hệ Leader
- **Muốn thêm package mới:** Hỏi Leader trước (tránh conflict)
- **API Backend:** Xem Swagger tại `https://aura-backend-736756685022.asia-southeast1.run.app/docs`
- **Tiến độ dự án:** Xem file `docs/team/TIEN-DO-DU-AN.md`

**Leader sẽ:**
- Review và merge tất cả Pull Requests
- Cập nhật backend AI (thay mock data → AI thật)
- Hỗ trợ debug khi cần
- Cập nhật tài liệu này mỗi khi có thay đổi lớn
