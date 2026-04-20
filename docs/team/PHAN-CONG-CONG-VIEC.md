# AURA Social – Phân Công Công Việc Nhóm 4 Người (v2)

> **Dự án:** AURA Social – Ambient Emotional Intelligence Social Platform  
> **Kiến trúc:** Hybrid (Firebase + FastAPI + Cloudflare R2)  
> **Nhóm:** 4 người (1 Leader + 3 Developer)

---

## 1. Nguyên Tắc Phân Công

- **Leader** đảm nhận toàn bộ **hệ thống cốt lõi**: AI/ML, Backend, Firebase, DevOps
- **3 Developer** tập trung vào **Flutter app**: hoàn thiện chức năng, UX, mở rộng tính năng
- Chia theo **feature domain** → mỗi người sở hữu phần của mình
- Code review chéo: Leader review tất cả PR trước khi merge

---

## 2. Phase 0: Leader Setup Hạ Tầng ✅ ĐÃ XONG

| # | Task | Status |
|---|---|---|
| 1 | Tạo Flutter project + Design System + 5 screens skeleton | ✅ |
| 2 | Brand Identity Kit (logo, app icon, splash) | ✅ |
| 3 | Tạo Firebase project (Auth, Firestore, RTDB, FCM) | ✅ |
| 4 | Firebase ↔ Flutter integration (FlutterFire CLI) | ✅ |
| 5 | FastAPI backend skeleton + R2 storage | ✅ |
| 6 | Git repo + push | ✅ |

---

## 3. Phân Công Chi Tiết

---

### 👑 LEADER – AI/ML + Backend + Infrastructure + DevOps

**Trách nhiệm:** Toàn bộ hệ thống cốt lõi – AI training, FastAPI backend, Firebase infrastructure, Cloud Functions, deployment, code review.

#### A. Firebase Infrastructure

| # | Task | File/Location | Priority |
|---|---|---|---|
| 1 | Firestore: Security Rules cho `users`, `posts`, `comments` | `firestore.rules` | 🔴 |
| 2 | Firestore: Security Rules cho `waves`, `soul_connections` | `firestore.rules` | 🔴 |
| 3 | Firestore: Security Rules cho `conversations`, `notifications` | `firestore.rules` | 🔴 |
| 4 | Firestore: Subcollections `emotion_profile`, `behavioral_events`, `feed_cache` | `firestore.rules` | 🔴 |
| 5 | Firestore: Composite indexes | `firestore.indexes.json` | 🔴 |
| 6 | RTDB: Schema `messages`, `presence`, `typing`, `wave_messages` | `database.rules.json` | 🔴 |
| 7 | Cloudflare R2: Bucket + CORS + public access | Dashboard | ✅ |

#### B. Cloud Functions (Event Triggers)

| # | Task | File | Priority |
|---|---|---|---|
| 8 | `on_user_created` → init user doc + emotion profile | `functions/main.py` | 🔴 |
| 9 | `on_user_deleted` → GDPR cascade delete | `functions/main.py` | 🔴 |
| 10 | `on_new_post` → call FastAPI `/content/analyze` | `functions/main.py` | 🔴 |
| 11 | `on_new_message` → push notification | `functions/main.py` | 🔴 |
| 12 | `on_follow` → update counts + notify | `functions/main.py` | 🟡 |
| 13 | `trigger_soul_compute` → call FastAPI (30min cron) | `functions/main.py` | 🟡 |
| 14 | `trigger_wave_detect` → call FastAPI (15min cron) | `functions/main.py` | 🟡 |
| 15 | `cleanup_behavioral_events` → delete > 30 days | `functions/main.py` | 🟢 |

#### C. FastAPI AI Backend

| # | Task | File | Priority |
|---|---|---|---|
| 16 | Firebase Admin SDK init + auth middleware | `app/config.py`, `app/auth.py` | ✅ |
| 17 | R2 Storage service + upload router | `app/services/storage.py` | ✅ |
| 18 | ML: Model Loader (HuggingFace Transformers) | `app/ml/model_loader.py` | 🔴 |
| 19 | ML: Vector math (cosine similarity, fusion) | `app/ml/vector_math.py` | ✅ |
| 20 | Service: Content Analyzer (sentiment + embedding) | `app/services/content_analyzer.py` | 🔴 |
| 21 | Service: Emotion Inference (5-layer + fusion) | `app/services/emotion_inference.py` | 🔴 |
| 22 | Service: Emotional Mode Detection | `app/services/emotion_inference.py` | 🔴 |
| 23 | Service: Recommendation (candidate → scoring → ranking) | `app/services/recommendation.py` | 🔴 |
| 24 | Service: Recommendation (emotional balancing) | `app/services/recommendation.py` | 🟡 |
| 25 | Service: Soul Connect (compatibility scoring) | `app/services/soul_connect.py` | 🟡 |
| 26 | Service: Wave Generator (DBSCAN clustering) | `app/services/wave_generator.py` | 🟡 |
| 27 | Service: Wellbeing Guard | `app/services/wellbeing_guard.py` | 🟡 |
| 28 | Router: POST /emotion/infer | `app/routers/emotion.py` | 🔴 |
| 29 | Router: POST /feed/generate | `app/routers/feed.py` | 🔴 |
| 30 | Router: POST /content/analyze | `app/routers/content.py` | 🔴 |
| 31 | Router: POST /soul/compute + /suggestions | `app/routers/soul.py` | 🟡 |
| 32 | Router: POST /waves/detect | `app/routers/waves.py` | 🟡 |
| 33 | Router: POST /wellbeing/check | `app/routers/wellbeing.py` | 🟡 |

#### D. DevOps & Deployment

| # | Task | File | Priority |
|---|---|---|---|
| 34 | Deploy Firebase rules + Cloud Functions | CLI | 🔴 |
| 35 | Deploy FastAPI → Cloud Run (Docker) | Dockerfile | 🔴 |
| 36 | Code review tất cả PRs | Git | 🔴 |

**Deliverables:**
- [ ] Tất cả AI endpoints trả dữ liệu thực (không mock)
- [ ] HuggingFace model loads + inference thành công
- [ ] Firestore + RTDB rules deployed
- [ ] Cloud Functions deployed
- [ ] FastAPI deployed trên Cloud Run

---

### 📱 Person 2 – Flutter Core UI (Auth + Feed + Post + Profile)

**Trách nhiệm:** Authentication flow, Feed hiển thị, Tạo/xem post, Profile + Aura Ring, kết nối dữ liệu từ backend.

#### Task List:

| # | Task | File | Priority |
|---|---|---|---|
| 1 | AuraApiService: Dio + Firebase token interceptor | `core/services/api_service.dart` | 🔴 |
| 2 | Models: UserModel (fromFirestore, toFirestore) | `shared/models/user_model.dart` | 🔴 |
| 3 | Models: PostModel | `features/feed/models/post_model.dart` | 🔴 |
| 4 | Models: EmotionProfileModel | `shared/models/emotion_profile_model.dart` | 🔴 |
| 5 | Provider: Auth state (Firebase Auth stream) | `providers/auth_state_provider.dart` | 🔴 |
| 6 | Provider: User profile (Firestore stream) | `providers/user_profile_provider.dart` | 🔴 |
| 7 | Provider: Emotion profile stream | `providers/emotion_profile_provider.dart` | 🔴 |
| 8 | Screen: Login (Email + Google Sign-In) | `features/auth/screens/login_screen.dart` | 🔴 |
| 9 | Screen: Register + privacy consent | `features/auth/screens/register_screen.dart` | 🔴 |
| 10 | Screen: Onboarding (giới thiệu app) | `features/auth/screens/onboarding_screen.dart` | 🟡 |
| 11 | GoRouter: Auth guard (redirect khi chưa login) | `core/router/app_router.dart` | 🔴 |
| 12 | Screen: For You Feed (gọi FastAPI → hiển thị) | `features/feed/screens/feed_screen.dart` | 🔴 |
| 13 | Screen: Following Feed (Firestore query) | `features/feed/screens/feed_screen.dart` | 🟡 |
| 14 | Widget: Post Card (kết nối dữ liệu thực) | `features/feed/widgets/post_card.dart` | 🔴 |
| 15 | Widget: Emotion Reaction Bar (ghi reaction Firestore) | `features/feed/widgets/emotion_reaction_bar.dart` | 🔴 |
| 16 | Screen: Create Post (text + image + mood picker) | `features/post/screens/create_post_screen.dart` | 🔴 |
| 17 | Upload ảnh post → FastAPI → R2 | `features/post/screens/create_post_screen.dart` | 🔴 |
| 18 | Screen: Post Detail + Comments | `features/post/screens/post_detail_screen.dart` | 🟡 |
| 19 | Widget: Aura Ring (kết nối emotion vector thực) | `shared/widgets/aura_ring_widget.dart` | 🔴 |
| 20 | Screen: Profile (Firestore data + stats + post grid) | `features/profile/screens/profile_screen.dart` | 🔴 |
| 21 | Screen: Edit Profile (update avatar → R2) | `features/profile/screens/edit_profile_screen.dart` | 🟡 |
| 22 | Screen: Other User Profile (follow/unfollow) | `features/profile/screens/user_profile_screen.dart` | 🟡 |
| 23 | Widget: Loading/Error shared widgets | `shared/widgets/` | 🟡 |

**Deliverables:**
- [ ] Auth flow hoàn chỉnh (register → login → home → logout)
- [ ] Feed hiển thị posts từ Firestore/FastAPI
- [ ] Tạo post với ảnh upload lên R2
- [ ] Reaction ghi vào Firestore
- [ ] Aura Ring renders theo emotion vector thực
- [ ] Profile + Edit profile hoàn chỉnh

---

### 💬 Person 3 – Flutter Social (Chat + Soul Connect + Waves)

**Trách nhiệm:** Chat real-time, Soul Connect matching UI, Emotional Waves, kết nối dữ liệu từ RTDB/Firestore.

#### Task List:

| # | Task | File | Priority |
|---|---|---|---|
| 1 | Model: MessageModel | `features/chat/models/message_model.dart` | 🔴 |
| 2 | Model: ConversationModel | `features/chat/models/conversation_model.dart` | 🔴 |
| 3 | Provider: Chat (RTDB stream) | `features/chat/providers/chat_provider.dart` | 🔴 |
| 4 | Provider: Presence (online/offline) | `features/chat/providers/presence_provider.dart` | 🔴 |
| 5 | Screen: Conversations List | `features/chat/screens/conversations_list_screen.dart` | 🔴 |
| 6 | Screen: Chat (send/receive real-time) | `features/chat/screens/chat_screen.dart` | 🔴 |
| 7 | Widget: Message Bubble (text + emotion tint) | `features/chat/widgets/message_bubble.dart` | 🔴 |
| 8 | Widget: Typing Indicator | `features/chat/widgets/typing_indicator.dart` | 🟡 |
| 9 | Widget: Chat Input (text + emoji + image) | `features/chat/widgets/chat_input.dart` | 🔴 |
| 10 | Service: Soul Service (calls FastAPI) | `services/soul_service.dart` | 🟡 |
| 11 | Provider: Soul Connect (FastAPI data) | `features/soul_connect/providers/soul_provider.dart` | 🟡 |
| 12 | Screen: Soul Connect (hiển thị suggestions) | `features/soul_connect/screens/soul_connect_screen.dart` | 🟡 |
| 13 | Widget: Soul Card (accept/reject animation) | `features/soul_connect/widgets/soul_card.dart` | 🟡 |
| 14 | Widget: Compatibility Breakdown (radar chart) | `features/soul_connect/widgets/compatibility_breakdown.dart` | 🟢 |
| 15 | Provider: Waves (Firestore stream) | `features/waves/providers/waves_provider.dart` | 🟡 |
| 16 | Screen: Waves List (hiển thị nhóm) | `features/waves/screens/waves_list_screen.dart` | 🟡 |
| 17 | Screen: Wave Group Chat | `features/waves/screens/wave_chat_screen.dart` | 🟡 |
| 18 | Widget: Wave Card + Momentum Bar | `features/waves/widgets/` | 🟡 |
| 19 | Screen: Search Users | `features/search/screens/search_screen.dart` | 🟡 |
| 20 | Widget: User Search Result Tile | `features/search/widgets/user_tile.dart` | 🟡 |

**Deliverables:**
- [ ] Chat 1-1 real-time hoạt động (gửi/nhận/typing)
- [ ] Online/Offline presence indicator
- [ ] Soul Connect hiển thị + accept/reject
- [ ] Waves list + join/leave + group chat
- [ ] Search users + view profile

---

### ⚙️ Person 4 – Flutter UX & Features (Notifications + Settings + Tracking + Polish)

**Trách nhiệm:** Behavioral tracker, Notifications, Settings, Emotional Compass, UX polish, testing, animations.

#### Task List:

| # | Task | File | Priority |
|---|---|---|---|
| 1 | ★ Behavioral Tracker (event buffer + 30s batch) | `services/behavioral_tracker.dart` | 🔴 |
| 2 | Provider: Behavioral tracker | `providers/behavioral_tracker_provider.dart` | 🔴 |
| 3 | Service: Feed Service (calls FastAPI /feed/generate) | `services/feed_service.dart` | 🔴 |
| 4 | Service: Wellbeing Service (calls FastAPI) | `services/wellbeing_service.dart` | 🟡 |
| 5 | FCM: Push notification setup + handler | `services/fcm_service.dart` | 🔴 |
| 6 | Provider: Notifications (Firestore stream) | `features/notifications/providers/notification_provider.dart` | 🟡 |
| 7 | Screen: Notifications | `features/notifications/screens/notifications_screen.dart` | 🟡 |
| 8 | Widget: Notification Tile (reaction, follow, message) | `features/notifications/widgets/notification_tile.dart` | 🟡 |
| 9 | Screen: Settings | `features/settings/screens/settings_screen.dart` | 🟡 |
| 10 | Screen: AI Settings (toggle features ON/OFF) | `features/settings/screens/ai_settings_screen.dart` | 🟡 |
| 11 | Screen: Privacy Settings (data export, delete account) | `features/settings/screens/privacy_settings_screen.dart` | 🟢 |
| 12 | Screen: Emotional Compass (radar chart + timeline) | `features/compass/screens/emotional_compass_screen.dart` | 🟢 |
| 13 | Widget: Emotion Radar Chart (fl_chart) | `features/compass/widgets/emotion_radar_chart.dart` | 🟢 |
| 14 | Widget: Emotion Timeline (7-day trend) | `features/compass/widgets/emotion_timeline.dart` | 🟢 |
| 15 | Widget: AI Insight Card | `features/compass/widgets/ai_insight_card.dart` | 🟢 |
| 16 | Widget: Wellbeing Break Card | `features/wellbeing/widgets/break_card.dart` | 🟢 |
| 17 | Widget: AI Status Bar "🤖 Đang hiểu bạn..." | `shared/widgets/ai_status_bar.dart` | 🟡 |
| 18 | UX: Micro-animations cho Post Card, Feed transitions | Across features | 🟡 |
| 19 | UX: Pull-to-refresh, infinite scroll, shimmer loading | Across features | 🟡 |
| 20 | UX: Dark/Light theme toggle | `core/theme/` | 🟢 |
| 21 | Testing: Widget tests cho shared components | `test/` | 🟡 |
| 22 | Testing: Integration tests cho auth flow | `test/` | 🟢 |

**Deliverables:**
- [ ] Behavioral tracker ghi events mỗi 30s
- [ ] Push notifications hiển thị
- [ ] Settings screens hoạt động
- [ ] Emotional Compass với radar chart + timeline
- [ ] UX polish: animations, loading states, error handling
- [ ] Widget tests pass

---

## 4. Dependency Map

```
Phase 0 (Leader setup) ✅ ĐÃ XONG
    │
    ├──► 👑 Leader: Firebase Rules + CF + AI Backend
    │         ├── Firestore Rules → unblock Person 2, 3, 4
    │         ├── FastAPI endpoints → unblock Person 2 (feed), Person 4 (tracker)
    │         └── Cloud Functions → auto-process data
    │
    ├──► 📱 Person 2: Flutter Core UI
    │         ├── Auth flow + Models → unblock Person 3, 4
    │         ├── api_service.dart → Person 3, 4 dùng chung
    │         └── Feed CẦN FastAPI URL từ Leader
    │
    ├──► 💬 Person 3: Flutter Social
    │         ├── Cần shared code từ Person 2 (models, api_service)
    │         └── Soul Connect CẦN FastAPI từ Leader
    │
    └──► ⚙️ Person 4: Flutter UX
              ├── Cần shared code từ Person 2
              ├── Behavioral tracker CẦN FastAPI từ Leader
              └── Notifications CẦN Cloud Functions từ Leader
```

**Giảm blocking:**
1. **Leader** push Firestore Rules SỚM NHẤT → unblock tất cả
2. **Person 2** push shared code (models, api_service) SỚM NHẤT → Person 3, 4 cần
3. Dùng **mock data** khi chờ backend: Person 2, 3, 4 build UI trước

---

## 5. Tổng Kết Workload

| Người | Phạm vi | Số tasks | Focus |
|---|---|---|---|
| 👑 Leader | AI/ML + Backend + Firebase + DevOps | 36 | Hệ thống cốt lõi |
| 📱 Person 2 | Flutter Core UI | 23 | Auth + Feed + Post + Profile |
| 💬 Person 3 | Flutter Social | 20 | Chat + Soul + Waves + Search |
| ⚙️ Person 4 | Flutter UX & Features | 22 | Tracking + Notifs + Settings + Polish |

> **Leader** gánh nhiều nhất về mặt technical depth. Team 3 người chia đều UI features.

---

## 6. Quy Tắc Làm Việc

| Quy tắc | Chi tiết |
|---|---|
| **Branching** | Mỗi task = 1 branch: `feature/P2-login-screen`, `feature/P3-chat-system` |
| **PR naming** | `[P2] Implement login screen with Google Sign-In` |
| **Code review** | Leader review tất cả. Ít nhất 1 approve trước merge |
| **Communication** | Báo khi push shared code để người khác pull |
| **Mock data** | Dùng mock khi chờ backend, replace sau |
| **Daily sync** | Report tiến độ hàng ngày (tasks done / tasks blocked) |

---

## 7. Timeline Gợi Ý

```
Tuần 1: ──────────────────────────────────────
  👑 Leader: Firestore Rules + CF + API endpoints (emotion, feed, content)
  📱 P2:    Auth flow (login → register → home) + Models + api_service
  💬 P3:    Chat system (RTDB real-time) + Message UI
  ⚙️ P4:    Behavioral tracker + FCM setup + Notification screen

Tuần 2: ──────────────────────────────────────
  👑 Leader: AI training + Soul Connect API + Waves API
  📱 P2:    Feed (Firestore + FastAPI) + Create Post + Upload ảnh
  💬 P3:    Soul Connect UI + Waves UI + Search
  ⚙️ P4:    Settings screens + Emotional Compass

Tuần 3: ──────────────────────────────────────
  👑 Leader: Wellbeing Guard + Deploy Cloud Run + CI/CD
  📱 P2:    Profile + Edit Profile + Post Detail
  💬 P3:    Polish chat + Group chat (Waves)
  ⚙️ P4:    UX polish + Animations + Testing

Tuần 4: ──────────────────────────────────────
  ALL:     Integration testing + Bug fixes + Demo preparation
```
