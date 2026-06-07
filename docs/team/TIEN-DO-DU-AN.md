# 📊 AURA Social – Báo Cáo Tiến Độ Dự Án

> **Cập nhật lần cuối:** 18/05/2026  
> **Trạng thái tổng quan:** 🟢 Frontend sẵn sàng test · 🟡 Backend AI đang phát triển

---

## 🗓️ Lịch Sử Cập Nhật

| Ngày | Nội dung |
|---|---|
| 13/04/2026 | Khởi tạo dự án, thiết kế hệ thống, phân công công việc |
| 18/04/2026 | Deploy Firebase + FastAPI backend skeleton, team bắt đầu code |
| 18/05/2026 | **Merge tất cả nhánh vào `main`**, sửa lỗi biên dịch, tích hợp Google Sign-In |

---

## ✅ Những Gì Đã Hoàn Thành (tính đến 18/05/2026)

### Frontend – Flutter App (~98% UI hoàn thiện)

| Module | Màn hình / Widget | Người phụ trách | Trạng thái |
|---|---|---|---|
| **Auth** | Login Screen | Person 2 | ✅ Hoàn thiện + Google Sign-In |
| **Auth** | Register Screen | Person 2 | ✅ Hoàn thiện + Google Sign-In |
| **Auth** | Onboarding Screen | Person 2 | ✅ |
| **Feed** | For You Tab (mock AI feed) | Leader | ✅ Pull-to-refresh + Infinite scroll |
| **Feed** | Following Tab | Leader | ✅ |
| **Feed** | Post Card widget | Leader | ✅ Aura Ring + Reactions |
| **Feed** | Shimmer Loading | Person 4 | ✅ |
| **Post** | Create Post Screen | Person 2 | ✅ Text + Image picker |
| **Post** | Post Detail + Comments | Person 2 | ✅ |
| **Profile** | My Profile Screen | Person 2 | ✅ Emotional Compass card |
| **Profile** | User Profile (khác) | Person 2 | ✅ Follow/Unfollow |
| **Profile** | Edit Profile Screen | Person 2 | ✅ |
| **Chat** | Conversations List | Person 3 | ✅ |
| **Chat** | Chat Screen (RTDB) | Person 3 | ✅ Real-time messages |
| **Soul Connect** | Soul Connect Screen | Person 3 | ✅ Swipe card UI |
| **Soul Connect** | Swipe Card widget | Person 3 | ✅ |
| **Waves** | Waves List Screen | Person 3 | ✅ |
| **Waves** | Wave Chat Screen | Person 3 | ✅ |
| **Compass** | Emotional Compass Screen | Leader | ✅ |
| **Wellbeing** | Wellbeing Screen | Person 4 | ✅ |
| **Settings** | Settings Screen | Person 4 | ✅ |
| **Settings** | AI Settings Screen | Person 4 | ✅ |
| **Settings** | Privacy Settings | Person 4 | ✅ |
| **Notifications** | Notifications Screen | Person 4 | ✅ |
| **Search** | Search Screen | Person 3 | ✅ |
| **Shared** | AuraRing Widget | Leader | ✅ Emotion gradient ring |
| **Shared** | BehavioralTracker | Person 4 | ✅ Ghi events → Firestore |

### Backend / Infrastructure

| Thành phần | Trạng thái |
|---|---|
| Firebase Auth (Email/Password) | ✅ Hoạt động |
| Firebase Auth (Google Sign-In) | ✅ Code xong – cần bật trên Console |
| Firestore (đọc/ghi posts, users) | ✅ Hoạt động |
| Firebase RTDB (chat real-time) | ✅ Hoạt động |
| FastAPI backend skeleton | ✅ Deploy trên Cloud Run |
| FastAPI `/health` endpoint | ✅ |
| FastAPI AI services (emotion, feed, soul) | 🔴 Chưa triển khai – dùng mock data |
| Cloud Functions | 🟡 Partial (cần deploy) |

---

## 🔄 Đang Làm / Cần Làm

### 🔴 Ưu tiên cao (Cần làm ngay)

| # | Việc cần làm | Người | Deadline |
|---|---|---|---|
| 1 | **Bật Email/Password** trên Firebase Console | Leader | ASAP |
| 2 | **Bật Google Sign-In** trên Firebase Console | Leader | ASAP |
| 3 | **Thêm SHA-1** debug keystore của từng máy vào Firebase | Mỗi thành viên | ASAP |
| 4 | Test luồng đăng ký / đăng nhập | Tất cả | Tuần này |
| 5 | Test luồng tạo bài viết và feed | Tất cả | Tuần này |

### 🟡 Ưu tiên trung bình

| # | Việc cần làm | Người |
|---|---|---|
| 6 | Triển khai FastAPI `/api/v1/emotion/infer` (AI thật) | Leader |
| 7 | Triển khai FastAPI `/api/v1/feed/generate` | Leader |
| 8 | Deploy Cloud Functions | Leader |
| 9 | Thêm `crisis_resource_card.dart` widget | Person 4 |
| 10 | Tạo `app_constants.dart` và `asset_paths.dart` | Leader |

### 🟢 Cải thiện sau

| # | Việc cần làm | Người |
|---|---|---|
| 11 | Unit tests cho auth flow | Tất cả |
| 12 | Tối ưu hiệu suất Firestore queries | Leader |
| 13 | Push notifications (FCM) | Person 4 |
| 14 | Hoàn thiện Soul Connect algorithm | Leader |

---

## 📦 Cấu Trúc Nhánh Git Hiện Tại

```
main  ← Nhánh chính, đã merge tất cả (CẦN PULL VỀ)
├── Authentication     (Person 2 - đã merge)
├── Thuan-Per2         (Person 2 - đã merge)
├── Thuy-nhiemvuperson4 (Person 4 - đã merge)
├── features/chat      (Person 3 - đã merge)
└── features/soul      (Person 3 - đã merge)
```

> ✅ **Tất cả nhánh đã được merge vào `main`**. Team chỉ cần `git pull origin main`.

---

## 🐛 Lỗi Đã Sửa (18/05/2026)

| Lỗi | Nguyên nhân | Đã sửa |
|---|---|---|
| `argument_type_not_assignable` (feed_screen.dart) | FeedService trả `Map` nhưng PostCard cần `PostModel` | ✅ Thêm `PostModel.fromMockMap()` |
| `invocation_of_non_function_expression` (profile_screen.dart) | `.animate()` chain không resolve sau merge | ✅ Sửa cấu trúc widget |
| `undefined_method 'push'` (user_profile_screen.dart) | Thiếu `import go_router` | ✅ Thêm import |
| Auth redirect loop | Splash không kiểm tra auth state | ✅ Kiểm tra `currentUser` |
| Race condition login | Router không reactive với auth changes | ✅ Thêm `refreshListenable` |
| `untitled/` commit nhầm | Thiếu gitignore rule | ✅ Đã thêm vào `.gitignore` |
