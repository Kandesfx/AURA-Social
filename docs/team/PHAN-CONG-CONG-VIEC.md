# AURA Social – Phân Công Công Việc Nhóm 4 Người

> **Dự án:** AURA Social – Ambient Emotional Intelligence Social Platform  
> **Kiến trúc:** Hybrid (Firebase + FastAPI)  
> **Nhóm:** 4 người (1 Leader + 3 Developer)

---

## 1. Nguyên Tắc Phân Công

- Chia theo **feature domain** → mỗi người sở hữu toàn bộ phần của mình
- Leader setup hạ tầng trước (Phase 0), sau đó 4 người làm **song song**
- Tất cả dùng AI Agent coding → chia đều task, không chia theo thời gian
- Code review chéo: Leader review tất cả PR trước khi merge

---

## 2. Phase 0: Leader Setup Hạ Tầng

> ⚠️ **Chỉ Leader làm.** 3 người còn lại chờ Leader push code lên Git.

| # | Task | Output |
|---|---|---|
| 1 | Tạo Firebase project trên console | Project ID + config files |
| 2 | Bật Auth (Google, Email), Firestore, RTDB, Storage, FCM | All services enabled |
| 3 | Tải `google-services.json` + `GoogleService-Info.plist` | Config files cho Flutter |
| 4 | Tạo Service Account key | `service-account.json` cho FastAPI |
| 5 | Tạo Flutter project từ Android Studio | Base Flutter project |
| 6 | Init FastAPI skeleton | `main.py`, `auth.py`, `config.py` |
| 7 | Init Cloud Functions | `firebase init functions` |
| 8 | Setup Git repo + branching | `main`, `dev`, `feature/*` branches |
| 9 | Push tất cả lên Git | Team clone và bắt đầu |

**Cấu trúc repo sau Phase 0:**
```
AURA-Social/
├── docs/                         ← Tài liệu (đã có)
│   ├── AURA-System-Design/       ← 8 tài liệu thiết kế
│   ├── team/                     ← Phân công công việc
│   └── ui-mockups/               ← Giao diện mẫu
│
├── app/                          ← Person 3 + 4 làm
│   ├── lib/
│   │   ├── core/                 ← Theme, router, services
│   │   ├── features/             ← Feature modules
│   │   ├── shared/               ← Shared widgets, models
│   │   └── providers/            ← Global providers
│   ├── pubspec.yaml
│   └── ...
│
├── fastapi-backend/              ← Person 2 làm
│   ├── main.py
│   ├── app/
│   │   ├── routers/
│   │   ├── services/
│   │   ├── models/
│   │   └── ml/
│   ├── Dockerfile
│   └── requirements.txt
│
├── firebase/                     ← Leader làm
│   ├── functions/
│   ├── firestore.rules
│   └── database.rules.json
│
└── README.md
```

---

## 3. Phân Công Chi Tiết (Song Song)

---

### 👑 Person 1: LEADER – Firebase Infrastructure + Cloud Functions + DevOps

**Trách nhiệm:** Database schema, security rules, event triggers, deployment, code review.

#### Task List:

| # | Task | File/Location | Priority |
|---|---|---|---|
| 1 | Firestore: Tạo collection `users` | `firestore.rules` | 🔴 |
| 2 | Firestore: Tạo collection `posts` | `firestore.rules` | 🔴 |
| 3 | Firestore: Tạo collection `comments` | `firestore.rules` | 🔴 |
| 4 | Firestore: Tạo collection `waves` + `waves/{id}/members` | `firestore.rules` | 🔴 |
| 5 | Firestore: Tạo collection `soul_connections` | `firestore.rules` | 🔴 |
| 6 | Firestore: Tạo collection `conversations` | `firestore.rules` | 🔴 |
| 7 | Firestore: Tạo collection `notifications` | `firestore.rules` | 🟡 |
| 8 | Firestore: Tạo collection `reports` | `firestore.rules` | 🟡 |
| 9 | Firestore: Tạo subcollection `users/{uid}/emotion_profile` | `firestore.rules` | 🔴 |
| 10 | Firestore: Tạo subcollection `users/{uid}/behavioral_events` | `firestore.rules` | 🔴 |
| 11 | Firestore: Tạo subcollection `users/{uid}/feed_cache` | `firestore.rules` | 🟡 |
| 12 | Firestore: Composite indexes | `firestore.indexes.json` | 🔴 |
| 13 | RTDB: Schema `messages`, `presence`, `typing`, `wave_messages` | `database.rules.json` | 🔴 |
| 14 | Storage: Upload rules (avatar, post media) | `storage.rules` | 🟡 |
| 15 | CF: `on_user_created` → init user doc + emotion profile | `functions/main.py` | 🔴 |
| 16 | CF: `on_user_deleted` → GDPR cascade delete | `functions/main.py` | 🔴 |
| 17 | CF: `on_new_post` → call FastAPI `/content/analyze` | `functions/main.py` | 🔴 |
| 18 | CF: `on_new_message` → push notification | `functions/main.py` | 🔴 |
| 19 | CF: `on_follow` → update counts + notify | `functions/main.py` | 🟡 |
| 20 | CF: `on_wave_member_change` → update count | `functions/main.py` | 🟡 |
| 21 | CF: `trigger_soul_compute` → call FastAPI (30min) | `functions/main.py` | 🟡 |
| 22 | CF: `trigger_wave_detect` → call FastAPI (15min) | `functions/main.py` | 🟡 |
| 23 | CF: `cleanup_behavioral_events` → delete > 30 days | `functions/main.py` | 🟡 |
| 24 | CF: `cleanup_expired_waves` → archive dead waves | `functions/main.py` | 🟢 |
| 25 | Deploy Firebase (rules + functions) | CLI | 🔴 |
| 26 | Deploy FastAPI → Cloud Run | Dockerfile | 🔴 |
| 27 | Code review tất cả PRs | Git | 🔴 |

**Deliverables:**
- [ ] Firestore + RTDB rules deployed
- [ ] Tất cả Cloud Functions deployed
- [ ] CI/CD pipeline hoạt động

---

### 🤖 Person 2: FastAPI AI Backend

**Trách nhiệm:** Toàn bộ AI server, ML models, REST API endpoints.

#### Task List:

| # | Task | File | Priority |
|---|---|---|---|
| 1 | Firebase Admin SDK init | `app/config.py` | 🔴 |
| 2 | Auth: `verify_firebase_token` | `app/auth.py` | 🔴 |
| 3 | Auth: `verify_internal_key` | `app/auth.py` | 🔴 |
| 4 | Pydantic: EmotionInferRequest/Response | `app/models/emotion.py` | 🔴 |
| 5 | Pydantic: FeedRequest/Response | `app/models/feed.py` | 🔴 |
| 6 | Pydantic: SoulRequest/Response | `app/models/soul.py` | 🟡 |
| 7 | Pydantic: ContentAnalysisRequest/Response | `app/models/content.py` | 🔴 |
| 8 | Pydantic: WellbeingRequest/Response | `app/models/wellbeing.py` | 🟡 |
| 9 | ML: Model Loader (HuggingFace) | `app/ml/model_loader.py` | 🔴 |
| 10 | ML: Vector math (cosine similarity, fusion) | `app/ml/vector_math.py` | 🔴 |
| 11 | Service: Content Analyzer (sentiment + embedding) | `app/services/content_analyzer.py` | 🔴 |
| 12 | Service: Emotion Inference (5-layer + fusion) | `app/services/emotion_inference.py` | 🔴 |
| 13 | Service: Emotional Mode Detection | `app/services/emotion_inference.py` | 🔴 |
| 14 | Service: Recommendation (candidate gen) | `app/services/recommendation.py` | 🔴 |
| 15 | Service: Recommendation (scoring + ranking) | `app/services/recommendation.py` | 🔴 |
| 16 | Service: Recommendation (emotional balancing) | `app/services/recommendation.py` | 🟡 |
| 17 | Service: Soul Connect (compatibility scoring) | `app/services/soul_connect.py` | 🟡 |
| 18 | Service: Wave Generator (DBSCAN clustering) | `app/services/wave_generator.py` | 🟡 |
| 19 | Service: Wellbeing Guard | `app/services/wellbeing_guard.py` | 🟡 |
| 20 | Service: Prompt Assistant | `app/services/prompt_assistant.py` | 🟢 |
| 21 | Router: POST /emotion/infer | `app/routers/emotion.py` | 🔴 |
| 22 | Router: POST /feed/generate | `app/routers/feed.py` | 🔴 |
| 23 | Router: POST /soul/compute + /suggestions | `app/routers/soul.py` | 🟡 |
| 24 | Router: POST /content/analyze | `app/routers/content.py` | 🔴 |
| 25 | Router: POST /waves/detect | `app/routers/waves.py` | 🟡 |
| 26 | Router: POST /wellbeing/check | `app/routers/wellbeing.py` | 🟡 |
| 27 | Rate limiting (slowapi) | `main.py` | 🟡 |
| 28 | Dockerfile + requirements.txt | Root | 🔴 |
| 29 | Unit tests (core modules) | `tests/` | 🟡 |

**Deliverables:**
- [ ] 7 API endpoints hoạt động
- [ ] HuggingFace model loads thành công
- [ ] Emotion inference trả đúng 8D vector
- [ ] Deployed trên Cloud Run

---

### 📱 Person 3: Flutter Core UI (Auth + Feed + Post + Profile)

**Trách nhiệm:** Design system, authentication, feed, post CRUD, profile, Aura Ring.

#### Task List:

| # | Task | File | Priority |
|---|---|---|---|
| 1 | Design System: Color palette + emotion colors | `core/theme/app_colors.dart` | 🔴 |
| 2 | Design System: Typography | `core/theme/app_typography.dart` | 🔴 |
| 3 | Design System: ThemeData | `core/theme/app_theme.dart` | 🔴 |
| 4 | Design System: Emotion → gradient mapping | `core/theme/emotion_gradients.dart` | 🔴 |
| 5 | Constants: Emotion types enum | `core/constants/emotion_types.dart` | 🔴 |
| 6 | AuraApiService: dio + Firebase token interceptor | `core/services/api_service.dart` | 🔴 |
| 7 | GoRouter: All routes + auth guard | `core/router/app_router.dart` | 🔴 |
| 8 | Models: UserModel | `shared/models/user_model.dart` | 🔴 |
| 9 | Models: PostModel | `features/feed/models/post_model.dart` | 🔴 |
| 10 | Models: EmotionProfileModel | `shared/models/emotion_profile_model.dart` | 🔴 |
| 11 | Provider: Auth state (Firebase Auth stream) | `providers/auth_state_provider.dart` | 🔴 |
| 12 | Provider: User profile (Firestore stream) | `providers/user_profile_provider.dart` | 🔴 |
| 13 | Provider: Emotion profile stream | `providers/emotion_profile_provider.dart` | 🔴 |
| 14 | Screen: Login | `features/auth/screens/login_screen.dart` | 🔴 |
| 15 | Screen: Register + privacy consent | `features/auth/screens/register_screen.dart` | 🔴 |
| 16 | Screen: Onboarding (no forced mood!) | `features/auth/screens/onboarding_screen.dart` | 🟡 |
| 17 | Screen: For You Feed (infinite scroll → FastAPI) | `features/feed/screens/for_you_feed_screen.dart` | 🔴 |
| 18 | Screen: Following Feed (Firestore query) | `features/feed/screens/following_feed_screen.dart` | 🟡 |
| 19 | Widget: Post Card | `features/feed/widgets/post_card.dart` | 🔴 |
| 20 | Widget: Emotion Reaction Bar (8 emotions) | `features/feed/widgets/emotion_reaction_bar.dart` | 🔴 |
| 21 | Widget: Feed Tab Bar | `features/feed/widgets/feed_tab_bar.dart` | 🟡 |
| 22 | Screen: Create Post (text + image + mood) | `features/post/screens/create_post_screen.dart` | 🔴 |
| 23 | Screen: Post Detail (comments) | `features/post/screens/post_detail_screen.dart` | 🟡 |
| 24 | Widget: ★ Aura Ring (gradient animation) | `shared/widgets/aura_ring_widget.dart` | 🔴 |
| 25 | Screen: Profile + Aura Ring + stats + grid | `features/profile/screens/profile_screen.dart` | 🔴 |
| 26 | Screen: Edit Profile | `features/profile/screens/edit_profile_screen.dart` | 🟡 |
| 27 | Widget: AI Status Bar "🤖 Đang hiểu bạn..." | `shared/widgets/ai_status_bar.dart` | 🟢 |
| 28 | Widget: Loading + Error shared widgets | `shared/widgets/` | 🟡 |

**Deliverables:**
- [ ] Auth flow hoàn chỉnh (register → login → home)
- [ ] Feed hiển thị posts
- [ ] Tạo/xem/xóa post
- [ ] Aura Ring renders theo emotion vector
- [ ] Profile screen hoàn chỉnh

---

### 💬 Person 4: Flutter Social (Chat + Soul + Waves + Settings)

**Trách nhiệm:** Chat real-time, Soul Connect UI, Emotional Waves, notifications, settings, behavioral tracker.

#### Task List:

| # | Task | File | Priority |
|---|---|---|---|
| 1 | ★ Behavioral Tracker (event buffer + 30s batch) | `services/behavioral_tracker.dart` | 🔴 |
| 2 | Service: Feed Service (calls FastAPI) | `services/feed_service.dart` | 🔴 |
| 3 | Service: Soul Service (calls FastAPI) | `services/soul_service.dart` | 🟡 |
| 4 | Service: Wellbeing Service (calls FastAPI) | `services/wellbeing_service.dart` | 🟡 |
| 5 | Provider: Behavioral tracker | `providers/behavioral_tracker_provider.dart` | 🔴 |
| 6 | Model: MessageModel | `features/chat/models/message_model.dart` | 🔴 |
| 7 | Provider: Chat (RTDB stream) | `features/chat/providers/chat_provider.dart` | 🔴 |
| 8 | Provider: Presence (online/offline) | `features/chat/providers/presence_provider.dart` | 🔴 |
| 9 | Screen: Conversations List | `features/chat/screens/conversations_list_screen.dart` | 🔴 |
| 10 | Screen: Chat (send/receive/typing) | `features/chat/screens/chat_screen.dart` | 🔴 |
| 11 | Widget: Message Bubble | `features/chat/widgets/message_bubble.dart` | 🔴 |
| 12 | Widget: Typing Indicator | `features/chat/widgets/typing_indicator.dart` | 🟡 |
| 13 | Widget: Chat Input | `features/chat/widgets/chat_input.dart` | 🔴 |
| 14 | Provider: Soul Connect (FastAPI) | `features/soul_connect/providers/soul_provider.dart` | 🟡 |
| 15 | Screen: Soul Connect (suggestions) | `features/soul_connect/screens/soul_connect_screen.dart` | 🟡 |
| 16 | Widget: Soul Card (accept/reject) | `features/soul_connect/widgets/soul_card.dart` | 🟡 |
| 17 | Widget: Compatibility Breakdown | `features/soul_connect/widgets/compatibility_breakdown.dart` | 🟢 |
| 18 | Provider: Waves (Firestore stream) | `features/waves/providers/waves_provider.dart` | 🟡 |
| 19 | Screen: Waves List | `features/waves/screens/waves_list_screen.dart` | 🟡 |
| 20 | Screen: Wave Chat | `features/waves/screens/wave_chat_screen.dart` | 🟡 |
| 21 | Widget: Wave Card + Momentum Bar | `features/waves/widgets/` | 🟡 |
| 22 | Provider: Notifications | `features/notifications/providers/notification_provider.dart` | 🟡 |
| 23 | Screen: Notifications | `features/notifications/screens/notifications_screen.dart` | 🟡 |
| 24 | FCM: Push notification setup | `services/fcm_service.dart` | 🔴 |
| 25 | Screen: Settings | `features/settings/screens/settings_screen.dart` | 🟡 |
| 26 | Screen: AI Settings (toggle features) | `features/settings/screens/ai_settings_screen.dart` | 🟡 |
| 27 | Screen: Privacy Settings (data export, delete) | `features/settings/screens/privacy_settings_screen.dart` | 🟢 |
| 28 | Screen: Emotional Compass (radar + timeline) | `features/compass/screens/emotional_compass_screen.dart` | 🟢 |
| 29 | Widget: Wellbeing Break Card | `features/wellbeing/widgets/break_card.dart` | 🟢 |

**Deliverables:**
- [ ] Chat 1-1 real-time hoạt động
- [ ] Soul Connect hiển thị + accept/reject
- [ ] Waves list + join/leave + group chat
- [ ] Behavioral tracker ghi events mỗi 30s
- [ ] Notifications hiển thị
- [ ] AI Settings toggles hoạt động

---

## 4. Dependency Map

```
Phase 0 (Leader setup)
    │
    ├──► 👑 Leader: Firebase rules + CF
    │         └── CF on_new_post CẦN FastAPI URL từ Person 2
    │
    ├──► 🤖 Person 2: FastAPI
    │         └── Cần Firebase Service Account từ Phase 0
    │
    ├──► 📱 Person 3: Flutter Core
    │         ├── Cần Firebase configs từ Phase 0
    │         └── Feed CẦN FastAPI URL từ Person 2
    │
    └──► 💬 Person 4: Flutter Social
              ├── Cần Firebase configs từ Phase 0
              ├── Cần shared code từ Person 3 (theme, api_service)
              └── Behavioral tracker CẦN FastAPI URL từ Person 2
```

**Giảm blocking:**
1. Person 2 deploy FastAPI có `/health` endpoint SỚM NHẤT → cho team có URL
2. Person 3 push shared code (theme, api_service, models) SỚM NHẤT → Person 4 cần
3. Dùng mock data khi chờ backend: Person 3 + 4 có thể dùng fake data để build UI trước

---

## 5. Tổng Kết Workload

| Người | Phạm vi | Số tasks | Focus |
|---|---|---|---|
| 👑 Leader | Firebase + CF + DevOps | 27 | Infrastructure + Integration |
| 🤖 Person 2 | FastAPI AI Backend | 29 | AI/ML Processing |
| 📱 Person 3 | Flutter Core UI | 28 | Auth + Feed + Post + Profile |
| 💬 Person 4 | Flutter Social | 29 | Chat + Soul + Waves + Settings |

> Mỗi người ~27-29 tasks, **cân bằng workload**.

---

## 6. Quy Tắc Làm Việc

| Quy tắc | Chi tiết |
|---|---|
| **Branching** | Mỗi task = 1 branch: `feature/P2-emotion-inference`, `feature/P3-login-screen` |
| **PR naming** | `[P2] Implement emotion inference engine` |
| **Code review** | Leader review tất cả. Ít nhất 1 approve trước merge |
| **Communication** | Báo khi push shared code để người khác pull |
| **Mock data** | Dùng mock khi chờ backend, replace sau |
