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


class ModerationCheckRequest(BaseModel):
    """Request schema for content moderation checks."""
    text: str


class ModerationCheckResponse(BaseModel):
    """Response schema from moderation checks."""
    is_toxic: bool
    toxicity_score: float
    flagged_categories: List[str]
    cleaned_text: str


class ContentAssistRequest(BaseModel):
    """Request schema for AI writing assistant."""
    text: Optional[str] = ""
    mood_theme: Optional[str] = "warm"
    media_url: Optional[str] = None


class ContentAssistResponse(BaseModel):
    """Response schema from AI writing assistant."""
    suggestions: List[str]
    predicted_emotion_vector: Dict[str, float]

