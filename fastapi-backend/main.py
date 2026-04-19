"""
AURA Social – FastAPI Main Application
Entry point for the AI backend server.
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import get_settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: startup and shutdown events."""
    settings = get_settings()

    # ── Startup ──
    # Init Firebase Admin SDK
    from app.utils.firebase_client import init_firebase
    init_firebase()
    print("✅ Firebase Admin SDK initialized")

    # Init R2 Storage
    from app.services.storage import get_storage
    try:
        storage = get_storage()
        print(f"✅ R2 Storage connected (bucket: {storage.bucket_name})")
    except Exception as e:
        print(f"⚠️  R2 Storage not configured: {e}")

    # TODO: Load ML models at startup (Person 2)
    # from app.ml.model_loader import ModelLoader
    # app.state.models = ModelLoader()
    # app.state.models.load_all()
    # print("✅ ML models loaded")

    print(f"🚀 AURA Social API v{settings.api_version} started")
    yield

    # ── Shutdown ──
    print("🔄 Shutting down AURA Social API...")


# ── Create FastAPI app ──
settings = get_settings()

app = FastAPI(
    title="AURA Social AI Backend",
    description="Emotional Intelligence Social Network – AI Processing Server",
    version=settings.api_version,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS ──
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Import & Register Routers ──
from app.routers import emotion, feed, content, upload

app.include_router(emotion.router, prefix="/api/v1/emotion", tags=["Emotion"])
app.include_router(feed.router, prefix="/api/v1/feed", tags=["Feed"])
app.include_router(content.router, prefix="/api/v1/content", tags=["Content"])
app.include_router(upload.router, prefix="/api/v1/upload", tags=["Upload"])

# TODO: Person 2 sẽ thêm các routers sau:
# from app.routers import soul, waves, wellbeing, prompts
# app.include_router(soul.router, prefix="/api/v1/soul", tags=["Soul Connect"])
# app.include_router(waves.router, prefix="/api/v1/waves", tags=["Waves"])
# app.include_router(wellbeing.router, prefix="/api/v1/wellbeing", tags=["Wellbeing"])
# app.include_router(prompts.router, prefix="/api/v1/prompts", tags=["Prompts"])


# ── Health Check ──
@app.get("/health", tags=["System"])
async def health_check():
    """Health check endpoint for monitoring."""
    return {
        "status": "ok",
        "version": settings.api_version,
        "service": "AURA Social AI Backend",
    }


@app.get("/", tags=["System"])
async def root():
    """Root endpoint."""
    return {
        "message": "🔮 AURA Social AI Backend",
        "docs": "/docs",
        "health": "/health",
    }
