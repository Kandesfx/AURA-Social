"""
AURA Social – Feed Router
Endpoints for AI-curated feed generation.
"""
from fastapi import APIRouter, Depends
from app.auth import get_current_user
from app.models.feed import FeedRequest, FeedResponse, FeedItem

router = APIRouter()


@router.post("/generate", response_model=FeedResponse)
async def generate_feed(
    request: FeedRequest,
    user: dict = Depends(get_current_user),
):
    """
    Generate AI-curated feed cho user.

    TODO (Person 2): Implement 3-stage recommendation pipeline
    - Stage 1: Candidate Generation (Firestore query)
    - Stage 2: Scoring & Ranking (emotion matching)
    - Stage 3: Emotional Balancing (diversity injection)
    """
    uid = user["uid"]

    # Mock response
    return FeedResponse(
        items=[],
        next_cursor=None,
        emotional_reason=f"Feed cho user {uid} – chờ implement",
    )
