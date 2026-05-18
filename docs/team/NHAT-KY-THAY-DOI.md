# 📝 AURA Social – Nhật Ký Thay Đổi (Changelog)

> File này ghi lại tất cả thay đổi quan trọng theo thời gian.  
> Thành viên nên đọc phần mới nhất mỗi khi `git pull`.

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
