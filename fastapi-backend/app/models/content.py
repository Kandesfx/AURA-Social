"""
AURA Social – Content Analysis Pydantic Models
"""
from pydantic import BaseModel
from typing import Dict, List, Optional


class ContentAnalysisRequest(BaseModel):
    """Request from Cloud Function on_new_post."""
    post_id: str
    text: str
    user_id: str
    media_urls: Optional[List[str]] = None


class ContentAnalysisResponse(BaseModel):
    """Response with emotion analysis of post content."""
    emotion_vector: Dict[str, float]
    sentiment_score: float  # -1.0 to 1.0
    embedding: List[float]  # 384-dim text embedding
    is_safe: bool  # Content safety flag
    language: Optional[str] = None
