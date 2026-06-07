"""
AURA Social – Emotion Router
Endpoints for emotion inference and analysis.
"""
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from app.auth import get_current_user
from app.models.emotion import EmotionInferRequest, EmotionInferResponse
from app.ml.emotion_engine import emotion_inference_engine, EMOTIONS
from app.utils.firebase_client import get_firestore

router = APIRouter()


@router.post("/infer", response_model=EmotionInferResponse)
async def infer_emotion(
    request: EmotionInferRequest,
    user: dict = Depends(get_current_user),
):
    """
    Infers user emotional state from recent text inputs, behavioral logs (scroll, dwell),
    and contextual cues. Updates user's emotion profile in Firestore.
    """
    uid = user["uid"]
    db = get_firestore()

    try:
        # ── Layer 1: Behavioral Signals ──
        events = request.behavioral_events or []
        behavioral_res = emotion_inference_engine.analyze_behavioral(events)

        # ── Layer 2: Content Interaction (Fetch recent analytics from Firestore if available) ──
        # Fallback to neutral interaction vector
        interaction_res = {'vector': [0.125] * 8}
        try:
            # Check if user has recorded interactions in the last 24h
            user_doc = db.collection('users').document(uid).get()
            if user_doc.exists:
                user_data = user_doc.to_dict()
                recent_interactions = user_data.get('recent_interactions', {})
                if recent_interactions:
                    interaction_res = emotion_inference_engine.analyze_interactions(recent_interactions)
        except Exception as e:
            print(f"⚠️ Failed to load user interactions from Firestore: {e}")

        # ── Layer 3: Text Sentiment ──
        text_list = []
        if request.text:
            text_list.append(request.text)
        
        # Try fetching user's recent posts/comments text for broader context
        try:
            posts_query = db.collection('posts').where('user_id', '==', uid).order_by('created_at', direction='DESCENDING').limit(3).stream()
            for doc in posts_query:
                p_data = doc.to_dict()
                if p_data.get('content'):
                    text_list.append(p_data['content'])
        except Exception:
            pass

        text_res = emotion_inference_engine.analyze_texts(text_list)

        # ── Layer 4: Temporal Context ──
        context_data = request.context or {}
        if 'hour' not in context_data:
            context_data['hour'] = datetime.now().hour
        if 'day_of_week' not in context_data:
            context_data['day_of_week'] = datetime.now().weekday()
        if 'session_gap_hours' not in context_data:
            # We can calculate session gap from last update
            context_data['session_gap_hours'] = 2.0
            try:
                profile_ref = db.collection('users').document(uid).collection('emotion_profile').document('current').get()
                if profile_ref.exists:
                    p_data = profile_ref.to_dict()
                    updated_at = p_data.get('updated_at')
                    if updated_at:
                        # Ensure offset-aware datetime
                        if updated_at.tzinfo is None:
                            updated_at = updated_at.replace(tzinfo=timezone.utc)
                        gap = (datetime.now(timezone.utc) - updated_at).total_seconds() / 3600.0
                        context_data['session_gap_hours'] = gap
            except Exception:
                pass

        temporal_res = emotion_inference_engine.analyze_temporal(context_data)

        # ── Layer 5: Social Graph ──
        social_res = {'vector': [0.125] * 8}
        try:
            # Estimate reciprocity from followers vs following
            user_ref = db.collection('users').document(uid).get()
            if user_ref.exists:
                u_data = user_ref.to_dict()
                followers = u_data.get('followersCount', 0)
                following = u_data.get('followingCount', 0)
                reciprocity = 1.0
                if following > 0:
                    reciprocity = min(1.0, followers / following)
                social_res = emotion_inference_engine.analyze_social({'reciprocity_rate': reciprocity})
        except Exception:
            pass

        # ── Weighted Signal Fusion ──
        explicit_mood = context_data.get('explicit_mood')
        fused = emotion_inference_engine.fuse_signals(
            behavioral=behavioral_res,
            interaction=interaction_res,
            text=text_res,
            temporal=temporal_res,
            social=social_res,
            explicit_mood=explicit_mood
        )

        # ── Detect Emotional Mode ──
        emotional_mode = emotion_inference_engine.detect_emotional_mode(fused)

        # ── Calculate Confidence Score ──
        signals_avail = {
            'behavioral_count': len(events),
            'interaction_count': 1 if interaction_res['vector'] != [0.125] * 8 else 0,
            'text_count': len(text_list),
            'has_explicit_mood': explicit_mood is not None
        }
        confidence = emotion_inference_engine.calculate_confidence(signals_avail)

        # Determine dominant emotion
        sorted_vector = sorted(fused['emotion_vector'].items(), key=lambda item: item[1], reverse=True)
        dominant_emotion = sorted_vector[0][0] if sorted_vector else "explore"

        # ── Update Database ──
        now = datetime.now(timezone.utc)
        # 1. Update subcollection `users/{uid}/emotion_profile/current`
        db.collection('users').document(uid)\
            .collection('emotion_profile').document('current').set({
                'emotion_vector': fused['emotion_vector'],
                'valence': fused['valence'],
                'arousal': fused['arousal'],
                'dominance': fused['dominance'],
                'emotional_mode': emotional_mode,
                'confidence': confidence,
                'updated_at': now
            })

        # 2. Update denormalized current state on user document
        db.collection('users').document(uid).update({
            'current_emotion_vector': fused['emotion_vector'],
            'emotional_mode': emotional_mode,
            'author_dominant_emotion': dominant_emotion,
            'updated_at': now
        })

        print(f"📊 Emotional state inferred and saved for user {uid}: dominant={dominant_emotion}, mode={emotional_mode}.")

        return EmotionInferResponse(
            emotion_vector=fused['emotion_vector'],
            dominant_emotion=dominant_emotion,
            confidence=confidence,
            emotional_mode=emotional_mode
        )
    except Exception as e:
        print(f"❌ Error during emotion inference: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Emotion inference failed: {str(e)}",
        )
