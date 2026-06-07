"""
AURA Social – AI Content Moderation Engine
Detects toxic speech, harassment, self-harm, and inappropriate emotional content.
"""
import re
from typing import Dict, Any, List
from app.ml.model_loader import model_loader
from app.services.config_service import config_service

class ContentModerator:
    """
    Combines NLP deep sentiment score with dynamic keyword heuristics from Firestore.
    Flags toxic content and filters profanities dynamically.
    """

    def mask_profanity(self, text: str, profanities: List[str]) -> str:
        """Replace profanity words with stars using a dynamic regex pattern."""
        if not profanities:
            return text
        pattern = re.compile(
            r'\b(' + '|'.join(map(re.escape, profanities)) + r')\b',
            re.IGNORECASE
        )
        return pattern.sub(lambda m: "*" * len(m.group(0)), text)

    def analyze_text(self, text: str) -> Dict[str, Any]:
        """
        Analyze text for toxicity, self-harm, and hate speech.
        """
        if not text.strip():
            return {
                "is_toxic": False,
                "toxicity_score": 0.0,
                "flagged_categories": [],
                "cleaned_text": ""
            }

        # Retrieve dynamic configs
        config = config_service.get_moderation_config()
        profanities = config.get("profanities", [])
        self_harm = config.get("self_harm", [])
        hate_speech = config.get("hate_speech", [])

        text_lower = text.lower()
        flagged_categories = []
        heuristic_score = 0.0

        # 1. Check Profanity / Toxicity
        profanities_found = [w for w in profanities if re.search(r'\b' + re.escape(w) + r'\b', text_lower)]
        if profanities_found:
            flagged_categories.append("profanity")
            heuristic_score += 0.4 + (0.1 * min(len(profanities_found), 5))

        # 2. Check Self-Harm
        self_harm_found = [w for w in self_harm if w in text_lower]
        if self_harm_found:
            flagged_categories.append("self_harm")
            heuristic_score += 0.8  # High severity

        # 3. Check Hate Speech
        hate_speech_found = [w for w in hate_speech if w in text_lower]
        if hate_speech_found:
            flagged_categories.append("hate_speech")
            heuristic_score += 0.5 + (0.1 * min(len(hate_speech_found), 4))

        # 4. Integrate Sentiment Negativity
        sentiment_negativity = 0.0
        try:
            emotion_pipeline = model_loader.get_emotion_model()
            if emotion_pipeline:
                res = emotion_pipeline(text[:512])[0]
                label = res["label"]  # Format: "1 star" to "5 stars"
                score = res["score"]

                if "1 star" in label:
                    sentiment_negativity = score * 0.5
                elif "2 stars" in label:
                    sentiment_negativity = score * 0.3
                elif "3 stars" in label:
                    sentiment_negativity = score * 0.1
        except Exception as e:
            print(f"⚠️ Moderation: Failed sentiment analysis: {e}")

        # Combine heuristic and ML sentiment negativity
        toxicity_score = min(1.0, heuristic_score + sentiment_negativity)

        # Flag as toxic if threshold is reached or critical categories are flagged
        is_toxic = (toxicity_score >= 0.45) or ("self_harm" in flagged_categories) or ("hate_speech" in flagged_categories)

        if is_toxic and "profanity" not in flagged_categories and toxicity_score >= 0.45 and not flagged_categories:
            flagged_categories.append("general_toxicity")

        cleaned_text = self.mask_profanity(text, profanities)

        return {
            "is_toxic": is_toxic,
            "toxicity_score": round(float(toxicity_score), 3),
            "flagged_categories": flagged_categories,
            "cleaned_text": cleaned_text
        }

# Singleton instance
content_moderator = ContentModerator()
