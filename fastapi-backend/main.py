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
    print("[Firebase] Firebase Admin SDK initialized")

    # Init R2 Storage
    from app.services.storage import get_storage
    try:
        storage = get_storage()
        print(f"[R2] R2 Storage connected (bucket: {storage.bucket_name})")
    except Exception as e:
        print(f"[R2] R2 Storage not configured: {e}")

    # Load ML models at startup
    from app.ml.model_loader import model_loader
    model_loader.load_all()
    app.state.model_loader = model_loader
    print("[ML] ML models loaded")

    print(f"[AURA] AURA Social API v{settings.api_version} started")
    yield

    # ── Shutdown ──
    print("[System] Shutting down AURA Social API...")


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

# ── Mount Static Files (for local uploads fallback) ──
from fastapi.staticfiles import StaticFiles
import os
os.makedirs("static", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")


# ── Import & Register Routers ──
from app.routers import emotion, feed, content, upload

app.include_router(emotion.router, prefix="/api/v1/emotion", tags=["Emotion"])
app.include_router(feed.router, prefix="/api/v1/feed", tags=["Feed"])
app.include_router(content.router, prefix="/api/v1/content", tags=["Content"])
app.include_router(upload.router, prefix="/api/v1/upload", tags=["Upload"])

# Include Soul Connect Router
from app.routers import soul
app.include_router(soul.router, prefix="/api/v1/soul", tags=["Soul Connect"])

# Include Wellbeing and Prompts Routers (Phase 5)
from app.routers import wellbeing, prompts, challenges
app.include_router(wellbeing.router, prefix="/api/v1/wellbeing", tags=["Wellbeing"])
app.include_router(prompts.router, prefix="/api/v1/prompts", tags=["Prompts"])
app.include_router(challenges.router, prefix="/api/v1/challenges", tags=["Challenges"])



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
