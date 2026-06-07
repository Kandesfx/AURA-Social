"""
AURA Social – AI Wellbeing Router
Endpoints for weekly emotional reports and self-care advice.
"""
from datetime import datetime, timedelta, timezone
import random
from fastapi import APIRouter, Depends, HTTPException, status
from app.auth import get_current_user
from app.models.wellbeing import (
    WeeklyReportResponse,
    WellbeingCheckRequest,
    WellbeingCheckResponse,
    WellbeingScoreResponse,
    DailyInsightResponse,
)
from app.ml.analytics_engine import weekly_analytics_engine
from app.utils.firebase_client import get_firestore

router = APIRouter()

@router.get("/report", response_model=WeeklyReportResponse)
async def get_weekly_report(user: dict = Depends(get_current_user)):
    """
    Generate the weekly emotional report and self-care recommendations for the logged-in user.
    """
    uid = user["uid"]
    db = get_firestore()
    
    checkins = []
    seven_days_ago = datetime.now(timezone.utc) - timedelta(days=7)

    try:
        # 1. Query Firestore for emotion history in the last 7 days
        # Collection: users/{uid}/emotion_history
        history_ref = db.collection('users').document(uid).collection('emotion_history')
        # Filter for check-ins within the last week
        query = history_ref.where('timestamp', '>=', seven_days_ago).order_by('timestamp', direction='ASCENDING').stream()

        for doc in query:
            data = doc.to_dict()
            # Standardize timestamp
            ts = data.get('timestamp')
            if isinstance(ts, datetime):
                # Ensure it is timezone-aware
                if ts.tzinfo is None:
                    ts = ts.replace(tzinfo=timezone.utc)
            checkins.append({
                'timestamp': ts,
                'emotion_vector': data.get('emotion_vector'),
                'dominant_emotion': data.get('dominant_emotion')
            })
    except Exception as e:
        print(f"⚠️ Wellbeing Router: Failed to fetch history from Firestore: {e}")

    # 2. Fallback: If there are no check-ins, return the default report
    if not checkins:
        print(f"ℹ️ No check-ins found for user {uid} in Firestore. Returning default report.")
        try:
            report = weekly_analytics_engine._get_default_report(uid)
            return WeeklyReportResponse(**report)
        except Exception as e:
            print(f"❌ Failed to generate default report: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Default report generation failed: {str(e)}"
            )

    # 3. Generate report
    try:
        report = weekly_analytics_engine.generate_weekly_report(uid, checkins)
        return WeeklyReportResponse(**report)
    except Exception as e:
        print(f"❌ Failed to generate weekly report: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Report generation failed: {str(e)}"
        )


@router.post("/check", response_model=WellbeingCheckResponse)
async def check_wellbeing(
    request: WellbeingCheckRequest,
    user: dict = Depends(get_current_user)
):
    """Real-time wellbeing check based on session data."""
    uid = user["uid"]
    session_minutes = request.session_duration_minutes
    emotion_vector = request.current_emotion_vector
    
    # Calculate wellbeing score from emotion vector
    positive = sum(emotion_vector.get(e, 0) for e in ['joy', 'trust', 'anticipation'])
    negative = sum(emotion_vector.get(e, 0) for e in ['sadness', 'fear', 'anger', 'disgust'])
    wellbeing_score = int(max(0, min(100, 50 + (positive - negative) * 100)))
    
    should_break = session_minutes >= 30 or negative > 0.4
    break_type = 'session_break' if session_minutes >= 30 else ('positive_inject' if negative > 0.4 else 'none')
    
    title = ""
    subtitle = ""
    suggestion = None
    
    if break_type == 'session_break':
        title = "🌙 Nghỉ ngơi một chút nhé!"
        subtitle = f"Bạn đã sử dụng AURA được {session_minutes} phút. Hãy dành chút thời gian để thư giãn."
        suggestion = "Thử nhìn ra cửa sổ hoặc uống một ly nước 💧"
    elif break_type == 'positive_inject':
        title = "✨ Góc tươi sáng"
        subtitle = "AURA nhận thấy bạn có thể cần một chút năng lượng tích cực."
        suggestion = "Hãy xem Emotional Compass để hiểu rõ hơn cảm xúc của bạn 🧭"
        
    return WellbeingCheckResponse(
        should_break=should_break,
        break_type=break_type,
        title=title,
        subtitle=subtitle,
        wellbeing_score=wellbeing_score,
        suggestion=suggestion
    )


@router.get("/score", response_model=WellbeingScoreResponse)
async def get_wellbeing_score(user: dict = Depends(get_current_user)):
    """Get overall wellbeing score based on user's recent emotion history."""
    uid = user["uid"]
    db = get_firestore()
    seven_days_ago = datetime.now(timezone.utc) - timedelta(days=7)
    
    try:
        history_ref = db.collection('users').document(uid).collection('emotion_history')
        query = history_ref.where('timestamp', '>=', seven_days_ago).stream()
        
        checkins = []
        for doc in query:
            data = doc.to_dict()
            if data.get('emotion_vector'):
                checkins.append(data.get('emotion_vector'))
                
        if not checkins:
            # Fallback from user profile dominant emotion
            user_doc = db.collection('users').document(uid).get()
            if user_doc.exists:
                user_data = user_doc.to_dict()
                dom = user_data.get('auraDominantEmotion', 'explore')
                if dom in ['joy', 'trust', 'anticipation']:
                    return WellbeingScoreResponse(score=85)
                elif dom in ['sadness', 'fear', 'anger', 'disgust']:
                    return WellbeingScoreResponse(score=55)
            return WellbeingScoreResponse(score=75)
            
        total_pos = 0.0
        total_neg = 0.0
        for vec in checkins:
            pos = sum(vec.get(e, 0) for e in ['joy', 'trust', 'anticipation'])
            neg = sum(vec.get(e, 0) for e in ['sadness', 'fear', 'anger', 'disgust'])
            total_pos += pos
            total_neg += neg
            
        avg_pos = total_pos / len(checkins)
        avg_neg = total_neg / len(checkins)
        score = int(max(0, min(100, 50 + (avg_pos - avg_neg) * 100)))
        return WellbeingScoreResponse(score=score)
    except Exception as e:
        print(f"⚠️ Failed to calculate real wellbeing score: {e}")
        return WellbeingScoreResponse(score=70)


@router.get("/daily-insight", response_model=DailyInsightResponse)
async def get_daily_insight(user: dict = Depends(get_current_user)):
    """Get daily emotional insight generated by Gemini or rules."""
    uid = user["uid"]
    db = get_firestore()
    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    
    try:
        history_ref = db.collection('users').document(uid).collection('emotion_history')
        query = history_ref.where('timestamp', '>=', today_start).stream()
        
        checkins = []
        for doc in query:
            data = doc.to_dict()
            ts = data.get('timestamp')
            if isinstance(ts, datetime) and ts.tzinfo is None:
                ts = ts.replace(tzinfo=timezone.utc)
            checkins.append({
                'timestamp': ts,
                'emotion_vector': data.get('emotion_vector'),
                'dominant_emotion': data.get('dominant_emotion')
            })
            
        # Get dominant emotion
        dominant_emotion = "explore"
        user_doc = db.collection('users').document(uid).get()
        if user_doc.exists:
            user_data = user_doc.to_dict()
            dominant_emotion = user_data.get('auraDominantEmotion', 'explore')
            
        if checkins:
            # Or get it from the last checkin today
            dominant_emotion = checkins[-1].get('dominant_emotion') or dominant_emotion
            
        insight = weekly_analytics_engine.generate_daily_insight(
            user_id=uid,
            checkins=checkins,
            dominant_emotion=dominant_emotion
        )
        return DailyInsightResponse(**insight)
    except Exception as e:
        print(f"❌ Failed to generate daily insight: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Daily insight generation failed: {str(e)}"
        )
