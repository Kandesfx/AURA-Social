# AURA v3.0 – Thiết Kế Cơ Sở Dữ Liệu Chi Tiết

> **Tài liệu:** 02/07 – Database Design  
> **Phiên bản:** 3.0 (Behavioral AI Edition)

---

## 1. Tổng Quan Database Architecture

AURA v3.0 sử dụng dual-database strategy:

| Database | Vai trò | Dữ liệu |
|---|---|---|
| **Cloud Firestore** | Primary structured data, AI state | Users, Posts, Emotion Profiles, Waves, Soul Connections, Behavioral Events, Notifications, Feed Cache |
| **Realtime Database** | High-frequency real-time data | Chat Messages, Typing Indicators, Online Presence, Wave Live Chat |

### Sự Thay Đổi Từ v2.0

| Collection/Path | v2.0 | v3.0 |
|---|---|---|
| `users` | `current_mood` field (string) | `emotion_profile` subcollection |
| `posts` | `mood_tag` field | `ai_emotion_vector`, `content_embedding` |
| `rooms` | Static Vibe Rooms | → Replaced by `waves` (dynamic) |
| `matches` | Rule-based mood match | → Replaced by `soul_connections` |
| **(New)** `behavioral_events` | N/A | Subcollection of `users` |
| **(New)** `feed_cache` | N/A | Subcollection of `users` |
| **(New)** `waves` | N/A | Top-level collection |
| **(New)** `soul_connections` | N/A | Top-level collection |

---

## 2. Cloud Firestore Collections

### 2.1 Collection: `users`

```javascript
// Document: /users/{userId}
{
  // === Identity ===
  "uid": "firebase-auth-uid",
  "email": "user@example.com",
  "display_name": "Minh Anh",
  "username": "minhanh_", 
  "avatar_url": "gs://aura-social-v3.appspot.com/avatars/{uid}.jpg",
  "bio": "Just vibing through life ✨",
  "date_of_birth": Timestamp,
  "gender": "female",          // "male" | "female" | "non-binary" | "prefer_not_to_say"
  
  // === Interests ===
  "interests": ["music", "travel", "art", "psychology", "cooking"],
  
  // === Social Stats ===
  "followers_count": 42,
  "following_count": 58,
  "posts_count": 15,
  "connections_count": 8,      // Soul Connect count
  
  // === Emotion State (summary from emotion_profile) ===
  "aura_dominant_emotion": "joy",     // For display / Aura Ring color
  "aura_valence": 0.65,               // Quick access for queries
  "aura_confidence": 0.78,
  "emotional_mode": "explore",        // Current mode
  
  // === AI Preferences ===
  "ai_settings": {
    "emotion_inference_enabled": true,
    "behavioral_tracking_enabled": true,
    "mood_expression_enabled": true,    // Optional mood sharing
    "wellbeing_guard_enabled": true,
    "soul_connect_enabled": true,
    "aura_ring_visible": true,          // Show/hide Aura Ring to others
    "fer_enabled": false,               // Phase 3: Facial recognition
    "keystroke_enabled": false,         // Phase 3: Keystroke dynamics
  },
  
  // === Status ===
  "is_online": false,
  "last_active_at": Timestamp,
  "account_status": "active",  // "active" | "suspended" | "deleted"
  
  // === System ===
  "fcm_token": "firebase-messaging-token",
  "created_at": Timestamp,
  "updated_at": Timestamp,
  "app_version": "3.0.0",
  "privacy_consent_at": Timestamp,     // GDPR/AI Act consent
  "privacy_consent_version": "3.0",
}
```

### 2.2 Subcollection: `users/{userId}/emotion_profile`

```javascript
// Document: /users/{userId}/emotion_profile/current
// Single document, continuously updated by Emotion Inference Engine
{
  // === Real-time Emotion Vector (8D Plutchik) ===
  "current_emotion_vector": {
    "joy": 0.35,
    "trust": 0.20,
    "anticipation": 0.15,
    "surprise": 0.05,
    "sadness": 0.10,
    "fear": 0.02,
    "anger": 0.03,
    "disgust": 0.01
  },
  
  // === Meta-Dimensions ===
  "valence": 0.65,           // -1.0 (negative) to 1.0 (positive)
  "arousal": 0.45,           // 0.0 (calm) to 1.0 (excited)
  "dominance": 0.55,         // 0.0 (submissive) to 1.0 (dominant)
  
  // === Inference Metadata ===
  "emotion_confidence": 0.78,
  "emotion_source": "inferred",     // "inferred" | "expressed" | "hybrid"
  "emotional_mode": "explore",       // "gentle_uplift" | "empathetic_mirror" | "amplify" | "deep_chill" | "explore"
  "signals_used": ["behavioral", "interaction", "text"],
  
  // === Behavioral Fingerprint ===
  "behavior_signals": {
    "avg_scroll_speed": 2.3,          // px/ms
    "avg_dwell_time": 4.5,            // seconds
    "session_frequency": "high",       // "low" | "medium" | "high"
    "interaction_rate": 0.12,          // interactions / posts viewed
    "content_preference_vector": [0.3, 0.7, 0.1, ...],  // 64D embedding
    "peak_activity_hours": [22, 23, 0, 1],
    "reaction_distribution": {         // Which reactions user gives most
      "joy": 0.40,
      "trust": 0.25,
      "sadness": 0.15,
      "anger": 0.05,
      "surprise": 0.10,
      "anticipation": 0.03,
      "fear": 0.01,
      "disgust": 0.01
    }
  },
  
  // === Weekly Emotional Pattern ===
  "weekly_pattern": {
    "mon": {"dominant": "anticipation", "valence": 0.2},
    "tue": {"dominant": "trust", "valence": 0.3},
    "wed": {"dominant": "sadness", "valence": -0.1},
    "thu": {"dominant": "sadness", "valence": -0.2},
    "fri": {"dominant": "joy", "valence": 0.5},
    "sat": {"dominant": "joy", "valence": 0.7},
    "sun": {"dominant": "trust", "valence": 0.4}
  },
  "weekly_emotion_pattern_vector": [...],   // Flattened 7×8=56D vector for matching
  
  // === Emotional Trends ===
  "weekly_trend": {
    "dominant_emotion": "joy",
    "stability_score": 0.7,         // 0 = volatile, 1 = stable
    "trend_direction": "improving",  // "improving" | "stable" | "declining"
    "avg_valence": 0.35,
    "sessions_count": 28
  },
  
  // === Timestamps ===
  "updated_at": Timestamp,
  "last_calibration_at": Timestamp,    // User manually confirmed/corrected
  "first_inference_at": Timestamp,
  "total_inferences": 156
}
```

### 2.3 Subcollection: `users/{userId}/behavioral_events`

```javascript
// Document: /users/{userId}/behavioral_events/{batchId}
// Written by client every 30 seconds during active session
// Processed by Cloud Function, then aged out (30 days retention)
{
  "session_id": "uuid-session-id",
  "batch_number": 3,
  "timestamp": Timestamp,
  
  "events": [
    {
      "type": "post_view",
      "post_id": "post-123",
      "dwell_time_ms": 4500,
      "scroll_speed_px_ms": 2.1,
      "scroll_depth_percent": 0.85,
      "timestamp": Timestamp
    },
    {
      "type": "interaction",
      "action": "reaction",
      "reaction_type": "joy",
      "post_id": "post-456",
      "timestamp": Timestamp
    },
    {
      "type": "post_skip",
      "post_id": "post-789",
      "time_before_skip_ms": 800,
      "timestamp": Timestamp
    },
    {
      "type": "search",
      "query": "lo-fi music",
      "timestamp": Timestamp
    }
  ],
  
  // === Session Metadata ===
  "session_duration_sec": 180,
  "posts_viewed": 12,
  "posts_interacted": 3,
  "posts_skipped": 4,
  
  // === Processing Status ===
  "processed": false,
  "processed_at": null
}
```

### 2.4 Subcollection: `users/{userId}/feed_cache`

```javascript
// Document: /users/{userId}/feed_cache/for_you
// Pre-computed by recommendation pipeline, read by Flutter client
{
  "posts": [
    {
      "post_id": "post-001",
      "score": 0.92,
      "reason": "emotional_resonance",    // Why this post was recommended
      "position": 0
    },
    {
      "post_id": "post-042",
      "score": 0.88,
      "reason": "collaborative",
      "position": 1
    },
    // ... top 50 posts
  ],
  
  "emotional_mode": "explore",
  "generated_at": Timestamp,
  "expires_at": Timestamp,     // Refresh after 30 min or pull-to-refresh
  "user_emotion_at_generation": {
    "valence": 0.65,
    "arousal": 0.45,
    "dominant": "joy"
  },
  
  // Break cards injected by Wellbeing Guard
  "break_cards": [
    {
      "position": 15,
      "type": "positive_inject",
      "title": "✨ Góc tươi sáng"
    }
  ]
}
```

### 2.5 Collection: `posts`

```javascript
// Document: /posts/{postId}
{
  "post_id": "auto-generated-id",
  "user_id": "author-uid",
  
  // === Content ===
  "content": "Hôm nay mình cảm thấy rất tốt sau khi chạy bộ buổi sáng! 🏃‍♂️",
  "media_urls": ["gs://aura-social-v3.appspot.com/posts/{postId}/img1.jpg"],
  "media_type": "image",        // "none" | "image" | "video" | "audio"
  
  // === AI Analysis (auto-populated by Cloud Function) ===
  "ai_emotion_vector": {
    "joy": 0.50, "trust": 0.15, "anticipation": 0.20,
    "surprise": 0.05, "sadness": 0.02, "fear": 0.01,
    "anger": 0.01, "disgust": 0.01
  },
  "ai_valence": 0.72,
  "ai_sentiment": "positive",
  "ai_sentiment_score": 0.72,
  "content_embedding": [0.12, -0.34, ...],   // 64D embedding for recommendation
  "quality_score": 0.75,

  // === User Expression (optional) ===
  "mood_expression": "happy",     // null if user didn't tag
  
  // === Engagement Metrics ===
  "reactions_count": 24,
  "reactions_breakdown": {
    "joy": 15, "trust": 5, "anticipation": 2,
    "surprise": 1, "sadness": 0, "fear": 0,
    "anger": 0, "disgust": 0
  },
  "comments_count": 8,
  "shares_count": 3,
  "saves_count": 5,
  "views_count": 120,
  "avg_dwell_time_ms": 5200,      // Average time users spend viewing
  
  // === Moderation ===
  "is_toxic": false,
  "toxicity_score": 0.02,
  "crisis_detected": false,
  "report_count": 0,
  "status": "active",            // "active" | "hidden" | "removed"
  
  // === Meta ===
  "created_at": Timestamp,
  "updated_at": Timestamp,
}
```

### 2.6 Subcollection: `posts/{postId}/comments`

```javascript
// Document: /posts/{postId}/comments/{commentId}
{
  "comment_id": "auto-id",
  "user_id": "commenter-uid",
  "content": "Tuyệt vời quá! Keep it up 💪",
  
  // AI Analysis
  "ai_sentiment": "positive",
  "ai_sentiment_score": 0.85,
  
  "reactions_count": 3,
  "created_at": Timestamp
}
```

### 2.7 Collection: `soul_connections`

```javascript
// Document: /soul_connections/{connectionId}
{
  "connection_id": "auto-id",
  "user_a_id": "uid-A",
  "user_b_id": "uid-B",
  "participants": ["uid-A", "uid-B"],   // Array for querying both
  
  // === Soul Score (computed by AI) ===
  "soul_score": 0.85,
  "compatibility_breakdown": {
    "emotional_pattern": 0.88,
    "content_taste": 0.82,
    "complementary": 0.90,
    "interests": 0.75,
    "activity": 0.80
  },
  "connection_type": "Kindred Spirit",   // Human-readable
  "reason": "emotional_pattern",          // Primary factor
  
  // === Status ===
  "status": "active",      // "suggested" | "pending" | "active" | "rejected" | "blocked"
  "suggested_at": Timestamp,
  "user_a_action": "accept",    // "accept" | "reject" | null
  "user_b_action": "accept",
  "connected_at": Timestamp,
  
  // === Conversation ===
  "conversation_id": "conv-id",  // Link to RTDB chat
  "last_interaction_at": Timestamp,
  
  // === Meta ===
  "created_at": Timestamp,
  "updated_at": Timestamp
}
```

### 2.8 Collection: `waves`

```javascript
// Document: /waves/{waveId}
{
  "wave_id": "auto-id",
  
  // === Theme ===
  "title": "Đêm Không Ngủ 🌊",
  "emoji": "🌊",
  "description": "Dành cho những ai đang thức khuya và cần ai đó trò chuyện",
  
  // === AI Context ===
  "emotion_cluster_center": {
    "joy": 0.05, "trust": 0.30, "anticipation": 0.10,
    "surprise": 0.05, "sadness": 0.30, "fear": 0.10,
    "anger": 0.05, "disgust": 0.05
  },
  "dominant_emotion": "sadness",
  "trigger_signals": ["late_night_activity_spike", "loneliness_cluster"],
  
  // === Lifecycle ===
  "status": "active",          // "forming" | "active" | "fading" | "archived"
  "momentum": 0.85,            // 0.0-1.0, below 0.2 → auto-close
  "max_members": 50,
  "member_count": 32,
  "message_count": 245,
  
  // === Access ===
  "is_public": true,
  "min_emotion_similarity": 0.6,  // Min similarity to join
  
  // === Timing ===
  "created_at": Timestamp,
  "peak_at": Timestamp,
  "estimated_end_at": Timestamp,
  "ended_at": null
}
```

### 2.9 Subcollection: `waves/{waveId}/members`

```javascript
// Document: /waves/{waveId}/members/{userId}
{
  "uid": "user-uid",
  "display_name": "Minh Anh",
  "avatar_url": "...",
  "aura_dominant_emotion": "sadness",
  "joined_at": Timestamp,
  "last_active_at": Timestamp,
  "message_count": 8,
  "status": "active"       // "active" | "left"
}
```

### 2.10 Collection: `conversations`

```javascript
// Document: /conversations/{conversationId}
{
  "conversation_id": "auto-id",
  "type": "direct",             // "direct" | "soul_connect"
  "participants": ["uid-A", "uid-B"],
  
  // === Last Message (denormalized for list display) ===
  "last_message": {
    "content": "Haha mình cũng vậy!",
    "sender_id": "uid-A",
    "timestamp": Timestamp,
    "type": "text"
  },
  
  // === Unread Counts ===
  "unread_counts": {
    "uid-A": 0,
    "uid-B": 3
  },
  
  // === Connection Reference ===
  "soul_connection_id": "conn-id",  // null for non-soul conversations
  
  // === Meta ===
  "created_at": Timestamp,
  "updated_at": Timestamp
}
```

### 2.11 Collection: `notifications`

```javascript
// Document: /notifications/{notificationId}
{
  "notification_id": "auto-id",
  "user_id": "target-uid",
  
  "type": "soul_suggestion",    
  // Types: "soul_suggestion" | "soul_accepted" | "wave_invite" | 
  //        "new_message" | "post_reaction" | "post_comment" |
  //        "new_follower" | "wellbeing_insight" | "system"
  
  "title": "Ai đó đồng điệu với bạn 💜",
  "body": "Một Kindred Spirit vừa được tìm thấy. Nói xin chào?",
  
  // === References ===
  "reference_type": "soul_connection",
  "reference_id": "conn-id",
  
  "sender_id": "sender-uid",     // null for system notifications
  "sender_name": "Hoàng Anh",
  "sender_avatar": "...",
  
  // === Status ===
  "is_read": false,
  "read_at": null,
  
  "created_at": Timestamp
}
```

### 2.12 Collection: `reports`

```javascript
// Document: /reports/{reportId}
{
  "report_id": "auto-id",
  "reporter_id": "uid",
  "target_type": "post",     // "post" | "user" | "comment" | "wave_message"
  "target_id": "post-id",
  "reason": "harassment",    // "spam" | "harassment" | "hate_speech" | "inappropriate" | "other"
  "description": "Optional description...",
  "status": "pending",       // "pending" | "reviewed" | "actioned" | "dismissed"
  "created_at": Timestamp,
  "reviewed_at": null,
  "action_taken": null
}
```

---

## 3. Realtime Database (RTDB) Structure

### 3.1 Chat Messages

```json
{
  "messages": {
    "{conversationId}": {
      "{messageId}": {
        "sender_id": "uid-A",
        "content": "Hey, nice to meet you!",
        "type": "text",
        "timestamp": 1713456789000,
        "read_by": {
          "uid-A": true,
          "uid-B": false
        },
        "ai_sentiment": null
      }
    }
  }
}
```

**Message types**: `text` | `image` | `sticker` | `reaction` | `system` | `ai_suggestion`

### 3.2 Typing Indicators

```json
{
  "typing": {
    "{conversationId}": {
      "{userId}": {
        "is_typing": true,
        "timestamp": 1713456789000
      }
    }
  }
}
```

### 3.3 Online Presence

```json
{
  "presence": {
    "{userId}": {
      "online": true,
      "last_seen": 1713456789000,
      "active_screen": "feed"
    }
  }
}
```

### 3.4 Wave Live Chat

```json
{
  "wave_messages": {
    "{waveId}": {
      "{messageId}": {
        "sender_id": "uid-A",
        "sender_name": "Minh Anh",
        "sender_avatar": "...",
        "content": "Ai cũng đang thức khuya à? 🌙",
        "type": "text",
        "timestamp": 1713456789000,
        "reactions": {
          "uid-B": "trust",
          "uid-C": "joy"
        }
      }
    }
  }
}
```

---

## 4. Security Rules

### 4.1 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ===== Helper Functions =====
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isValidUser() {
      return isAuthenticated() && 
             exists(/databases/$(database)/documents/users/$(request.auth.uid));
    }
    
    // ===== USERS =====
    match /users/{userId} {
      // Read: authenticated users can read basic profile
      allow read: if isAuthenticated();
      
      // Create: self only
      allow create: if isOwner(userId);
      
      // Update: self only, cannot modify system fields
      allow update: if isOwner(userId) &&
        !request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['uid', 'created_at', 'aura_dominant_emotion', 
                   'aura_valence', 'aura_confidence', 'emotional_mode']);
      
      // Delete: self only (triggers GDPR cleanup function)
      allow delete: if isOwner(userId);
      
      // --- Emotion Profile (AI-managed, read-only for client) ---
      match /emotion_profile/{docId} {
        allow read: if isOwner(userId);
        allow write: if false; // Only Cloud Functions can write
      }
      
      // --- Behavioral Events (write-only for client) ---
      match /behavioral_events/{batchId} {
        allow create: if isOwner(userId) &&
          request.resource.data.keys().hasAll(['events', 'session_id', 'timestamp']);
        allow read, update, delete: if false; // Only Cloud Functions
      }
      
      // --- Feed Cache (read-only for client) ---
      match /feed_cache/{docId} {
        allow read: if isOwner(userId);
        allow write: if false; // Only Cloud Functions
      }
      
      // --- Following/Followers ---
      match /following/{targetId} {
        allow read: if isAuthenticated();
        allow write: if isOwner(userId);
      }
      
      match /followers/{followerId} {
        allow read: if isAuthenticated();
        allow write: if false; // Managed by Cloud Functions
      }
    }
    
    // ===== POSTS =====
    match /posts/{postId} {
      // Read: all authenticated users
      allow read: if isAuthenticated();
      
      // Create: authenticated, with required fields
      allow create: if isAuthenticated() &&
        request.resource.data.user_id == request.auth.uid &&
        request.resource.data.keys().hasAll(['content', 'user_id', 'created_at']);
      
      // Update: owner (content only), or Cloud Functions (AI fields)
      allow update: if isAuthenticated() &&
        resource.data.user_id == request.auth.uid &&
        !request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['user_id', 'created_at', 'ai_emotion_vector', 'ai_valence',
                   'content_embedding', 'quality_score', 'views_count']);
      
      // Delete: owner only
      allow delete: if isAuthenticated() && 
        resource.data.user_id == request.auth.uid;
      
      // --- Comments ---
      match /comments/{commentId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated() &&
          request.resource.data.user_id == request.auth.uid;
        allow delete: if isAuthenticated() && 
          resource.data.user_id == request.auth.uid;
      }
    }
    
    // ===== SOUL CONNECTIONS =====
    match /soul_connections/{connectionId} {
      // Read: participants only
      allow read: if isAuthenticated() &&
        request.auth.uid in resource.data.participants;
      
      // Create: only Cloud Functions
      allow create: if false;
      
      // Update: participants can accept/reject
      allow update: if isAuthenticated() &&
        request.auth.uid in resource.data.participants &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['user_a_action', 'user_b_action', 'status', 'updated_at']);
      
      allow delete: if false;
    }
    
    // ===== WAVES =====
    match /waves/{waveId} {
      // Read: all authenticated users
      allow read: if isAuthenticated();
      
      // Create/Update: only Cloud Functions
      allow create, update: if false;
      
      // --- Wave Members ---
      match /members/{memberId} {
        allow read: if isAuthenticated();
        // Join: self only, if wave is active
        allow create: if isOwner(memberId) && 
          get(/databases/$(database)/documents/waves/$(waveId)).data.status == 'active';
        // Leave: self only
        allow update: if isOwner(memberId);
        allow delete: if isOwner(memberId);
      }
    }
    
    // ===== CONVERSATIONS =====
    match /conversations/{conversationId} {
      // Read: participants only
      allow read: if isAuthenticated() &&
        request.auth.uid in resource.data.participants;
      
      allow create: if false; // Only Cloud Functions
      
      // Update: participants (for unread count reset)
      allow update: if isAuthenticated() &&
        request.auth.uid in resource.data.participants;
    }
    
    // ===== NOTIFICATIONS =====
    match /notifications/{notificationId} {
      // Read: owner only
      allow read: if isAuthenticated() &&
        resource.data.user_id == request.auth.uid;
      
      // Update: owner (mark as read)
      allow update: if isAuthenticated() &&
        resource.data.user_id == request.auth.uid &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['is_read', 'read_at']);
      
      allow create, delete: if false;
    }
    
    // ===== REPORTS =====
    match /reports/{reportId} {
      allow create: if isAuthenticated() &&
        request.resource.data.reporter_id == request.auth.uid;
      allow read, update, delete: if false;
    }
  }
}
```

### 4.2 Realtime Database Security Rules

```json
{
  "rules": {
    // === Chat Messages ===
    "messages": {
      "$conversationId": {
        ".read": "auth != null && root.child('conversation_members').child($conversationId).child(auth.uid).exists()",
        "$messageId": {
          ".write": "auth != null && root.child('conversation_members').child($conversationId).child(auth.uid).exists()",
          ".validate": "newData.hasChildren(['sender_id', 'content', 'type', 'timestamp']) && newData.child('sender_id').val() == auth.uid"
        }
      }
    },
    
    // === Conversation Members (helper for auth) ===
    "conversation_members": {
      "$conversationId": {
        ".read": "auth != null && data.child(auth.uid).exists()",
        ".write": false
      }
    },
    
    // === Typing Indicators ===
    "typing": {
      "$conversationId": {
        ".read": "auth != null && root.child('conversation_members').child($conversationId).child(auth.uid).exists()",
        "$userId": {
          ".write": "auth != null && auth.uid == $userId"
        }
      }
    },
    
    // === Online Presence ===
    "presence": {
      "$userId": {
        ".read": "auth != null",
        ".write": "auth != null && auth.uid == $userId"
      }
    },
    
    // === Wave Live Chat ===
    "wave_messages": {
      "$waveId": {
        ".read": "auth != null",
        "$messageId": {
          ".write": "auth != null",
          ".validate": "newData.hasChildren(['sender_id', 'content', 'type', 'timestamp']) && newData.child('sender_id').val() == auth.uid"
        }
      }
    }
  }
}
```

---

## 5. Indexes & Query Patterns

### 5.1 Composite Indexes Cần Thiết

| Collection | Fields | Query Purpose |
|---|---|---|
| `users` | `is_online` ASC, `last_active_at` DESC | Find active users for wave detection |
| `posts` | `created_at` DESC, `quality_score` DESC | Candidate generation for feed |
| `posts` | `user_id` ASC, `created_at` DESC | User profile post list |
| `soul_connections` | `user_a_id` ASC, `status` ASC, `soul_score` DESC | Get user's connections |
| `soul_connections` | `user_b_id` ASC, `status` ASC, `soul_score` DESC | Get user's connections |
| `waves` | `status` ASC, `momentum` DESC | Browse active waves |
| `notifications` | `user_id` ASC, `is_read` ASC, `created_at` DESC | User notification list |
| `conversations` | `participants` ARRAY_CONTAINS, `updated_at` DESC | Conversation list |

### 5.2 Common Query Patterns

```dart
// 1. Get For You feed (from cache)
final feedDoc = await firestore
    .collection('users').doc(uid)
    .collection('feed_cache').doc('for_you')
    .get();

// 2. Get active waves
final waves = await firestore
    .collection('waves')
    .where('status', isEqualTo: 'active')
    .orderBy('momentum', descending: true)
    .limit(10)
    .get();

// 3. Get soul connection suggestions
final suggestions = await firestore
    .collection('soul_connections')
    .where('participants', arrayContains: uid)
    .where('status', isEqualTo: 'suggested')
    .orderBy('soul_score', descending: true)
    .limit(10)
    .get();

// 4. Get conversations
final conversations = await firestore
    .collection('conversations')
    .where('participants', arrayContains: uid)
    .orderBy('updated_at', descending: true)
    .limit(20)
    .get();

// 5. Get unread notifications
final notifications = await firestore
    .collection('notifications')
    .where('user_id', isEqualTo: uid)
    .where('is_read', isEqualTo: false)
    .orderBy('created_at', descending: true)
    .limit(50)
    .get();

// 6. Following feed (chronological)
final following = await firestore
    .collection('users').doc(uid)
    .collection('following')
    .get();
final followingIds = following.docs.map((d) => d.id).toList();

final posts = await firestore
    .collection('posts')
    .where('user_id', whereIn: followingIds.take(10)) // Firestore limit: 10
    .orderBy('created_at', descending: true)
    .limit(20)
    .get();
```

---

## 6. Data Retention & Cleanup

| Dữ liệu | Retention | Cleanup |
|---|---|---|
| `behavioral_events` | 30 ngày | Scheduled function: aggregate → delete raw |
| `emotion_profile/current` | Vĩnh viễn (overwrite) | User delete → xóa |
| `feed_cache` | 30 phút | Regenerate on schedule/request |
| `wave_messages` (RTDB) | 24h sau wave archive | Scheduled cleanup |
| `waves` (archived) | 90 ngày | Scheduled delete |
| `messages` (RTDB) | Vĩnh viễn | User delete → xóa all |
| `notifications` | 90 ngày | Scheduled cleanup |
| `posts` | Vĩnh viễn | User delete → cascade |

---

## 7. Data Migration từ v2.0

| v2.0 field/collection | v3.0 migration |
|---|---|
| `users.current_mood` | Remove field, replaced by `emotion_profile` subcollection |
| `users.mood_history` | Migrate to initial `weekly_pattern` seed |
| `rooms` | Archive, replaced by `waves` collection |
| `matches` | Archive, replaced by `soul_connections` |
| `posts.mood_tag` | Keep as `mood_expression` (optional user tag) |

---

> **Tài liệu tiếp theo:** [03-MODULE-AI.md](./03-MODULE-AI.md)
