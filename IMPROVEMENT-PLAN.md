# AURA Social – Kế Hoạch Cải Thiện Toàn Diện

> **Ngày tạo:** 08/06/2026  
> **Phiên bản:** 1.0  
> **Trạng thái dự án:** MVP đang phát triển  
> **Đánh giá hiện tại:** Frontend 8.5/10 · Backend 8.5/10 · AI 6/10 · Docs 9/10 · Notifications 7/10 · CI/CD 7/10 · Testing 7/10

---

## 📋 Mục Lục

1. [Tổng Quan & Đánh Giá Thực Trạng](#1-tổng-quan--đánh-giá-thực-trạng)
2. [Phase 1: Cải Thiện AI/ML (Tuần 1-4)](#2-phase-1-cải-thiện-aiml-tuần-1-4)
3. [Phase 2: Nâng Cấp Giao Diện & UX (Tuần 3-6)](#3-phase-2-nâng-cấp-giao-diện--ux-tuần-3-6)
4. [Phase 3: Hoàn Thiện Notifications & Real-time (Tuần 5-8)](#4-phase-3-hoàn-thiện-notifications--real-time-tuần-5-8)
5. [Phase 4: Cải Thiện Backend & Infrastructure (Tuần 7-10)](#5-phase-4-cải-thiện-backend--infrastructure-tuần-7-10)
6. [Phase 5: Testing, CI/CD & Polish (Tuần 9-12)](#6-phase-5-testing-cicd--polish-tuần-9-12)
7. [Ma Trận Ưu Tiên & Effort Estimation](#7-ma-trận-ưu-tiên--effort-estimation)

---

## 1. Tổng Quan & Đánh Giá Thực Trạng

### Đánh Giá Tổng Quan

| Module | Điểm | Điểm mạnh | Điểm yếu |
|--------|------|-----------|-----------|
| **Frontend (Flutter)** | 8.0/10 | Clean Architecture, Riverpod, GoRouter, design system, unified state widgets, shimmer loading | Firebase SDK version mismatch đã fix, thiếu tests, error handling đồng nhất |
| **Backend (FastAPI)** | 8.0/10 | Logic nghiệp vụ đầy đủ, ML pipeline rõ ràng | Rate limiting chưa áp dụng, logging chưa structured, hardcoded constants |
| **AI/ML** | 6.0/10 | 5-layer pipeline, Vietnamese keywords, Plutchik model | Models chưa trained, fallback heuristics, chưa có evaluation metrics |
| **Notifications** | 7.0/10 | FCM setup cơ bản, notification service backend, smart scheduling, 8 notification types | Notification grouping, deep links đầy đủ, batch notifications chưa implement |
| **UI/UX** | 6.5/10 | Design system, theme dark/light, animations | Thiếu skeleton loading toàn bộ, empty states, error states |
| **Documentation** | 8.5/10 | 8 design docs chi tiết, team docs đầy đủ | Thiếu visual mockups PNG, API examples, performance benchmarks |
| **Testing/CI** | 7.0/10 | dev_dependencies có flutter_test, pytest, unit tests đầy đủ (5 files), CI pipeline đã tạo | CI pipeline chưa chạy lần nào, cần thêm integration tests |

### Chi Tiết Vấn Đề Cần Giải Quyết

#### 🔴 Nghiêm Trọng (Cần fix ngay)

| # | Vấn đề | Module | Tác động |
|---|---------|--------|-----------|
| 1 | **Firebase SDK version mismatch** | Flutter | Build errors, crash khi chạy |
| 2 | **ML models chưa trained** | AI/ML | Emotion inference chỉ dùng heuristics |
| 3 | **Không có unit tests** | Testing | Không đảm bảo chất lượng code |

#### 🟠 Quan Trọng (Nên fix sớm)

| # | Vấn đề | Module | Tác động |
|---|---------|--------|-----------|
| 4 | Notification system chưa hoàn chỉnh | Notifications | Người dùng không nhận được thông báo đúng lúc |
| 5 | Empty/loading/error states thiếu | UI/UX | Trải nghiệm kém khi dữ liệu trống |
| 6 | API service thiếu error interceptor | Backend | Crash khi mất mạng |
| 7 | Thiếu visual mockups PNG/Figma | Docs | Khó hình dung UI thực tế |
| 8 | Soul Connect query limit 50 users | Backend | Không scale được khi user tăng |

#### 🟡 Cần Thiết (Nên fix sau MVP)

| # | Vấn đề | Module | Tác động |
|---|---------|--------|-----------|
| 9 | Rate limiting chưa áp dụng | Backend | Bị abuse endpoint |
| 10 | Structured logging thay vì print() | Backend | Khó debug production |
| 11 | Wellbeing tracking UI chưa hoàn chỉnh | UI | Không hiển thị data đẹp |
| 12 | Không có CI/CD pipeline | Infra | Manual deploy dễ lỗi |
| 13 | HuggingFace model weights chưa optimized | AI/ML | Latency cao |
| 14 | Không có API documentation với examples | Docs | Khó integrate |

---

## 2. Phase 1: Cải Thiện AI/ML (Tuần 1-4)

### 2.1 Fix Firebase SDK Version Mismatch 🔴

**Vấn đề:** Firebase packages có version không tương thích.

```yaml
# pubspec.yaml - hiện tại
firebase_core: ^4.7.0      # ❌ Không tồn tại hoặc quá cũ
firebase_auth: ^6.4.0
cloud_firestore: ^6.3.0
firebase_database: ^12.3.0
firebase_storage: ^13.4.2
firebase_messaging: ^16.2.0
```

**Hành động:**
- [ ] Chạy `flutter pub outdated firebase` để kiểm tra phiên bản mới nhất
- [ ] Thống nhất tất cả Firebase packages về cùng major version mới nhất
- [ ] Test toàn bộ auth flow, Firestore reads/writes, FCM

**Mục tiêu:** Build thành công, tất cả Firebase features hoạt động.

---

### 2.2 Train/Populate ML Models với Sample Data 🟠

**Vấn đề:** Emotion inference hiện chỉ dùng Vietnamese keywords và heuristics.

**Hành động:**

#### A. Chuẩn Bị Dataset

```
ML/training/
├── datasets/
│   ├── vietnamese_emotions_train.json    # 500+ labeled samples
│   ├── vietnamese_emotions_val.json      # 100+ validation samples
│   └── behavioral_signals.json           # Synthetic behavioral data
├── notebooks/
│   ├── 01_evaluate_baseline.ipynb        # Evaluate current heuristics
│   ├── 02_finetune_sentiment.ipynb        # Fine-tune PhoBERT
│   └── 03_evaluate_model.ipynb           # Compare models
└── results/
    ├── baseline_metrics.json
    └── finetuned_metrics.json
```

#### B. Evaluate Baseline (Week 1)

```python
# Đánh giá emotion_engine hiện tại với ground truth labels
# Metrics: Accuracy, F1-Score, Confusion Matrix, Emotion-wise Precision/Recall
# Expected: ~55-65% accuracy với heuristics

emotion_engine_evaluation = {
  "joy":        {"precision": 0.72, "recall": 0.68, "f1": 0.70},
  "sadness":    {"precision": 0.65, "recall": 0.71, "f1": 0.68},
  "anger":      {"precision": 0.70, "recall": 0.62, "f1": 0.66},
  "fear":       {"precision": 0.58, "recall": 0.55, "f1": 0.56},
  "surprise":   {"precision": 0.50, "recall": 0.48, "f1": 0.49},
  "disgust":    {"precision": 0.55, "recall": 0.52, "f1": 0.53},
  "trust":      {"precision": 0.60, "recall": 0.58, "f1": 0.59},
  "anticipation":{"precision": 0.55, "recall": 0.50, "f1": 0.52},
  "overall_accuracy": 0.61
}
```

#### C. Fine-tune Sentiment Model (Week 2-3)

- **Model:** `vinai/phobert-base` hoặc `wonxu/PhoBERT_sentiment`
- **Dataset:** UIT-VSFC (Vietnamese Sentiment) + custom labeled data
- **Target:** Accuracy > 80%, inference latency < 200ms

```python
# fastapi-backend/app/ml/emotion_engine.py - Cải tiến Layer 3

class EmotionEngine:
    def __init__(self):
        self.sentiment_pipeline = pipeline(
            "sentiment-multilingual",
            model="nlptown/bert-base-multilingual-uncased-sentiment",
            device=0 if torch.cuda.is_available() else -1
        )
        # Thêm: Fine-tuned Vietnamese model
        self.vietnamese_pipeline = pipeline(
            "sentiment-analysis",
            model="path/to/finetuned_phobert",
            device=0 if torch.cuda.is_available() else -1
        )
    
    def _analyze_text_layer(self, text: str, language_hint: str = "vi") -> np.ndarray:
        # Ưu tiên Vietnamese model nếu detect được tiếng Việt
        if self._is_vietnamese(text):
            result = self.vietnamese_pipeline(text[:512])
        else:
            result = self.sentiment_pipeline(text[:512])
        return self._sentiment_to_plutchik(result)
```

#### D. Evaluation & Comparison (Week 4)

- Compare baseline vs fine-tuned model
- A/B test trên production (nếu có user)
- Document evaluation results

---

### 2.3 Cải Thiện Emotion Inference Confidence 🟡

**Hiện tại:** Confidence score chưa có clear threshold.

**Cải tiến:**

```python
# fastapi-backend/app/ml/emotion_engine.py

class EmotionInferenceResult:
    dominant_emotion: str
    confidence: float          # 0.0 - 1.0
    confidence_level: str      # "high" | "medium" | "low"
    emotion_vector: List[float]  # 8D Plutchik
    reasoning: str
    signal_sources: Dict[str, float]  # Which signals contributed

def infer_emotion(event_data: dict) -> EmotionInferenceResult:
    signals = collect_signals(event_data)
    
    # Weighted fusion
    final_vector = fuse_signals(signals)
    
    # Calculate confidence based on signal diversity
    confidence = calculate_confidence(signals)
    
    if confidence < 0.4:
        # Trigger explicit mood check-in prompt
        trigger_mood_checkin(user_id)
    
    return EmotionInferenceResult(
        dominant_emotion=dominant(final_vector),
        confidence=confidence,
        confidence_level="high" if confidence > 0.7 else "medium" if confidence > 0.5 else "low",
        emotion_vector=final_vector,
        reasoning=generate_reasoning(signals),
        signal_sources={k: v.weight for k, v in signals.items()}
    )
```

---

### 2.4 Vietnamese Sarcasm & Slang Detection 🟡

**Vấn đề:** "ảo thật", "đỉnh nóc", "mệt óc" không được xử lý đúng.

**Hành động:**

```python
# fastapi-backend/app/ml/slang_detector.py

VIETNAMESE_SARCASM_PATTERNS = {
    "positive_intensifier_sarcasm": {
        "patterns": [
            r"đỉnh\w*", r"ảo\w*", r"ngầu\w*", 
            r"xịt\w*", r"vl\w*", r"cmnl"
        ],
        "indicator": "positive_word + exaggerated = likely sarcasm"
    },
    "negative_under_positive": {
        "patterns": [
            r"tốt\w* quá", r"vui\w* quá", r"hạnh phúc\w*",
            r"oke\w* rồi", r"ổn\w* đấy"
        ],
        "indicator": "positive surface + underlying negative context"
    }
}

VIETNAMESE_EMOTION_KEYWORDS = {
    "joy": ["vui", "hạnh phúc", "mừng", "phấn khích", "hào hứng", "đỉnh", "xịn", "bùng nổ"],
    "sadness": ["buồn", "thất vọng", "chán", "mệt", "mất", "tiếc", "khổ", "đau"],
    "anger": ["giận", "bực", "tức", "cay", "ghét", "khó chịu", "bực bội"],
    "fear": ["sợ", "lo", "ám ảnh", "hoảng", "lo lắng", "bất an", "rùng mình"],
    "surprise": ["wow", "ồ", "không tin", "bất ngờ", "trời ơi", "đập", "hết sức"],
    "disgust": ["ghê", "buồn nôn", "kinh tở", "ác", "khó ưa", "chướng"],
    "trust": ["tin", "yêu", "thích", "quý", "tâm đắc", "thoải mái", "an tâm"],
    "anticipation": ["chờ", "mong", "hy vọng", "kỳ vọng", "háo hức", "nóng lòng"]
}
```

---

## 3. Phase 2: Nâng Cấp Giao Diện & UX (Tuần 3-6)

### 3.1 Hoàn Thiện All States cho Mọi Screen 🟠

**Vấn đề:** Nhiều màn hình thiếu loading, empty, error states.

#### A. Tạo Unified State Widget

```dart
// shared/widgets/aura_state_builder.dart

enum AuraStateStatus { loading, success, error, empty }

class AuraStateBuilder<T> extends StatelessWidget {
  final AsyncValue<T> state;
  final Widget Function(T data) onSuccess;
  final Widget? onLoading;
  final Widget Function(String error, VoidCallback? onRetry)? onError;
  final Widget? onEmpty;
  final String? emptyMessage;
  final String? errorMessage;
}

class AuraShimmerLoading extends StatelessWidget {
  final int itemCount;
  final Widget Function(int index) itemBuilder;
}

class AuraEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
}
```

#### B. Áp dụng cho từng screen

| Screen | Loading State | Empty State | Error State |
|--------|-------------|-------------|-------------|
| Feed | Shimmer cards (5 items) | "Chưa có bài viết nào" + CTA | Retry button + message |
| Soul Connect | Swipe cards shimmer | "Không tìm thấy ai phù hợp" | Retry + filter button |
| Chat | Messages skeleton | "Bắt đầu cuộc trò chuyện" | Retry + offline indicator |
| Profile | Cover + grid shimmer | "Chưa có bài viết" | Retry button |
| Notifications | List shimmer | "Không có thông báo" | Retry + clear all |
| Search | Recent searches | "Tìm kiếm người dùng" | No results illustration |

#### C. Tạo Illustration Assets

```
assets/illustrations/
├── empty_feed.svg        # No posts illustration
├── empty_chat.svg        # No messages illustration
├── empty_notifications.svg
├── empty_search.svg
├── empty_waves.svg
├── error_500.svg        # Server error
├── error_offline.svg     # No internet
├── error_empty.svg       # No data
└── onboarding_*.svg     # Onboarding illustrations (5 screens)
```

---

### 3.2 Cải Thiện Feed UI 🟠

**Cải tiến cần thiết:**

#### A. Infinite Scroll với Smart Loading

```dart
// feed/providers/feed_provider.dart

class FeedNotifier extends StateNotifier<FeedState> {
  Future<void> loadMore() async {
    if (state.hasMore && !state.isLoadingMore) {
      state = state.copyWith(isLoadingMore: true);
      final newPosts = await feedService.getFeed(
        cursor: state.posts.last.id,
        limit: 10,
      );
      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        hasMore: newPosts.length == 10,
        isLoadingMore: false,
      );
    }
  }
}

class FeedScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= 
            scrollInfo.metrics.maxScrollExtent - 500) {
          ref.read(feedProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.builder(
        // ...
      ),
    );
  }
}
```

#### B. Emotion Reaction Bar Cải Tiến

```dart
// feed/widgets/emotion_reaction_bar.dart

class EmotionReactionBar extends StatelessWidget {
  final PostModel post;
  final Function(EmotionType) onReact;
}

class EmotionReactionBar extends StatelessWidget {
  // Hiện tại: chỉ hiện icon
  // Cần cải tiến:
  
  // 1. Hiện số lượng reaction theo từng emotion
  // 2. Animation khi tap (scale + particle effect)
  // 3. Long-press để xem ai đã react
  // 4. Double-tap post để reaction nhanh (Joy)
  // 5. Color highlight cho reaction đã chọn
}
```

#### C. Pull-to-Refresh với Custom Indicator

```dart
// FeedScreen - Custom refresh indicator
RefreshIndicator(
  onRefresh: () async {
    await ref.read(feedProvider.notifier).refresh();
  },
  color: AuraColors.primary,
  backgroundColor: AuraColors.surface,
  child: ListView(...),
)
```

---

### 3.3 Wellbeing & Emotional Compass UI 🟠

**Hiện tại:** Screens đã có nhưng cần polish và bổ sung data visualization.

#### A. Wellbeing Dashboard Components

```dart
// wellbeing/widgets/wellbeing_dashboard.dart

class WellbeingDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wellbeingData = ref.watch(wellbeingProvider);
    
    return Column(
      children: [
        // 1. Wellbeing Score Ring
        WellbeingScoreRing(score: wellbeingData.score),
        
        // 2. Mood Trend Chart (7 ngày)
        MoodTrendChart(weeklyData: wellbeingData.weekly),
        
        // 3. Emotion Distribution (pie chart)
        EmotionDistributionChart(
          emotions: wellbeingData.emotionCounts,
        ),
        
        // 4. Streak & Achievements
        WellbeingStreakCard(streak: wellbeingData.streak),
        
        // 5. AI Insight Card
        InsightCard(insight: wellbeingData.aiInsight),
        
        // 6. Quick Actions
        QuickActionsGrid(
          actions: [
            ActionItem(icon: Icons.check_circle, label: "Mood Check-in"),
            ActionItem(icon: Icons.fitness_center, label: "Challenge"),
            ActionItem(icon: Icons.self_improvement, label: "Meditation"),
            ActionItem(icon: Icons.timeline, label: "Compass"),
          ],
        ),
      ],
    );
  }
}
```

#### B. Emotional Compass Radar Chart

```dart
// compass/widgets/emotion_radar_chart.dart

class EmotionRadarChart extends StatelessWidget {
  // fl_chart RadarChart với 8 axes
  // Mỗi axis = 1 emotion theo Plutchik
  // Background gradient thay đổi theo dominant emotion
  
  // Cải tiến:
  // 1. Animated transition khi emotion thay đổi
  // 2. Touch interaction để xem chi tiết từng emotion
  // 3. Historical comparison overlay (last week vs now)
  // 4. Color gradient fill thay vì solid color
}
```

#### C. Emotion Timeline Widget

```dart
// compass/widgets/emotion_timeline.dart

class EmotionTimeline extends StatelessWidget {
  // Timeline dọc hiển thị emotion changes theo thời gian
  // 
  // Mỗi node = 1 emotion với:
  // - Time badge
  // - Emotion icon + color
  // - Brief context (post, activity, etc.)
  // - Confidence indicator
  //
  // Grouping theo: Morning / Afternoon / Evening / Night
}
```

---

### 3.4 Chat & Conversation UI Improvements 🟠

#### A. Message Bubble Cải Tiến

```dart
// chat/widgets/message_bubble.dart

class MessageBubble extends StatelessWidget {
  // Hiện tại: basic text bubbles
  // Cần thêm:
  
  // 1. Image messages với zoom capability
  // 2. Post share cards (khi share bài viết)
  // 3. Emotion reaction badges (like/love/haha/...)
  // 4. Reply thread indicator
  // 5. Read receipts (checkmarks)
  // 6. Timestamp grouping (today/yesterday/date)
  // 7. Typing indicator animation
  // 8. Voice message placeholder (future)
}

// Message status indicators
enum MessageStatus { sending, sent, delivered, read }

// Reaction picker
class ReactionPicker extends StatelessWidget {
  // 8 emotion reactions + custom emoji
  // Float animation khi hiện/ẩn
}
```

#### B. Conversations List Improvements

```dart
// chat/screens/conversations_list_screen.dart

class ConversationsListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Search bar
        SearchBar(),
        
        // 2. Filter chips
        // ["Tất cả", "Chưa đọc", "Nhóm", "Soul Connections"]
        
        // 3. Pinned conversations section
        // Horizontal scroll của pinned chats
        
        // 4. All conversations list
        // Grouping: "Hôm nay" / "Hôm qua" / "Tuần này" / Older
        
        // 5. Empty state
        // "Bắt đầu kết nối Soul để trò chuyện"
      ],
    );
  }
}
```

#### C. Chat Input Improvements

```dart
// chat/widgets/chat_input.dart

class ChatInput extends StatefulWidget {
  // Hiện tại: basic text field + send button
  // Cần thêm:
  
  // 1. Multi-line text input (expanding)
  // 2. Attachment picker (image, post)
  // 3. Emotion expression selector (optional mood context)
  // 4. AI Prompt Assistant trigger (@ai)
  // 5. Voice message button (future)
  // 6. Typing animation indicator
  // 7. Character count cho long messages
}
```

---

### 3.5 Wave (Emotional Group Chat) UI 🟠

**Vấn đề:** Waves list và wave chat chưa hoàn chỉnh.

```dart
// waves/widgets/wave_components.dart

class WaveCard extends StatelessWidget {
  // Wave card với:
  // - Wave name (AI-generated hoặc emotion-based)
  // - Member count + avatars row
  // - Dominant emotion badge
  // - Wave momentum bar (active/inactive/ending)
  // - Time remaining
  // - Join/Leave button
}

class WaveChatScreen extends StatelessWidget {
  // Wave chat với:
  // - Member list sidebar (swipe to show)
  // - Emotion reactions per message
  // - Wave momentum bar (top)
  // - Auto-leave timer
  // - Wave ending notification
}

class WaveMomentumIndicator extends StatelessWidget {
  // Visual indicator của wave intensity
  // - Wave đang tăng (↑)
  // - Wave đỉnh (peak)
  // - Wave giảm (↓)
  // - Wave kết thúc (fade out)
}
```

---

### 3.6 Onboarding & First-Time User Experience 🟡

**Cải tiến:**

```dart
// onboarding/screens/

class OnboardingScreen extends StatefulWidget {
  // 5 screens:
  
  // Screen 1: Welcome
  // "Chào mừng đến với AURA"
  // Animated Aura Ring intro
  
  // Screen 2: Emotion Concept
  // "Cảm xúc của bạn tạo nên trải nghiệm"
  // Interactive emotion picker demo
  
  // Screen 3: Soul Connect
  // "Kết nối theo cảm xúc"
  // Demo swipe cards
  
  // Screen 4: Privacy
  // "Dữ liệu của bạn, quyền kiểm soát của bạn"
  // Privacy consent with clear explanations
  
  // Screen 5: Get Started
  // "Sẵn sàng khám phá?"
  // CTA button
  
  // Indicators: dots + skip button + progress
}
```

---

### 3.7 Animation & Micro-interactions 🟡

```dart
// Tạo shared animation utilities

class AuraAnimations {
  // 1. Page transitions
  static CustomTransitionPage fadeSlideTransition()
  
  // 2. Card interactions
  // - Scale on tap
  // - Shimmer loading
  // - Pull to refresh indicator
  
  // 3. Emotion-specific animations
  // - Joy: bounce
  // - Sadness: fade down
  // - Anger: shake
  // - Fear: flicker
  
  // 4. Notification animations
  // - Slide in from top
  // - Badge bounce
  
  // 5. Bottom nav transitions
  // - Scale + color transition
}
```

---

### 3.8 Responsive & Dark/Light Mode Polish 🟡

```dart
// Cải thiện responsive design

class ResponsiveLayout extends StatelessWidget {
  // Breakpoints:
  // - Mobile: < 600px
  // - Tablet: 600px - 1200px
  // - Desktop: > 1200px
  
  // Tablet improvements:
  // - Split view (list + detail)
  // - Larger touch targets
  // - Multi-column layouts
  
  // Dark mode polish:
  // - True black (#000000) cho AMOLED
  // - Consistent surface colors
  // - Emotion colors remain visible in dark mode
}
```

---

## 4. Phase 3: Hoàn Thiện Notifications & Real-time (Tuần 5-8)

### 4.1 Notification System Architecture 🟠

```dart
// services/notification_service.dart

class AURANotificationService {
  // 1. Notification Types
  static const String TYPE_MESSAGE = 'message';
  static const String TYPE_SOUL_MATCH = 'soul_match';
  static const String TYPE_WAVE_JOIN = 'wave_join';
  static const String TYPE_WELLBEING_REMINDER = 'wellbeing_reminder';
  static const String TYPE_CHALLENGE = 'challenge';
  static const String TYPE_POST_REACTION = 'post_reaction';
  static const String TYPE_FOLLOW = 'follow';
  static const String TYPE_AI_INSIGHT = 'ai_insight';
  
  // 2. Notification Channels (Android)
  static const Map<String, AndroidNotificationChannel> CHANNELS = {
    'messages': AndroidNotificationChannel(
      id: 'messages',
      name: 'Tin nhắn',
      description: 'Thông báo tin nhắn mới',
      importance: Importance.high,
    ),
    'social': AndroidNotificationChannel(
      id: 'social',
      name: 'Hoạt động xã hội',
      description: 'Soul matches, reactions, follows',
      importance: Importance.defaultImportance,
    ),
    'wellbeing': AndroidNotificationChannel(
      id: 'wellbeing',
      name: 'Sức khỏe tinh thần',
      description: 'Nhắc nhở check-in, thử thách',
      importance: Importance.low,
    ),
  };
  
  // 3. FCM Token Management
  Future<void> saveFCMToken(String userId);
  Future<void> deleteFCMToken(String userId);
  
  // 4. Handle notification taps (deep links)
  void handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final payload = data['payload'];
    
    switch (type) {
      case TYPE_MESSAGE:
        context.push('/chat/$payload');
      case TYPE_SOUL_MATCH:
        context.push('/soul');
      case TYPE_WAVE_JOIN:
        context.push('/wave/$payload');
      // ...
    }
  }
}
```

### 4.2 Notification Providers & State Management 🟠

```dart
// notifications/providers/notification_provider.dart

class NotificationState {
  final List<NotificationItem> items;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final NotificationFilter filter;
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  // 1. Load notifications với pagination
  Future<void> loadNotifications({bool refresh = false});
  
  // 2. Mark as read (single / all)
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  
  // 3. Delete notification
  Future<void> deleteNotification(String notificationId);
  
  // 4. Filter
  void setFilter(NotificationFilter filter);
  
  // 5. Real-time listener
  void startListening();
  void stopListening();
}

enum NotificationFilter {
  all,        // Tất cả
  unread,     // Chưa đọc
  messages,   // Tin nhắn
  social,     // Hoạt động xã hội
  wellbeing,  // Sức khỏe
}
```

### 4.3 Push Notification Triggers (Backend) 🟠

```python
# fastapi-backend/app/services/notification_service.py

class NotificationService:
    async def send_notification(
        self,
        user_id: str,
        notification_type: str,
        title: str,
        body: str,
        data: dict = None,
        priority: str = "normal"
    ):
        # Firebase Cloud Messaging
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            android=messaging.AndroidConfig(
                priority="high" if priority == "high" else "normal",
                notification_channel_id=self._get_channel(notification_type),
            ),
            apns=messaging.APNSConfig(
                headers={"apns-priority": "10" if priority == "high" else "5"},
            ),
            token=await self._get_fcm_token(user_id),
        )
        return messaging.send(message)
    
    # Trigger points
    async def on_new_message(self, conversation_id: str, sender_id: str):
        # Gửi notification cho all participants (trừ sender)
        pass
    
    async def on_soul_match(self, user_id: str, matched_user_id: str):
        # "Người phù hợp với bạn đang online"
        pass
    
    async def on_wave_nearby(self, user_id: str, wave_id: str):
        # "Có wave mới gần bạn"
        pass
    
    async def on_wellbeing_reminder(self, user_id: str):
        # Smart reminder based on user patterns
        pass
```

### 4.4 Notification Scheduling & Smart Reminders 🟡

```python
# Chỉ gửi notification khi appropriate

class SmartNotificationScheduler:
    # 1. Quiet Hours
    QUIET_HOURS = {"start": 22, "end": 8}  # 10 PM - 8 AM
    
    # 2. User preferences
    async def should_send(self, user_id: str, notification_type: str) -> bool:
        prefs = await self._get_user_prefs(user_id)
        
        # Check quiet hours
        if self._is_quiet_hours():
            return notification_type in ["wellbeing_crisis", "urgent_message"]
        
        # Check user preferences
        if not prefs.get(f"notify_{notification_type}", True):
            return False
        
        # Check notification fatigue (max 5 notifications/hour)
        recent_count = await self._get_recent_notification_count(user_id)
        if recent_count >= 5:
            return notification_type in ["message", "soul_match"]
        
        return True
    
    # 3. Batch non-urgent notifications
    # Gửi batch notification mỗi 2 giờ thay vì liên tục
```

---

### 4.5 In-App Notification Center 🟠

```dart
// notifications/screens/notifications_screen.dart

class NotificationsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo"),
        actions: [
          // Filter button
          PopupMenuButton<NotificationFilter>(
            icon: Icon(Icons.filter_list),
            onSelected: (filter) {
              ref.read(notificationProvider.notifier).setFilter(filter);
            },
          ),
          // Mark all read
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
              },
              child: const Text("Đọc tất cả"),
            ),
        ],
      ),
      body: AuraStateBuilder<NotificationState>(
        state: state,
        onSuccess: (data) => _NotificationList(data: data),
        onLoading: () => _NotificationShimmer(),
        onEmpty: () => _EmptyNotifications(),
        onError: (error, retry) => _ErrorState(error: error, onRetry: retry),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  // Grouping: Hôm nay / Hôm qua / Tuần này / Older
  // Each item: avatar + content + time + unread indicator
  // Swipe to delete
  // Tap to navigate (deep link)
}
```

---

### 4.6 Real-time Presence & Typing Indicators 🟡

```dart
// services/realtime_service.dart

class RealtimeService {
  // 1. Online presence
  Stream<List<String>> watchOnlineUsers(List<String> userIds) {
    // Firebase RTDB - theo dõi online/offline status
  }
  
  // 2. Typing indicators
  void startTyping(String conversationId) {
    // Set typing = true với TTL 3 seconds
    // Auto-expire để không stuck "typing"
  }
  
  void stopTyping(String conversationId) {
    // Set typing = false
  }
  
  Stream<bool> watchTyping(String conversationId) {
    // Listen to typing status changes
  }
  
  // 3. Last seen
  Future<void> updateLastSeen(String userId);
  Stream<DateTime?> watchLastSeen(String userId);
}
```

---

## 5. Phase 4: Cải Thiện Backend & Infrastructure (Tuần 7-10)

### 5.1 Error Handling & Logging 🟠

**Hiện tại:** Dùng `print()` và `try/except` rải rác.

```python
# fastapi-backend/app/utils/logging.py

import logging
import json
from datetime import datetime
from typing import Any

class StructuredFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "function": record.funcName,
            "line": record.lineno,
        }
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)
        if hasattr(record, "user_id"):
            log_data["user_id"] = record.user_id
        if hasattr(record, "request_id"):
            log_data["request_id"] = record.request_id
        return json.dumps(log_data)

# Usage in routers
@router.post("/emotion/infer")
async def infer_emotion(request: EmotionInferRequest, request_id: str = None):
    logger = logging.getLogger(__name__)
    logger.info(
        "Emotion inference started",
        extra={"user_id": request.user_id, "request_id": request_id}
    )
```

### 5.2 Rate Limiting 🟠

```python
# fastapi-backend/app/utils/rate_limiter.py

from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)

# Per-endpoint rate limits
RATE_LIMITS = {
    "/api/v1/emotion/infer": "10/minute",
    "/api/v1/feed/generate": "30/minute",
    "/api/v1/content/analyze": "20/minute",
    "/api/v1/upload": "10/minute",
    "/api/v1/soul/suggestions": "20/minute",
    "/api/v1/wellbeing/check": "60/minute",
    "/health": "120/minute",
}

@router.post("/emotion/infer")
@limiter.limit(RATE_LIMITS["/api/v1/emotion/infer"])
async def infer_emotion(request: Request, ...):
    pass
```

### 5.3 Standardized Error Responses 🟠

```python
# fastapi-backend/app/models/errors.py

from pydantic import BaseModel
from typing import Optional, Any

class APIErrorResponse(BaseModel):
    error: str                    # Error code: "VALIDATION_ERROR", "NOT_FOUND", etc.
    message: str                   # Human-readable message
    details: Optional[Any] = None # Field-level errors
    request_id: Optional[str] = None
    
    @classmethod
    def validation_error(cls, details: dict, request_id: str = None):
        return cls(
            error="VALIDATION_ERROR",
            message="Invalid request data",
            details=details,
            request_id=request_id,
        )
    
    @classmethod
    def not_found(cls, resource: str, request_id: str = None):
        return cls(
            error="NOT_FOUND",
            message=f"{resource} not found",
            request_id=request_id,
        )
    
    @classmethod
    def unauthorized(cls, request_id: str = None):
        return cls(
            error="UNAUTHORIZED",
            message="Invalid or expired authentication token",
            request_id=request_id,
        )

# Global exception handler
@router.exception_handler(APIErrorResponse)
async def api_error_handler(request, exc: APIErrorResponse):
    status_map = {
        "VALIDATION_ERROR": 400,
        "NOT_FOUND": 404,
        "UNAUTHORIZED": 401,
        "RATE_LIMITED": 429,
        "INTERNAL_ERROR": 500,
    }
    return JSONResponse(
        status_code=status_map.get(exc.error, 500),
        content=exc.model_dump(),
    )
```

### 5.4 Health Check & Monitoring Endpoints 🟠

```python
# fastapi-backend/app/routers/health.py

@router.get("/health")
async def health_check():
    """Liveness probe - Kubernetes và monitoring dashboards"""
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@router.get("/health/ready")
async def readiness_check():
    """Readiness probe - kiểm tra tất cả dependencies"""
    checks = {
        "firebase": await check_firebase(),
        "ml_models": check_ml_models_loaded(),
        "r2_storage": await check_r2_connection(),
    }
    
    all_healthy = all(checks.values())
    status_code = 200 if all_healthy else 503
    
    return JSONResponse(
        status_code=status_code,
        content={
            "status": "ready" if all_healthy else "degraded",
            "checks": checks,
            "timestamp": datetime.utcnow().isoformat(),
        }
    )

@router.get("/health/metrics")
async def metrics():
    """Prometheus-compatible metrics endpoint"""
    return {
        "requests_total": counter_requests,
        "emotion_inferences_total": counter_emotion,
        "avg_latency_ms": avg_latency_ms,
        "active_users_5min": active_users_5min,
    }
```

### 5.5 Pagination & Scalability Improvements 🟠

```python
# Soul Connect - Scale beyond 50 users

@router.post("/api/v1/soul/suggestions")
async def get_soul_suggestions(request: SoulRequest):
    # Thay vì query tất cả users và filter
    # Dùng Firestore compound query với indexed fields
    
    # 1. Query users with similar emotion patterns (indexed)
    similar_emotion_users = db.collection("users").where(
        filter=FieldFilter("emotion_vector", "ARRAY_CONTAINS_ANY", 
                          top_3_emotions)
    ).limit(200)  # Tăng limit
    
    # 2. Batch process để tính soul scores
    scored_users = await batch_compute_soul_scores(
        users=list(similar_emotion_users.stream()),
        current_user=current_user,
        batch_size=50
    )
    
    # 3. Return top N với pagination
    paginated = scored_users[
        (request.page or 0) * (request.limit or 10):
        ((request.page or 0) + 1) * (request.limit or 10)
    ]
    
    return SoulSuggestionsResponse(
        suggestions=paginated,
        total=len(scored_users),
        has_more=len(scored_users) > (request.page + 1) * request.limit
    )
```

### 5.6 CORS & Security Hardening 🟡

```python
# fastapi-backend/main.py

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",           # Local dev
        "https://your-app.web.app",        # Firebase Hosting
        "https://your-app.firebaseapp.com", # Firebase Hosting alt
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
)

# Security headers
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    return response
```

---

### 5.7 Database Indexes Optimization 🟡

```json
// firestore.indexes.json - cần deploy thêm indexes

{
  "indexes": [
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "emotion_vector", "arrayConfig": "CONTAINS_ANY" },
        { "fieldPath": "last_active", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "is_active", "order": "ASCENDING" },
        { "fieldPath": "last_active", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "emotion_tag", "order": "ASCENDING" },
        { "fieldPath": "created_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "emotion_tag", "order": "ASCENDING" },
        { "fieldPath": "engagement_score", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## 6. Phase 5: Testing, CI/CD & Polish (Tuần 9-12)

### 6.1 Unit Tests 🟠

#### Flutter Unit Tests

```dart
// test/unit/emotion_engine_test.dart

void main() {
  group('EmotionEngine', () {
    late EmotionEngine engine;
    
    setUp(() {
      engine = EmotionEngine();
    });
    
    test('should infer joy from positive Vietnamese text', () async {
      final result = await engine.inferEmotion(
        text: 'Hôm nay trời đẹp quá, mình vui lắm!',
        language: 'vi',
      );
      
      expect(result.dominantEmotion, EmotionType.joy);
      expect(result.confidence, greaterThan(0.5));
    });
    
    test('should handle sarcasm patterns', () async {
      final result = await engine.inferEmotion(
        text: 'Ủa đỉnh thật đấy, ảo vl',
        language: 'vi',
      );
      
      // Sarcasm detection should reduce false positive joy
      expect(result.confidence, lessThan(0.8));
    });
    
    test('should return neutral when no signals', () async {
      final result = await engine.inferEmotion(
        text: '',
        behavioralSignals: {},
      );
      
      expect(result.dominantEmotion, EmotionType.neutral);
      expect(result.confidence, lessThan(0.5));
    });
  });
}

// test/unit/feed_provider_test.dart

void main() {
  group('FeedProvider', () {
    test('should load initial posts', () async {
      // Mock feedService
      // Test pagination
      // Test refresh
      // Test error handling
    });
    
    test('should handle emotional resonance scoring', () async {
      // Test different emotional modes
      // Test wellbeing guard
    });
  });
}

// test/unit/soul_engine_test.dart

void main() {
  group('SoulEngine', () {
    test('should calculate compatibility correctly', () async {
      final user1 = createTestUser(emotionVector: [0.8, 0.5, 0.3, ...]);
      final user2 = createTestUser(emotionVector: [0.7, 0.4, 0.2, ...]);
      
      final score = SoulEngine.calculateCompatibility(user1, user2);
      
      expect(score, greaterThan(0.6));
    });
  });
}
```

#### Python Unit Tests

```python
# fastapi-backend/tests/test_emotion_engine.py

import pytest
import numpy as np
from app.ml.emotion_engine import EmotionEngine

@pytest.fixture
def engine():
    return EmotionEngine()

class TestEmotionEngine:
    def test_behavioral_layer_basic(self, engine):
        signals = {
            "scroll_speed": 0.8,
            "dwell_time": 0.3,
            "interaction_rate": 0.6,
        }
        result = engine._analyze_behavioral_layer(signals)
        assert result.shape == (8,)
        assert np.all(result >= 0) and np.all(result <= 1)
    
    def test_text_layer_vietnamese(self, engine):
        result = engine._analyze_text_layer("Tôi rất vui và hạnh phúc")
        assert result.argmax() == 0  # Joy should be dominant
    
    def test_fusion_weights_sum_to_one(self, engine):
        weights = engine._get_fusion_weights()
        assert np.isclose(sum(weights.values()), 1.0)
    
    def test_neutral_fallback_on_error(self, engine):
        result = engine.infer({})
        assert result["emotion_vector"] == [0.125] * 8

# fastapi-backend/tests/test_feed_pipeline.py

class TestFeedPipeline:
    def test_wellbeing_guard_blocks_negative_streak(self):
        # Test wellbeing guard logic
        pass
    
    def test_positive_injection_after_3_negatives(self):
        # Test positive content injection
        pass
```

### 6.2 Integration Tests 🟡

```python
# fastapi-backend/tests/test_api_integration.py

import pytest
from httpx import AsyncClient, ASGITransport
from main import app

@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

class TestEmotionAPI:
    async def test_infer_endpoint_returns_valid_response(self, client):
        response = await client.post(
            "/api/v1/emotion/infer",
            json={
                "user_id": "test_user",
                "behavioral_signals": {
                    "scroll_speed": 0.5,
                    "dwell_time": 0.5,
                    "interaction_rate": 0.5,
                },
                "text_content": "Hôm nay thật tuyệt vời",
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert "emotion_vector" in data
        assert len(data["emotion_vector"]) == 8
        assert "confidence" in data

class TestFeedAPI:
    async def test_feed_generation_with_pagination(self, client):
        response = await client.post(
            "/api/v1/feed/generate",
            json={"user_id": "test_user", "limit": 5}
        )
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert len(data["items"]) <= 5
```

### 6.3 GitHub Actions CI/CD Pipeline 🟠

```yaml
# .github/workflows/ci.yml

name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  flutter-test:
    name: Flutter Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
      
      - name: Get Flutter dependencies
        run: flutter pub get
      
      - name: Analyze Flutter code
        run: flutter analyze --no-fatal-infos --no-fatal-warnings
      
      - name: Run unit tests
        run: flutter test --machine > test-resultsflutter.json
      
      - name: Upload Flutter test results
        uses: actions/upload-artifact@v4
        with:
          name: flutter-test-results
          path: test-resultsflutter.json
  
  backend-test:
    name: Backend Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          cd fastapi-backend
          pip install -r requirements.txt
      
      - name: Run pytest
        run: |
          cd fastapi-backend
          pytest tests/ -v --cov=app --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
  
  build-android:
    name: Build Android APK
    runs-on: ubuntu-latest
    needs: flutter-test
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      
      - name: Get Flutter dependencies
        run: flutter pub get
      
      - name: Build debug APK
        run: flutter build apk --debug
      
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: aura-debug-apk
          path: build/app/outputs/flutter-apk/app-debug.apk
```

```yaml
# .github/workflows/deploy.yml

name: Deploy to Cloud Run

on:
  push:
    branches: [main]

jobs:
  deploy-backend:
    name: Deploy FastAPI Backend
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Build and push Docker image
        run: |
          cd fastapi-backend
          gcloud builds submit --tag gcr.io/${{ secrets.GCP_PROJECT_ID }}/aura-api:${{ github.sha }}
      
      - name: Deploy to Cloud Run
        run: |
          gcloud run deploy aura-api \
            --image gcr.io/${{ secrets.GCP_PROJECT_ID }}/aura-api:${{ github.sha }} \
            --region asia-southeast1 \
            --platform managed \
            --allow-unauthenticated \
            --set-env-vars ENVIRONMENT=production
```

### 6.4 Firebase Security Rules Testing 🟡

```javascript
// firebase-admin/rules-tester.js

const assert = require('firestore-export-import/assertions');

// Test all security rules
describe('Firestore Security Rules', () => {
  describe('users collection', () => {
    test('users can read their own profile', async () => {
      await assertPermitted({
        request.auth.uid: 'user1',
        resource: { data: { id: 'user1' } }
      }).toRead();
    });
    
    test('users cannot read other users private data', async () => {
      await assertDenied({
        request.auth.uid: 'user1',
        resource: { data: { id: 'user2', is_private: true } }
      }).toRead();
    });
  });
  
  describe('posts collection', () => {
    test('anyone can read public posts', async () => {
      await assertPermitted({
        resource: { data: { is_public: true } }
      }).toRead();
    });
  });
});
```

### 6.5 Performance Optimization 🟡

#### Flutter Performance

```dart
// Performance improvements

// 1. Image caching - đã dùng cached_network_image ✓

// 2. ListView optimization
ListView.builder(
  itemCount: posts.length,
  itemBuilder: (context, index) {
    return PostCard(
      key: ValueKey(posts[index].id),  // Stable keys
      post: posts[index],
    );
  },
  cacheExtent: 500,  // Pre-load ahead
)

// 3. Const widgets
// Dùng const constructor cho tất cả widgets không thay đổi

// 4. RepaintBoundary cho heavy widgets
RepaintBoundary(
  child: ComplexChart(),
)

// 5. Fl_chart lazy loading
// Chỉ render chart khi visible
```

#### Backend Performance

```python
# fastapi-backend/app/ml/model_loader.py

class ModelLoader:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def load_models(self):
        """Lazy load models - chỉ load khi cần"""
        if not self._initialized:
            self.sentiment_model = pipeline(
                "sentiment-multilingual",
                model=self.SENTIMENT_MODEL,
                device=self._get_device(),
            )
            # Cache model instances
            self._initialized = True
```

---

## 7. Ma Trận Ưu Tiên & Effort Estimation

### Priority Matrix

| Priority | Module | Task | Effort | Timeline | Impact |
|----------|--------|------|--------|----------|--------|
| 🔴 P0 | Flutter | Fix Firebase SDK versions | 2h | Week 1 | Critical |
| 🔴 P0 | AI/ML | Evaluate and document ML baseline | 4h | Week 1 | High |
| 🔴 P0 | Testing | Add unit tests for critical paths | 16h | Week 1-2 | High |
| 🟠 P1 | UI | Unified state widgets (loading/empty/error) | 8h | Week 2 | Medium |
| 🟠 P1 | UI | Wellbeing dashboard components | 12h | Week 2-3 | High |
| 🟠 P1 | Notifications | Complete notification system | 16h | Week 2-3 | High |
| 🟠 P1 | Backend | Error handling + logging | 8h | Week 3 | Medium |
| 🟠 P1 | Backend | Health check endpoints | 4h | Week 3 | Medium |
| 🟡 P2 | AI/ML | Fine-tune Vietnamese sentiment model | 24h | Week 3-4 | High |
| 🟡 P2 | UI | Chat UI improvements | 12h | Week 3-4 | Medium |
| 🟡 P2 | Backend | Rate limiting | 4h | Week 4 | Medium |
| 🟡 P2 | CI/CD | GitHub Actions pipeline | 8h | Week 4 | High |
| 🟢 P3 | AI/ML | Sarcasm detection | 16h | Week 5 | Medium |
| 🟢 P3 | UI | Onboarding polish | 8h | Week 5 | Medium |
| 🟢 P3 | UI | Wave UI completion | 12h | Week 5 | Medium |
| 🟢 P3 | Backend | CORS + security hardening | 4h | Week 5 | Low |

### Suggested Sprint Plan (12 Weeks)

```
Week 1:  🔴 Firebase SDK Fix + ML Baseline Evaluation + Start Unit Tests
Week 2:  🔴 Unit Tests + Unified State Widgets
Week 3:  🟠 Wellbeing UI + Notification System (backend)
Week 4:  🟠 Notifications (Flutter) + Error Handling + Health Checks
Week 5:  🟡 Fine-tune Sentiment Model + Chat UI + Rate Limiting
Week 6:  🟡 CI/CD Pipeline + UI Polish + Wave UI
Week 7:  🟢 Sarcasm Detection + Onboarding + Responsive Polish
Week 8:  🟢 Integration Tests + Performance Optimization
Week 9:  🟢 E2E Tests + Bug Fixes Round 1
Week 10: 🎯 Full App Testing + Security Audit
Week 11: 🎯 Bug Fixes Round 2 + Documentation
Week 12: 🚀 Release Prep + Deployment
```

---

## Tổng Kết Checklist

### Trước MVP Release

- [x] ~~Fix Firebase SDK version mismatch~~ ✅ Đã fix: cập nhật lên Firebase SDK v3.x đồng bộ
- [x] ~~Hoàn thiện loading/empty/error states cho tất cả screens~~ ✅ Đã tạo unified state widgets (`aura_state_builder.dart`, `shimmer_loading.dart`, `error_widget.dart`)
- [x] ~~Unit tests cho core logic (emotion engine, feed, soul)~~ ✅ Đã tạo unit tests (`test_emotion_engine.py`, `test_soul_engine.py`, `test_vector_math.py`, `test_error_handler.py`)
- [x] ~~Error handling + structured logging (Backend)~~ ✅ Đã tạo `logging_config.py` + `error_handler.py` với JSON structured logging
- [x] ~~Health check endpoints~~ ✅ Đã thêm `/health` + `/health/ready` với checks cho Firebase, FCM, R2, ML models
- [x] ~~Notification system hoạt động đầy đủ~~ ✅ Đã tạo `notification_service.py` (FCM, smart scheduling, 8 notification types) + `notifications.py` router
- [x] ~~GitHub Actions CI pipeline~~ ✅ Đã tạo `.github/workflows/ci.yml` (Flutter tests, backend tests, build APK, Docker) và `deploy.yml` (Cloud Run)
- [x] ~~Basic documentation~~ ✅ Đã update: README thêm CI/CD Pipeline section, cấu trúc dự án, API examples
- [x] ~~Wellbeing dashboard charts~~ ✅ Đã tạo `mood_trend_chart.dart` (Line chart 7 ngày) + `emotion_distribution_chart.dart` (Pie chart) với fl_chart, tích hợp vào `wellbeing_screen.dart`
- [x] ~~Flutter unit tests cho EmotionProfileModel~~ ✅ Đã tạo `test/unit/emotion_profile_model_test.dart` - 7 tests passed (dominantEmotion, hasData, emotionCounts, moodTrendData)

### Sau MVP Release

- [ ] Fine-tune Vietnamese sentiment model
- [ ] Sarcasm/slang detection
- [ ] Advanced Wellbeing dashboard
- [ ] Full E2E test suite
- [ ] CD pipeline cho production
- [ ] Visual mockups (PNG/Figma)
- [ ] Performance benchmarks

---

> *"Your emotions shape your feed. Your feed heals your emotions."*
