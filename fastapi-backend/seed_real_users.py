"""
AURA Social – Firestore User Seeder
Seeds sample user profiles to Firestore so they can be matched via Soul Connect.
"""
import os
import sys
import random
from datetime import datetime, timezone

# Add current directory to python path
sys.path.append(os.path.abspath(os.path.dirname(__file__)))

from app.config import get_settings
from app.utils.firebase_client import init_firebase, get_firestore

def seed_users():
    print("🌱 Initializing Firebase Admin SDK...")
    init_firebase()
    db = get_firestore()
    
    # 5 Real-looking profiles with distinct vibes
    users_to_seed = [
        {
            "uid": "aura_user_linh",
            "email": "linh.nguyen@aura.vn",
            "display_name": "Linh Nguyễn",
            "username": "linh_chill",
            "bio": "Yêu thích đọc sách, nghe nhạc chill và đi bộ hoàng hôn ☕✨. Cùng kết nối nhé!",
            "interests": ["music", "reading", "nature", "coffee"],
            "aura_dominant_emotion": "joy",
            "current_emotion_vector": {
                "joy": 0.50, "trust": 0.20, "anticipation": 0.10, "surprise": 0.05,
                "sadness": 0.05, "fear": 0.04, "anger": 0.03, "disgust": 0.03
            },
            "peak_activity_hours": [9, 14, 20]
        },
        {
            "uid": "aura_user_huy",
            "email": "huy.tran@aura.vn",
            "display_name": "Quang Huy",
            "username": "huy_tech_runner",
            "bio": "Tech enthusiast, thích chạy bộ mỗi sáng 🏃‍♂️🚀. Đam mê xây dựng sản phẩm công nghệ.",
            "interests": ["tech", "running", "sports", "coding"],
            "aura_dominant_emotion": "anticipation",
            "current_emotion_vector": {
                "joy": 0.20, "trust": 0.20, "anticipation": 0.45, "surprise": 0.05,
                "sadness": 0.04, "fear": 0.02, "anger": 0.02, "disgust": 0.02
            },
            "peak_activity_hours": [6, 12, 18, 21]
        },
        {
            "uid": "aura_user_dang",
            "email": "dang.phan@aura.vn",
            "display_name": "Phan Đăng",
            "username": "dang_zen",
            "bio": "Tâm trí tĩnh lặng, hướng đến cuộc sống tối giản và bình yên 🧘‍♂️📖.",
            "interests": ["yoga", "meditation", "reading", "art"],
            "aura_dominant_emotion": "trust",
            "current_emotion_vector": {
                "joy": 0.15, "trust": 0.50, "anticipation": 0.10, "surprise": 0.05,
                "sadness": 0.10, "fear": 0.05, "anger": 0.02, "disgust": 0.03
            },
            "peak_activity_hours": [5, 10, 15, 22]
        },
        {
            "uid": "aura_user_nhan",
            "email": "nhan.le@aura.vn",
            "display_name": "Minh Nhân",
            "username": "nhan_music_chill",
            "bio": "Sống để nghe nhạc và du lịch bụi 🎸🎒. Thích đi phượt bằng xe máy.",
            "interests": ["travel", "music", "guitar", "photography"],
            "aura_dominant_emotion": "surprise",
            "current_emotion_vector": {
                "joy": 0.30, "trust": 0.15, "anticipation": 0.15, "surprise": 0.35,
                "sadness": 0.02, "fear": 0.01, "anger": 0.01, "disgust": 0.01
            },
            "peak_activity_hours": [8, 17, 23]
        },
        {
            "uid": "aura_user_vy",
            "email": "vy.hoang@aura.vn",
            "display_name": "Tường Vy",
            "username": "vy_creative",
            "bio": "Designer tự do 🎨. Yêu cái đẹp, mèo và những cuộc hội thoại sâu sắc.",
            "interests": ["design", "art", "cats", "writing"],
            "aura_dominant_emotion": "joy",
            "current_emotion_vector": {
                "joy": 0.40, "trust": 0.30, "anticipation": 0.10, "surprise": 0.10,
                "sadness": 0.04, "fear": 0.03, "anger": 0.02, "disgust": 0.01
            },
            "peak_activity_hours": [10, 16, 21, 0]
        }
    ]

    print("🚀 Seeding users into Firestore...")
    for u in users_to_seed:
        uid = u["uid"]
        
        # Create 384-dimension vector for content taste embedding simulation
        # Random float vector that is standard for MiniLM models
        random.seed(hash(uid))
        pref_vector = [random.uniform(-0.1, 0.1) for _ in range(384)]
        
        doc_data = {
            "uid": uid,
            "email": u["email"],
            "display_name": u["display_name"],
            "username": u["username"],
            "bio": u["bio"],
            "interests": u["interests"],
            "followers_count": random.randint(10, 150),
            "following_count": random.randint(10, 150),
            "posts_count": random.randint(5, 30),
            "connections_count": random.randint(2, 25),
            "aura_dominant_emotion": u["aura_dominant_emotion"],
            "aura_valence": 0.5,
            "aura_confidence": 0.85,
            "current_emotion_vector": u["current_emotion_vector"],
            "content_preference_vector": pref_vector,
            "peak_activity_hours": u["peak_activity_hours"],
            "is_online": True,
            "account_status": "active",
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc),
            "ai_settings": {
                "emotion_inference_enabled": True,
                "behavioral_tracking_enabled": True,
                "mood_expression_enabled": True,
                "wellbeing_guard_enabled": True,
                "soul_connect_enabled": True,
                "aura_ring_visible": True
            }
        }
        
        # Write to Firestore
        db.collection("users").document(uid).set(doc_data)
        print(f"✅ Seeded user: {u['display_name']} ({uid})")
        
    print("🎉 ALL USERS SEEDED SUCCESSFULLY!")

if __name__ == "__main__":
    seed_users()
