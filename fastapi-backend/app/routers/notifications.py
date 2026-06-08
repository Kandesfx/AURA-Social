"""
AURA Social - Notification Router

API endpoints để gửi notification và quản lý notification preferences.
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.auth import get_current_user
from app.services.notification_service import notification_service, NotificationType
from app.utils.logging_config import get_logger

router = APIRouter()
logger = get_logger(__name__)


# ── Request / Response Models ─────────────────────────────────────────────────

class NotificationSendRequest(BaseModel):
    user_id: str = Field(..., description="ID của user nhận notification")
    type: str = Field(..., description="Loại notification (message, soul_match, ...)")
    title: str = Field(..., max_length=200, description="Tiêu đề notification")
    body: str = Field(..., max_length=500, description="Nội dung notification")
    data: Optional[dict] = Field(default=None, description="Payload data cho deep link")
    priority: str = Field(default="normal", description="high | normal")
    image_url: Optional[str] = Field(default=None, description="URL ảnh thumbnail")


class NotificationPreferencesRequest(BaseModel):
    notify_message: bool = True
    notify_soul_match: bool = True
    notify_wave_join: bool = True
    notify_wellbeing_reminder: bool = True
    notify_challenge: bool = True
    notify_post_reaction: bool = True
    notify_follow: bool = True
    notify_ai_insight: bool = False
    quiet_hours_enabled: bool = True
    quiet_hours_start: int = Field(default=22, ge=0, le=23)
    quiet_hours_end: int = Field(default=8, ge=0, le=23)


class NotificationPreferencesResponse(BaseModel):
    preferences: dict
    user_id: str


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/send")
async def send_notification(
    request: NotificationSendRequest,
    user: dict = Depends(get_current_user),
):
    """
    Gửi notification tới một user cụ thể.
    Yêu cầu: Firebase auth token hợp lệ.
    """
    try:
        notification_type = NotificationType(request.type)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid notification type: {request.type}",
        )

    result = await notification_service.send(
        user_id=request.user_id,
        notification_type=notification_type,
        title=request.title,
        body=request.body,
        data=request.data,
        priority=request.priority,
        image_url=request.image_url,
    )

    if result:
        return {"status": "sent", "message_id": result}
    else:
        return {"status": "skipped", "message": "Notification not sent (no token or blocked by scheduler)"}


@router.post("/preferences")
async def set_notification_preferences(
    request: NotificationPreferencesRequest,
    user: dict = Depends(get_current_user),
):
    """
    Cập nhật notification preferences của user.
    Lưu vào Firestore: users/{uid}/settings/notifications
    """
    from app.utils.firebase_client import get_firestore
    from google.cloud.firestore import ServerTimestamp

    uid = user["uid"]
    db = get_firestore()

    try:
        db.collection("users").document(uid).collection("settings").document(
            "notifications"
        ).set(request.model_dump())

        logger.info(
            f"Notification preferences updated for user {uid}",
            extra={"user_id": uid},
        )
        return NotificationPreferencesResponse(
            preferences=request.model_dump(),
            user_id=uid,
        )
    except Exception as e:
        logger.error(f"Failed to update notification preferences: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update preferences",
        )


@router.get("/preferences", response_model=NotificationPreferencesResponse)
async def get_notification_preferences(
    user: dict = Depends(get_current_user),
):
    """
    Lấy notification preferences hiện tại của user.
    """
    from app.utils.firebase_client import get_firestore

    uid = user["uid"]
    db = get_firestore()

    try:
        doc = (
            db.collection("users")
            .document(uid)
            .collection("settings")
            .document("notifications")
            .get()
        )

        if doc.exists:
            return NotificationPreferencesResponse(
                preferences=doc.to_dict(),
                user_id=uid,
            )
        else:
            # Return defaults
            return NotificationPreferencesResponse(
                preferences=NotificationPreferencesRequest().model_dump(),
                user_id=uid,
            )
    except Exception as e:
        logger.error(f"Failed to get notification preferences: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve preferences",
        )


# ── Internal Trigger Endpoints ─────────────────────────────────────────────────

@router.post("/trigger/soul-match")
async def trigger_soul_match_notification(
    user_id: str,
    matched_user_id: str,
    matched_user_name: str,
    soul_score: float,
    connection_type: str,
):
    """
    Internal endpoint: gửi notification khi có Soul Connection mới.
    Gọi từ SoulEngine sau khi tìm được match.
    """
    result = await notification_service.on_soul_match(
        user_id=user_id,
        matched_user_id=matched_user_id,
        matched_user_name=matched_user_name,
        soul_score=soul_score,
        connection_type=connection_type,
    )
    return {"status": "sent" if result else "skipped"}


@router.post("/trigger/wellbeing-reminder")
async def trigger_wellbeing_reminder(
    user_id: str,
    reminder_type: str,
    message: str,
):
    """
    Internal endpoint: gửi notification nhắc nhở wellbeing.
    Gọi từ WellbeingService theo schedule.
    """
    result = await notification_service.on_wellbeing_reminder(
        user_id=user_id,
        reminder_type=reminder_type,
        message=message,
    )
    return {"status": "sent" if result else "skipped"}


@router.post("/trigger/ai-insight")
async def trigger_ai_insight_notification(
    user_id: str,
    insight_title: str,
    insight_body: str,
):
    """
    Internal endpoint: gửi notification với AI insight.
    """
    result = await notification_service.on_ai_insight(
        user_id=user_id,
        insight_title=insight_title,
        insight_body=insight_body,
    )
    return {"status": "sent" if result else "skipped"}