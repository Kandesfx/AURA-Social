"""
AURA Social – Standardized Error Responses
Provides consistent error format across all API endpoints.
"""
from typing import Optional, Any
from pydantic import BaseModel, Field
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException


# ─── Error Codes ────────────────────────────────────────────────────────────

class ErrorCode:
    # 4xx Client Errors
    VALIDATION_ERROR = "VALIDATION_ERROR"
    NOT_FOUND = "NOT_FOUND"
    UNAUTHORIZED = "UNAUTHORIZED"
    FORBIDDEN = "FORBIDDEN"
    RATE_LIMITED = "RATE_LIMITED"
    CONFLICT = "CONFLICT"
    BAD_REQUEST = "BAD_REQUEST"

    # 5xx Server Errors
    INTERNAL_ERROR = "INTERNAL_ERROR"
    SERVICE_UNAVAILABLE = "SERVICE_UNAVAILABLE"
    UPSTREAM_ERROR = "UPSTREAM_ERROR"

    # Domain-specific
    EMOTION_INFERENCE_ERROR = "EMOTION_INFERENCE_ERROR"
    FEED_GENERATION_ERROR = "FEED_GENERATION_ERROR"
    SOUL_MATCH_ERROR = "SOUL_MATCH_ERROR"
    WELLBEING_ERROR = "WELLBEING_ERROR"
    UPLOAD_ERROR = "UPLOAD_ERROR"
    AUTH_ERROR = "AUTH_ERROR"
    FIRESTORE_ERROR = "FIRESTORE_ERROR"


# ─── Error Response Model ───────────────────────────────────────────────────

class APIErrorResponse(BaseModel):
    """Standardized error response format for all API endpoints."""

    error: str = Field(..., description="Machine-readable error code")
    message: str = Field(..., description="Human-readable error message")
    details: Optional[Any] = Field(
        default=None,
        description="Additional error details (field validation errors, etc.)"
    )
    request_id: Optional[str] = Field(
        default=None,
        description="Request ID for debugging and log correlation"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "error": "VALIDATION_ERROR",
                "message": "Invalid request data",
                "details": {"field": "user_id", "issue": "Required field missing"},
                "request_id": "req_abc123"
            }
        }

    # ─── Factory Methods ────────────────────────────────────────────────────

    @classmethod
    def validation_error(
        cls,
        message: str = "Invalid request data",
        details: Any = None,
        request_id: Optional[str] = None
    ) -> "APIErrorResponse":
        return cls(
            error=ErrorCode.VALIDATION_ERROR,
            message=message,
            details=details,
            request_id=request_id,
        )

    @classmethod
    def not_found(
        cls,
        resource: str,
        identifier: Optional[str] = None,
        request_id: Optional[str] = None
    ) -> "APIErrorResponse":
        msg = f"{resource} not found"
        if identifier:
            msg = f"{resource} with ID '{identifier}' not found"
        return cls(
            error=ErrorCode.NOT_FOUND,
            message=msg,
            request_id=request_id,
        )

    @classmethod
    def unauthorized(
        cls,
        message: str = "Authentication required",
        request_id: Optional[str] = None
    ) -> "APIErrorResponse":
        return cls(
            error=ErrorCode.UNAUTHORIZED,
            message=message,
            request_id=request_id,
        )

    @classmethod
    def forbidden(
        cls,
        message: str = "You do not have permission to access this resource",
        request_id: Optional[str] = None
    ) -> "APIErrorResponse":
        return cls(
            error=ErrorCode.FORBIDDEN,
            message=message,
            request_id=request_id,
        )

    @classmethod
    def rate_limited(
        cls,
        message: str = "Too many requests. Please slow down.",
        retry_after: Optional[int] = None,
        request_id: Optional[str] = None
    ) -> "APIErrorResponse":
        details = {"retry_after_seconds": retry_after} if retry_after else None
        return cls(
            error=ErrorCode.RATE_LIMITED,
            message=message,
            details=details,
            request_id=request_id,
        )

    @classmethod
    def internal_error(
        cls,
        message: str = "An internal error occurred. Please try again later.",
        request_id: Optional[str] = None
    ) -> "APIErrorResponse":
        return cls(
            error=ErrorCode.INTERNAL_ERROR,
            message=message,
            request_id=request_id,
        )

    @classmethod
    def service_unavailable(
        cls,
        service: str,
        request_id: Optional[str] = None
    ) -> "APIErrorResponse":
        return cls(
            error=ErrorCode.SERVICE_UNAVAILABLE,
            message=f"Service '{service}' is temporarily unavailable. Please try again later.",
            details={"service": service},
            request_id=request_id,
        )

    @classmethod
    def bad_request(
        cls,
        message: str,
        details: Any = None,
        request_id: Optional[str] = None
    ) -> "APIErrorResponse":
        return cls(
            error=ErrorCode.BAD_REQUEST,
            message=message,
            details=details,
            request_id=request_id,
        )

    @classmethod
    def firestore_error(
        cls,
        operation: str,
        request_id: Optional[str] = None
    ) -> "APIErrorResponse":
        return cls(
            error=ErrorCode.FIRESTORE_ERROR,
            message=f"Database operation '{operation}' failed. Please try again.",
            details={"operation": operation},
            request_id=request_id,
        )

    @classmethod
    def emotion_error(
        cls,
        message: str = "Emotion inference failed",
        request_id: Optional[str] = None
    ) -> "APIErrorResponse":
        return cls(
            error=ErrorCode.EMOTION_INFERENCE_ERROR,
            message=message,
            request_id=request_id,
        )


# ─── HTTP Status Code Mapping ───────────────────────────────────────────────

_ERROR_STATUS_MAP: dict[str, int] = {
    ErrorCode.VALIDATION_ERROR: 400,
    ErrorCode.BAD_REQUEST: 400,
    ErrorCode.UNAUTHORIZED: 401,
    ErrorCode.AUTH_ERROR: 401,
    ErrorCode.FORBIDDEN: 403,
    ErrorCode.NOT_FOUND: 404,
    ErrorCode.RATE_LIMITED: 429,
    ErrorCode.CONFLICT: 409,
    ErrorCode.INTERNAL_ERROR: 500,
    ErrorCode.SERVICE_UNAVAILABLE: 503,
    ErrorCode.UPSTREAM_ERROR: 502,
    ErrorCode.EMOTION_INFERENCE_ERROR: 500,
    ErrorCode.FEED_GENERATION_ERROR: 500,
    ErrorCode.SOUL_MATCH_ERROR: 500,
    ErrorCode.WELLBEING_ERROR: 500,
    ErrorCode.UPLOAD_ERROR: 500,
    ErrorCode.FIRESTORE_ERROR: 503,
}


def get_status_code(error_code: str) -> int:
    """Map error code to HTTP status code."""
    return _ERROR_STATUS_MAP.get(error_code, 500)


def error_to_json_response(error: APIErrorResponse) -> JSONResponse:
    """Convert APIErrorResponse to FastAPI JSONResponse."""
    return JSONResponse(
        status_code=get_status_code(error.error),
        content=error.model_dump(exclude_none=True),
    )


# ─── Exception Handlers ────────────────────────────────────────────────────

async def api_error_exception_handler(request: Request, exc: APIErrorResponse) -> JSONResponse:
    """Handler for APIErrorResponse exceptions."""
    return error_to_json_response(exc)


async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    """Handler for FastAPI validation errors (Pydantic)."""
    errors = []
    for error in exc.errors():
        field = ".".join(str(loc) for loc in error["loc"])
        errors.append({
            "field": field,
            "message": error["msg"],
            "type": error["type"],
        })

    error = APIErrorResponse.validation_error(
        message="Request validation failed",
        details={"errors": errors},
        request_id=request.state.request_id if hasattr(request.state, "request_id") else None,
    )
    return error_to_json_response(error)


async def http_exception_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    """Handler for HTTP exceptions."""
    error_code_map = {
        400: ErrorCode.BAD_REQUEST,
        401: ErrorCode.UNAUTHORIZED,
        403: ErrorCode.FORBIDDEN,
        404: ErrorCode.NOT_FOUND,
        429: ErrorCode.RATE_LIMITED,
        500: ErrorCode.INTERNAL_ERROR,
        503: ErrorCode.SERVICE_UNAVAILABLE,
    }

    error = APIErrorResponse(
        error=error_code_map.get(exc.status_code, ErrorCode.INTERNAL_ERROR),
        message=exc.detail,
        request_id=request.state.request_id if hasattr(request.state, "request_id") else None,
    )
    return error_to_json_response(error)


async def generic_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Fallback handler for unhandled exceptions."""
    from app.utils.logging_config import get_logger
    logger = get_logger(__name__)
    logger.error(f"Unhandled exception: {exc}", exc_info=exc)

    error = APIErrorResponse.internal_error(
        message="An unexpected error occurred. Please try again later.",
        request_id=request.state.request_id if hasattr(request.state, "request_id") else None,
    )
    return error_to_json_response(error)


# ─── Utility Functions ──────────────────────────────────────────────────────

def extract_request_id(request: Request) -> Optional[str]:
    """Extract request ID from headers or generate one."""
    return (
        request.headers.get("X-Request-ID")
        or request.headers.get("X-Request-Id")
        or getattr(request.state, "request_id", None)
    )
