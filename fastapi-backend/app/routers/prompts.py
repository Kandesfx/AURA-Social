"""
AURA Social – AI Prompts Router
Endpoints for generating empathetic chat suggestions.
"""
from fastapi import APIRouter, HTTPException, status
from app.models.prompts import (
    IcebreakersRequest, IcebreakersResponse,
    ReplySuggestionsRequest, ReplySuggestionsResponse,
    PersonalizeNotificationRequest, PersonalizeNotificationResponse
)
from app.ml.prompt_engine import prompt_engine

router = APIRouter()

@router.post("/icebreakers", response_model=IcebreakersResponse)
async def get_icebreakers(request: IcebreakersRequest):
    """
    Get custom empathetic icebreaker suggestions to start a conversation.
    """
    try:
        res = prompt_engine.generate_icebreakers(
            user_mood=request.user_mood,
            partner_mood=request.partner_mood,
            connection_type=request.connection_type
        )
        return IcebreakersResponse(icebreakers=res)
    except Exception as e:
        print(f"❌ Error generating icebreakers: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate icebreakers: {str(e)}"
        )

@router.post("/suggest-replies", response_model=ReplySuggestionsResponse)
async def suggest_replies(request: ReplySuggestionsRequest):
    """
    Suggest quick empathetic replies based on the latest chat message.
    """
    try:
        res = prompt_engine.suggest_replies(
            last_message=request.last_message,
            partner_mood=request.partner_mood,
            user_mood=request.user_mood
        )
        return ReplySuggestionsResponse(suggestions=res)
    except Exception as e:
        print(f"❌ Error suggesting replies: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate reply suggestions: {str(e)}"
        )

@router.post("/personalize-notification", response_model=PersonalizeNotificationResponse)
async def personalize_notification(request: PersonalizeNotificationRequest):
    """
    Generate personalized notification text based on recipient mood.
    """
    try:
        res = prompt_engine.personalize_notification(
            sender_name=request.sender_name,
            message_body=request.message_body,
            recipient_mood=request.recipient_mood
        )
        return PersonalizeNotificationResponse(**res)
    except Exception as e:
        print(f"❌ Error personalizing notification: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to personalize notification: {str(e)}"
        )

