# 📱 Person 2 – Flutter Core UI: Walkthrough & Test Guide

> **Ngày hoàn thành:** 2026-05-12  
> **Tasks hoàn thành:** 18/18 (Tuần 1 + Tuần 2)  
> **Phạm vi:** Auth + Feed + Post + Providers + Models

---

## 1. Tổng Quan Files Đã Tạo/Sửa

### 📁 Files MỚI (12 files)

| # | File | Mô tả |
|---|---|---|
| 1 | `lib/core/services/api_service.dart` | HTTP client (Dio) kết nối FastAPI backend |
| 2 | `lib/shared/models/user_model.dart` | Model cho Firestore `users` collection |
| 3 | `lib/features/feed/models/post_model.dart` | Model cho `posts` + `comments` collection |
| 4 | `lib/shared/models/emotion_profile_model.dart` | Model cho `emotion_profile` subcollection |
| 5 | `lib/providers/auth_state_provider.dart` | Auth state stream + login/register actions |
| 6 | `lib/providers/user_profile_provider.dart` | User profile stream + follow/unfollow service |
| 7 | `lib/providers/emotion_profile_provider.dart` | Emotion profile stream provider |
| 8 | `lib/providers/api_service_provider.dart` | Riverpod provider cho API service singleton |
| 9 | `lib/features/auth/screens/onboarding_screen.dart` | 4-slide giới thiệu app (Aura Ring, AI Feed, Soul Connect, Privacy) |
| 10 | `lib/features/post/screens/post_detail_screen.dart` | Chi tiết bài viết + comments stream |

### 📝 Files ĐÃ SỬA (7 files)

| # | File | Thay đổi |
|---|---|---|
| 1 | `lib/features/auth/screens/login_screen.dart` | Skeleton → Firebase Auth integration + validation + loading states |
| 2 | `lib/features/auth/screens/register_screen.dart` | Skeleton → Firebase Auth + Firestore user creation + terms checkbox |
| 3 | `lib/core/router/app_router.dart` | Thêm auth guard redirect, onboarding route, post detail route |
| 4 | `lib/features/feed/screens/feed_screen.dart` | Mock data → Firestore streams (For You + Following tabs) |
| 5 | `lib/features/feed/widgets/post_card.dart` | Map data → PostModel + CachedNetworkImage + timeago |
| 6 | `lib/features/feed/widgets/emotion_reaction_bar.dart` | Static display → Firestore read/write reactions + toggle + haptic |
| 7 | `lib/features/post/screens/create_post_screen.dart` | Skeleton → Image picker + Firestore + R2 upload via FastAPI |

---

## 2. Chi Tiết Từng Module

### 🔌 Module: API Service (`core/services/api_service.dart`)

**Class `AuraApiService`** – HTTP client singleton kết nối Flutter → FastAPI backend.

| Method | Mô tả | Ví dụ sử dụng |
|---|---|---|
| `get(path)` | GET request | `api.get('/api/v1/user/profile')` |
| `post(path, data)` | POST request | `api.post('/api/v1/feed/generate', data: {...})` |
| `put(path, data)` | PUT request | `api.put('/api/v1/user/settings', data: {...})` |
| `delete(path)` | DELETE request | `api.delete('/api/v1/post/123')` |
| `uploadFile(path, filePath, fieldName)` | Upload file multipart (ảnh → R2) | `api.uploadFile('/upload/image', filePath: file.path, fieldName: 'file')` |

**Class `_AuthInterceptor`** – Interceptor tự động gắn Firebase token.

- `onRequest()`: Lấy `currentUser.getIdToken()` → gắn `Authorization: Bearer <token>` vào mọi request
- `onError()`: Detect 401 Unauthorized → có thể force refresh token

**Config:**
- Base URL: `String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080')`
- Timeouts: connect 10s, receive 30s, send 30s
- Debug mode: LogInterceptor in request/response body

---

### 📦 Module: Models

#### `UserModel` (`shared/models/user_model.dart`)

Map 1:1 với Firestore collection `users/{userId}`. Chứa:
- Thông tin cá nhân: `uid`, `email`, `displayName`, `username`, `avatarUrl`, `bio`, `interests`
- Social stats: `followersCount`, `followingCount`, `postsCount`
- Emotion summary: `auraDominantEmotion`, `auraValence`, `auraConfidence`, `emotionalMode`
- AI settings: Map config bật/tắt các tính năng AI
- System: `fcmToken`, `createdAt`, `updatedAt`, `privacyConsentAt`

| Method | Mô tả |
|---|---|
| `fromFirestore(DocumentSnapshot)` | Parse Firestore document → UserModel (xử lý null safety, type casting) |
| `toFirestore()` | Chuyển thành `Map<String, dynamic>` để ghi Firestore (auto `FieldValue.serverTimestamp()`) |
| `copyWith(...)` | Tạo bản sao với 1 số fields thay đổi (immutable pattern) |
| `defaultAiSettings()` | Static: trả Map AI settings mặc định cho user mới đăng ký |

#### `PostModel` + `CommentModel` (`features/feed/models/post_model.dart`)

**PostModel** – Map Firestore `posts/{postId}`:
- Content: `content`, `mediaUrls`, `mediaType`
- AI Analysis: `aiEmotionVector` (8D), `aiValence`, `aiSentiment`
- Engagement: `reactionsCount`, `reactionsBreakdown` (Map per emotion), `commentsCount`
- Denormalized author: `authorName`, `authorUsername`, `authorAvatarUrl` (để hiển thị nhanh)

| Method/Property | Mô tả |
|---|---|
| `fromFirestore()` | Parse post document, xử lý Map<dynamic> → typed Map |
| `toFirestore()` | Serialize cho post mới (auto-init reactions = 0, status = 'active') |
| `hasMedia` | Getter: `mediaUrls.isNotEmpty && mediaType != 'none'` |
| `dominantEmotion` | Getter: emotion key có value cao nhất trong `aiEmotionVector` |
| `totalEngagement` | Getter: `reactionsCount + commentsCount + sharesCount` |

**CommentModel** – Map subcollection `posts/{postId}/comments/{commentId}`

#### `EmotionProfileModel` (`shared/models/emotion_profile_model.dart`)

Map subcollection `users/{userId}/emotion_profile/current`. Read-only từ client (data do FastAPI cập nhật).

| Property | Mô tả |
|---|---|
| `currentEmotionVector` | Map 8D Plutchik: `{joy: 0.3, trust: 0.2, ...}` (tổng = 1.0) |
| `valence` | -1.0 (tiêu cực) → +1.0 (tích cực) |
| `arousal` | 0.0 (bình tĩnh) → 1.0 (phấn khích) |
| `dominance` | 0.0 (thụ động) → 1.0 (chủ động) |
| `emotionConfidence` | Độ tin cậy inference 0.0 – 1.0 |
| `emotionalMode` | `gentle_uplift` / `empathetic_mirror` / `amplify` / `deep_chill` / `explore` |
| `dominantEmotion` | Getter: key có value cao nhất |
| `moodDescription` | Getter: text tiếng Việt mô tả mood dựa trên valence |
| `hasData` | Getter: `totalInferences > 0` |

---

### 🔐 Module: Auth (`providers/auth_state_provider.dart`)

**`authStateProvider`** – `StreamProvider<User?>`: lắng nghe `FirebaseAuth.authStateChanges()`

**`AuthNotifier`** – StateNotifier quản lý auth actions:

| Method | Mô tả | Firestore? |
|---|---|---|
| `signInWithEmail(email, password)` | `FirebaseAuth.signInWithEmailAndPassword()` | ❌ |
| `registerWithEmail(...)` | `createUserWithEmailAndPassword()` → tạo user document + emotion profile | ✅ |
| `signOut()` | `FirebaseAuth.signOut()` | ❌ |
| `resetPassword(email)` | `sendPasswordResetEmail()` | ❌ |
| `clearError()` | Reset error state | ❌ |

**Error mapping** – Firebase error codes → tiếng Việt:
- `user-not-found` → "Không tìm thấy tài khoản với email này"
- `wrong-password` → "Mật khẩu không đúng"
- `email-already-in-use` → "Email này đã được sử dụng"
- `weak-password` → "Mật khẩu quá yếu (tối thiểu 6 ký tự)"
- etc.

**Register flow (chi tiết):**
1. `FirebaseAuth.createUserWithEmailAndPassword()` → tạo Firebase Auth user
2. `user.updateDisplayName()` → cập nhật display name
3. Tạo `users/{uid}` document trong Firestore với `UserModel.toFirestore()`
4. Tạo `users/{uid}/emotion_profile/current` document với default emotion vector

---

### 👤 Module: User Profile (`providers/user_profile_provider.dart`)

| Provider | Type | Mô tả |
|---|---|---|
| `userProfileProvider(uid)` | `StreamProvider.family<UserModel, String>` | Stream realtime 1 user document |
| `currentUserProfileProvider` | `StreamProvider<UserModel?>` | Shortcut cho logged-in user |
| `userProfileServiceProvider` | `Provider<UserProfileService>` | Service cho write operations |

**`UserProfileService`** methods:

| Method | Mô tả |
|---|---|
| `updateProfile(uid, ...)` | Update `display_name`, `username`, `bio`, `interests` |
| `updateAvatar(uid, url)` | Update `avatar_url` |
| `toggleFollow(myUid, targetUid)` | Batch write: tạo/xóa `following/{targetUid}` + update counts cả 2 users |
| `isFollowing(myUid, targetUid)` | Check subcollection document exists |

---

### 🛣️ Module: Router (`core/router/app_router.dart`)

**Auth Guard Logic:**
```
IF user == null AND path NOT in [/, /login, /register, /onboarding]
  → REDIRECT to /login

IF user != null AND path in [/login, /register]
  → REDIRECT to /feed

ELSE → no redirect
```

**All Routes:**

| Path | Screen | Auth Required | Type |
|---|---|---|---|
| `/` | SplashScreen | ❌ | Standalone |
| `/onboarding` | OnboardingScreen | ❌ | Standalone |
| `/login` | LoginScreen | ❌ | Standalone |
| `/register` | RegisterScreen | ❌ | Standalone |
| `/feed` | FeedScreen | ✅ | Shell (bottom nav) |
| `/soul` | SoulConnectScreen | ✅ | Shell (bottom nav) |
| `/chat` | ConversationsListScreen | ✅ | Shell (bottom nav) |
| `/profile` | ProfileScreen | ✅ | Shell (bottom nav) |
| `/create-post` | CreatePostScreen | ✅ | Fullscreen |
| `/post/:postId` | PostDetailScreen | ✅ | Fullscreen |

---

### 📰 Module: Feed (`features/feed/`)

**FeedScreen** – 2 tabs sử dụng TabController + NestedScrollView:

| Tab | Data Source | Query Logic |
|---|---|---|
| **For You** | Firestore `posts` | `where('status', '==', 'active').orderBy('created_at', desc).limit(50)` |
| **Following** | Firestore `following` → `posts` | Lấy following UIDs → `where('user_id', whereIn: ids).limit(30)` |

**UI States:**
- Loading: Shimmer placeholders (3 skeleton cards)
- Empty: Icon + text "Chưa có bài viết nào"
- Error: Error icon + message
- Data: ListView.builder với animation fadeIn + slideY

---

### 💬 Module: Reactions (`features/feed/widgets/emotion_reaction_bar.dart`)

**Firestore write logic khi user tap reaction:**

```
TAP emotion X:
├── Nếu đang chọn X → UNREACT:
│   ├── DELETE posts/{postId}/reactions/{userId}
│   ├── UPDATE posts/{postId}: reactions_count -= 1
│   └── UPDATE posts/{postId}: reactions_breakdown.X -= 1
│
├── Nếu đang chọn Y (khác X) → SWITCH:
│   ├── UPDATE posts/{postId}: reactions_breakdown.Y -= 1
│   ├── UPDATE posts/{postId}: reactions_breakdown.X += 1
│   └── SET posts/{postId}/reactions/{userId} = {emotion: X}
│
└── Nếu chưa chọn gì → REACT:
    ├── SET posts/{postId}/reactions/{userId} = {emotion: X, timestamp}
    ├── UPDATE posts/{postId}: reactions_count += 1
    └── UPDATE posts/{postId}: reactions_breakdown.X += 1
```

**Features:**
- Optimistic UI: cập nhật local state trước, rollback nếu Firestore batch fail
- Haptic feedback: `HapticFeedback.lightImpact()` khi tap
- AnimatedScale: emoji scale 1.0 → 1.2 khi selected
- Load initial state: đọc `reactions/{userId}` document khi init

---

### ✍️ Module: Create Post (`features/post/screens/create_post_screen.dart`)

**Flow tạo bài viết:**
```
1. User nhập text content
2. (Tùy chọn) Tap "Thư viện" → ImagePicker.pickImage(source: gallery)
   HOẶC Tap "Chụp ảnh" → ImagePicker.pickImage(source: camera)
3. (Tùy chọn) Chọn mood expression (8 emotions Plutchik)
4. Tap "Đăng" button
5. IF có ảnh:
   └── Upload ảnh → FastAPI POST /api/v1/upload/image
       └── Nhận response: {url: "https://r2.example.com/abc.jpg"}
6. Lấy user info từ Firestore users/{uid} (denormalize)
7. Tạo PostModel → .toFirestore() → Firestore posts.add()
8. Update users/{uid}.posts_count += 1
9. Navigator.pop() → trở về feed
```

**Image config:** maxWidth 1200px, quality 85% (giảm dung lượng upload)

---

### 📄 Module: Post Detail (`features/post/screens/post_detail_screen.dart`)

**Components:**
- `_PostContent`: Full post view (AuraRing + author + content + image + reactions)
- `_CommentTile`: Comment item (avatar + name + content + time + delete button)
- Comment input: TextField + Send button ở bottom

**Firestore streams:**
- Post: `posts/{postId}` document stream → auto-update reactions count
- Comments: `posts/{postId}/comments` collection stream, orderBy `created_at` asc

**Add comment flow:**
1. Lấy user info từ Firestore (denormalize author name/avatar)
2. Add document to `posts/{postId}/comments`
3. Increment `posts/{postId}.comments_count`

---

### 🎭 Module: Onboarding (`features/auth/screens/onboarding_screen.dart`)

4 slides giới thiệu tính năng chính:

| Slide | Emoji | Title | Mô tả |
|---|---|---|---|
| 1 | 🔮 | Aura Ring | Vòng hào quang phản ánh cảm xúc qua màu sắc |
| 2 | 🧠 | Feed Thông Minh | AI đọc hành vi để cá nhân hóa feed theo tâm trạng |
| 3 | 💜 | Soul Connect | Kết nối sâu dựa trên mẫu cảm xúc, không chỉ bề mặt |
| 4 | 🛡️ | Quyền Riêng Tư | Mọi AI có thể tắt/bật, dữ liệu thuộc về user |

**Logic:** SharedPreferences flag `onboarding_seen`. Chỉ hiện 1 lần, sau đó → login.

---

## 3. Workflow Test Thủ Công

### Test 1: Auth Flow 🔐

```
1. Mở app → Splash → (chưa login) → Login Screen
2. Tap "Đăng ký" → Register Screen
3. Nhập: tên "Test User", email "test@aura.com", mật khẩu "123456", xác nhận "123456"
4. Check ☑ checkbox đồng ý điều khoản
5. Tap "Tạo tài khoản"
   ✅ Verify: loading spinner hiện trên button
   ✅ Verify: redirect tới /feed
   ✅ Verify Firestore Console: users/{uid} document được tạo
   ✅ Verify Firestore Console: users/{uid}/emotion_profile/current được tạo
6. Kill app → mở lại → skip login, vào Feed trực tiếp (auth guard)
```

### Test 2: Feed Display 📰

```
1. Ở Feed Screen → Tab "For You"
   ✅ Verify: shimmer loading placeholder hiện khi đang load
   ✅ Verify: posts hiển thị với avatar, tên, thời gian, nội dung
   ✅ Verify: ảnh load lazy (placeholder → image)
   ✅ Pull down → RefreshIndicator hiện
2. Switch Tab "Following"
   ✅ Nếu chưa follow ai: empty state "Chưa follow ai"
3. Quay lại Tab "For You" → data vẫn giữ (không reload)
```

### Test 3: Create Post ✍️

```
1. Tap "+" trên bottom nav → Navigate tới /create-post
2. Nhập "Hello AURA! Đây là bài viết đầu tiên 🎉"
   ✅ Verify: nút "Đăng" chuyển từ disabled → enabled
3. Tap "Thư viện" → chọn 1 ảnh
   ✅ Verify: ảnh preview hiện bên dưới text
   ✅ Verify: nút X ở góc ảnh để xóa
4. Tap mood "😊 Vui vẻ"
   ✅ Verify: chip highlight với emotion color
5. Tap "Đăng"
   ✅ Verify: loading spinner
   ✅ Verify: pop về feed
   ✅ Verify: bài viết mới xuất hiện trong feed
   ✅ Verify Firestore: posts collection có document mới
```

### Test 4: Reactions 🎭

```
1. Ở Feed → tap emoji 😊 (Joy) trên 1 bài post
   ✅ Verify: emoji scale lên, count +1
   ✅ Verify: haptic feedback rung nhẹ
   ✅ Verify Firestore: posts/{id}/reactions/{uid} document tạo
2. Tap lại 😊 → unreact
   ✅ Verify: count -1, highlight mất
   ✅ Verify Firestore: reactions document bị xóa
3. Tap 😢 (Sad) khi đã react 😊
   ✅ Verify: 😊 count -1, 😢 count +1 (switch reaction)
```

### Test 5: Post Detail + Comments 💬

```
1. Ở Feed → tap icon 💬 trên 1 post
   ✅ Verify: navigate tới /post/{postId}
   ✅ Verify: full post hiển thị (content + image + reactions)
2. Nhập "Bài viết hay quá!" → tap Send icon
   ✅ Verify: comment hiện trong list
   ✅ Verify: comment count tăng +1
   ✅ Verify Firestore: comments subcollection
3. Tap X trên comment của mình
   ✅ Verify: comment biến mất, count -1
```

### Test 6: Validation ⚠️

```
1. Login → email trống → "Email không hợp lệ"
2. Login → password trống → "Vui lòng nhập mật khẩu"
3. Login → sai credentials → "Email hoặc mật khẩu không đúng" (SnackBar đỏ)
4. Register → password < 6 → "Mật khẩu tối thiểu 6 ký tự"
5. Register → confirm ≠ password → "Mật khẩu không khớp"
6. Register → email đã dùng → "Email này đã được sử dụng"
7. Register → chưa check terms → "Vui lòng đồng ý với Điều khoản dịch vụ" (SnackBar vàng)
```

---

## 4. Lưu Ý Kỹ Thuật

### ⚠️ Chưa Implement
- **Google Sign-In**: Cần thêm `google_sign_in` package + SHA-1 config trên Firebase Console
- **FastAPI AI Feed**: For You tab hiện query Firestore trực tiếp, cần đổi sang `POST /api/v1/feed/generate` khi backend sẵn sàng
- **R2 Upload fallback**: Nếu FastAPI chưa có endpoint upload, post sẽ được tạo không có ảnh

### 📌 Config cần thiết
- **API_URL**: Đổi khi deploy: `flutter run --dart-define=API_URL=https://your-cloudrun-url.run.app`
- **Firebase**: Cần `google-services.json` (Android) và `GoogleService-Info.plist` (iOS)

### 📌 Firestore Indexes cần tạo
```
Collection: posts
  - Composite index: status ASC, created_at DESC
  - Composite index: user_id ASC, status ASC, created_at DESC
```

---

## 5. Tuần 3: Profile + Polish (✅ Hoàn thành)

### 📁 Files MỚI Tuần 3 (4 files)

| # | File | Mô tả |
|---|---|---|
| 1 | `lib/features/profile/screens/edit_profile_screen.dart` | Chỉnh sửa hồ sơ (name, bio, avatar, interests) |
| 2 | `lib/features/profile/screens/user_profile_screen.dart` | Xem profile người khác + Follow/Unfollow |
| 3 | `lib/shared/widgets/loading_widget.dart` | AuraLoadingWidget + AuraShimmerList |
| 4 | `lib/shared/widgets/error_widget.dart` | AuraErrorWidget + AuraEmptyWidget |

### 📝 Files ĐÃ SỬA Tuần 3 (3 files)

| # | File | Thay đổi |
|---|---|---|
| 1 | `lib/shared/widgets/aura_ring_widget.dart` | v2: confidence → ring width, arousal → pulse speed, CachedNetworkImage |
| 2 | `lib/features/profile/screens/profile_screen.dart` | Skeleton → Firestore data + emotion compass + post grid + logout |
| 3 | `lib/core/router/app_router.dart` | Thêm routes `/profile/edit` và `/user/:userId` |

---

### 🔮 Module: Aura Ring v2 (`shared/widgets/aura_ring_widget.dart`)

**Cải tiến so với v1:**

| Feature | v1 (cũ) | v2 (mới) |
|---|---|---|
| Ring width | Cố định theo size | `confidence` (0→1) → 2px–5.5px |
| Pulse speed | Cố định 2500ms | `arousal` (0→1) → 3500ms–1200ms |
| Avatar loading | `Image.network` | `CachedNetworkImage` (cache + placeholder) |
| Hot update | Không | `didUpdateWidget` detect arousal change |

**Params mới:**

| Param | Type | Mô tả |
|---|---|---|
| `confidence` | `double` (0.0–1.0) | Độ tin cậy AI → ring dày hơn khi confidence cao |
| `arousal` | `double` (0.0–1.0) | Mức phấn khích → pulse nhanh hơn khi arousal cao |

**Logic tính ring width:**
```
base = size < 50 ? 2.0 : size < 80 ? 3.0 : 3.5
ringWidth = base + (confidence × 2.0)
// Kết quả: 2.0px (low confidence) → 5.5px (high confidence)
```

**Logic tính pulse speed:**
```
durationMs = (3500 - arousal × 2300).clamp(1200, 3500)
// arousal = 0.0 → 3500ms (chậm, bình tĩnh)
// arousal = 1.0 → 1200ms (nhanh, phấn khích)
```

---

### 👤 Module: Profile Screen (`features/profile/screens/profile_screen.dart`)

**Data source:** `currentUserProfileProvider` + `currentEmotionProfileProvider` (Riverpod streams)

**Components:**

| Component | Mô tả |
|---|---|
| Avatar + Aura Ring | Real emotion vector từ provider, confidence + arousal |
| Name + Username + Bio | Từ Firestore `users/{uid}` |
| Stats Row | posts_count, followers_count, following_count, connections_count |
| Emotional Compass Card | Dominant emotion + emoji + confidence % + emotional mode + mood description |
| Interests Tags | Wrap layout với `#tag` chips |
| Post Grid | Firestore query `posts.where(user_id == uid)`, grid 3 columns |
| Actions | Edit Profile button, Logout (PopupMenu) |

**Emotional Compass Card hiển thị:**
```
🎯 Kỳ vọng  📊 78%
Mode: 🧭 Khám phá
Đang vui vẻ 😊
```

**Post Grid logic:**
- Query: `posts` → `where user_id == uid, status == active` → `orderBy created_at desc` → `limit 30`
- Grid items: ảnh (CachedNetworkImage) hoặc text preview (gradient background)
- Tap → navigate `/post/{postId}`

---

### ✏️ Module: Edit Profile (`features/profile/screens/edit_profile_screen.dart`)

**Form fields:**

| Field | Controller | Validation |
|---|---|---|
| Tên hiển thị | `_nameCtrl` | Min 2 ký tự |
| Username | `_usernameCtrl` | Min 3 ký tự |
| Giới thiệu (bio) | `_bioCtrl` | Max 150 ký tự |
| Sở thích | `_interestsCtrl` | Comma-separated → List |

**Avatar flow:**
```
1. Tap avatar → ImagePicker (gallery, maxWidth 500, quality 85%)
2. Hiện preview (Image.file trong AuraRing)
3. Khi Save → upload FastAPI /api/v1/upload/avatar → nhận URL
4. Update Firestore users/{uid}.avatar_url
```

**Save flow:**
```
1. Validate form
2. Upload avatar nếu có ảnh mới → nhận URL
3. Parse interests: "music, coding, travel" → ["music", "coding", "travel"]
4. UserProfileService.updateProfile(uid, displayName, username, bio, interests)
5. UserProfileService.updateAvatar(uid, url) nếu có
6. SnackBar "Đã cập nhật hồ sơ! ✅"
7. context.pop()
```

---

### 👥 Module: Other User Profile (`features/profile/screens/user_profile_screen.dart`)

**Route:** `/user/:userId`

**Components giống Profile Screen + thêm:**

| Component | Mô tả |
|---|---|
| Follow/Unfollow button | FilledButton (Follow) / OutlinedButton (Đang follow) |
| Nhắn tin button | OutlinedButton.icon (TODO: navigate to chat) |

**Follow/Unfollow logic (sử dụng `UserProfileService.toggleFollow`):**
```
toggleFollow(myUid, targetUid):
├── Check users/{myUid}/following/{targetUid} exists?
├── IF exists (đang follow) → UNFOLLOW:
│   ├── DELETE following/{targetUid}
│   ├── myUser.following_count -= 1
│   └── targetUser.followers_count -= 1
└── IF not exists → FOLLOW:
    ├── SET following/{targetUid} = {followed_at: timestamp}
    ├── myUser.following_count += 1
    └── targetUser.followers_count += 1
```

**Loading states:**
- `_loadingFollow`: check initial follow status
- `_togglingFollow`: while batch write in progress

---

### 🔄 Module: Shared Widgets

#### `AuraLoadingWidget` (`shared/widgets/loading_widget.dart`)

Branded loading spinner với container có shadow.

| Prop | Type | Mô tả |
|---|---|---|
| `message` | `String?` | Text hiển thị dưới spinner |

#### `AuraShimmerList` (`shared/widgets/loading_widget.dart`)

Skeleton loading placeholder cho list.

| Prop | Type | Mô tả |
|---|---|---|
| `itemCount` | `int` | Số shimmer cards (default: 3) |
| `itemHeight` | `double` | Chiều cao mỗi card (default: 160) |

Shimmer animation: stagger start (card 0: 0ms, card 1: 200ms, card 2: 400ms), opacity pulse 0.3 → 0.7.

#### `AuraErrorWidget` (`shared/widgets/error_widget.dart`)

Error state với retry button.

| Prop | Type | Mô tả |
|---|---|---|
| `message` | `String` | Error message |
| `onRetry` | `VoidCallback?` | Callback nút "Thử lại" |
| `icon` | `IconData?` | Custom icon |

#### `AuraEmptyWidget` (`shared/widgets/error_widget.dart`)

Empty state widget.

| Prop | Type | Mô tả |
|---|---|---|
| `title` | `String` | Tiêu đề |
| `subtitle` | `String?` | Mô tả phụ |
| `icon` | `IconData?` | Custom icon |
| `action` | `VoidCallback?` | Action button callback |
| `actionLabel` | `String?` | Text trên action button |

---

### Routes mới Tuần 3

| Path | Screen | Auth? |
|---|---|---|
| `/profile/edit` | EditProfileScreen | ✅ |
| `/user/:userId` | UserProfileScreen | ✅ |

---

## 6. Test Thủ Công Tuần 3

### Test 7: Profile Display 👤

```
1. Tap "Me" trên bottom nav → Profile Screen
   ✅ Verify: Avatar với Aura Ring (emotion vector thực)
   ✅ Verify: Tên, username, bio từ Firestore
   ✅ Verify: Stats (posts, followers, following) đúng
   ✅ Verify: Emotional Compass card hiện dominant emotion + confidence
   ✅ Verify: Post grid hiển thị bài viết của bạn
2. Tap 1 post trong grid → navigate tới post detail
```

### Test 8: Edit Profile ✏️

```
1. Từ Profile → tap icon Edit (pencil) trên AppBar
   ✅ Verify: form fields pre-filled với data hiện tại
2. Đổi tên "Test User 2", thêm bio "Hello AURA!"
3. Thêm interests: "music, travel, coding"
4. Tap avatar → chọn ảnh mới
   ✅ Verify: preview ảnh mới trong AuraRing
5. Tap "Lưu"
   ✅ Verify: loading spinner
   ✅ Verify: SnackBar "Đã cập nhật hồ sơ! ✅"
   ✅ Verify: pop về Profile, data đã cập nhật
   ✅ Verify Firestore: users/{uid} document updated
```

### Test 9: Other User Profile + Follow 👥

```
1. Từ Feed → tap avatar trên 1 post → navigate /user/{uid}
   ✅ Verify: hiện profile người khác
   ✅ Verify: nút "Follow" hiện (nếu chưa follow)
2. Tap "Follow"
   ✅ Verify: loading spinner → button đổi thành "Đang follow"
   ✅ Verify Firestore: following/{targetUid} document tạo
   ✅ Verify: your following_count +1, their followers_count +1
3. Tap "Đang follow" → unfollow
   ✅ Verify: button đổi lại "Follow"
   ✅ Verify Firestore: following document xóa, counts -1
4. Tap "Nhắn tin" → (TODO: navigate to chat)
```

### Test 10: Shared Widgets 🔄

```
1. Tắt WiFi → vào Profile
   ✅ Verify: AuraLoadingWidget hiện spinner
   ✅ Verify: sau timeout → AuraErrorWidget hiện "Đã xảy ra lỗi" + nút "Thử lại"
2. Tap "Thử lại" → bật WiFi
   ✅ Verify: data load thành công
3. User mới chưa có posts → vào Profile
   ✅ Verify: empty state "Chưa có bài viết nào"
```

---

## 7. Tổng Kết

### 📊 Thống kê

| Tuần | Tasks | Files mới | Files sửa |
|---|---|---|---|
| Tuần 1 | 11 | 8 | 3 |
| Tuần 2 | 7 | 1 | 4 |
| Tuần 3 | 5 | 4 | 3 |
| **Tổng** | **23** | **13** | **10** |

### ✅ Tất cả 23 Tasks đã hoàn thành

- [x] Foundation: API Service, Models (User/Post/Emotion), Providers
- [x] Auth: Login, Register, Onboarding, Auth Guard
- [x] Feed: For You + Following tabs, Firestore streams, shimmer loading
- [x] Post: Create post, image upload R2, Post detail + comments
- [x] Reactions: 8 emotions Plutchik, Firestore toggle, optimistic UI
- [x] Profile: Profile screen, Edit profile, Other user profile
- [x] Aura Ring: v2 với confidence + arousal
- [x] Follow: Follow/Unfollow với batch writes
- [x] Shared: Loading, Error, Empty widgets
- [x] Router: Auth guard + all routes
