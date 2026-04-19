# 🤖 AURA Social – FastAPI AI Backend

> Emotional Intelligence Processing Server

## Quick Start (Person 2)

### 1. Setup Environment

```bash
cd fastapi-backend

# Tạo virtual environment
python -m venv venv

# Activate (Windows)
.\venv\Scripts\activate

# Activate (macOS/Linux)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure

```bash
# Copy env template
cp .env.example .env

# Điền các giá trị vào .env:
# - R2 credentials (hỏi Leader)
# - Firebase service account (hỏi Leader)
# - Internal API key (tự tạo random string)
```

### 3. Firebase Service Account

- Nhận file `service-account.json` từ Leader
- Đặt vào `fastapi-backend/service-account.json`
- **KHÔNG commit file này lên Git!**

### 4. Run

```bash
uvicorn main:app --reload --port 8080
```

Mở `http://localhost:8080/docs` để xem Swagger UI.

---

## Project Structure

```
fastapi-backend/
├── main.py                     # App entry + routers registration
├── app/
│   ├── config.py               # Settings (from .env)
│   ├── auth.py                 # Firebase token + internal key verification
│   ├── routers/
│   │   ├── emotion.py          # POST /api/v1/emotion/infer
│   │   ├── feed.py             # POST /api/v1/feed/generate
│   │   ├── content.py          # POST /api/v1/content/analyze (internal)
│   │   └── upload.py           # POST /api/v1/upload/* (R2)
│   ├── models/                 # Pydantic schemas
│   │   ├── emotion.py          # EmotionVector, EmotionInferRequest/Response
│   │   ├── feed.py             # FeedRequest/Response
│   │   └── content.py          # ContentAnalysisRequest/Response
│   ├── services/
│   │   └── storage.py          # ✅ R2 storage (đã implement)
│   ├── ml/                     # ML models (TODO)
│   └── utils/
│       └── firebase_client.py  # Firebase Admin SDK
├── .env.example                # Environment template
├── requirements.txt
└── Dockerfile
```

## API Endpoints

| Method | Path | Auth | Status |
|--------|------|------|--------|
| `GET` | `/health` | None | ✅ Done |
| `POST` | `/api/v1/emotion/infer` | Firebase Token | 🟡 Mock |
| `POST` | `/api/v1/feed/generate` | Firebase Token | 🟡 Mock |
| `POST` | `/api/v1/content/analyze` | Internal Key | 🟡 Mock |
| `POST` | `/api/v1/upload/avatar` | Firebase Token | ✅ Done |
| `POST` | `/api/v1/upload/post-image/{id}` | Firebase Token | ✅ Done |

> 🟡 Mock = Trả mock data, Person 2 cần implement logic thực.

## TODO (Person 2)

1. [ ] Implement emotion inference (5-layer analysis)
2. [ ] Implement feed recommendation (3-stage pipeline)
3. [ ] Implement content analyzer (NLP sentiment)
4. [ ] Add Soul Connect router + service
5. [ ] Add Waves router + service
6. [ ] Add Wellbeing router + service
7. [ ] Load HuggingFace models at startup
8. [ ] Write unit tests
