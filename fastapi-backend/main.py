"""
AURA Social – FastAPI Main Application
Entry point for the AI backend server.
"""
from contextlib import asynccontextmanager
import uuid
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from starlette.middleware.base import BaseHTTPMiddleware
from app.config import get_settings
from app.utils.logging_config import setup_logging, get_logger, set_request_context, clear_request_context
from app.utils.error_handler import (
    validation_exception_handler,
    http_exception_handler,
    generic_exception_handler,
)


# ─── Request ID Middleware ───────────────────────────────────────────────────

class RequestIDMiddleware(BaseHTTPMiddleware):
    """Middleware to add request ID to every request for tracing."""

    async def dispatch(self, request: Request, call_next):
        request_id = (
            request.headers.get("X-Request-ID")
            or request.headers.get("X-Request-Id")
            or f"req_{uuid.uuid4().hex[:12]}"
        )
        request.state.request_id = request_id

        set_request_context(request_id=request_id)
        try:
            response = await call_next(request)
            response.headers["X-Request-ID"] = request_id
            return response
        finally:
            clear_request_context()


# ─── Lifespan ────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: startup and shutdown events."""
    settings = get_settings()
    logger = get_logger(__name__)

    # ── Startup ──
    # Init Firebase Admin SDK
    from app.utils.firebase_client import init_firebase
    try:
        init_firebase()
        logger.info("Firebase Admin SDK initialized")
    except Exception as e:
        logger.warning(f"Firebase Admin SDK initialization failed: {e}")

    # Init R2 Storage
    from app.services.storage import get_storage
    try:
        storage = get_storage()
        logger.info(f"R2 Storage connected (bucket: {storage.bucket_name})")
    except Exception as e:
        logger.warning(f"R2 Storage not configured: {e}")

    # Load ML models at startup
    from app.ml.model_loader import model_loader
    model_loader.load_all()
    app.state.model_loader = model_loader
    logger.info("ML models loaded")

    logger.info(f"AURA Social API v{settings.api_version} started")
    yield

    # ── Shutdown ──
    logger.info("Shutting down AURA Social API...")


# ─── Create FastAPI app ──
settings = get_settings()

# Setup logging (use JSON in production, colored in dev)
log_level = getattr(__import__('os', fromlist=['environ']), 'environ').get("LOG_LEVEL", "INFO")
log_json = getattr(__import__('os', fromlist=['environ']), 'environ').get("LOG_JSON", "false").lower() == "true"
setup_logging(level=log_level, use_json=log_json)

app = FastAPI(
    title="AURA Social AI Backend",
    description="Emotional Intelligence Social Network – AI Processing Server",
    version=settings.api_version,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ─── Middleware ──
app.add_middleware(RequestIDMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins.split(","),
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
)

# ─── Exception handlers ──
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(Exception, generic_exception_handler)

# ─── Mount Static Files (for local uploads fallback) ──
from fastapi.staticfiles import StaticFiles
import os
os.makedirs("static", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")


# ─── Import & Register Routers ──
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

# Include Notification Router
from app.routers import notifications
app.include_router(notifications.router, prefix="/api/v1/notifications", tags=["Notifications"])


# ─── Health Check Endpoints ──
@app.get("/health", tags=["System"])
async def health_check():
    """Liveness probe for Kubernetes and monitoring."""
    return {
        "status": "ok",
        "version": settings.api_version,
        "service": "AURA Social AI Backend",
    }


@app.get("/health/ready", tags=["System"])
async def readiness_check():
    """Readiness probe – checks all dependencies."""
    from app.utils.firebase_client import get_firestore
    from app.services.storage import get_storage
    from app.ml.model_loader import model_loader

    checks = {
        "firebase": False,
        "firebase_messaging": False,
        "r2_storage": False,
        "ml_models": False,
    }
    all_healthy = False

    try:
        from firebase_admin import messaging
        checks["firebase_messaging"] = True
    except Exception:
        pass

    try:
        db = get_firestore()
        db.collection("__name__").limit(1).get()
        checks["firebase"] = True
    except Exception as e:
        get_logger(__name__).warning(f"Firebase health check failed: {e}")

    try:
        storage = get_storage()
        checks["r2_storage"] = True
    except Exception:
        pass

    try:
        checks["ml_models"] = model_loader.is_loaded
    except Exception:
        pass

    all_healthy = all(checks.values())
    status_code = 200 if all_healthy else 503

    return JSONResponse(
        status_code=status_code,
        content={
            "status": "ready" if all_healthy else "degraded",
            "checks": checks,
        },
    )


from fastapi.responses import JSONResponse


@app.get("/", tags=["System"])
async def root():
    """Root endpoint."""
    return {
        "message": "🔮 AURA Social AI Backend",
        "docs": "/docs",
        "health": "/health",
    }
