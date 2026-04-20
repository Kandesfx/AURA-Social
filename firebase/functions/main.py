"""
AURA Social – Cloud Functions (Firebase Functions 2nd Gen - Python)

⚠️ YÊU CẦU BLAZE PLAN để deploy.
   Hiện tại code chỉ để sẵn. Khi có Blaze plan, chạy:
   cd firebase && firebase deploy --only functions

Tạm thời, các logic này được xử lý trực tiếp trong FastAPI.
"""
import os
import json
import requests
from firebase_functions import firestore_fn, https_fn, scheduler_fn
from firebase_admin import initialize_app, firestore, auth, messaging

# Initialize Firebase Admin
app = initialize_app()

# FastAPI backend URL (thay bằng Cloud Run URL khi deploy)
FASTAPI_URL = os.environ.get("FASTAPI_URL", "http://localhost:8080")
INTERNAL_API_KEY = os.environ.get("INTERNAL_API_KEY", "")


def get_db():
    """Lazy-init Firestore client (tránh lỗi credentials khi CLI analyze)."""
    return firestore.client()


# ════════════════════════════════════════════════════
# 1. ON USER CREATED
# Trigger: Auth → User mới đăng ký
# Action: Tạo user doc + emotion profile mặc định
# ════════════════════════════════════════════════════
@https_fn.on_call()
def on_user_created(req: https_fn.CallableRequest):
    """
    Khi user mới đăng ký, tạo:
    - Document trong /users/{uid}
    - Subcollection /users/{uid}/emotion_profile/current
    """
    uid = req.auth.uid if req.auth else None
    if not uid:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="User must be authenticated"
        )

    user_record = auth.get_user(uid)

    # Tạo user document
    user_data = {
        "uid": uid,
        "displayName": user_record.display_name or "",
        "email": user_record.email or "",
        "photoURL": user_record.photo_url or "",
        "bio": "",
        "followersCount": 0,
        "followingCount": 0,
        "postsCount": 0,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
        "isOnline": True,
        "lastSeen": firestore.SERVER_TIMESTAMP,
    }

    get_db().collection("users").document(uid).set(user_data)

    # Tạo emotion profile mặc định (neutral)
    default_emotion = {
        "emotionVector": {
            "joy": 0.125,
            "trust": 0.125,
            "anticipation": 0.125,
            "surprise": 0.125,
            "sadness": 0.125,
            "fear": 0.125,
            "anger": 0.125,
            "disgust": 0.125,
        },
        "dominantEmotion": "neutral",
        "emotionalMode": "balanced",
        "confidence": 0.0,
        "lastUpdated": firestore.SERVER_TIMESTAMP,
        "updateCount": 0,
    }

    get_db().collection("users").document(uid) \
      .collection("emotion_profile").document("current") \
      .set(default_emotion)

    print(f"✅ Created user doc + emotion profile for {uid}")
    return {"success": True, "uid": uid}


# ════════════════════════════════════════════════════
# 2. ON NEW POST
# Trigger: Firestore → /posts/{postId} created
# Action: Gọi FastAPI /content/analyze để phân tích cảm xúc
# ════════════════════════════════════════════════════
@firestore_fn.on_document_created(document="posts/{postId}")
def on_new_post(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]):
    """
    Khi có bài post mới:
    1. Gọi FastAPI /content/analyze
    2. Lưu emotion_vector vào post document
    3. Cập nhật user's emotion_profile
    """
    post_id = event.params["postId"]
    post_data = event.data.to_dict()

    if not post_data or not post_data.get("text"):
        print(f"⚠️ Post {post_id} has no text, skipping analysis")
        return

    # Gọi FastAPI Content Analysis
    try:
        response = requests.post(
            f"{FASTAPI_URL}/api/v1/content/analyze",
            json={
                "post_id": post_id,
                "text": post_data.get("text", ""),
                "user_id": post_data.get("authorId", ""),
                "media_urls": post_data.get("mediaUrls", []),
            },
            headers={"X-Internal-Key": INTERNAL_API_KEY},
            timeout=30,
        )

        if response.status_code == 200:
            analysis = response.json()

            # Cập nhật post với emotion data từ AI
            get_db().collection("posts").document(post_id).update({
                "emotionVector": analysis.get("emotion_vector", {}),
                "sentimentScore": analysis.get("sentiment_score", 0),
                "isAnalyzed": True,
                "analyzedAt": firestore.SERVER_TIMESTAMP,
            })

            print(f"✅ Post {post_id} analyzed: {analysis.get('emotion_vector', {})}")
        else:
            print(f"❌ FastAPI error {response.status_code}: {response.text}")

    except Exception as e:
        print(f"❌ Failed to analyze post {post_id}: {e}")


# ════════════════════════════════════════════════════
# 3. ON NEW MESSAGE
# Trigger: Firestore → khi conversation cập nhật lastMessage
# Action: Gửi push notification cho người nhận
# ════════════════════════════════════════════════════
@firestore_fn.on_document_updated(document="conversations/{conversationId}")
def on_conversation_updated(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]):
    """
    Khi conversation có tin nhắn mới → push notification.
    """
    after = event.data.after.to_dict()
    before = event.data.before.to_dict()

    if not after or not before:
        return

    # Chỉ trigger khi lastMessage thay đổi
    if after.get("lastMessage") == before.get("lastMessage"):
        return

    sender_id = after.get("lastMessageSenderId", "")
    member_ids = after.get("memberIds", [])
    last_message = after.get("lastMessage", "")

    # Gửi notification cho tất cả members trừ người gửi
    for member_id in member_ids:
        if member_id == sender_id:
            continue

        # Lấy FCM token của người nhận
        user_doc = get_db().collection("users").document(member_id).get()
        if not user_doc.exists:
            continue

        user_data = user_doc.to_dict()
        fcm_token = user_data.get("fcmToken")
        if not fcm_token:
            continue

        # Lấy tên người gửi
        sender_doc = get_db().collection("users").document(sender_id).get()
        sender_name = sender_doc.to_dict().get("displayName", "Someone") if sender_doc.exists else "Someone"

        # Gửi push notification
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=sender_name,
                    body=last_message[:100],
                ),
                token=fcm_token,
                data={
                    "type": "new_message",
                    "conversationId": event.params["conversationId"],
                    "senderId": sender_id,
                },
            )
            messaging.send(message)
            print(f"✅ Push sent to {member_id}")
        except Exception as e:
            print(f"❌ Failed to send push to {member_id}: {e}")


# ════════════════════════════════════════════════════
# 4. ON FOLLOW
# Trigger: Firestore → /users/{uid}/followers/{followerId} created
# Action: Cập nhật follower/following counts + notify
# ════════════════════════════════════════════════════
@firestore_fn.on_document_created(document="users/{userId}/followers/{followerId}")
def on_follow(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]):
    """Cập nhật counts và tạo notification khi follow."""
    user_id = event.params["userId"]
    follower_id = event.params["followerId"]

    # Tăng follower count cho user được follow
    get_db().collection("users").document(user_id).update({
        "followersCount": firestore.Increment(1)
    })

    # Tăng following count cho người follow
    get_db().collection("users").document(follower_id).update({
        "followingCount": firestore.Increment(1)
    })

    # Tạo notification
    get_db().collection("notifications").add({
        "recipientId": user_id,
        "senderId": follower_id,
        "type": "follow",
        "message": "đã follow bạn",
        "isRead": False,
        "createdAt": firestore.SERVER_TIMESTAMP,
    })

    print(f"✅ {follower_id} followed {user_id}")
