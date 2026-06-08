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
            # Override emotional mode if crisis_watch is active
            if user_profile.get('crisis_watch', False):
                user_profile['emotional_mode'] = 'gentle_uplift'
                print(f"🚨 User {uid} is in crisis_watch mode. Forcing emotional_mode to gentle_uplift.")
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

        # Normalize required fields and check defaults
        if not isinstance(user_profile.get('content_preference_vector'), list) or len(user_profile.get('content_preference_vector')) != 384:
            user_profile['content_preference_vector'] = [0.0] * 384

        if not isinstance(user_profile.get('interests'), list):
            user_profile['interests'] = []

        if 'emotional_mode' not in user_profile:
            user_profile['emotional_mode'] = 'explore'

        if 'current_session_minutes' not in user_profile:
            user_profile['current_session_minutes'] = 5

        # Fetch actual following_ids from subcollection users/{uid}/following
        following_ids = []
        try:
            following_snap = db.collection('users').document(uid).collection('following').stream()
            following_ids = [doc.id for doc in following_snap]
        except Exception as fe:
            print(f"⚠️ Error fetching following IDs for user {uid}: {fe}")
        user_profile['following_ids'] = following_ids

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
            
            # Serialize post data for client
            post_data = {
                'post_id': post_id,
                'user_id': post.get('user_id', ''),
                'content': post.get('content', ''),
                'media_type': post.get('media_type', 'none'),
                'media_urls': post.get('media_urls', []),
                'ai_emotion_vector': post.get('ai_emotion_vector', {}),
                'reactions_count': post.get('reactions_count', 0),
                'comments_count': post.get('comments_count', 0),
                'author_name': post.get('author_name', 'User'),
                'author_username': post.get('author_username', ''),
                'author_avatar_url': post.get('author_avatar_url'),
                'author_dominant_emotion': post.get('author_dominant_emotion', 'explore'),
                'is_breaker': post.get('is_breaker', False),
                'breaker_type': post.get('breaker_type'),
                'created_at': str(post.get('created_at', '')),
            }
            items.append(FeedItem(post_id=post_id, score=score, reason=reason, post_data=post_data))

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
