"""
AURA Social – Content Analysis Router
Endpoints for analyzing post content (called by Cloud Functions).
"""
from fastapi import APIRouter, Depends, HTTPException, status
from app.auth import verify_internal_key
from app.models.content import ContentAnalysisRequest, ContentAnalysisResponse, ModerationCheckRequest, ModerationCheckResponse
from app.ml.model_loader import model_loader
from app.ml.emotion_engine import emotion_inference_engine, EMOTIONS
from app.ml.moderation_engine import content_moderator
from app.utils.firebase_client import get_firestore

router = APIRouter()


@router.post("/analyze", response_model=ContentAnalysisResponse)
async def analyze_content(
    request: ContentAnalysisRequest,
    valid: bool = Depends(verify_internal_key),
):
    """
    Analyzes new post content. Called automatically by Firebase Cloud Function trigger `on_new_post`.
    Updates Firestore post document with AI metadata.
    """
    if not request.text or len(request.text.strip()) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Post text is empty",
        )

    try:
        # 1. Generate 384-dimensional text embedding
        embedding = model_loader.get_sentence_embedding(request.text)

        # 2. Extract 8D Plutchik emotion vector
        text_analysis = emotion_inference_engine.analyze_texts([request.text])
        emotion_vector = text_analysis['vector'] # returns list of 8 floats
        emotion_dict = {EMOTIONS[i]: float(emotion_vector[i]) for i in range(8)}

        # 3. Calculate sentiment score (-1.0 to 1.0)
        # We can run the sentiment model to estimate stars
        sentiment_score = 0.0
        sentiment_pipeline = model_loader.get_emotion_model()
        if sentiment_pipeline:
            try:
                res = sentiment_pipeline(request.text[:512])[0]
                stars = int(res['label'].split()[0]) # '1 star' ... '5 stars'
                # Map 1..5 -> -1.0 .. 1.0
                sentiment_score = (stars - 3) / 2.0
            except Exception:
                # Fallback to math on Plutchik vector
                valence = (emotion_dict['joy'] + emotion_dict['trust'] + emotion_dict['anticipation']) - \
                          (emotion_dict['sadness'] + emotion_dict['fear'] + emotion_dict['anger'] + emotion_dict['disgust'])
                sentiment_score = float(max(-1.0, min(1.0, valence)))

        # 4. Content safety check (using the advanced content moderation engine)
        mod_res = content_moderator.analyze_text(request.text)
        is_toxic = mod_res["is_toxic"]
        crisis_detected = "self_harm" in mod_res["flagged_categories"]
        is_safe = not is_toxic

        # Determine dominant emotion
        sorted_emotions = sorted(emotion_dict.items(), key=lambda item: item[1], reverse=True)
        dominant_emotion = sorted_emotions[0][0] if sorted_emotions else "explore"

        # 5. Update the post document in Firestore
        db = get_firestore()
        post_ref = db.collection('posts').document(request.post_id)
        
        # Calculate valence
        valence_score = (emotion_dict['joy'] + emotion_dict['trust'] + emotion_dict['anticipation']) - \
                        (emotion_dict['sadness'] + emotion_dict['fear'] + emotion_dict['anger'] + emotion_dict['disgust'])

        update_payload = {
            'ai_emotion_vector': emotion_dict,
            'ai_valence': round(float(valence_score), 4),
            'ai_sentiment': "positive" if sentiment_score > 0.1 else "negative" if sentiment_score < -0.1 else "neutral",
            'ai_sentiment_score': round(float(sentiment_score), 4),
            'content_embedding': embedding,
            'is_toxic': is_toxic,
            'crisis_detected': crisis_detected,
            'cleaned_content': mod_res["cleaned_text"],
            'quality_score': 0.7 if is_safe else 0.2, # default safety quality score
            'author_dominant_emotion': dominant_emotion
        }

        # Update Firestore
        post_ref.update(update_payload)
        print(f"📊 Post {request.post_id} analyzed and updated successfully in Firestore.")

        return ContentAnalysisResponse(
            emotion_vector=emotion_dict,
            sentiment_score=round(float(sentiment_score), 4),
            embedding=embedding,
            is_safe=is_safe,
            language="vi"
        )
    except Exception as e:
        print(f"❌ Error during post content analysis: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Content analysis failed: {str(e)}",
        )


@router.post("/check-moderation", response_model=ModerationCheckResponse)
async def check_moderation(request: ModerationCheckRequest):
    """
    Real-time text moderation endpoint for posts or comments before submission.
    """
    try:
        result = content_moderator.analyze_text(request.text)
        return ModerationCheckResponse(**result)
    except Exception as e:
        print(f"❌ Error during manual content moderation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Content moderation failed: {str(e)}",
        )
