"""
AURA Social – Emotion Pydantic Models
8D emotion vector based on Plutchik's wheel.
"""
from pydantic import BaseModel, Field
from typing import Dict, Optional, List


class EmotionVector(BaseModel):
    """8-dimensional emotion vector."""
    joy: float = Field(0.0, ge=0.0, le=1.0)
    trust: float = Field(0.0, ge=0.0, le=1.0)
    anticipation: float = Field(0.0, ge=0.0, le=1.0)
    surprise: float = Field(0.0, ge=0.0, le=1.0)
    sadness: float = Field(0.0, ge=0.0, le=1.0)
    fear: float = Field(0.0, ge=0.0, le=1.0)
    anger: float = Field(0.0, ge=0.0, le=1.0)
    disgust: float = Field(0.0, ge=0.0, le=1.0)


class BehavioralEvent(BaseModel):
    """Single behavioral event from Flutter tracker."""
    event_type: str  # "scroll", "view", "react", "dwell"
    target_id: Optional[str] = None
    duration_ms: Optional[int] = None
    metadata: Optional[Dict] = None
    timestamp: float


class EmotionInferRequest(BaseModel):
    """Request for emotion inference."""
    text: Optional[str] = None
    behavioral_events: Optional[List[BehavioralEvent]] = None
    context: Optional[Dict] = None  # time, location, etc.


class EmotionInferResponse(BaseModel):
    """Response from emotion inference."""
    emotion_vector: Dict[str, float]
    dominant_emotion: str
    confidence: float = Field(ge=0.0, le=1.0)
    emotional_mode: Optional[str] = None  # "optimistic", "reflective", etc.
