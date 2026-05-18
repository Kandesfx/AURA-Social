# AURA Social – Person 3: Flutter Social (Chat + Soul Connect + Waves + Search)

> **Người thực hiện:** Person 3  
> **Phiên bản:** v1.0  
> **Cập nhật:** 2026-05-13

---

## 1. Tổng Quan Phân Công

Person 3 chịu trách nhiệm toàn bộ module **Flutter Social**, bao gồm:

| Module | Trạng thái | Mô tả |
|---|---|---|
| **Chat** | ✅ Hoàn thành | 1-1 chat, conversations list, typing indicator, message bubbles |
| **Soul Connect** | ✅ Hoàn thành | AI-powered soul matching, swipeable cards, compatibility breakdown |
| **Emotional Waves** | ✅ Hoàn thành | Group emotional waves, wave chat, momentum tracking |
| **Search** | ✅ Hoàn thành | User search, emotion filter chips, trending users |

---

## 2. Chi Tiết Từng Module

### 2.1 Chat Module

**Đã xây từ trước:**

| File | Loại | Mô tả |
|---|---|---|
| `features/chat/models/conversation_model.dart` | Model | ConversationModel, LastMessage, ConversationType |
| `features/chat/models/message_model.dart` | Model | MessageModel, MessageType enum |
| `features/chat/providers/chat_provider.dart` | Provider | ConversationsNotifier, ChatMessagesNotifier + mock data |
| `features/chat/providers/presence_provider.dart` | Provider | UserPresence, TypingStatus + mock data |
| `features/chat/screens/conversations_list_screen.dart` | Screen | Danh sách conversations với AuraRing, online status, unread count |
| `features/chat/screens/chat_screen.dart` | Screen | Chat 1-1 real-time, date separators, typing indicator |
| `features/chat/widgets/message_bubble.dart` | Widget | Bubble với AI sentiment glow |
| `features/chat/widgets/chat_input.dart` | Widget | Input bar: text + emoji + attach + send |
| `features/chat/widgets/typing_indicator.dart` | Widget | Animated dots indicator |

---

### 2.2 Soul Connect Module

**Files MỚI tạo:**

| File | Loại | Mô tả |
|---|---|---|
| `features/soul_connect/models/soul_connection_model.dart` | **[NEW]** Model | SoulSuggestion, SoulUser, CompatibilityBreakdown |
| `features/soul_connect/providers/soul_provider.dart` | **[NEW]** Provider | soulSuggestionsProvider (FutureProvider), soulActionProvider, currentSoulIndexProvider |
| `features/soul_connect/widgets/soul_card.dart` | **[NEW]** Widget | Card hiển thị suggestion: AuraRing avatar, soul score animated, connection type badge, action buttons |
| `features/soul_connect/widgets/compatibility_breakdown.dart` | **[NEW]** Widget | 5 animated progress bars: Emotional, Content, Activity, Social, Interest |
| `features/soul_connect/widgets/swipe_card.dart` | **[NEW]** Widget | Drag-to-swipe card stack, overlay indicators (💜/❌), behind-card parallax |
| `services/soul_service.dart` | **[NEW]** Service | SoulConnectService: getSuggestions(), respondToConnection() + mock data |

**Files REFACTORED:**

| File | Thay đổi |
|---|---|
| `features/soul_connect/screens/soul_connect_screen.dart` | **[REFACTORED]** StatelessWidget → ConsumerWidget, AsyncValue handling (loading/error/data), info bottom sheet |

**API Endpoints sử dụng:**

| Method | Endpoint | Mô tả |
|---|---|---|
| `POST` | `/api/v1/soul/suggestions` | Lấy AI-curated suggestions (limit: 10) |
| Firestore | `soul_connections/{id}` | Accept/Reject connection |

**Trạng thái:** Hiện dùng **mock data**. Khi backend FastAPI ready → chỉ cần uncomment code trong `SoulConnectService`.

---

### 2.3 Emotional Waves Module

**Files MỚI tạo:**

| File | Loại | Mô tả |
|---|---|---|
| `features/waves/models/wave_model.dart` | **[NEW]** Model | WaveModel, WaveMember, WaveMessage, WaveStatus enum |
| `features/waves/providers/waves_provider.dart` | **[NEW]** Provider | activeWavesProvider, waveMessagesProvider, waveMembersProvider, joinedWaveIdsProvider |
| `features/waves/screens/waves_list_screen.dart` | **[NEW]** Screen | Danh sách waves, pull-to-refresh, join/enter actions, stats header |
| `features/waves/screens/wave_chat_screen.dart` | **[NEW]** Screen | Group chat trong wave, momentum banner, member sheet |
| `features/waves/widgets/wave_card.dart` | **[NEW]** Widget | Card với emotion gradient, momentum bar, time remaining, join button |
| `features/waves/widgets/wave_momentum_bar.dart` | **[NEW]** Widget | Animated color-coded progress bar (green/yellow/red) |
| `features/waves/widgets/wave_member_list.dart` | **[NEW]** Widget | Stacked AuraRing avatars + expandable member list |

**Firestore Collections:**
- `waves/{waveId}` – Wave metadata, momentum, status
- `waves/{waveId}/members/{userId}` – Member info
- RTDB `wave_messages/{waveId}/{messageId}` – Live chat

---

### 2.4 Search Module

**Files MỚI tạo:**

| File | Loại | Mô tả |
|---|---|---|
| `features/search/screens/search_screen.dart` | **[NEW]** Screen | Search input, emotion filter chips, trending users, results list |
| `features/search/widgets/user_tile.dart` | **[NEW]** Widget | User tile: AuraRing avatar, name, bio, emotion badge, online dot |

---

## 3. Infrastructure (Shared)

**Files MỚI tạo cho toàn hệ thống:**

| File | Mô tả |
|---|---|
| `core/services/api_service.dart` | AuraApiService: Dio HTTP client + Firebase Auth token interceptor |
| `providers/api_service_provider.dart` | Global Riverpod provider cho AuraApiService singleton |

---

## 4. Router Updates

**File MODIFIED:** `core/router/app_router.dart`

Thêm routes mới:

```dart
// Waves (Person 3)
GoRoute(path: '/waves', builder: ... => WavesListScreen()),
GoRoute(path: '/wave/:waveId', builder: ... => WaveChatScreen()),

// Search (Person 3) 
GoRoute(path: '/search', builder: ... => SearchScreen()),
```

---

## 5. Design System Tuân Thủ

Tất cả files Person 3 tạo đều tuân thủ:

- ✅ `AuraColors` – Không hardcode màu
- ✅ `AuraTypography` – Font Inter via Google Fonts
- ✅ `AuraRing` – Widget avatar cốt lõi
- ✅ `EmotionGradients` – Gradient theo cảm xúc
- ✅ `flutter_animate` – Micro-animations
- ✅ `flutter_riverpod` – State management
- ✅ `go_router` – Navigation
- ✅ Dark mode first

---

## 6. Mock Data → Production Swap Guide

Tất cả modules hiện dùng **mock data** (consistent với pattern của Chat module). Khi backend sẵn sàng:

### Soul Connect
```dart
// Trong services/soul_service.dart
// Uncomment HTTP call, xóa mock data:
final response = await _api.dio.post('/api/v1/soul/suggestions', data: {
  'limit': limit,
});
return (response.data['suggestions'] as List)
    .map((s) => SoulSuggestion.fromMap(s))
    .toList();
```

### Waves
```dart
// Trong features/waves/providers/waves_provider.dart
// Replace FutureProvider bằng StreamProvider từ Firestore:
final activeWavesProvider = StreamProvider<List<WaveModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('waves')
      .where('status', whereIn: ['forming', 'active', 'fading'])
      .snapshots()
      .map((snap) => snap.docs.map((d) => WaveModel.fromFirestore(d)).toList());
});
```

### Search
```dart
// Trong features/search/screens/search_screen.dart
// Replace mock search bằng Firestore query hoặc Algolia/Typesense
```

---

## 7. Tổng Kết

### Files mới tạo: 16 files

| # | Path |
|---|---|
| 1 | `core/services/api_service.dart` |
| 2 | `providers/api_service_provider.dart` |
| 3 | `services/soul_service.dart` |
| 4 | `features/soul_connect/models/soul_connection_model.dart` |
| 5 | `features/soul_connect/providers/soul_provider.dart` |
| 6 | `features/soul_connect/widgets/soul_card.dart` |
| 7 | `features/soul_connect/widgets/compatibility_breakdown.dart` |
| 8 | `features/soul_connect/widgets/swipe_card.dart` |
| 9 | `features/waves/models/wave_model.dart` |
| 10 | `features/waves/providers/waves_provider.dart` |
| 11 | `features/waves/screens/waves_list_screen.dart` |
| 12 | `features/waves/screens/wave_chat_screen.dart` |
| 13 | `features/waves/widgets/wave_card.dart` |
| 14 | `features/waves/widgets/wave_momentum_bar.dart` |
| 15 | `features/waves/widgets/wave_member_list.dart` |
| 16 | `features/search/screens/search_screen.dart` |
| 17 | `features/search/widgets/user_tile.dart` |

### Files sửa đổi: 2 files

| # | Path | Thay đổi |
|---|---|---|
| 1 | `features/soul_connect/screens/soul_connect_screen.dart` | Full refactor: static → dynamic Riverpod |
| 2 | `core/router/app_router.dart` | Thêm routes: /waves, /wave/:id, /search |

### Analysis Results
- **0 errors** ✅
- **0 warnings từ code Person 3** ✅ (2 warnings từ code người khác)
- **5 infos** (style suggestions, không ảnh hưởng runtime)
