"""
AURA Social - Notification Service

Gửi FCM push notifications cho users.
Hỗ trợ:
- Notification types: message, soul_match, wave_join, wellbeing_reminder, challenge, post_reaction, follow, ai_insight
- Smart scheduling: quiet hours, notification fatigue, batch notifications
- Deep links cho Flutter routing
"""
import logging
from datetime import datetime, timezone
from typing import Optional
from enum import Enum

from firebase_admin import firestore

from app.utils.logging_config import get_logger

logger = get_logger(__name__)


# ── Notification Types ────────────────────────────────────────────────────────

class NotificationType(str, Enum):
    MESSAGE = "message"
    SOUL_MATCH = "soul_match"
    WAVE_JOIN = "wave_join"
    WELLBEING_REMINDER = "wellbeing_reminder"
    CHALLENGE = "challenge"
    POST_REACTION = "post_reaction"
    FOLLOW = "follow"
    AI_INSIGHT = "ai_insight"
    POST = "post"
    SYSTEM = "system"


# ── Notification Channels (Android) ───────────────────────────────────────────

NOTIFICATION_CHANNELS = {
    NotificationType.MESSAGE: {
        "id": "messages",
        "name": "Tin nhắn",
        "description": "Thông báo tin nhắn mới",
        "importance": "high",
    },
    NotificationType.SOUL_MATCH: {
        "id": "social",
        "name": "Soul Connections",
        "description": "Kết nối Soul mới",
        "importance": "high",
    },
    NotificationType.WAVE_JOIN: {
        "id": "social",
        "name": "Waves",
        "description": "Wave mới tham gia",
        "importance": "default",
    },
    NotificationType.WELLBEING_REMINDER: {
        "id": "wellbeing",
        "name": "Sức khỏe tinh thần",
        "description": "Nhắc nhở check-in, thử thách",
        "importance": "low",
    },
    NotificationType.CHALLENGE: {
        "id": "wellbeing",
        "name": "Thử thách",
        "description": "Thử thách mới",
        "importance": "default",
    },
    NotificationType.POST_REACTION: {
        "id": "social",
        "name": "Hoạt động xã hội",
        "description": "Reactions, comments",
        "importance": "default",
    },
    NotificationType.FOLLOW: {
        "id": "social",
        "name": "Người theo dõi",
        "description": "Người mới theo dõi",
        "importance": "default",
    },
    NotificationType.AI_INSIGHT: {
        "id": "wellbeing",
        "name": "AI Insights",
        "description": "Phân tích cảm xúc từ AI",
        "importance": "low",
    },
    NotificationType.POST: {
        "id": "social",
        "name": "Bài viết",
        "description": "Bài viết mới từ người theo dõi",
        "importance": "default",
    },
    NotificationType.SYSTEM: {
        "id": "system",
        "name": "Hệ thống",
        "description": "Thông báo hệ thống",
        "importance": "high",
    },
}


# ── Smart Notification Scheduler ──────────────────────────────────────────────

QUIET_HOURS = {"start": 22, "end": 8}  # 10 PM - 8 AM
MAX_NOTIFICATIONS_PER_HOUR = 5


class NotificationScheduler:
    """
    Smart scheduler: quyết định có gửi notification không.
    - Quiet hours: không gửi trừ notification khẩn cấp
    - Notification fatigue: max 5 notifications/giờ
    - Batch non-urgent: gửi batch mỗi 2 giờ thay vì liên tục
    """

    URGENT_TYPES = {
        NotificationType.MESSAGE,
        NotificationType.WAVE_JOIN,
        NotificationType.SOUL_MATCH,
    }

    def should_send(
        self,
        notification_type: NotificationType,
        user_preferences: Optional[dict] = None,
        recent_count: int = 0,
    ) -> bool:
        """Quyết định có nên gửi notification cho user không."""
        # 1. Kiểm tra quiet hours
        if self._is_quiet_hours():
            if notification_type not in self.URGENT_TYPES:
                logger.debug(
                    f"Skipping notification {notification_type} - quiet hours",
                    extra={"notification_type": notification_type.value},
                )
                return False

        # 2. Kiểm tra user preferences
        pref_key = f"notify_{notification_type.value}"
        if user_preferences and not user_preferences.get(pref_key, True):
            logger.debug(
                f"Skipping notification {notification_type} - user preference off",
                extra={"notification_type": notification_type.value},
            )
            return False

        # 3. Kiểm tra notification fatigue
        if recent_count >= MAX_NOTIFICATIONS_PER_HOUR:
            if notification_type not in self.URGENT_TYPES:
                logger.debug(
                    f"Skipping notification {notification_type} - fatigue limit reached",
                    extra={"recent_count": recent_count},
                )
                return False

        return True

    def _is_quiet_hours(self) -> bool:
        """Kiểm tra có đang trong quiet hours không."""
        now = datetime.now(timezone.utc).hour
        start = QUIET_HOURS["start"]
        end = QUIET_HOURS["end"]

        if start <= end:
            return start <= now < end
        else:
            return now >= start or now < end


# ── Main Notification Service ─────────────────────────────────────────────────

class NotificationService:
    """
    Gửi FCM push notifications tới users.

    Usage:
        ns = NotificationService()
        await ns.send(
            user_id="user_123",
            notification_type=NotificationType.MESSAGE,
            title="Tin nhắn mới",
            body="Bạn có tin nhắn từ Minh",
            data={"conversation_id": "conv_456"},
        )
    """

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return
        self._initialized = True
        self.scheduler = NotificationScheduler()
        self._fcm_initialized = False

    def _ensure_fcm(self) -> bool:
        """Đảm bảo FCM messaging được khởi tạo."""
        if self._fcm_initialized:
            return True
        try:
            from firebase_admin import messaging

            self._messaging = messaging
            self._fcm_initialized = True
            logger.info("FCM messaging initialized")
            return True
        except Exception as e:
            logger.warning(f"FCM messaging not available: {e}")
            return False

    async def send(
        self,
        user_id: str,
        notification_type: NotificationType,
        title: str,
        body: str,
        data: Optional[dict] = None,
        priority: str = "normal",
        image_url: Optional[str] = None,
    ) -> Optional[str]:
        """
        Gửi notification tới user.

        Args:
            user_id: Firebase user ID
            notification_type: Loại notification
            title: Tiêu đề notification
            body: Nội dung notification
            data: Payload data cho deep link (sẽ gửi qua FCM data message)
            priority: "high" hoặc "normal"
            image_url: URL ảnh thumbnail (optional)

        Returns:
            FCM message ID nếu gửi thành công, None nếu thất bại
        """
        if not self._ensure_fcm():
            logger.warning("FCM not initialized, skipping notification")
            return None

        # 1. Lấy FCM token từ Firestore
        fcm_token = await self._get_fcm_token(user_id)
        if not fcm_token:
            logger.debug(f"No FCM token for user {user_id}")
            return None

        # 2. Kiểm tra smart scheduling
        user_prefs = await self._get_user_preferences(user_id)
        recent_count = await self._get_recent_notification_count(user_id)

        if not self.scheduler.should_send(
            notification_type=notification_type,
            user_preferences=user_prefs,
            recent_count=recent_count,
        ):
            logger.debug(
                f"Notification blocked by scheduler for user {user_id}",
                extra={
                    "user_id": user_id,
                    "notification_type": notification_type.value,
                },
            )
            return None

        # 3. Build FCM message
        channel_info = NOTIFICATION_CHANNELS.get(
            notification_type, NOTIFICATION_CHANNELS[NotificationType.SYSTEM]
        )

        try:
            notification = self._messaging.Notification(
                title=title,
                body=body,
                image=image_url,
            )

            android_config = self._messaging.AndroidConfig(
                priority="high" if priority == "high" else "normal",
                notification=self._messaging.AndroidNotification(
                    channel_id=channel_info["id"],
                    icon="ic_notification",
                    color="#7C3AED",  # AURA purple
                    click_action="FLUTTER_NOTIFICATION_CLICK",
                ),
            )

            apns_config = self._messaging.APNSConfig(
                headers={
                    "apns-priority": "10" if priority == "high" else "5",
                    "apns-push-type": "alert",
                },
                payload=self._messaging.APNSPayload(
                    aps=self._messaging.Aps(
                        sound="default",
                        badge=1,
                    ),
                ),
            )

            # Merge notification data
            message_data = {
                "type": notification_type.value,
                **(data or {}),
            }

            message = self._messaging.Message(
                notification=notification,
                data=message_data,
                android=android_config,
                apns=apns_config,
                token=fcm_token,
            )

            # 4. Gửi
            response = self._messaging.send(message)

            # 5. Log notification gửi thành công
            await self._log_notification_sent(
                user_id=user_id,
                notification_type=notification_type,
                message_id=response,
            )

            logger.info(
                f"Notification sent to user {user_id}",
                extra={
                    "user_id": user_id,
                    "notification_type": notification_type.value,
                    "message_id": response,
                },
            )
            return response

        except self._messaging.UnregisteredError:
            # Token không hợp lệ, xóa khỏi Firestore
            logger.warning(f"FCM token expired for user {user_id}")
            await self._delete_fcm_token(user_id)
            return None

        except self._messaging.QuotaExceededError:
            logger.warning(f"FCM quota exceeded for user {user_id}")
            return None

        except Exception as e:
            logger.error(
                f"Failed to send notification: {e}",
                extra={
                    "user_id": user_id,
                    "notification_type": notification_type.value,
                    "error": str(e),
                },
            )
            return None

    # ── Trigger Points ────────────────────────────────────────────────────────

    async def on_new_message(
        self,
        conversation_id: str,
        sender_id: str,
        sender_name: str,
        sender_avatar: Optional[str] = None,
        message_preview: str = "",
    ) -> Optional[str]:
        """Gửi notification khi có tin nhắn mới trong cuộc trò chuyện."""
        # Lấy danh sách participants (trừ sender)
        participant_ids = await self._get_conversation_participants(conversation_id)
        recipient_ids = [uid for uid in participant_ids if uid != sender_id]

        if not recipient_ids:
            return None

        # Gửi notification cho mỗi recipient
        results = []
        for recipient_id in recipient_ids:
            result = await self.send(
                user_id=recipient_id,
                notification_type=NotificationType.MESSAGE,
                title=sender_name,
                body=message_preview or "Gửi tin nhắn mới",
                data={
                    "conversation_id": conversation_id,
                    "sender_id": sender_id,
                    "target_id": conversation_id,
                },
                priority="high",
            )
            results.append(result)
        return results[0] if len(results) == 1 else results

    async def on_soul_match(
        self,
        user_id: str,
        matched_user_id: str,
        matched_user_name: str,
        soul_score: float,
        connection_type: str,
    ) -> Optional[str]:
        """Gửi notification khi có Soul Connection mới."""
        return await self.send(
            user_id=user_id,
            notification_type=NotificationType.SOUL_MATCH,
            title="Soul Connection mới!",
            body=f"{matched_user_name} có mức độ phù hợp {int(soul_score * 100)}% với bạn",
            data={
                "matched_user_id": matched_user_id,
                "soul_score": str(soul_score),
                "connection_type": connection_type,
                "target_id": matched_user_id,
            },
            priority="high",
        )

    async def on_wave_nearby(
        self,
        user_id: str,
        wave_id: str,
        wave_name: str,
        member_count: int,
        dominant_emotion: str,
    ) -> Optional[str]:
        """Gửi notification khi có wave mới gần user."""
        return await self.send(
            user_id=user_id,
            notification_type=NotificationType.WAVE_JOIN,
            title="Wave mới gần bạn",
            body=f"{wave_name} - {member_count} người đang ở trạng thái {dominant_emotion}",
            data={
                "wave_id": wave_id,
                "target_id": wave_id,
            },
            priority="normal",
        )

    async def on_wellbeing_reminder(
        self,
        user_id: str,
        reminder_type: str,
        message: str,
    ) -> Optional[str]:
        """Gửi notification nhắc nhở wellbeing."""
        title_map = {
            "mood_checkin": "Đã đến lúc check-in cảm xúc",
            "challenge": "Thử thách mới đang chờ bạn",
            "streak": "Giữ chuỗi wellbeing của bạn",
            "insight": "AI có gì muốn chia sẻ",
        }
        title = title_map.get(reminder_type, "Nhắc nhở từ AURA")

        return await self.send(
            user_id=user_id,
            notification_type=NotificationType.WELLBEING_REMINDER,
            title=title,
            body=message,
            data={
                "reminder_type": reminder_type,
                "target_id": "wellbeing",
            },
            priority="normal",
        )

    async def on_post_reaction(
        self,
        user_id: str,
        post_id: str,
        reactor_name: str,
        reaction_emotion: str,
        total_reactions: int,
    ) -> Optional[str]:
        """Gửi notification khi bài viết được reaction."""
        emotion_emoji = {
            "joy": "vui",
            "sadness": "buồn",
            "anger": "giận",
            "fear": "sợ",
            "surprise": "bất ngờ",
            "disgust": "ghê tởm",
            "trust": "tin tưởng",
            "anticipation": "mong chờ",
        }
        emotion_text = emotion_emoji.get(reaction_emotion, reaction_emotion)

        body = f"{reactor_name} đã bày tỏ cảm xúc '{emotion_text}'"
        if total_reactions > 1:
            body += f" ({total_reactions} reactions)"

        return await self.send(
            user_id=user_id,
            notification_type=NotificationType.POST_REACTION,
            title="Reaction mới",
            body=body,
            data={
                "post_id": post_id,
                "target_id": post_id,
                "emotion": reaction_emotion,
            },
            priority="normal",
        )

    async def on_follow(
        self,
        user_id: str,
        follower_id: str,
        follower_name: str,
    ) -> Optional[str]:
        """Gửi notification khi có người theo dõi mới."""
        return await self.send(
            user_id=user_id,
            notification_type=NotificationType.FOLLOW,
            title="Người theo dõi mới",
            body=f"{follower_name} đã bắt đầu theo dõi bạn",
            data={
                "follower_id": follower_id,
                "target_id": follower_id,
            },
            priority="normal",
        )

    async def on_ai_insight(
        self,
        user_id: str,
        insight_title: str,
        insight_body: str,
    ) -> Optional[str]:
        """Gửi notification với AI insight."""
        return await self.send(
            user_id=user_id,
            notification_type=NotificationType.AI_INSIGHT,
            title=insight_title,
            body=insight_body,
            data={
                "target_id": "compass",
            },
            priority="low",
        )

    # ── Database Helpers ───────────────────────────────────────────────────────

    async def _get_fcm_token(self, user_id: str) -> Optional[str]:
        """Lấy FCM token của user từ Firestore."""
        try:
            from app.utils.firebase_client import get_firestore

            db = get_firestore()
            doc = db.collection("users").document(user_id).get()
            if doc.exists:
                return doc.to_dict().get("fcmToken")
            return None
        except Exception as e:
            logger.warning(f"Failed to get FCM token: {e}")
            return None

    async def _delete_fcm_token(self, user_id: str) -> None:
        """Xóa FCM token của user khỏi Firestore."""
        try:
            from app.utils.firebase_client import get_firestore

            db = get_firestore()
            db.collection("users").document(user_id).update(
                {"fcmToken": firestore.DELETE_FIELD}
            )
        except Exception as e:
            logger.warning(f"Failed to delete FCM token: {e}")

    async def _get_user_preferences(self, user_id: str) -> Optional[dict]:
        """Lấy notification preferences của user."""
        try:
            from app.utils.firebase_client import get_firestore

            db = get_firestore()
            doc = db.collection("users").document(user_id).collection("settings").document("notifications").get()
            if doc.exists:
                return doc.to_dict()
            return None
        except Exception:
            return None

    async def _get_recent_notification_count(self, user_id: str) -> int:
        """Đếm số notification đã gửi trong 1 giờ qua."""
        try:
            from app.utils.firebase_client import get_firestore

            db = get_firestore()
            one_hour_ago = datetime.now(timezone.utc)
            docs = (
                db.collection("users")
                .document(user_id)
                .collection("notification_log")
                .where("sent_at", ">=", one_hour_ago)
                .stream()
            )
            return sum(1 for _ in docs)
        except Exception:
            return 0

    async def _log_notification_sent(
        self,
        user_id: str,
        notification_type: NotificationType,
        message_id: str,
    ) -> None:
        """Log notification đã gửi vào Firestore."""
        try:
            from app.utils.firebase_client import get_firestore

            db = get_firestore()
            db.collection("users").document(user_id).collection("notification_log").add(
                {
                    "type": notification_type.value,
                    "message_id": message_id,
                    "sent_at": datetime.now(timezone.utc),
                }
            )
        except Exception as e:
            logger.warning(f"Failed to log notification: {e}")

    async def _get_conversation_participants(
        self, conversation_id: str
    ) -> list[str]:
        """Lấy danh sách participant IDs của một cuộc trò chuyện."""
        try:
            from app.utils.firebase_client import get_firestore

            db = get_firestore()
            doc = db.collection("conversations").document(conversation_id).get()
            if doc.exists:
                return doc.to_dict().get("participantIds", [])
            return []
        except Exception:
            return []


# Singleton instance
notification_service = NotificationService()