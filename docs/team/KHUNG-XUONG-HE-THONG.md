# AURA Social – Khung Xương Hệ Thống (System Skeleton)

> Tài liệu này mô tả **cấu trúc file/folder** chi tiết mà Leader cần tạo trước khi team bắt đầu.
> Sau khi tạo xong, push lên Git để 3 người còn lại clone và bắt đầu làm.

---

## 1. Flutter App Skeleton

### 1.1 pubspec.yaml dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.3.0
  firebase_auth: ^5.2.0
  cloud_firestore: ^5.4.0
  firebase_database: ^11.1.0
  firebase_storage: ^12.3.0
  firebase_messaging: ^15.1.0
  firebase_analytics: ^11.3.0
  firebase_crashlytics: ^4.1.0
  firebase_remote_config: ^5.1.0

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.2.0

  # HTTP
  dio: ^5.4.3

  # UI
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7
  flutter_local_notifications: ^17.2.1
  fl_chart: ^0.68.0
  lottie: ^3.1.2
  shimmer: ^3.0.0
  flutter_animate: ^4.5.0

  # Utils
  uuid: ^4.4.0
  timeago: ^3.6.1
  intl: ^0.19.0
  shared_preferences: ^2.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
```

### 1.2 Cấu trúc thư mục Flutter

```
app/lib/
│
├── main.dart                                    # App entry point
├── app.dart                                     # MaterialApp + ProviderScope
│
├── core/                                        # ━━━ SHARED INFRASTRUCTURE ━━━
│   ├── theme/
│   │   ├── app_colors.dart                      # Bảng màu + emotion colors
│   │   ├── app_typography.dart                  # Font styles (Google Fonts)
│   │   ├── app_theme.dart                       # ThemeData (light/dark)
│   │   └── emotion_gradients.dart               # Map emotion → LinearGradient
│   │
│   ├── constants/
│   │   ├── emotion_types.dart                   # enum EmotionType { joy, trust, ... }
│   │   ├── app_constants.dart                   # API URLs, thresholds
│   │   └── asset_paths.dart                     # Image/icon paths
│   │
│   ├── router/
│   │   └── app_router.dart                      # GoRouter (tất cả routes)
│   │
│   └── services/
│       └── api_service.dart                     # AuraApiService (dio → FastAPI)
│
├── features/                                    # ━━━ FEATURE MODULES ━━━
│   │
│   ├── auth/                                    # 📱 Person 3
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── onboarding_screen.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── widgets/
│   │       └── social_login_buttons.dart
│   │
│   ├── feed/                                    # 📱 Person 3
│   │   ├── screens/
│   │   │   ├── for_you_feed_screen.dart
│   │   │   └── following_feed_screen.dart
│   │   ├── providers/
│   │   │   └── feed_provider.dart
│   │   ├── widgets/
│   │   │   ├── post_card.dart
│   │   │   ├── emotion_reaction_bar.dart
│   │   │   └── feed_tab_bar.dart
│   │   └── models/
│   │       └── post_model.dart
│   │
│   ├── post/                                    # 📱 Person 3
│   │   ├── screens/
│   │   │   ├── create_post_screen.dart
│   │   │   └── post_detail_screen.dart
│   │   ├── providers/
│   │   │   └── post_provider.dart
│   │   └── widgets/
│   │       └── media_picker_widget.dart
│   │
│   ├── profile/                                 # 📱 Person 3
│   │   ├── screens/
│   │   │   ├── profile_screen.dart
│   │   │   └── edit_profile_screen.dart
│   │   ├── providers/
│   │   │   └── profile_provider.dart
│   │   └── widgets/
│   │       ├── aura_ring.dart
│   │       ├── profile_header.dart
│   │       └── post_grid.dart
│   │
│   ├── chat/                                    # 💬 Person 4
│   │   ├── screens/
│   │   │   ├── conversations_list_screen.dart
│   │   │   └── chat_screen.dart
│   │   ├── providers/
│   │   │   ├── chat_provider.dart
│   │   │   └── presence_provider.dart
│   │   ├── widgets/
│   │   │   ├── message_bubble.dart
│   │   │   ├── typing_indicator.dart
│   │   │   └── chat_input.dart
│   │   └── models/
│   │       └── message_model.dart
│   │
│   ├── soul_connect/                            # 💬 Person 4
│   │   ├── screens/
│   │   │   └── soul_connect_screen.dart
│   │   ├── providers/
│   │   │   └── soul_provider.dart
│   │   └── widgets/
│   │       ├── soul_card.dart
│   │       ├── compatibility_breakdown.dart
│   │       └── swipe_card.dart
│   │
│   ├── waves/                                   # 💬 Person 4
│   │   ├── screens/
│   │   │   ├── waves_list_screen.dart
│   │   │   └── wave_chat_screen.dart
│   │   ├── providers/
│   │   │   └── waves_provider.dart
│   │   └── widgets/
│   │       ├── wave_card.dart
│   │       ├── wave_momentum_bar.dart
│   │       └── wave_member_list.dart
│   │
│   ├── notifications/                           # 💬 Person 4
│   │   ├── screens/
│   │   │   └── notifications_screen.dart
│   │   ├── providers/
│   │   │   └── notification_provider.dart
│   │   └── widgets/
│   │       └── notification_tile.dart
│   │
│   ├── settings/                                # 💬 Person 4
│   │   ├── screens/
│   │   │   ├── settings_screen.dart
│   │   │   ├── ai_settings_screen.dart
│   │   │   └── privacy_settings_screen.dart
│   │   └── providers/
│   │       └── settings_provider.dart
│   │
│   ├── compass/                                 # 💬 Person 4
│   │   ├── screens/
│   │   │   └── emotional_compass_screen.dart
│   │   └── widgets/
│   │       ├── emotion_radar_chart.dart
│   │       ├── emotion_timeline.dart
│   │       └── ai_insight_card.dart
│   │
│   └── wellbeing/                               # 💬 Person 4
│       └── widgets/
│           ├── break_card.dart
│           └── crisis_resource_card.dart
│
├── shared/                                      # ━━━ SHARED COMPONENTS ━━━
│   ├── widgets/
│   │   ├── aura_ring_widget.dart                # Reusable Aura Ring
│   │   ├── loading_widget.dart
│   │   ├── error_widget.dart
│   │   ├── ai_status_bar.dart
│   │   └── bottom_nav_bar.dart                  # Main navigation
│   └── models/
│       ├── user_model.dart
│       └── emotion_profile_model.dart
│
├── services/                                    # ━━━ BACKEND SERVICES ━━━
│   ├── behavioral_tracker.dart                  # 💬 Person 4
│   ├── feed_service.dart                        # 💬 Person 4
│   ├── soul_service.dart                        # 💬 Person 4
│   ├── wellbeing_service.dart                   # 💬 Person 4
│   └── fcm_service.dart                         # 💬 Person 4
│
└── providers/                                   # ━━━ GLOBAL PROVIDERS ━━━
    ├── auth_state_provider.dart                  # 📱 Person 3
    ├── user_profile_provider.dart                # 📱 Person 3
    ├── emotion_profile_provider.dart             # 📱 Person 3
    ├── api_service_provider.dart                 # 📱 Person 3
    ├── behavioral_tracker_provider.dart          # 💬 Person 4
    └── wellbeing_provider.dart                   # 💬 Person 4
```

### 1.3 Bottom Navigation Structure

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│              [Current Screen Content]               │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│   🏠 Feed    🔮 Soul    ➕ Post    💬 Chat    👤 Me │
│                                                     │
└─────────────────────────────────────────────────────┘

Tab 1: Feed (For You / Following)     → Person 3
Tab 2: Soul Connect                    → Person 4
Tab 3: Create Post (FAB)              → Person 3
Tab 4: Chat (Conversations)           → Person 4
Tab 5: Profile (Me)                    → Person 3
```

---

## 2. FastAPI Backend Skeleton

```
fastapi-backend/
│
├── main.py                              # FastAPI app + lifespan + CORS
├── requirements.txt                     # Dependencies
├── Dockerfile                           # Docker build for Cloud Run
├── .env.example                         # Environment variables template
│
├── app/
│   ├── __init__.py
│   ├── config.py                        # Settings + Firebase init
│   ├── auth.py                          # verify_firebase_token + verify_internal_key
│   │
│   ├── models/                          # Pydantic schemas
│   │   ├── __init__.py
│   │   ├── emotion.py                   # EmotionInferRequest/Response
│   │   ├── feed.py                      # FeedRequest/Response
│   │   ├── soul.py                      # SoulRequest/Response
│   │   ├── wave.py                      # WaveRequest/Response
│   │   ├── content.py                   # ContentAnalysisRequest/Response
│   │   └── wellbeing.py                 # WellbeingRequest/Response
│   │
│   ├── routers/                         # API route handlers
│   │   ├── __init__.py
│   │   ├── emotion.py                   # POST /api/v1/emotion/*
│   │   ├── feed.py                      # POST /api/v1/feed/*
│   │   ├── soul.py                      # POST /api/v1/soul/*
│   │   ├── waves.py                     # POST /api/v1/waves/*
│   │   ├── content.py                   # POST /api/v1/content/*
│   │   ├── wellbeing.py                 # POST /api/v1/wellbeing/*
│   │   └── prompts.py                   # GET /api/v1/prompts/*
│   │
│   ├── services/                        # Business logic
│   │   ├── __init__.py
│   │   ├── emotion_inference.py         # ★ 5-layer analysis + fusion
│   │   ├── recommendation.py            # ★ 3-stage pipeline
│   │   ├── soul_connect.py              # ★ Compatibility scoring
│   │   ├── wave_generator.py            # ★ Cluster detection
│   │   ├── content_analyzer.py          # Sentiment + embedding
│   │   ├── wellbeing_guard.py           # ★ Wellbeing protection
│   │   ├── prompt_assistant.py          # Mood-based prompts
│   │   └── notification.py              # FCM via Admin SDK
│   │
│   ├── ml/                              # ML model management
│   │   ├── __init__.py
│   │   ├── model_loader.py              # Load models at startup
│   │   └── vector_math.py              # Cosine similarity, fusion
│   │
│   └── utils/
│       ├── __init__.py
│       ├── firebase_client.py           # Firebase Admin SDK wrapper
│       ├── constants.py                 # Emotion types, thresholds
│       └── helpers.py
│
└── tests/
    ├── __init__.py
    ├── test_emotion.py
    ├── test_recommendation.py
    ├── test_soul_connect.py
    └── test_content.py
```

---

## 3. Firebase / Cloud Functions Skeleton

```
firebase/
│
├── .firebaserc                          # Project aliases
├── firebase.json                        # Firebase config
├── firestore.rules                      # Firestore Security Rules
├── firestore.indexes.json               # Composite indexes
├── database.rules.json                  # RTDB Security Rules
├── storage.rules                        # Cloud Storage rules
│
└── functions/
    ├── main.py                          # All Cloud Function triggers
    ├── requirements.txt
    └── utils/
        └── helpers.py
```

---

## 4. Leader Starter Code

### 4.1 Flutter `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    const ProviderScope(
      child: AuraApp(),
    ),
  );
}
```

### 4.2 Flutter `app.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class AuraApp extends ConsumerWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'AURA Social',
      debugShowCheckedModeBanner: false,
      theme: AuraTheme.light,
      darkTheme: AuraTheme.dark,
      themeMode: ThemeMode.dark,  // Default dark mode
      routerConfig: router,
    );
  }
}
```

### 4.3 Flutter `core/services/api_service.dart`

```dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuraApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',  // Change to Cloud Run URL
  );
  
  late final Dio dio;
  
  AuraApiService() {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(_AuthInterceptor());
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 → refresh token or logout
    if (err.response?.statusCode == 401) {
      // Force re-auth
    }
    handler.next(err);
  }
}
```

### 4.4 FastAPI `main.py`

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Load ML models at startup
    from app.ml.model_loader import ModelLoader
    from app.utils.firebase_client import init_firebase
    
    init_firebase()
    app.state.models = ModelLoader()
    app.state.models.load_all()
    print("✅ All ML models loaded")
    yield
    print("🔄 Shutting down...")

app = FastAPI(
    title="AURA Social AI Backend",
    version="3.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import and register routers
from app.routers import emotion, feed, soul, waves, content, wellbeing, prompts

app.include_router(emotion.router, prefix="/api/v1/emotion", tags=["Emotion"])
app.include_router(feed.router, prefix="/api/v1/feed", tags=["Feed"])
app.include_router(soul.router, prefix="/api/v1/soul", tags=["Soul Connect"])
app.include_router(waves.router, prefix="/api/v1/waves", tags=["Waves"])
app.include_router(content.router, prefix="/api/v1/content", tags=["Content"])
app.include_router(wellbeing.router, prefix="/api/v1/wellbeing", tags=["Wellbeing"])
app.include_router(prompts.router, prefix="/api/v1/prompts", tags=["Prompts"])

@app.get("/health")
async def health_check():
    return {"status": "ok", "version": "3.0.0"}
```

---

## 5. Git Branching Strategy

```
main ─────────────────────────────────────────────►
  │
  └── dev ────────────────────────────────────────►
       │
       ├── feature/P1-firestore-rules ────► PR → dev
       ├── feature/P1-cloud-functions ────► PR → dev
       ├── feature/P2-emotion-inference ──► PR → dev
       ├── feature/P2-feed-api ───────────► PR → dev
       ├── feature/P3-auth-screens ───────► PR → dev
       ├── feature/P3-feed-ui ────────────► PR → dev
       ├── feature/P4-chat-system ────────► PR → dev
       ├── feature/P4-soul-connect ───────► PR → dev
       └── ...
```

**Rules:**
- Không push trực tiếp vào `main` hoặc `dev`
- Mỗi task = 1 branch name format: `feature/P{number}-{task-name}`
- PR cần Leader approve trước merge
- Merge conflicts → người tạo PR tự resolve
