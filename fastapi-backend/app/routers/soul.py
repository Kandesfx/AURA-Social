"""
AURA Social – Soul Connect Router
Endpoints for calculating user compatibility and getting matched soul suggestions.
"""
from datetime import datetime, timezone
import random
from typing import Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from app.auth import get_current_user
from app.ml.soul_engine import soul_engine
from app.utils.firebase_client import get_firestore

router = APIRouter()

# ── Pydantic Models ──

class CompatibilityBreakdown(BaseModel):
    emotionalPattern: float
    contentTaste: float
    complementary: float
    interests: float
    activity: float

class SoulUser(BaseModel):
    uid: str
    displayName: str
    bio: Optional[str] = ""
    auraDominantEmotion: str
    emotionVector: Dict[str, float]

class SoulSuggestion(BaseModel):
    connectionId: str
    soulScore: float
    connectionType: str
    breakdown: CompatibilityBreakdown
    otherUser: SoulUser

class SoulSuggestionsRequest(BaseModel):
    limit: int = 10

class SoulSuggestionsResponse(BaseModel):
    suggestions: List[SoulSuggestion]


@router.post("/suggestions", response_model=SoulSuggestionsResponse)
async def get_soul_suggestions(
    request: SoulSuggestionsRequest,
    user: dict = Depends(get_current_user),
):
    """
    Computes and returns a list of highly-compatible soul suggestions.
    Compares the current user's profile and emotion history with other users in Firestore.
    """
    uid = user["uid"]
    db = get_firestore()

    try:
        # 1. Fetch current user's data
        user_ref = db.collection('users').document(uid).get()
        if not user_ref.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found",
            )
        user_profile = user_ref.to_dict()
        user_profile['uid'] = uid

        # Ensure current user has fallback fields for calculation
        if 'content_preference_vector' not in user_profile:
            user_profile['content_preference_vector'] = [0.0] * 384
        if 'current_emotion_vector' not in user_profile:
            # check subcollection
            try:
                profile_doc = db.collection('users').document(uid).collection('emotion_profile').document('current').get()
                if profile_doc.exists:
                    user_profile['current_emotion_vector'] = profile_doc.to_dict().get('emotion_vector')
            except Exception:
                pass
        
        # 2. Query other users from Firestore
        other_users = []
        try:
            users_query = db.collection('users').limit(50).stream()
            for doc in users_query:
                if doc.id == uid:
                    continue  # Skip self
                
                u_data = doc.to_dict()
                u_data['uid'] = doc.id
                other_users.append(u_data)
        except Exception as e:
            print(f"⚠️ Error querying other users: {e}")

        # 3. Filter out users that are already matched (optional / simple check for demo)
        # In production, query `soul_connections` to exclude existing matches

        # 4. Compute compatibility for each other user
        suggestions = []
        for other in other_users:
            # Provide defaults for clean scoring
            if 'content_preference_vector' not in other:
                other['content_preference_vector'] = [0.0] * 384
            if 'current_emotion_vector' not in other:
                other['current_emotion_vector'] = {
                    'joy': 0.125, 'trust': 0.125, 'anticipation': 0.125, 'surprise': 0.125,
                    'sadness': 0.125, 'fear': 0.125, 'anger': 0.125, 'disgust': 0.125
                }
            
            # Compute score
            res = soul_engine.calculate_soul_score(user_profile, other)
            
            # Filter matches with a score above a baseline (e.g. 0.55) to ensure quality matches
            if res['soul_score'] >= 0.55:
                # Map Plutchik vector keys to floats
                emo_vector = other['current_emotion_vector']
                dominant = other.get('author_dominant_emotion', 'explore')
                
                # Check for existing connection ID or generate one (order-independent)
                first_id, second_id = (uid, other['uid']) if uid < other['uid'] else (other['uid'], uid)
                connection_id = f"soul-conn-{first_id}-{second_id}"

                # Save to Firestore if not exists, so user can respond to it
                try:
                    conn_ref = db.collection('soul_connections').document(connection_id)
                    conn_doc = conn_ref.get()
                    if not conn_doc.exists:
                        conn_ref.set({
                            'user_a_id': uid,
                            'user_b_id': other['uid'],
                            'participants': [uid, other['uid']],
                            'soul_score': res['soul_score'],
                            'connection_type': res['connection_type'],
                            'compatibility_breakdown': {
                                'emotional_pattern': res['breakdown']['emotional_pattern'],
                                'content_taste': res['breakdown']['content_taste'],
                                'complementary': res['breakdown']['complementary'],
                                'interests': res['breakdown']['interests'],
                                'activity': res['breakdown']['activity']
                            },
                            'status': 'suggested',
                            'created_at': datetime.now(timezone.utc),
                            'updated_at': datetime.now(timezone.utc)
                        })
                except Exception as e:
                    print(f"⚠️ Failed to write soul connection {connection_id} to Firestore: {e}")

                suggestion = SoulSuggestion(
                    connectionId=connection_id,
                    soulScore=res['soul_score'],
                    connectionType=res['connection_type'],
                    breakdown=CompatibilityBreakdown(
                        emotionalPattern=res['breakdown']['emotional_pattern'],
                        contentTaste=res['breakdown']['content_taste'],
                        complementary=res['breakdown']['complementary'],
                        interests=res['breakdown']['interests'],
                        activity=res['breakdown']['activity']
                    ),
                    otherUser=SoulUser(
                        uid=other['uid'],
                        displayName=other.get('displayName', 'Người dùng AURA'),
                        bio=other.get('bio', ''),
                        auraDominantEmotion=dominant,
                        emotionVector=emo_vector
                    )
                )
                suggestions.append(suggestion)

        # 5. Fallback to mock suggestions if there are no other users in database
        if len(suggestions) < 2:
            print("ℹ️ Firestore has fewer users than expected. Injecting fallback mock suggestions.")
            suggestions.extend(_get_fallback_suggestions(uid))

        # Sort suggestions by compatibility score descending
        suggestions.sort(key=lambda x: x.soulScore, reverse=True)
        suggestions = suggestions[:request.limit]

        return SoulSuggestionsResponse(suggestions=suggestions)

    except Exception as e:
        print(f"❌ Error in Soul Connect matching: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch soul suggestions: {str(e)}",
        )


def _get_fallback_suggestions(current_uid: str) -> List[SoulSuggestion]:
    """Fallback suggestions mapped to client models."""
    mock_users = [
        {
            'uid': 'user_fall_1',
            'displayName': 'Linh Nguyễn',
            'bio': 'Love reading books and chill music ☕✨',
            'auraDominantEmotion': 'joy',
            'emotionVector': {
                'joy': 0.45, 'trust': 0.25, 'anticipation': 0.15, 'surprise': 0.05,
                'sadness': 0.04, 'fear': 0.02, 'anger': 0.02, 'disgust': 0.02
            }
        },
        {
            'uid': 'user_fall_2',
            'displayName': 'Quang Huy',
            'bio': 'Tech enthusiast, runner 🏃‍♂️🚀',
            'auraDominantEmotion': 'anticipation',
            'emotionVector': {
                'anticipation': 0.40, 'joy': 0.30, 'trust': 0.15, 'surprise': 0.05,
                'sadness': 0.05, 'fear': 0.02, 'anger': 0.02, 'disgust': 0.01
            }
        },
        {
            'uid': 'user_fall_3',
            'displayName': 'Phan Đăng',
            'bio': 'Quiet mind, peaceful thoughts 🧘‍♂️📖',
            'auraDominantEmotion': 'trust',
            'emotionVector': {
                'trust': 0.50, 'joy': 0.20, 'anticipation': 0.10, 'surprise': 0.05,
                'sadness': 0.10, 'fear': 0.02, 'anger': 0.01, 'disgust': 0.02
            }
        }
    ]

    suggestions = []
    for i, u in enumerate(mock_users):
        score = 0.85 - i * 0.06
        suggestions.append(
            SoulSuggestion(
                connectionId=f"soul-conn-fall-{current_uid[:4]}-{u['uid'][:4]}",
                soulScore=score,
                connectionType="Vibe Partner" if score < 0.8 else "Soulmate",
                breakdown=CompatibilityBreakdown(
                    emotionalPattern=0.88 - i * 0.05,
                    contentTaste=0.85 - i * 0.04,
                    complementary=0.90 - i * 0.06,
                    interests=0.75 - i * 0.02,
                    activity=0.80 - i * 0.03
                ),
                otherUser=SoulUser(
                    uid=u['uid'],
                    displayName=u['displayName'],
                    bio=u['bio'],
                    auraDominantEmotion=u['auraDominantEmotion'],
                    emotionVector=u['emotionVector']
                )
            )
        )
    return suggestions
