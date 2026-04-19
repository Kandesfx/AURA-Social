# AURA v3.0 – Lộ Trình Phát Triển Chi Tiết

> **Tài liệu:** 07/07 – Development Roadmap  
> **Phiên bản:** 3.0 (Behavioral AI Edition)

---

## 1. Tổng Quan Roadmap

### Timeline Tổng Quát

```
Phase 1: MVP Foundation        Phase 2: Intelligence         Phase 3: Advanced AI
(3 tháng)                      (3 tháng)                     (6 tháng)
────────────────────           ─────────────────────         ─────────────────────
T1    T2    T3                 T4    T5    T6                T7   T8  ... T12

Core Features +                Fine-tuned NLP +              FER + Keystroke +
Basic AI +                     Collaborative +               GNN + Multimodal +
Firebase + FastAPI Setup       Emotional Compass              Two-Tower Retrieval
```

---

## 2. Phase 1: MVP Foundation (Tháng 1–3)

### Mục Tiêu
Xây dựng nền tảng hoạt động được với đầy đủ flow chính: đăng ký → AI inference cơ bản → For You feed → Soul Connect → Chat → Waves.

### Sprint 1–2 (Tuần 1–4): Backend Foundation

| Task | Chi tiết | Ưu tiên |
|---|---|---|
| Firebase Project Setup | Tạo project, configure auth, Firestore, RTDB, Storage | 🔴 |
| Firestore Schema | Deploy tất cả collections + security rules + indexes | 🔴 |
| RTDB Schema | Messages, presence, typing, wave_messages | 🔴 |
| **FastAPI Backend Setup** | **FastAPI project, Docker, Cloud Run deploy, Firebase Admin SDK** | 🔴 |
| Auth Functions (CF) | `on_user_created`, `on_user_deleted` | 🔴 |
| Basic Sentiment Pipeline | Deploy HuggingFace multilingual model trên **FastAPI** | 🔴 |
| Post Analysis (CF → FastAPI) | `on_new_post` trigger → call FastAPI `/content/analyze` | 🔴 |
| Chat Function (CF) | `on_new_message` → notifications + Firestore sync | 🔴 |

**Deliverable Sprint 1–2**: Firebase data layer + FastAPI AI server hoạt động, auth flow, basic AI sentiment.

### Sprint 3–4 (Tuần 5–8): Core AI Engine (MVP)

| Task | Chi tiết | Ưu tiên |
|---|---|---|
| Emotion Inference Engine (MVP) | Implement 5-layer signal analysis on **FastAPI** | 🔴 |
| Behavioral Signal Collector | Flutter client-side event tracking + batch to FastAPI | 🔴 |
| Emotion Infer Endpoint | FastAPI `POST /emotion/infer` → update emotion vector | 🔴 |
| Emotional Mode Detection | 5 modes: gentle_uplift, empathetic_mirror, amplify, deep_chill, explore | 🔴 |
| Feed Generation Endpoint | FastAPI `POST /feed/generate` → 3-stage pipeline | 🔴 |
| Wellbeing Guard (Basic) | Negative streak detection + positive injection | 🟡 |

**Deliverable Sprint 3–4**: AI inference hoạt động trên FastAPI, feed cá nhân hóa cơ bản.

### Sprint 5–6 (Tuần 9–12): Frontend Core + Social Features

| Task | Chi tiết | Ưu tiên |
|---|---|---|
| Flutter Project Setup | Riverpod, GoRouter, Firebase SDK, **dio (HTTP → FastAPI)**, theme | 🔴 |
| Auth Screens | Login, Register, Onboarding (no forced mood check-in!) | 🔴 |
| For You Feed Screen | Infinite scroll, post cards, emotion reactions | 🔴 |
| Following Feed Screen | Chronological feed from followed users | 🔴 |
| Create Post Screen | Text + image + optional mood expression | 🔴 |
| Aura Ring Component | Gradient ring with emotion-to-color mapping | 🔴 |
| Soul Connect (Basic) | `compute_soul_scores` + suggestion UI + accept/reject | 🟡 |
| Chat System | RTDB messages, typing indicator, presence | 🔴 |
| Emotional Waves (Basic) | `detect_emotion_clusters` + wave list + wave chat | 🟡 |
| Notifications | FCM setup, notification list screen | 🟡 |
| Profile Screen | Basic profile + Aura Ring + post grid | 🟡 |
| Behavioral Tracker Integration | Track scroll, dwell, interactions silently | 🔴 |
| AI Status Bar | "🤖 Đang hiểu bạn..." indicator | 🟡 |
| AI Settings Screen | Toggle all AI features on/off | 🟡 |

**Deliverable**: Functional MVP app with all core flows working.

### Phase 1 – Definition of Done

| Criteria | ✅ |
|---|---|
| User can register/login | ⬜ |
| AI infers emotion from behavioral signals | ⬜ |
| For You feed shows personalized content | ⬜ |
| Emotion reactions work (8 types) | ⬜ |
| Aura Ring reflects emotion visually | ⬜ |
| Soul Connect suggests compatible users | ⬜ |
| 1-1 Chat works real-time | ⬜ |
| Emotional Waves auto-creates from clusters | ⬜ |
| Wellbeing Guard injects break cards | ⬜ |
| AI Settings toggles work | ⬜ |
| Security rules deployed and tested | ⬜ |
| Privacy consent flow functional | ⬜ |

---

## 3. Phase 2: Intelligence Enhancement (Tháng 4–6)

### Mục Tiêu
Nâng cao chất lượng AI: fine-tuned Vietnamese NLP, collaborative filtering, emotional compass, content quality.

### Sprint 7–8 (Tuần 13–16): Advanced NLP + Content Intelligence

| Task | Chi tiết | Ưu tiên |
|---|---|---|
| Fine-tune PhoBERT | Train trên VLSP + UIT-VSFC cho Vietnamese sentiment | 🔴 |
| Vietnamese sarcasm/slang detection | Handle "ảo thật", "đỉnh nóc", regionalism | 🔴 |
| Content Embedding Model | Generate 64D vectors cho content similarity matching | 🟡 |
| Content Quality ML Model | Train model from engagement data (replace heuristic) | 🟡 |
| Comment Sentiment | `on_comment_analyze` function | 🟡 |

### Sprint 9–10 (Tuần 17–20): Advanced Recommendation + Analytics

| Task | Chi tiết | Ưu tiên |
|---|---|---|
| Collaborative Filtering | Matrix factorization: users with similar taste → recommend content | 🔴 |
| Two-Tower Prototype | Basic user embedding + content embedding matching | 🟡 |
| Advanced Feed Scoring | Improved engagement prediction using ML model | 🔴 |
| Mood Prediction (LSTM) | Time-series model predicting emotional trajectory | 🟡 |
| Feed A/B Testing | Remote Config + Firebase Analytics comparison | 🟡 |

### Sprint 11–12 (Tuần 21–24): Emotional Compass + Polish

| Task | Chi tiết | Ưu tiên |
|---|---|---|
| Emotional Compass Screen | Full dashboard: radar chart, timeline, insights | 🔴 |
| Wellbeing Score | Aggregated wellbeing metric (0-100) | 🟡 |
| AI Insights | "Bạn thường vui vào cuối tuần..." text generation | 🟡 |
| Data Export | Download personal data as JSON (GDPR) | 🟡 |
| Admin Panel (Web) | Firebase Hosting: user management, moderation queue | 🟡 |
| Toxicity Fine-tuning | Vietnamese hate speech + harassment model | 🟡 |
| Performance Optimization | Optimize FastAPI latency, Firestore queries, image loading | 🟡 |
| Wave Theming Improvement | LLM-assisted wave name/description generation | 🟢 |
| Creator Tools | Post analytics: views, reactions breakdown, reach | 🟢 |

### Phase 2 – Definition of Done

| Criteria | ✅ |
|---|---|
| Vietnamese NLP handles sarcasm/slang | ⬜ |
| Collaborative filtering improves feed quality | ⬜ |
| Emotional Compass shows meaningful insights | ⬜ |
| Wellbeing Score calculated accurately | ⬜ |
| Feed engagement metrics improve 20%+ | ⬜ |
| Data export functional (GDPR) | ⬜ |
| Admin panel operational | ⬜ |

---

## 4. Phase 3: Advanced AI & Scale (Tháng 7–12)

### Mục Tiêu
Triển khai các tính năng AI nâng cao: FER, keystroke dynamics, GNN, multimodal fusion, và sẵn sàng scale.

### Sprint 13–16 (Tuần 25–32): On-Device AI

| Task | Chi tiết | Ưu tiên |
|---|---|---|
| Facial Emotion Recognition (FER) | TFLite on-device model từ FER2013/AffectNet | 🟡 |
| FER Privacy | Toàn bộ xử lý on-device, chỉ gửi emotion vector | 🔴 |
| FER UI Integration | Camera preview + real-time emotion overlay | 🟡 |
| Keystroke Dynamics | Bi-LSTM trên typing patterns (speed, pressure, pause) | 🟢 |
| On-device Signal Fusion | Combine FER + keystroke + behavioral → richer emotion vector | 🟡 |

### Sprint 17–20 (Tuần 33–40): Graph & Advanced Recommendation

| Task | Chi tiết | Ưu tiên |
|---|---|---|
| GNN Emotion Graph | Model emotion propagation across social connections | 🟡 |
| Community Emotion Analysis | Detect community-level emotional trends | 🟡 |
| Two-Tower Deep Retrieval | Full implementation: user tower + content tower | 🔴 |
| Real-time Model Update | Online learning from new interaction data | 🟡 |
| Wave Intelligence | Predict wave momentum, optimal wave timing | 🟢 |

### Sprint 21–24 (Tuần 41–48): Multimodal & Scale

| Task | Chi tiết | Ưu tiên |
|---|---|---|
| Multimodal Fusion | Combine text + image + FER + keystroke + behavioral | 🟡 |
| Voice Emotion (Prototype) | Analyze voice notes for emotional cues | 🟢 |
| FastAPI GPU Migration | Move to GPU-enabled VPS for heavy models | 🟡 |
| Horizontal Scaling | FastAPI load balancing, Redis caching layer | 🟡 |
| International NLP | Support English, Japanese, Korean sentiment | 🟢 |
| App Store Release | Production build, review, submission | 🔴 |

### Phase 3 – Definition of Done

| Criteria | ✅ |
|---|---|
| FER works on-device with privacy | ⬜ |
| GNN improves community-level recommendations | ⬜ |
| Two-Tower model outperforms heuristic scoring | ⬜ |
| Multimodal fusion increases emotion confidence 20%+ | ⬜ |
| System handles 10K+ DAU | ⬜ |
| App Store approved and published | ⬜ |

---

## 5. Human Resources

### Đội Ngũ Đề Xuất (MVP – 3 Tháng)

| Vai trò | Số lượng | Trách nhiệm |
|---|---|---|
| **Flutter Developer** | 1–2 | UI/UX, state management, behavioral tracker |
| **Backend/AI Developer** | 1 | FastAPI backend, AI modules, Cloud Functions triggers |
| **UI/UX Designer** | 1 (part-time) | Design system, screen designs, Aura Ring visuals |

### Division of Work (Solo/Small Team)

Nếu 1 người làm tất cả:
```
Tuần 1-4:   Backend (Firebase + FastAPI setup, schema, auth, AI endpoints)
Tuần 5-8:   AI Engine (Emotion inference, sentiment, recommendation on FastAPI)
Tuần 9-12:  Frontend (Flutter screens, UI components, integration)
Tuần 12:    Testing, bug fixes, MVP release
```

---

## 6. Tech Stack Summary

### MVP (Phase 1)

| Layer | Technology | Version |
|---|---|---|
| Frontend | Flutter/Dart | 3.19+ |
| State | Riverpod | 2.5+ |
| Navigation | GoRouter | 13+ |
| HTTP Client | **dio** | 5.4+ |
| Auth | Firebase Auth | Latest |
| Database | Cloud Firestore + RTDB | Latest |
| Storage | Firebase Cloud Storage | Latest |
| **AI Backend** | **FastAPI (Python)** | **3.12** |
| Triggers | Cloud Functions (Python) | 3.12 |
| AI/NLP | HuggingFace Transformers | 4.38+ |
| ML | NumPy, scikit-learn, PyTorch | Latest |
| Push | Firebase Cloud Messaging | Latest |
| Analytics | Firebase Analytics | Latest |
| Monitoring | Crashlytics + Performance | Latest |
| Config | Firebase Remote Config | Latest |
| **Deploy** | **Docker + Cloud Run** | Latest |

### Phase 2 Additions

| Technology | Purpose |
|---|---|
| PhoBERT (fine-tuned) | Vietnamese NLP |
| LSTM (PyTorch/TF) | Mood prediction |
| Content embedding model | Content similarity |

### Phase 3 Additions

| Technology | Purpose |
|---|---|
| TFLite | On-device FER |
| PyTorch Geometric | GNN emotion graph |
| Two-Tower model | Deep retrieval |
| Vertex AI | Model training & serving at scale |

---

## 7. KPIs & Success Metrics

### Engagement Metrics

| KPI | MVP Target | Phase 2 Target | Phase 3 Target |
|---|---|---|---|
| DAU / MAU Ratio | > 20% | > 35% | > 50% |
| Avg. Session Duration | > 5 min | > 10 min | > 15 min |
| Sessions per Day | > 1.5 | > 2.5 | > 3.5 |
| Feed Scroll Depth | > 10 posts | > 15 posts | > 20 posts |
| Interaction Rate | > 5% | > 10% | > 15% |

### AI Quality Metrics

| KPI | MVP Target | Phase 2 Target | Phase 3 Target |
|---|---|---|---|
| Emotion Inference Confidence | > 50% | > 70% | > 85% |
| Sentiment Accuracy (Vietnamese) | > 70% | > 85% (PhoBERT) | > 90% |
| Feed Click-Through Rate | > 3% | > 5% | > 8% |
| Soul Connect Accept Rate | > 20% | > 30% | > 40% |
| Wellbeing Guard Effectiveness | Measured | > 15% negative reduction | > 25% |

### Social Metrics

| KPI | MVP Target | Phase 2 Target | Phase 3 Target |
|---|---|---|---|
| Soul Connections per User | > 1 | > 3 | > 5 |
| Wave Participation Rate | > 10% | > 20% | > 30% |
| Chat Messages per Connection | > 5/day | > 10/day | > 15/day |
| User Retention (D7) | > 15% | > 25% | > 40% |
| User Retention (D30) | > 5% | > 12% | > 20% |

---

## 8. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **Low emotion accuracy** (MVP) | Cao | Cao | Fallback to neutral mode, user can override, improve with data |
| **Firebase cost spikes** | Trung bình | Cao | Batch writes, cache aggressively, monitoring alerts |
| **FastAPI server downtime** | Thấp | Cao | Cloud Run auto-restart, health checks, fallback to cached feed |
| **Privacy backlash** | Thấp | Cao | Transparent AI indicator, full user control, GDPR compliance |
| **Content moderation gaps** | Trung bình | Cao | Multi-layer approach, community reporting, manual review |
| **FastAPI cost** | Trung bình | Trung bình | Cloud Run min 1 instance, scale-to-zero khi ít user |
| **Model bias** | Trung bình | Trung bình | Vietnamese language testing, diverse test data, user feedback |
| **User adoption** | Trung bình | Cao | Focus on unique value (emotional matching), viral Aura Ring |

---

## 9. Deployment Strategy

### Phase 1: Internal Testing
```
Week 1-10: Development
Week 11:   Internal alpha testing
Week 12:   Bug fixes, polish
           → Deploy Firebase to staging project
           → Deploy FastAPI to Cloud Run (staging)
```

### Phase 2: Beta Release
```
Month 4:   Closed beta (50 users, friends & classmates)
Month 5:   Open beta (TestFlight / Firebase App Distribution)
Month 6:   Iterate based on feedback
```

### Phase 3: Public Release
```
Month 7-8:  Play Store / App Store review preparation
Month 9:    Soft launch (Vietnam market)
Month 10+:  Scale & iterate
```

---

## 10. Tổng Kết

AURA v3.0 là bước tiến vượt bậc từ nền tảng mạng xã hội đơn giản sang **Emotion-Aware Social Platform** thực sự:

| Yếu tố | Trước (v2.0) | Sau (v3.0) |
|---|---|---|
| Cơ chế | Cứng nhắc, thủ công | Tự động, AI-driven |
| Kiến trúc | Firebase only | **Hybrid (Firebase + FastAPI)** |
| Thuật toán | Rule-based | Deep learning pipeline |
| Community | Tĩnh | Động (Waves) |
| Matching | Bề mặt | Sâu (Soul Connect) |
| UX | Đơn giản | Adaptive, emotion-aware |
| Bảo mật | Cơ bản | GDPR + EU AI Act compliant |
| Identity | Text/emoji | Visual (Aura Ring) |

> **"Your emotions shape your feed. Your feed heals your emotions."**

---

> **Quay lại:** [00-TONG-QUAN-HE-THONG.md](./00-TONG-QUAN-HE-THONG.md)
