"""
AURA Social – AI Prompts Pydantic Models
"""
from pydantic import BaseModel
from typing import List, Optional

class IcebreakersRequest(BaseModel):
    user_mood: str
    partner_mood: str
    connection_type: Optional[str] = None

class IcebreakersResponse(BaseModel):
    icebreakers: List[str]

class ReplySuggestionsRequest(BaseModel):
    last_message: str
    user_mood: str
    partner_mood: str

class ReplySuggestionsResponse(BaseModel):
    suggestions: List[str]
