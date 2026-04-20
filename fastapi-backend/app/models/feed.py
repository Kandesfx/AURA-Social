"""
AURA Social – Feed Pydantic Models
"""
from pydantic import BaseModel, Field
from typing import Dict, Optional, List


class FeedRequest(BaseModel):
    """Request for AI-curated feed."""
    cursor: Optional[str] = None
    limit: int = Field(20, ge=1, le=50)
    emotion_context: Optional[Dict[str, float]] = None  # Current user emotion


class FeedItem(BaseModel):
    """Single feed item."""
    post_id: str
    score: float  # Relevance score
    reason: Optional[str] = None  # Why this post was recommended


class FeedResponse(BaseModel):
    """Response from feed generation."""
    items: List[FeedItem]
    next_cursor: Optional[str] = None
    emotional_reason: Optional[str] = None
