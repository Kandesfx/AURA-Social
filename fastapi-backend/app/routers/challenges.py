"""
AURA Social – AI Challenges Router
"""
from datetime import datetime, timezone, timedelta
import random
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from app.auth import get_current_user
from app.models.challenges import (
    ChallengeItem,
    ActiveChallengesResponse,
    CompleteChallengeRequest,
    CompleteChallengeResponse,
)
from app.utils.firebase_client import get_firestore

router = APIRouter()

# Predefined templates matching Plutchik/AURA emotions
CHALLENGE_TEMPLATES = {
    "sadness": [
        {
            "id": "gratitude_3d",
            "title": "🌸 3 ngày thực hành biết ơn",
            "description": "Mỗi ngày ghi lại ít nhất 3 điều tốt đẹp nhỏ nhoi bạn cảm thấy biết ơn trong ngày.",
            "duration_days": 3,
            "max_progress": 3,
            "category": "sadness"
        },
        {
            "id": "nature_walk_1d",
            "title": "🚶 Hòa mình vào thiên nhiên",
            "description": "Dành 15 phút đi bộ ngoài trời, không dùng điện thoại, chỉ tập trung ngắm nhìn cây cối và hít thở sâu.",
            "duration_days": 1,
            "max_progress": 1,
            "category": "sadness"
        }
    ],
    "anger": [
        {
            "id": "meditation_5m",
            "title": "🧘 5 phút thiền buông bỏ",
            "description": "Ngồi tĩnh lặng, tập trung hoàn toàn vào hơi thở ra vào để làm dịu ngọn lửa giận dữ bên trong.",
            "duration_days": 1,
            "max_progress": 1,
            "category": "anger"
        },
        {
            "id": "vent_journal",
            "title": "✍️ Viết nhật ký giải tỏa",
            "description": "Viết hết tất cả những tức giận, thất vọng lên trang giấy/ghi chú rồi xóa đi để giải phóng năng lượng tiêu cực.",
            "duration_days": 1,
            "max_progress": 1,
            "category": "anger"
        }
    ],
    "disgust": [
        {
            "id": "declutter_10m",
            "title": "🧹 10 phút dọn dẹp không gian",
            "description": "Sắp xếp lại bàn làm việc hoặc một góc phòng nhỏ để tạo cảm giác tươi mới và ngăn nắp.",
            "duration_days": 1,
            "max_progress": 1,
            "category": "disgust"
        }
    ],
    "fear": [
        {
            "id": "deep_breathing",
            "title": "🫁 Thở sâu giải tỏa lo âu",
            "description": "Thực hiện kỹ thuật thở hộp (box breathing: hít vào 4s, giữ 4s, thở ra 4s, giữ 4s) trong 3 phút.",
            "duration_days": 1,
            "max_progress": 1,
            "category": "fear"
        },
        {
            "id": "emotion_journal",
            "title": "📝 Gọi tên nỗi sợ",
            "description": "Viết ra điều đang làm bạn lo lắng nhất và phân tích xem kịch bản tệ nhất có thực sự đáng sợ như bạn nghĩ.",
            "duration_days": 1,
            "max_progress": 1,
            "category": "fear"
        }
    ],
    "surprise": [
        {
            "id": "new_habit",
            "title": "✨ Trải nghiệm một điều mới mẻ",
            "description": "Đi một con đường khác đi học/đi làm, nghe một thể loại nhạc mới hoặc thử một món ăn chưa từng ăn.",
            "duration_days": 1,
            "max_progress": 1,
            "category": "surprise"
        }
    ],
    "default": [
        {
            "id": "compliment_friends",
            "title": "💛 Lan tỏa sự ấm áp",
            "description": "Gửi ít nhất 1 tin nhắn cảm ơn hoặc khen ngợi chân thành đến một người bạn trên AURA.",
            "duration_days": 1,
            "max_progress": 1,
            "category": "joy"
        },
        {
            "id": "daily_goals",
            "title": "🌻 Thiết lập ngày mới",
            "description": "Đặt ra 3 mục tiêu nhỏ cần hoàn thành hôm nay và tập trung thực hiện chúng.",
            "duration_days": 1,
            "max_progress": 1,
            "category": "joy"
        }
    ]
}

@router.get("/active", response_model=ActiveChallengesResponse)
async def get_active_challenges(user: dict = Depends(get_current_user)):
    """
    Get or generate active wellbeing challenges based on user's current emotional state.
    """
    uid = user["uid"]
    db = get_firestore()
    now = datetime.now(timezone.utc)
    
    # 1. Fetch existing challenges for the user
    challenges_ref = db.collection('users').document(uid).collection('challenges')
    query = challenges_ref.where('status', '==', 'active').stream()
    
    active_challenges = []
    for doc in query:
        data = doc.to_dict()
        # Check if challenge has expired
        created_at_str = data.get('created_at', '')
        duration_days = data.get('duration_days', 1)
        try:
            created_at = datetime.fromisoformat(created_at_str.replace('Z', '+00:00'))
            if now > created_at + timedelta(days=duration_days):
                # Mark as expired
                doc.reference.update({'status': 'expired'})
                continue
        except Exception:
            pass
            
        active_challenges.append(ChallengeItem(
            id=doc.id,
            title=data.get('title', ''),
            description=data.get('description', ''),
            duration_days=data.get('duration_days', 1),
            category=data.get('category', 'default'),
            status=data.get('status', 'active'),
            progress=data.get('progress', 0),
            max_progress=data.get('max_progress', 1),
            created_at=created_at_str,
            completed_at=data.get('completed_at')
        ))
        
    if active_challenges:
        return ActiveChallengesResponse(challenges=active_challenges)
        
    # 2. If no active challenges exist, determine dominant emotion and generate new ones
    dominant_emotion = "default"
    try:
        # Check last 7 days of emotion history
        seven_days_ago = now - timedelta(days=7)
        history_ref = db.collection('users').document(uid).collection('emotion_history')
        history_query = history_ref.where('timestamp', '>=', seven_days_ago).stream()
        
        checkins = [doc.to_dict() for doc in history_query]
        if checkins:
            # Aggregate dominant emotions
            emotions = [c.get('dominant_emotion') for c in checkins if c.get('dominant_emotion')]
            if emotions:
                dominant_emotion = max(set(emotions), key=emotions.count)
        else:
            # Check user profile dominant emotion
            user_doc = db.collection('users').document(uid).get()
            if user_doc.exists:
                user_data = user_doc.to_dict()
                dominant_emotion = user_data.get('auraDominantEmotion', 'default')
    except Exception as e:
        print(f"⚠️ Challenges Router: Failed to read emotion state: {e}")
        
    # Standardize category
    category = dominant_emotion if dominant_emotion in CHALLENGE_TEMPLATES else "default"
    templates = CHALLENGE_TEMPLATES[category]
    
    # Generate 1 to 2 challenges
    selected_templates = templates
    if len(templates) > 2:
        selected_templates = random.sample(templates, 2)
        
    new_challenges = []
    for t in selected_templates:
        challenge_id = f"{t['id']}_{int(now.timestamp())}"
        doc_data = {
            "title": t["title"],
            "description": t["description"],
            "duration_days": t["duration_days"],
            "category": t["category"],
            "status": "active",
            "progress": 0,
            "max_progress": t["max_progress"],
            "created_at": now.isoformat() + "Z",
            "completed_at": None
        }
        challenges_ref.document(challenge_id).set(doc_data)
        
        new_challenges.append(ChallengeItem(
            id=challenge_id,
            title=doc_data["title"],
            description=doc_data["description"],
            duration_days=doc_data["duration_days"],
            category=doc_data["category"],
            status=doc_data["status"],
            progress=doc_data["progress"],
            max_progress=doc_data["max_progress"],
            created_at=doc_data["created_at"],
            completed_at=doc_data["completed_at"]
        ))
        
    return ActiveChallengesResponse(challenges=new_challenges)


@router.post("/complete", response_model=CompleteChallengeResponse)
async def complete_challenge(
    request: CompleteChallengeRequest,
    user: dict = Depends(get_current_user)
):
    """
    Update progress on a specific challenge and mark as completed if progress matches max_progress.
    """
    uid = user["uid"]
    challenge_id = request.challenge_id
    db = get_firestore()
    
    doc_ref = db.collection('users').document(uid).collection('challenges').document(challenge_id)
    doc = doc_ref.get()
    
    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Challenge not found"
        )
        
    data = doc.to_dict()
    if data.get('status') != 'active':
        return CompleteChallengeResponse(
            success=False,
            message=f"Challenge is already {data.get('status')}",
            challenge=ChallengeItem(
                id=doc.id,
                title=data.get('title', ''),
                description=data.get('description', ''),
                duration_days=data.get('duration_days', 1),
                category=data.get('category', 'default'),
                status=data.get('status', 'active'),
                progress=data.get('progress', 0),
                max_progress=data.get('max_progress', 1),
                created_at=data.get('created_at', ''),
                completed_at=data.get('completed_at')
            )
        )
        
    current_progress = data.get('progress', 0)
    max_progress = data.get('max_progress', 1)
    
    new_progress = min(max_progress, current_progress + request.progress_increment)
    new_status = 'completed' if new_progress >= max_progress else 'active'
    completed_at = datetime.now(timezone.utc).isoformat() + "Z" if new_status == 'completed' else None
    
    update_data = {
        'progress': new_progress,
        'status': new_status,
        'completed_at': completed_at
    }
    doc_ref.update(update_data)
    
    # Merge updates into local representation
    data.update(update_data)
    
    # If completed, let's also award a little wellbeing score boost or save to logs!
    if new_status == 'completed':
        try:
            # Record wellbeing score event or write log
            history_ref = db.collection('users').document(uid).collection('emotion_history')
            history_ref.add({
                'timestamp': datetime.now(timezone.utc),
                'dominant_emotion': 'joy',
                'emotion_vector': {
                    'joy': 0.8,
                    'trust': 0.8,
                    'anticipation': 0.5,
                    'surprise': 0.3,
                    'sadness': 0.0,
                    'fear': 0.0,
                    'anger': 0.0,
                    'disgust': 0.0
                },
                'source': 'challenge_completion',
                'challenge_title': data.get('title')
            })
        except Exception as e:
            print(f"⚠️ Failed to log challenge completion to history: {e}")
            
    updated_item = ChallengeItem(
        id=doc.id,
        title=data.get('title', ''),
        description=data.get('description', ''),
        duration_days=data.get('duration_days', 1),
        category=data.get('category', 'default'),
        status=data.get('status', 'active'),
        progress=data.get('progress', 0),
        max_progress=data.get('max_progress', 1),
        created_at=data.get('created_at', ''),
        completed_at=data.get('completed_at')
    )
    
    message = "Chúc mừng bạn đã hoàn thành thử thách! 🎉 Một hạt mầm tích cực đã được gieo trồng." if new_status == 'completed' else "Tiến trình của bạn đã được cập nhật."
    
    return CompleteChallengeResponse(
        success=True,
        message=message,
        challenge=updated_item
    )
