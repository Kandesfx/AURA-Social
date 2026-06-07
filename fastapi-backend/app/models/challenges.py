"""
AURA Social – AI Challenges Pydantic Models
"""
from pydantic import BaseModel
from typing import List, Optional

class ChallengeItem(BaseModel):
    id: str
    title: str
    description: str
    duration_days: int
    category: str
    status: str  # "active", "completed", "expired"
    progress: int
    max_progress: int
    created_at: str
    completed_at: Optional[str] = None

class ActiveChallengesResponse(BaseModel):
    challenges: List[ChallengeItem]

class CompleteChallengeRequest(BaseModel):
    challenge_id: str
    progress_increment: int = 1

class CompleteChallengeResponse(BaseModel):
    success: bool
    message: str
    challenge: Optional[ChallengeItem] = None
