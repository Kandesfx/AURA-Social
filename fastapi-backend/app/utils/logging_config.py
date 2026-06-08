"""
AURA Social – Structured Logging Utilities
Replaces print() statements with structured JSON logging for production.
"""
import logging
import sys
import json
from datetime import datetime, timezone
from typing import Any, Optional
from contextvars import ContextVar

# Context variable for request-scoped data (request_id, user_id, etc.)
request_context: ContextVar[dict] = ContextVar('request_context', default={})

# Logging format constants
EMOTION_LEVELS = ["TRACE", "DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]


class StructuredFormatter(logging.Formatter):
    """JSON formatter for structured logging."""

    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "function": record.funcName,
            "line": record.lineno,
        }

        # Add request context if available
        ctx = request_context.get()
        if ctx:
            log_entry["request_id"] = ctx.get("request_id")
            log_entry["user_id"] = ctx.get("user_id")

        # Add extra fields
        if hasattr(record, "extra"):
            log_entry.update(record.extra)

        # Add exception info if present
        if record.exc_info:
            log_entry["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_entry, ensure_ascii=False)


class ColoredFormatter(logging.Formatter):
    """Colored formatter for development console output."""

    COLORS = {
        "DEBUG": "\033[36m",     # Cyan
        "INFO": "\033[32m",      # Green
        "WARNING": "\033[33m",   # Yellow
        "ERROR": "\033[31m",     # Red
        "CRITICAL": "\033[35m",  # Magenta
        "RESET": "\033[0m",
    }

    def format(self, record: logging.LogRecord) -> str:
        color = self.COLORS.get(record.levelname, self.COLORS["RESET"])
        reset = self.COLORS["RESET"]
        timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
        ctx = request_context.get()
        request_id = ctx.get("request_id", "") if ctx else ""
        prefix = f"[{request_id}] " if request_id else ""
        return (
            f"{color}{timestamp}{reset} "
            f"{color}{record.levelname:<8}{reset} "
            f"{prefix}{record.getMessage()}"
        )


def setup_logging(level: str = "INFO", use_json: bool = False) -> None:
    """
    Configure root logger for the application.

    Args:
        level: Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        use_json: If True, use JSON format; otherwise colored console output
    """
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, level.upper(), logging.INFO))

    # Remove existing handlers
    root_logger.handlers.clear()

    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.DEBUG)

    if use_json:
        console_handler.setFormatter(StructuredFormatter())
    else:
        console_handler.setFormatter(ColoredFormatter())

    root_logger.addHandler(console_handler)

    # Set third-party loggers to WARNING to reduce noise
    for logger_name in ["uvicorn", "fastapi", "httpx", "firebase_admin"]:
        logging.getLogger(logger_name).setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    """Get a logger instance for the given module name."""
    return logging.getLogger(name)


class LoggerAdapter(logging.LoggerAdapter):
    """
    Logger adapter that automatically includes request context.
    """

    def process(self, msg: str, kwargs: dict) -> tuple:
        extra = kwargs.get("extra", {})
        ctx = request_context.get()
        if ctx:
            extra.setdefault("request_id", ctx.get("request_id"))
            extra.setdefault("user_id", ctx.get("user_id"))
        kwargs["extra"] = extra
        return msg, kwargs


def set_request_context(request_id: Optional[str] = None, user_id: Optional[str] = None) -> None:
    """Set context variables for the current request scope."""
    ctx = request_context.get().copy()
    if request_id:
        ctx["request_id"] = request_id
    if user_id:
        ctx["user_id"] = user_id
    request_context.set(ctx)


def clear_request_context() -> None:
    """Clear request context after request completes."""
    request_context.set({})


def log_with_context(logger: logging.Logger, level: str, msg: str, **kwargs: Any) -> None:
    """Log a message with current request context attached."""
    ctx = request_context.get()
    extra = kwargs.pop("extra", {})
    extra["request_id"] = ctx.get("request_id")
    extra["user_id"] = ctx.get("user_id")
    extra.update(kwargs)
    getattr(logger, level.lower())(msg, extra=extra)
