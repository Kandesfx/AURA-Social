"""
AURA Social – Content Analysis Router
Endpoints for analyzing post content (called by Cloud Functions).
"""
from fastapi import APIRouter, Depends
from app.auth import verify_internal_key
from app.models.content import ContentAnalysisRequest, ContentAnalysisResponse

router = APIRouter()


@router.post("/analyze", response_model=ContentAnalysisResponse)
async def analyze_content(
    request: ContentAnalysisRequest,
    valid: bool = Depends(verify_internal_key),
):
    """
    Phân tích nội dung bài post (gọi từ Cloud Function on_new_post).
    
    TODO (Person 2): Implement content analysis
    - Sentiment analysis (NLP)
    - Emotion vector extraction (8D Plutchik)
    - Text embedding generation
    - Content safety check
    """
    # Mock response
    return ContentAnalysisResponse(
        emotion_vector={
            "joy": 0.30, "trust": 0.25, "anticipation": 0.15,
            "surprise": 0.10, "sadness": 0.08, "fear": 0.05,
            "anger": 0.04, "disgust": 0.03,
        },
        sentiment_score=0.75,
        embedding=[0.0] * 384,  # 384-dim embedding placeholder
        is_safe=True,
        language="vi",
    )
