"""
AURA Social – AI Wellbeing Pydantic Models
"""
from pydantic import BaseModel
from typing import Dict, List, Any, Optional

class WeeklyReportRequest(BaseModel):
    user_id: str

class WeeklyReportResponse(BaseModel):
    user_id: str
    start_date: str
    end_date: str
    mood_distribution: Dict[str, float]
    stability_index: float
    stability_label: str
    stability_description: str
    dominant_emotion: str
    trends: Dict[str, Any]
    personalized_letter: str
    self_care_plan: Dict[str, Any]


class WellbeingCheckRequest(BaseModel):
    session_duration_minutes: int
    current_emotion_vector: Dict[str, float]


class WellbeingCheckResponse(BaseModel):
    should_break: bool
    break_type: str
    title: str
    subtitle: str
    wellbeing_score: int
    suggestion: Optional[str] = None


class WellbeingScoreResponse(BaseModel):
    score: int


class DailyInsightResponse(BaseModel):
    summary: str
    positive_pattern: str
    suggestion: str
    wellbeing_score: int
