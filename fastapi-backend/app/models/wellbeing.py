"""
AURA Social – AI Wellbeing Pydantic Models
"""
from pydantic import BaseModel
from typing import Dict, List, Any

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
