"""
AURA Social – Soul Connect Compatibility Engine
Computes matching scores between users based on emotional patterns, tastes, and interests.
"""
from typing import Dict, Any, List
import numpy as np
from app.ml.emotion_engine import EMOTIONS


class SoulConnectEngine:
    """
    Computes compatibility matching scores for the Soul Connect matching feature.
    """

    def __init__(self):
        pass

    def calculate_soul_score(self, user_a: Dict[str, Any], user_b: Dict[str, Any]) -> Dict[str, Any]:
        """
        Calculates a compatibility score (0.0 to 1.0) between user_a and user_b.
        """
        # 1. Weekly Emotion Pattern Similarity (30%)
        pattern_sim = self._pattern_similarity(
            user_a.get('weekly_emotion_pattern', []),
            user_b.get('weekly_emotion_pattern', [])
        )

        # 2. Content Preference Taste Similarity (25%)
        taste_sim = self._cosine_similarity(
            user_a.get('content_preference_vector', []),
            user_b.get('content_preference_vector', [])
        )

        # 3. Complementary Emotional Dynamics (20%)
        complementary = self._emotional_complementarity(
            user_a.get('current_emotion_vector', {}),
            user_b.get('current_emotion_vector', {})
        )

        # 4. Interest Overlap Rate (15%)
        raw_int_a = user_a.get('interests')
        interests_a = set(raw_int_a) if isinstance(raw_int_a, (list, tuple, set)) else set()
        raw_int_b = user_b.get('interests')
        interests_b = set(raw_int_b) if isinstance(raw_int_b, (list, tuple, set)) else set()
        
        if interests_a and interests_b:
            interest_sim = len(interests_a & interests_b) / len(interests_a | interests_b)
        else:
            interest_sim = 0.3  # Baseline overlap

        # 5. Activity Hours Alignment (10%)
        activity_sim = self._activity_alignment(
            user_a.get('peak_activity_hours', [12]),
            user_b.get('peak_activity_hours', [12])
        )

        # Fused Soul Score
        soul_score = (
            pattern_sim * 0.30 +
            taste_sim * 0.25 +
            complementary * 0.20 +
            interest_sim * 0.15 +
            activity_sim * 0.10
        )

        # Determine the strongest matching factor
        factors = {
            'emotional_pattern': pattern_sim,
            'content_taste': taste_sim,
            'complementary': complementary,
            'interests': interest_sim,
            'activity': activity_sim
        }
        strongest_factor = max(factors, key=factors.get)
        
        reason = self._get_connection_reason(strongest_factor, user_b.get('display_name', 'Người bạn mới'))

        return {
            'soul_score': round(soul_score, 3),
            'breakdown': {k: round(v, 3) for k, v in factors.items()},
            'reason': reason,
            'connection_type': self._get_connection_type(soul_score, complementary)
        }

    def _pattern_similarity(self, pattern_a: List[List[float]], pattern_b: List[List[float]]) -> float:
        """Compare weekly emotion patterns (7 days × 8 emotions)."""
        if not pattern_a or not pattern_b:
            return 0.5
        
        try:
            a = np.array(pattern_a).flatten()
            b = np.array(pattern_b).flatten()
            
            if len(a) != len(b) or len(a) == 0:
                return 0.5

            norm_a = np.linalg.norm(a)
            norm_b = np.linalg.norm(b)

            if norm_a == 0 or norm_b == 0:
                return 0.5

            cos_sim = float(np.dot(a, b) / (norm_a * norm_b))
            return (cos_sim + 1) / 2 # scale to [0, 1]
        except Exception:
            return 0.5

    def _cosine_similarity(self, vec_a: List[float], vec_b: List[float]) -> float:
        """Compare content taste embedding vectors."""
        if not vec_a or not vec_b:
            return 0.5

        try:
            a = np.array(vec_a)
            b = np.array(vec_b)

            if len(a) != len(b) or len(a) == 0:
                return 0.5

            norm_a = np.linalg.norm(a)
            norm_b = np.linalg.norm(b)

            if norm_a == 0 or norm_b == 0:
                return 0.5

            cos_sim = float(np.dot(a, b) / (norm_a * norm_b))
            return (cos_sim + 1) / 2 # scale to [0, 1]
        except Exception:
            return 0.5

    def _emotional_complementarity(self, emo_a: Dict[str, float], emo_b: Dict[str, float]) -> float:
        """
        Check if current emotions complement each other (e.g. stressed ↔ chill).
        """
        if not emo_a or not emo_b:
            return 0.5

        # Get values
        stressed_a = emo_a.get('stressed', emo_a.get('anger', 0.0) + emo_a.get('fear', 0.0))
        chill_b = emo_b.get('chill', emo_b.get('trust', 0.0) + emo_b.get('joy', 0.0))

        stressed_b = emo_b.get('stressed', emo_b.get('anger', 0.0) + emo_b.get('fear', 0.0))
        chill_a = emo_a.get('chill', emo_a.get('trust', 0.0) + emo_a.get('joy', 0.0))

        # Complementarity 1: stressed meets chill
        comp_stressed_chill = (stressed_a * chill_b + stressed_b * chill_a)

        # Complementarity 2: sad meets joy
        sad_a = emo_a.get('sadness', 0.0)
        joy_b = emo_b.get('joy', 0.0)
        sad_b = emo_b.get('sadness', 0.0)
        joy_a = emo_a.get('joy', 0.0)
        comp_sad_joy = (sad_a * joy_b + sad_b * joy_a)

        # Base similarity
        u_a = np.array([emo_a.get(e, 0.125) for e in EMOTIONS])
        u_b = np.array([emo_b.get(e, 0.125) for e in EMOTIONS])
        
        sim = 0.5
        norm_a = np.linalg.norm(u_a)
        norm_b = np.linalg.norm(u_b)
        if norm_a > 0 and norm_b > 0:
            sim = float(np.dot(u_a, u_b) / (norm_a * norm_b))
            sim = (sim + 1) / 2

        # Final score fuses standard similarity and complementary pairs
        comp_score = sim * 0.6 + comp_stressed_chill * 0.2 + comp_sad_joy * 0.2
        return float(min(1.0, max(0.0, comp_score)))

    def _activity_alignment(self, hours_a: List[int], hours_b: List[int]) -> float:
        """Compare peak activity hours."""
        if not isinstance(hours_a, (list, tuple, set)) or not isinstance(hours_b, (list, tuple, set)):
            return 0.5
        if not hours_a or not hours_b:
            return 0.5

        # Check overlap
        overlap = set(hours_a) & set(hours_b)
        if overlap:
            return 1.0
        
        # Calculate minimum distance between any hour
        min_dist = 24
        for ha in hours_a:
            for hb in hours_b:
                dist = min(abs(ha - hb), 24 - abs(ha - hb))
                if dist < min_dist:
                    min_dist = dist
        
        # Decay score based on hours distance
        return float(max(0.0, 1.0 - (min_dist / 12.0)))

    def _get_connection_reason(self, factor: str, name: str) -> str:
        reasons = {
            'emotional_pattern': f"Nhịp điệu cảm xúc hàng tuần của bạn và {name} rất tương đồng.",
            'content_taste': f"Bạn và {name} đều yêu thích những nội dung có cùng chủ đề.",
            'complementary': f"Cảm xúc hiện tại của hai bạn bù trừ, mang lại sự bình yên cho nhau.",
            'interests': f"Hai bạn cùng chia sẻ những sở thích đặc biệt.",
            'activity': f"Khung giờ hoạt động tích cực của bạn và {name} rất trùng khớp."
        }
        return reasons.get(factor, f"Hai bạn có mức độ tương thích tâm hồn cao.")

    def _get_connection_type(self, score: float, comp: float) -> str:
        if score > 0.85:
            return "Soulmate"
        if comp > 0.75:
            return "Emotional Anchor"
        if score > 0.7:
            return "Vibe Partner"
        return "New Connection"


# Singleton instance
soul_engine = SoulConnectEngine()
