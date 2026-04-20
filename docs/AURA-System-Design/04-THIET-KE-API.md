# AURA v3.0 – Thiết Kế API Chi Tiết (Hybrid Architecture)

> **Tài liệu:** 04/07 – API Design (FastAPI + Cloud Functions)  
> **Phiên bản:** 3.0 (Behavioral AI Edition)

---

## 1. Tổng Quan API Architecture (Hybrid)

AURA v3.0 API chia thành **2 layer**:

| Layer | Công nghệ | Vai trò | Giao tiếp |
|---|---|---|---|
| **AI Backend** | FastAPI (Python) | Toàn bộ AI/ML processing | Flutter → HTTP (dio) |
| **Event Triggers** | Cloud Functions (Python) | Lightweight triggers + cleanup | Firestore/RTDB triggers → call FastAPI |

### Tại Sao Chia 2 Layer?

```
Flutter App ──────┬──── Firebase SDK ──────► Firebase (data, auth, chat)
                  │
                  └──── dio HTTP ──────────► FastAPI (AI, recommendation, soul connect)
                  
Cloud Functions ──────── HTTP call ────────► FastAPI (content analysis on new post)
```

| So sánh | Cloud Functions (cũ) | FastAPI (mới) |
|---|---|---|
| Cold start | 2-10s cho AI | ❌ Không có |
| ML model reload | Mỗi cold start | Load 1 lần khi start |
| Memory | Max 8GB | Unlimited |
| Timeout | Max 540s | Unlimited |
| GPU | ❌ | ✅ (VPS/Cloud Run GPU) |

---

## 2. FastAPI AI Backend

### 2.1 Server Setup

```python
# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.ml.model_loader import ModelLoader
from app.utils.firebase_client import init_firebase
from app.routers import emotion, feed, soul, waves, content, wellbeing, prompts

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load ML models once at startup, reuse for all requests."""
    init_firebase()
    app.state.models = ModelLoader()
    app.state.models.load_all()  # Load HuggingFace, embeddings, etc.
    print("✅ All ML models loaded successfully")
    yield
    print("🔄 Shutting down...")

app = FastAPI(
    title="AURA AI Backend",
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

# Register routers
app.include_router(emotion.router, prefix="/api/v1/emotion", tags=["Emotion"])
app.include_router(feed.router, prefix="/api/v1/feed", tags=["Feed"])
app.include_router(soul.router, prefix="/api/v1/soul", tags=["Soul Connect"])
app.include_router(waves.router, prefix="/api/v1/waves", tags=["Waves"])
app.include_router(content.router, prefix="/api/v1/content", tags=["Content"])
app.include_router(wellbeing.router, prefix="/api/v1/wellbeing", tags=["Wellbeing"])
app.include_router(prompts.router, prefix="/api/v1/prompts", tags=["Prompts"])

@app.get("/health")
async def health_check():
    return {"status": "ok", "version": "3.0.0", "models_loaded": True}
```

### 2.2 Authentication Middleware

```python
# app/auth.py
from firebase_admin import auth as firebase_auth
from fastapi import Depends, HTTPException, Header

async def verify_firebase_token(authorization: str = Header(...)) -> dict:
    """
    Verify Firebase ID Token from Flutter client.
    Flutter sends: Authorization: Bearer <idToken>
    """
    try:
        token = authorization.replace("Bearer ", "")
        decoded = firebase_auth.verify_id_token(token)
        return decoded  # Contains uid, email, etc.
    except firebase_auth.InvalidIdTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
    except firebase_auth.ExpiredIdTokenError:
        raise HTTPException(status_code=401, detail="Token expired")
    except Exception:
        raise HTTPException(status_code=401, detail="Authentication failed")

# Internal auth for Cloud Functions → FastAPI calls
async def verify_internal_key(x_internal_key: str = Header(...)):
    """Verify that the request comes from our Cloud Functions."""
    import os
    if x_internal_key != os.environ.get("INTERNAL_API_KEY"):
        raise HTTPException(status_code=403, detail="Invalid internal key")
    return True
```

---

## 3. FastAPI Endpoints Chi Tiết

### 3.1 Emotion Inference API

#### `POST /api/v1/emotion/infer`

```python
# app/routers/emotion.py
from fastapi import APIRouter, Depends, Request
from app.auth import verify_firebase_token
from app.models.emotion import EmotionInferRequest, EmotionInferResponse
from app.services.emotion_inference import EmotionInferenceEngine

router = APIRouter()

@router.post("/infer", response_model=EmotionInferResponse)
async def infer_emotion(
    request: Request,
    body: EmotionInferRequest,
    user: dict = Depends(verify_firebase_token),
):
    """
    Core emotion inference endpoint.
    Called by Flutter client every 30s with behavioral batch.
    
    Input: Behavioral events batch
    Output: Updated emotion vector + emotional mode
    """
    uid = user["uid"]
    engine: EmotionInferenceEngine = request.app.state.models.emotion_engine
    db = get_firestore_client()
    
    # Get current emotion profile
    profile_doc = db.collection('users').document(uid) \
        .collection('emotion_profile').document('current').get()
    current_profile = profile_doc.to_dict() or {}
    
    # Layer 1: Behavioral
    behavioral = engine.analyze_behavioral(body.events)
    
    # Layer 2: Interactions
    interactions = engine.extract_interaction_signals(body.events)
    interaction_result = engine.analyze_interactions(interactions)
    
    # Layer 3: Text (from recent posts/comments)
    recent_texts = get_recent_user_texts(uid, db)
    text_result = engine.analyze_texts(recent_texts)
    
    # Layer 4: Temporal
    temporal = engine.analyze_temporal({
        'hour': datetime.now().hour,
        'day_of_week': datetime.now().weekday(),
        'session_gap_hours': body.session_gap_hours,
    })
    
    # Layer 5: Social
    social_data = get_social_signals(uid, db)
    social = engine.analyze_social(social_data)
    
    # FUSION
    result = engine.fuse_signals(
        behavioral, interaction_result, text_result, temporal, social
    )
    
    # Detect emotional mode
    mode = engine.detect_emotional_mode(result, current_profile.get('weekly_trend', {}))
    
    # Check significance
    old_vector = current_profile.get('current_emotion_vector', {})
    if not is_significant_change(old_vector, result['vector'], threshold=0.05):
        return EmotionInferResponse(
            emotion_vector=old_vector,
            changed=False,
            mode=current_profile.get('emotional_mode', 'explore'),
        )
    
    # Update Firestore
    dominant = max(result['vector'], key=result['vector'].get)
    confidence = calculate_confidence(body, current_profile)
    
    # Batch update: emotion profile + user summary
    batch = db.batch()
    
    profile_ref = db.collection('users').document(uid) \
        .collection('emotion_profile').document('current')
    batch.update(profile_ref, {
        'current_emotion_vector': result['vector'],
        'valence': result['valence'],
        'arousal': result['arousal'],
        'dominance': result['dominance'],
        'emotion_confidence': confidence,
        'emotional_mode': mode,
        'signals_used': ['behavioral', 'interaction', 'text', 'temporal', 'social'],
        'updated_at': firestore.SERVER_TIMESTAMP,
        'total_inferences': firestore.Increment(1),
    })
    
    user_ref = db.collection('users').document(uid)
    batch.update(user_ref, {
        'aura_dominant_emotion': dominant,
        'aura_valence': result['valence'],
        'aura_confidence': confidence,
        'emotional_mode': mode,
        'last_active_at': firestore.SERVER_TIMESTAMP,
    })
    
    batch.commit()
    
    return EmotionInferResponse(
        emotion_vector=result['vector'],
        valence=result['valence'],
        arousal=result['arousal'],
        dominance=result['dominance'],
        mode=mode,
        dominant=dominant,
        confidence=confidence,
        changed=True,
    )
```

**Request/Response Models:**
```python
# app/models/emotion.py
from pydantic import BaseModel
from typing import Optional

class BehavioralEvent(BaseModel):
    type: str  # "post_view", "interaction", "post_skip", "search"
    post_id: Optional[str] = None
    dwell_time_ms: Optional[int] = None
    scroll_speed_px_ms: Optional[float] = None
    action: Optional[str] = None
    reaction_type: Optional[str] = None
    query: Optional[str] = None
    timestamp: float

class EmotionInferRequest(BaseModel):
    events: list[BehavioralEvent]
    session_id: str
    session_gap_hours: float = 0.0

class EmotionInferResponse(BaseModel):
    emotion_vector: dict[str, float]
    valence: float = 0.0
    arousal: float = 0.0
    dominance: float = 0.0
    mode: str = "explore"
    dominant: str = "anticipation"
    confidence: float = 0.5
    changed: bool = False
```

---

### 3.2 Feed Generation API

#### `POST /api/v1/feed/generate`

```python
# app/routers/feed.py
@router.post("/generate", response_model=FeedResponse)
async def generate_feed(
    request: Request,
    body: FeedRequest,
    user: dict = Depends(verify_firebase_token),
):
    """
    Generate personalized For You feed.
    Called when user opens app or pull-to-refresh.
    """
    uid = user["uid"]
    db = get_firestore_client()
    
    # Check cache
    if not body.force_refresh and body.page == 1:
        cache = db.collection('users').document(uid) \
            .collection('feed_cache').document('for_you').get()
        if cache.exists:
            cache_data = cache.to_dict()
            age_min = (datetime.now() - cache_data['generated_at'].replace(tzinfo=None)).seconds / 60
            if age_min < 30:
                return FeedResponse.from_cache(cache_data)
    
    # Get user data
    user_data = db.collection('users').document(uid).get().to_dict()
    emotion = db.collection('users').document(uid) \
        .collection('emotion_profile').document('current').get().to_dict() or {}
    
    following = [d.id for d in db.collection('users').document(uid) \
        .collection('following').get()]
    
    user_profile = {**user_data, **emotion, 'following_ids': following}
    
    # Stage 1: Candidate Generation
    pipeline = request.app.state.models.recommendation_pipeline
    candidates = pipeline.generate_candidates(uid, user_profile, db)
    
    # Stage 2: Score & Rank
    scored = pipeline.score_and_rank(candidates, user_profile)
    
    # Stage 3: Emotional Balancing + Wellbeing Guard
    if user_data.get('ai_settings', {}).get('wellbeing_guard_enabled', True):
        final = pipeline.apply_wellbeing_guard(scored[:50], user_profile)
    else:
        final = scored[:50]
    
    # Paginate
    page_size = 20
    start = (body.page - 1) * page_size
    page_posts = final[start:start + page_size]
    
    # Cache page 1
    if body.page == 1:
        db.collection('users').document(uid) \
            .collection('feed_cache').document('for_you').set({
                'posts': [{'post_id': p['post_id'], 'score': p['feed_score']} for p in final],
                'emotional_mode': user_profile.get('emotional_mode'),
                'generated_at': firestore.SERVER_TIMESTAMP,
                'user_emotion_at_generation': {
                    'valence': emotion.get('valence', 0),
                    'dominant': user_data.get('aura_dominant_emotion', 'explore'),
                },
            })
    
    return FeedResponse(
        posts=[serialize_post(p) for p in page_posts],
        emotional_mode=user_profile.get('emotional_mode', 'explore'),
        has_more=start + page_size < len(final),
    )
```

---

### 3.3 Soul Connect API

#### `POST /api/v1/soul/compute` (Scheduled, called by Cloud Functions or background task)

```python
@router.post("/compute")
async def compute_soul_scores(
    request: Request,
    _: bool = Depends(verify_internal_key),  # Internal only
):
    """
    Batch compute soul compatibility scores.
    Called by Cloud Scheduler → Cloud Functions → FastAPI.
    """
    db = get_firestore_client()
    engine = request.app.state.models.soul_engine
    
    # Get active users with soul_connect enabled
    cutoff = datetime.now() - timedelta(hours=24)
    active_users = db.collection('users') \
        .where('last_active_at', '>=', cutoff) \
        .where('account_status', '==', 'active').get()
    
    users_data = []
    for doc in active_users:
        user = doc.to_dict()
        if not user.get('ai_settings', {}).get('soul_connect_enabled', True):
            continue
        emotion = doc.reference.collection('emotion_profile').document('current').get()
        if emotion.exists:
            user.update(emotion.to_dict())
        users_data.append(user)
    
    # Compare pairs
    new_suggestions = engine.batch_compute_and_suggest(users_data, db)
    
    return {"new_suggestions": new_suggestions, "users_analyzed": len(users_data)}
```

#### `POST /api/v1/soul/suggestions`

```python
@router.post("/suggestions", response_model=SoulSuggestionsResponse)
async def get_soul_suggestions(
    request: Request,
    body: SoulSuggestionsRequest,
    user: dict = Depends(verify_firebase_token),
):
    """Get soul connection suggestions for current user."""
    uid = user["uid"]
    db = get_firestore_client()
    limit = body.limit or 10
    
    suggestions = []
    for field in ['user_a_id', 'user_b_id']:
        docs = db.collection('soul_connections') \
            .where(field, '==', uid) \
            .where('status', '==', 'suggested') \
            .order_by('soul_score', direction='DESCENDING') \
            .limit(limit).get()
        suggestions.extend(docs)
    
    result = []
    for doc in suggestions:
        conn = doc.to_dict()
        other_uid = conn['user_b_id'] if conn['user_a_id'] == uid else conn['user_a_id']
        other = db.collection('users').document(other_uid).get().to_dict()
        result.append({
            'connection_id': doc.id,
            'soul_score': conn['soul_score'],
            'connection_type': conn['connection_type'],
            'breakdown': conn['compatibility_breakdown'],
            'other_user': {
                'uid': other_uid,
                'display_name': other.get('display_name', ''),
                'avatar_url': other.get('avatar_url', ''),
                'bio': other.get('bio', ''),
                'aura_dominant_emotion': other.get('aura_dominant_emotion', ''),
            }
        })
    
    result.sort(key=lambda x: x['soul_score'], reverse=True)
    return SoulSuggestionsResponse(suggestions=result[:limit])
```

---

### 3.4 Content Analysis API

#### `POST /api/v1/content/analyze`

```python
@router.post("/analyze", response_model=ContentAnalysisResponse)
async def analyze_content(
    request: Request,
    body: ContentAnalysisRequest,
    _: bool = Depends(verify_internal_key),  # Called by Cloud Functions only
):
    """
    Analyze post/comment content.
    Called by Cloud Function on_new_post trigger.
    """
    analyzer = request.app.state.models.content_analyzer
    
    result = analyzer.analyze(
        text=body.content,
        media_urls=body.media_urls,
    )
    
    return ContentAnalysisResponse(
        ai_emotion_vector=result['emotion_vector'],
        ai_valence=result['valence'],
        ai_sentiment=result['sentiment'],
        ai_sentiment_score=result['sentiment_score'],
        content_embedding=result['embedding'],
        quality_score=result['quality_score'],
        is_toxic=result['is_toxic'],
        toxicity_score=result['toxicity_score'],
        crisis_detected=result.get('crisis_detected', False),
    )
```

---

### 3.5 Waves API

#### `POST /api/v1/waves/detect`

```python
@router.post("/detect")
async def detect_waves(
    request: Request,
    _: bool = Depends(verify_internal_key),  # Scheduled
):
    """Scan active users, detect emotion clusters, create waves."""
    db = get_firestore_client()
    generator = request.app.state.models.wave_generator
    
    active_users = db.collection('users').where('is_online', '==', True).get()
    users_with_emotions = []
    for doc in active_users:
        user = doc.to_dict()
        emotion = doc.reference.collection('emotion_profile').document('current').get()
        if emotion.exists:
            user.update(emotion.to_dict())
            users_with_emotions.append(user)
    
    new_waves = generator.detect_and_create_waves(users_with_emotions, db)
    return {"new_waves_created": len(new_waves)}
```

---

### 3.6 Wellbeing API

#### `POST /api/v1/wellbeing/check`

```python
@router.post("/check", response_model=WellbeingCheckResponse)
async def check_wellbeing(
    request: Request,
    body: WellbeingCheckRequest,
    user: dict = Depends(verify_firebase_token),
):
    """
    Check if wellbeing intervention needed.
    Called by Flutter client periodically during session.
    """
    uid = user["uid"]
    guard = request.app.state.models.wellbeing_guard
    
    result = guard.check(
        uid=uid,
        session_duration_min=body.session_duration_min,
        posts_viewed=body.posts_viewed,
        negative_streak=body.negative_streak,
        current_valence=body.current_valence,
    )
    
    return WellbeingCheckResponse(
        action=result['action'],  # "none" | "positive_inject" | "session_break"
        title=result.get('title'),
        message=result.get('message'),
    )
```

---

## 4. Cloud Functions (Lightweight Triggers)

Cloud Functions **chỉ** xử lý event triggers + cleanup, KHÔNG chạy AI:

### 4.1 Tổng Hợp Cloud Functions

| # | Function | Trigger | Memory | Vai trò |
|---|---|---|---|---|
| 1 | `on_user_created` | Auth onCreate | 256MB | Init user doc + emotion profile |
| 2 | `on_user_deleted` | Auth onDelete | 512MB | GDPR cascade delete |
| 3 | `on_new_post` | Firestore onCreate | 256MB | Call FastAPI `/content/analyze` → update post |
| 4 | `on_new_message` | RTDB onWrite | 256MB | Update conversation + push notification |
| 5 | `on_connection_action` | Firestore onUpdate | 256MB | Create conversation when both accept |
| 6 | `on_follow` | Firestore onCreate | 256MB | Update counts + notify |
| 7 | `on_wave_member_change` | Firestore onCreate/Delete | 256MB | Update member count |
| 8 | `on_report_created` | Firestore onCreate | 256MB | Queue for moderation |
| 9 | `trigger_soul_compute` | Scheduled (30 min) | 256MB | Call FastAPI `/soul/compute` |
| 10 | `trigger_wave_detect` | Scheduled (15 min) | 256MB | Call FastAPI `/waves/detect` |
| 11 | `cleanup_behavioral_events` | Scheduled (daily) | 256MB | Delete 30-day old events |
| 12 | `cleanup_expired_waves` | Scheduled (hourly) | 256MB | Archive dead waves |
| 13 | `cleanup_old_notifications` | Scheduled (daily) | 256MB | Remove 90-day old notifications |

### 4.2 Cloud Function Code Examples

```python
# Cloud Function: Trigger khi post mới → call FastAPI
import requests

FASTAPI_URL = os.environ.get("FASTAPI_URL")  # https://aura-ai-xxxxx.run.app
INTERNAL_KEY = os.environ.get("INTERNAL_API_KEY")

@firestore_fn.on_document_created(
    document="posts/{postId}",
    region="asia-southeast1",
    memory=options.MemoryOption.MB_256,
)
def on_new_post(event):
    """Lightweight trigger: call FastAPI for content analysis."""
    post_data = event.data.to_dict()
    post_id = event.params['postId']
    
    # Call FastAPI
    response = requests.post(
        f"{FASTAPI_URL}/api/v1/content/analyze",
        json={
            "content": post_data.get("content", ""),
            "media_urls": post_data.get("media_urls", []),
        },
        headers={"X-Internal-Key": INTERNAL_KEY},
        timeout=30,
    )
    
    if response.status_code == 200:
        result = response.json()
        event.data.reference.update({
            'ai_emotion_vector': result['ai_emotion_vector'],
            'ai_valence': result['ai_valence'],
            'ai_sentiment': result['ai_sentiment'],
            'ai_sentiment_score': result['ai_sentiment_score'],
            'content_embedding': result['content_embedding'],
            'quality_score': result['quality_score'],
            'is_toxic': result['is_toxic'],
            'toxicity_score': result['toxicity_score'],
            'crisis_detected': result.get('crisis_detected', False),
        })
    
    # Update post count
    db = firestore.client()
    db.collection('users').document(post_data['user_id']).update({
        'posts_count': firestore.Increment(1),
    })
```

```python
# Scheduled: Trigger soul compute
@scheduler_fn.on_schedule(
    schedule="every 30 minutes",
    region="asia-southeast1",
    memory=options.MemoryOption.MB_256,
)
def trigger_soul_compute(event):
    """Just calls FastAPI to run soul score computation."""
    response = requests.post(
        f"{FASTAPI_URL}/api/v1/soul/compute",
        headers={"X-Internal-Key": INTERNAL_KEY},
        timeout=300,
    )
    logger.info(f"Soul compute result: {response.json()}")
```

```python
# Scheduled: Trigger wave detection
@scheduler_fn.on_schedule(
    schedule="every 15 minutes",
    region="asia-southeast1",
    memory=options.MemoryOption.MB_256,
)
def trigger_wave_detect(event):
    """Just calls FastAPI to run wave detection."""
    response = requests.post(
        f"{FASTAPI_URL}/api/v1/waves/detect",
        headers={"X-Internal-Key": INTERNAL_KEY},
        timeout=120,
    )
    logger.info(f"Wave detect result: {response.json()}")
```

---

## 5. Client-Side API Calls (Flutter)

### 5.1 API Service Base

```dart
class AuraApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://aura-ai-xxxxx.run.app',
  );
  
  final Dio _dio;
  
  AuraApiService() : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  )) {
    _dio.interceptors.add(AuthInterceptor());
  }
}

/// Auto-attach Firebase ID Token to every request
class AuthInterceptor extends Interceptor {
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
}
```

### 5.2 Behavioral Tracker (sends to FastAPI)

```dart
class BehavioralTracker {
  static const _batchIntervalSeconds = 30;
  final AuraApiService _api;
  final List<Map<String, dynamic>> _eventBuffer = [];
  Timer? _batchTimer;
  String? _sessionId;
  DateTime? _lastSessionEnd;
  
  BehavioralTracker(this._api);
  
  void startSession() {
    _sessionId = const Uuid().v4();
    _batchTimer = Timer.periodic(
      Duration(seconds: _batchIntervalSeconds),
      (_) => _flushBatch(),
    );
  }
  
  void trackPostView(String postId, int dwellTimeMs, double scrollSpeed) {
    _eventBuffer.add({
      'type': 'post_view',
      'post_id': postId,
      'dwell_time_ms': dwellTimeMs,
      'scroll_speed_px_ms': scrollSpeed,
      'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
    });
  }
  
  void trackInteraction(String postId, String action, String? reactionType) {
    _eventBuffer.add({
      'type': 'interaction',
      'action': action,
      'reaction_type': reactionType,
      'post_id': postId,
      'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
    });
  }
  
  Future<void> _flushBatch() async {
    if (_eventBuffer.isEmpty) return;
    
    final events = List<Map<String, dynamic>>.from(_eventBuffer);
    _eventBuffer.clear();
    
    try {
      // Also store in Firestore for backup/audit
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('behavioral_events')
          .add({
            'session_id': _sessionId,
            'timestamp': FieldValue.serverTimestamp(),
            'events': events,
            'processed': false,
          });
      
      // Call FastAPI for real-time emotion inference
      final sessionGap = _lastSessionEnd != null
          ? DateTime.now().difference(_lastSessionEnd!).inHours.toDouble()
          : 0.0;
      
      await _api._dio.post('/api/v1/emotion/infer', data: {
        'events': events,
        'session_id': _sessionId,
        'session_gap_hours': sessionGap,
      });
    } catch (e) {
      // Fallback: data is in Firestore, can be processed later
      debugPrint('Emotion inference failed: $e');
    }
  }
  
  void dispose() {
    _batchTimer?.cancel();
    _lastSessionEnd = DateTime.now();
    _flushBatch();
  }
}
```

### 5.3 Feed Service

```dart
class FeedService {
  final AuraApiService _api;
  
  FeedService(this._api);
  
  /// Get For You feed from FastAPI
  Future<FeedResult> getForYouFeed({int page = 1, bool refresh = false}) async {
    final response = await _api._dio.post('/api/v1/feed/generate', data: {
      'page': page,
      'force_refresh': refresh,
    });
    return FeedResult.fromMap(response.data);
  }
  
  /// Get Following feed (direct Firestore query - no AI needed)
  Stream<List<Post>> getFollowingFeed(String uid) {
    return FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('following')
        .snapshots()
        .asyncMap((following) async {
          final ids = following.docs.map((d) => d.id).toList();
          if (ids.isEmpty) return <Post>[];
          
          final posts = await FirebaseFirestore.instance
              .collection('posts')
              .where('user_id', whereIn: ids.take(10).toList())
              .orderBy('created_at', descending: true)
              .limit(20)
              .get();
          
          return posts.docs.map((d) => Post.fromFirestore(d)).toList();
        });
  }
}
```

### 5.4 Soul Connect Service

```dart
class SoulConnectService {
  final AuraApiService _api;
  
  SoulConnectService(this._api);
  
  Future<List<SoulSuggestion>> getSuggestions({int limit = 10}) async {
    final response = await _api._dio.post('/api/v1/soul/suggestions', data: {
      'limit': limit,
    });
    return (response.data['suggestions'] as List)
        .map((s) => SoulSuggestion.fromMap(s))
        .toList();
  }
  
  /// Accept/Reject uses Firestore directly (security rules handle validation)
  Future<void> respondToConnection(String connectionId, String action) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('soul_connections').doc(connectionId).get();
    final data = doc.data()!;
    
    final field = data['user_a_id'] == uid ? 'user_a_action' : 'user_b_action';
    await doc.reference.update({
      field: action,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
```

### 5.5 Wellbeing Service

```dart
class WellbeingService {
  final AuraApiService _api;
  
  WellbeingService(this._api);
  
  Future<WellbeingCheck> checkWellbeing({
    required int sessionDurationMin,
    required int postsViewed,
    required int negativeStreak,
    required double currentValence,
  }) async {
    final response = await _api._dio.post('/api/v1/wellbeing/check', data: {
      'session_duration_min': sessionDurationMin,
      'posts_viewed': postsViewed,
      'negative_streak': negativeStreak,
      'current_valence': currentValence,
    });
    return WellbeingCheck.fromMap(response.data);
  }
}
```

---

## 6. API Flow Diagrams

### 6.1 Emotion Inference Flow (Hybrid)

```
Flutter App                   FastAPI                    Firestore
    │                            │                          │
    │ ──30s batch──────────────► │                          │
    │  POST /emotion/infer       │                          │
    │  {events: [...]}           │                          │
    │                            │ ◄──── Read profile ───── │
    │                            │                          │
    │                            │ 5-layer analysis         │
    │                            │ Signal fusion            │
    │                            │ Mode detection           │
    │                            │                          │
    │                            │ ────── Write update ───► │
    │                            │  emotion_profile/current │
    │                            │  users/{uid}.aura_*      │
    │                            │                          │
    │ ◄──── Response ──────────  │                          │
    │  {vector, mode, changed}   │                          │
    │                            │                          │
    │ ──Also store backup─────────────────────────────────► │
    │  behavioral_events/{batch} │                          │
```

### 6.2 New Post Flow (Hybrid)

```
Flutter App                 Firestore              Cloud Function         FastAPI
    │                          │                        │                    │
    │ ─── Create post ───────► │                        │                    │
    │                          │ ── Trigger ──────────► │                    │
    │                          │                        │                    │
    │                          │                        │ ── POST ─────────► │
    │                          │                        │   /content/analyze │
    │                          │                        │   {content: "..."} │
    │                          │                        │                    │
    │                          │                        │ ◄── Response ───── │
    │                          │                        │   {emotion_vector, │
    │                          │                        │    sentiment, ...} │
    │                          │                        │                    │
    │                          │ ◄── Update post ────── │                    │
    │                          │   ai_emotion_vector    │                    │
    │                          │   content_embedding    │                    │
    │                          │   quality_score        │                    │
    │                          │                        │                    │
    │ ◄── Realtime update ──── │ (stream listener)      │                    │
```

---

## 7. Deployment

### 7.1 FastAPI Deployment

| Option | Pros | Cons | Chi phí |
|---|---|---|---|
| **Cloud Run** (recommended) | Auto-scale, min 1 instance, GCP integration | Cold start nếu scale to 0 | $50-200/mo |
| **Railway** | Simple deploy, Git push | Ít tuỳ chỉnh | $20-50/mo |
| **VPS (DigitalOcean/Vultr)** | Full control, GPU option | Manual scaling | $20-100/mo |
| **Render** | Free tier available | Cold start on free | Free-$50/mo |

### 7.2 Docker Configuration

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Download models at build time
RUN python -c "from app.ml.model_loader import ModelLoader; ModelLoader().download_models()"

EXPOSE 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "2"]
```

### 7.3 Requirements

```txt
fastapi==0.109.0
uvicorn==0.27.0
firebase-admin==6.3.0
transformers==4.38.0
torch==2.1.2
numpy==1.26.4
scikit-learn==1.4.0
pydantic==2.6.0
python-dotenv==1.0.0
httpx==0.26.0
```

---

## 8. Error Handling & Rate Limiting

### 8.1 Error Codes

| Code | HTTP Status | Meaning |
|---|---|---|
| `unauthenticated` | 401 | Invalid/expired Firebase token |
| `forbidden` | 403 | Invalid internal key |
| `not_found` | 404 | Resource not found |
| `rate_limited` | 429 | Too many requests |
| `internal_error` | 500 | Server/AI error |

### 8.2 Rate Limits (FastAPI)

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/generate")
@limiter.limit("10/minute")  # 10 feed generations per min per user
async def generate_feed(...):
    ...
```

| Endpoint | Limit | Per |
|---|---|---|
| `/feed/generate` | 10 calls | per minute per user |
| `/soul/suggestions` | 5 calls | per minute per user |
| `/emotion/infer` | 2 calls | per minute per user |
| `/wellbeing/check` | 5 calls | per minute per user |

---

> **Tài liệu tiếp theo:** [05-FRONTEND-FLUTTER.md](./05-FRONTEND-FLUTTER.md)
