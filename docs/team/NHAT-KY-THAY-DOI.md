# 📝 AURA Social – Nhật Ký Thay Đổi (Changelog)

> File này ghi lại tất cả thay đổi quan trọng theo thời gian.  
> Thành viên nên đọc phần mới nhất mỗi khi `git pull`.


## [07/06/2026] – Sửa lỗi xóa chat & Thêm chức năng sửa/xóa bài viết

### ⚠️ Thành viên cần làm sau khi pull:
1. Cập nhật **Firestore Rules** trên Firebase Console để cho phép hành động `delete` đối với cuộc trò chuyện bởi thành viên tham gia (xem hướng dẫn ở mục 3 dưới đây).

### ✅ Đã thêm:
- **Chức năng sửa bài viết (Post)**: 
  - Người dùng có thể nhấn vào nút ba chấm trên `PostCard` hoặc trong trang chi tiết bài viết, chọn "Chỉnh sửa bài viết".
  - Màn hình chỉnh sửa sẽ được điền sẵn nội dung cũ và hiển thị ảnh cũ (tải từ R2 qua `CachedNetworkImage`).
- **Chức năng xóa bài viết (Post)**:
  - Cho phép người dùng xóa bài viết của mình, tự động cập nhật giảm số lượng `posts_count` của người dùng đó.
  - Tự động quay về trang trước (`pop`) khi bài viết bị xóa từ màn hình chi tiết bài viết.

### 🐛 Đã sửa:
- **Lỗi xóa chat không cập nhật**: 
  - Sửa `firestore.rules` để cấp quyền xóa cuộc trò chuyện.
  - Chuyển `onDismissed` trong `conversations_list_screen.dart` sang chế độ bất đồng bộ (`async`/`await`) và bắt lỗi ngoại lệ khi hành động xóa gặp sự cố.

### 🔧 Thay đổi kỹ thuật:
- `firebase/firestore.rules`: Cập nhật quyền `delete` cho `conversations`.
- `conversations_list_screen.dart`: Chuyển xử lý `onDismissed` thành `async` và thêm `try-catch`.
- `app_router.dart`: Cập nhật route `/create-post` để nhận tham số `extra` kiểu `PostModel`.
- `create_post_screen.dart`: Thêm thuộc tính `postToEdit` và thay đổi logic lưu cập nhật bài viết hiện có.
- `post_card.dart`: Thêm menu ba chấm (Edit/Delete) cho bài viết của chính chủ.
- `post_detail_screen.dart`: Thêm menu ba chấm cho chính chủ và logic tự động pop khi post bị xóa.

---

## [18/05/2026] – Sửa lỗi biên dịch & Tích hợp Google Sign-In

### ⚠️ Thành viên cần làm sau khi pull:
1. Chạy `flutter pub get` (có package mới: `google_sign_in`)
2. **Bật Email/Password + Google** trên Firebase Console (xem HUONG-DAN-BAT-DAU.md mục 0)
3. **Thêm SHA-1 debug keystore của máy bạn** vào Firebase Console

### ✅ Đã thêm:
- **Google Sign-In** cho cả màn hình Login và Register
  - Nếu là user mới → tự động tạo Firestore document + emotion profile
  - Nếu đã có tài khoản → đăng nhập bình thường
- **Package `google_sign_in: ^6.2.2`** vào `pubspec.yaml`
- **`signInWithGoogle()`** method trong `auth_state_provider.dart`
- **Auth-aware Splash Screen** – kiểm tra trạng thái đăng nhập khi mở app
- **Stream-based Router** – dùng `refreshListenable` để router tự redirect khi auth thay đổi
- **Tài liệu tiến độ** `TIEN-DO-DU-AN.md`

### 🐛 Đã sửa:
- `argument_type_not_assignable` trong `feed_screen.dart` – thêm `PostModel.fromMockMap()`
- `invocation_of_non_function_expression` trong `profile_screen.dart` và `user_profile_screen.dart`
- Thiếu `import go_router` trong `user_profile_screen.dart`
- Auth redirect loop sau khi đăng nhập thành công
- Race condition giữa Firebase Auth state và GoRouter redirect
- Thư mục `untitled/` bị commit nhầm vào repo → đã xóa và thêm vào `.gitignore`

### 🔧 Thay đổi kỹ thuật:
- `splash_screen.dart`: Thêm `FirebaseAuth.instance.currentUser` check
- `app_router.dart`: Thêm `_AuthStateListenable` + `refreshListenable`
- `login_screen.dart`: Bỏ manual `context.go('/feed')` – router tự redirect
- `register_screen.dart`: Tương tự login + thêm nút Google
- `auth_state_provider.dart`: Thêm `signInWithGoogle()`, sửa `signOut()` để clear Google session
- `.gitignore`: Thêm `untitled/` và `.vs/`

---

## [18/04/2026 → 17/05/2026] – Team coding sprint

### Đã hoàn thành:
- Person 2: Auth screens, Feed, Post, Profile, Edit Profile, User Profile
- Person 3: Chat, Conversations, Soul Connect, Swipe Card, Waves, Wave Chat, Search
- Person 4: Wellbeing, Settings (AI + Privacy), Notifications, BehavioralTracker, Shimmer widgets

---

## [13/04/2026 → 18/04/2026] – Khởi tạo & Setup

### Đã hoàn thành:
- Khởi tạo Flutter project với Design System đầy đủ
- Tích hợp Firebase (Auth, Firestore, RTDB, FCM)
- Deploy FastAPI backend skeleton lên Cloud Run
- Thiết kế toàn bộ kiến trúc hệ thống
- Tạo repo GitHub, phân công công việc
- Brand Identity Kit (logo, app icon, splash)
