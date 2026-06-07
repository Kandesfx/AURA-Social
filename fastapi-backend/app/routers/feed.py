"""
AURA Social – Feed Router
Endpoints for AI-curated feed generation.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from app.auth import get_current_user
from app.models.feed import FeedRequest, FeedResponse, FeedItem
from app.ml.rec_engine import rec_pipeline
from app.utils.firebase_client import get_firestore

router = APIRouter()


@router.post("/generate", response_model=FeedResponse)
async def generate_feed(
    request: FeedRequest,
    user: dict = Depends(get_current_user),
):
    """
    Generates an AI-curated feed for the user.
    Uses a 3-stage recommendation pipeline:
    1. Candidate retrieval
    2. Heuristic and semantic scoring based on interests and emotion vector matching
    3. Wellbeing filtration (limits negative streaks, injects rest cards)
    """
    uid = user["uid"]
    db = get_firestore()

    try:
        # 1. Fetch user profile from Firestore
        user_ref = db.collection('users').document(uid).get()
        if user_ref.exists:
            user_profile = user_ref.to_dict()
            user_profile['uid'] = uid
        else:
            # Fallback default profile if not found
            user_profile = {
                'uid': uid,
                'display_name': 'Người dùng AURA',
                'interests': ['coding', 'music'],
                'content_preference_vector': [0.0] * 384,
                'following_ids': [],
                'emotional_mode': 'explore',
                'current_session_minutes': 5
            }

        # 2. Determine user's current emotion vector
        user_emotion = request.emotion_context
        if not user_emotion:
            # Try to load from user profile or subcollection
            user_emotion = user_profile.get('current_emotion_vector')
            if not user_emotion:
                try:
                    profile_doc = db.collection('users').document(uid).collection('emotion_profile').document('current').get()
                    if profile_doc.exists:
                        user_emotion = profile_doc.to_dict().get('emotion_vector')
                except Exception:
                    pass
            
            # Default fallback to neutral
            if not user_emotion:
                user_emotion = {
                    'joy': 0.125, 'trust': 0.125, 'anticipation': 0.125, 'surprise': 0.125,
                    'sadness': 0.125, 'fear': 0.125, 'anger': 0.125, 'disgust': 0.125
                }

        # 3. Candidate Generation
        candidates = await rec_pipeline.generate_candidates(uid, user_profile)

        # 4. Scoring & Ranking
        scored_posts = rec_pipeline.score_candidates(user_profile, candidates, user_emotion)

        # 5. Wellbeing Guard filtration
        final_posts = rec_pipeline.apply_wellbeing_guard(scored_posts, user_profile)

        # 6. Pagination
        start_idx = 0
        cursor = request.cursor
        if cursor:
            try:
                start_idx = int(cursor)
            except ValueError:
                start_idx = 0

        limit = request.limit
        end_idx = start_idx + limit
        paginated_posts = final_posts[start_idx:end_idx]

        next_cursor = str(end_idx) if end_idx < len(final_posts) else None

        # 7. Map to FeedItem list
        items = []
        for post in paginated_posts:
            post_id = post.get('post_id') or post.get('id')
            score = post.get('relevance_score', 0.5)
            reason = post.get('relevance_reason', '')
            items.append(FeedItem(post_id=post_id, score=score, reason=reason))

        emotional_mode = user_profile.get('emotional_mode', 'explore')
        dominant_emotion = sorted(user_emotion.items(), key=lambda x: x[1], reverse=True)[0][0]

        reason_summary = f"Bảng tin được đề xuất dựa trên chế độ cảm xúc '{emotional_mode}' (Cảm xúc chính: {dominant_emotion})."

        print(f"📊 Generated feed for user {uid}: returned {len(items)} items, next_cursor={next_cursor}, mode={emotional_mode}.")

        return FeedResponse(
            items=items,
            next_cursor=next_cursor,
            emotional_reason=reason_summary
        )

    except Exception as e:
        print(f"❌ Error generating feed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Feed generation failed: {str(e)}",
        )
