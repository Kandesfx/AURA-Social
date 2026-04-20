"""
AURA Social – Authentication Dependencies
Firebase token verification + internal API key for Cloud Functions.
"""
from fastapi import Depends, HTTPException, Header, status
from app.utils.firebase_client import verify_firebase_token
from app.config import get_settings


async def get_current_user(authorization: str = Header(...)) -> dict:
    """
    Verify Firebase ID token from Authorization header.

    Usage in router:
        @router.post("/endpoint")
        async def endpoint(user: dict = Depends(get_current_user)):
            uid = user["uid"]
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format",
        )

    token = authorization.split("Bearer ")[1]

    try:
        decoded = verify_firebase_token(token)
        return decoded
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid or expired token: {str(e)}",
        )


async def verify_internal_key(x_internal_key: str = Header(...)) -> bool:
    """
    Verify internal API key for Cloud Functions → FastAPI calls.

    Usage in router:
        @router.post("/internal-endpoint")
        async def endpoint(valid: bool = Depends(verify_internal_key)):
            ...
    """
    settings = get_settings()
    if x_internal_key != settings.internal_api_key:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid internal API key",
        )
    return True
