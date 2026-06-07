"""
AURA Social – Deep Recommendation Pipeline
Generates candidate posts, scores them using emotional intelligence and user taste,
and applies the Wellbeing Guard to balance user emotional health.
"""
import random
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional
import numpy as np
from app.utils.firebase_client import get_firestore
from app.ml.emotion_engine import EMOTIONS

class DeepRecommendationPipeline:
    """
    3-stage recommendation engine:
    1. Candidate Generation
    2. Scoring & Ranking (with Emotional Resonance)
    3. Emotional Balancing (Wellbeing Guard)
    """

    def __init__(self):
        pass

    # ── Stage 1: Candidate Generation ──
    async def generate_candidates(self, user_id: str, user_profile: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Generate candidates from Firestore with a fallback to mock candidates.
        """
        candidates = []
        db = get_firestore()

        try:
            # Query Firestore for active posts
            posts_ref = db.collection('posts')\
                .where('status', '==', 'active')\
                .order_by('created_at', direction='DESCENDING')\
                .limit(100)
            
            docs = posts_ref.stream()
            for doc in docs:
                post_data = doc.to_dict()
                post_data['post_id'] = doc.id
                candidates.append(post_data)
        except Exception as e:
            print(f"⚠️ Error fetching posts from Firestore: {e}")

        # Fallback to high-quality mock posts if Firestore is empty/unavailable
        if len(candidates) < 1:
            print("ℹ️ Firestore is completely empty. Injecting high-quality mock candidates.")
            candidates.extend(self._get_mock_posts())

        # Deduplicate candidates by post_id
        seen_ids = set()
        unique_candidates = []
        for post in candidates:
            post_id = post.get('post_id') or post.get('id')
            if post_id and post_id not in seen_ids:
                seen_ids.add(post_id)
                post['post_id'] = post_id  # Ensure uniform key
                unique_candidates.append(post)

        return unique_candidates

    # ── Stage 2: Scoring & Ranking ──
    def score_candidates(
        self,
        user_profile: Dict[str, Any],
        candidates: List[Dict[str, Any]],
        user_emotion: Dict[str, float]
    ) -> List[Dict[str, Any]]:
        """
        Scores and ranks candidates.
        Score = (Interest similarity * 0.35) + (Emotional resonance * 0.25) + (Social * 0.15) + (Quality * 0.15) + (Freshness * 0.10)
        """
        ranked_posts = []
        now = datetime.now(timezone.utc)

        # Extract user profile traits
        user_preference = np.array(user_profile.get('content_preference_vector', [0.0] * 384))
        user_following = user_profile.get('following_ids', [])
        user_mode = user_profile.get('emotional_mode', 'explore')

        # Calculate base preference norms
        pref_norm = np.linalg.norm(user_preference)

        for post in candidates:
            post_id = post.get('post_id') or post.get('id') or f"post_{random.randint(1000, 9999)}"

            # 1. Content Taste Similarity (35%)
            post_embedding = np.array(post.get('content_embedding', [0.0] * 384))
            embed_norm = np.linalg.norm(post_embedding)

            if pref_norm > 0 and embed_norm > 0:
                taste_score = float(np.dot(user_preference, post_embedding) / (pref_norm * embed_norm + 1e-9))
                taste_score = (taste_score + 1) / 2 # Normalize [-1, 1] to [0, 1]
            else:
                taste_score = 0.5

            # 2. Emotional Resonance (25%)
            post_emotion = post.get('ai_emotion_vector', {})
            resonance_score = self.calculate_emotional_resonance(
                user_emotion=user_emotion,
                post_emotion=post_emotion,
                mode=user_mode
            )

            # 3. Social Relevance (15%)
            post_user_id = post.get('user_id')
            is_following = post_user_id in user_following
            social_score = 0.8 if is_following else 0.2
            # Bonus if user_id is the user themselves (to see their own posts sometimes)
            if post_user_id == user_profile.get('uid'):
                social_score = 0.9

            # 4. Content Quality Score (15%)
            # Can be based on comment count and view ratio
            comments_count = post.get('comments_count', 0)
            reactions_count = post.get('reactions_count', 0)
            total_engagement = comments_count + reactions_count
            quality_score = float(min(1.0, total_engagement / 100.0))
            quality_score = max(0.4, quality_score) # Baseline quality is 0.4

            # 5. Freshness & Decay (10%)
            created_at = post.get('created_at')
            if isinstance(created_at, datetime):
                # Ensure offset-aware
                if created_at.tzinfo is None:
                    created_at = created_at.replace(tzinfo=timezone.utc)
                age_hours = (now - created_at).total_seconds() / 3600.0
            else:
                age_hours = 12.0 # Default age

            freshness_score = float(max(0.0, 1.0 - (age_hours / 72.0))) # Decay over 3 days

            # Fused final score
            final_score = (
                taste_score * 0.35 +
                resonance_score * 0.25 +
                social_score * 0.15 +
                quality_score * 0.15 +
                freshness_score * 0.10
            )

            # Generate reasoning string for the response
            reason = self._generate_reason_text(user_mode, resonance_score, taste_score, is_following)

            ranked_post = {
                **post,
                'post_id': post_id,
                'relevance_score': round(final_score, 4),
                'relevance_reason': reason
            }
            ranked_posts.append(ranked_post)

        # Sort posts descending by relevance score
        ranked_posts.sort(key=lambda x: x['relevance_score'], reverse=True)
        return ranked_posts

    def calculate_emotional_resonance(
        self,
        user_emotion: Dict[str, float],
        post_emotion: Dict[str, float],
        mode: str
    ) -> float:
        """
        Calculate resonance based on Plutchik vectors and user emotional mode.
        """
        if not user_emotion or not post_emotion:
            return 0.5

        u_vec = np.array([user_emotion.get(e, 0.125) for e in EMOTIONS])
        p_vec = np.array([post_emotion.get(e, 0.125) for e in EMOTIONS])

        u_norm = np.linalg.norm(u_vec)
        p_norm = np.linalg.norm(p_vec)

        similarity = 0.5
        if u_norm > 0 and p_norm > 0:
            similarity = float(np.dot(u_vec, p_vec) / (u_norm * p_norm + 1e-9))

        u_valence = (u_vec[0] + u_vec[1] + u_vec[2]) - (u_vec[4] + u_vec[5] + u_vec[6] + u_vec[7])
        p_valence = (p_vec[0] + p_vec[1] + p_vec[2]) - (p_vec[4] + p_vec[5] + p_vec[6] + p_vec[7])

        if mode == "empathetic_mirror":
            # Direct similarity matching (empathy / validation)
            return (similarity + 1) / 2
        
        elif mode == "gentle_uplift":
            # Prefer posts that are slightly more positive than the user, avoiding excessive positive gap (jarring)
            valence_gap = p_valence - u_valence
            if 0.1 <= valence_gap <= 0.4:
                return 0.9  # Ideal uplift
            elif 0.0 < valence_gap < 0.1:
                return 0.7  # Good, but very similar
            elif valence_gap > 0.4:
                return 0.5  # Too positive, might feel toxic positive
            else:
                return 0.3  # Negative or worsening gap

        elif mode == "amplify":
            # Match high energy positive
            return (similarity + 1) / 2
        
        elif mode == "deep_chill":
            # Calm energy - prefer trust (index 1) and joy (index 0), penalize anger (index 6) and surprise (index 3)
            chill_weight = p_vec[1] * 0.6 + p_vec[0] * 0.4
            high_energy = p_vec[6] * 0.7 + p_vec[3] * 0.3
            return float(min(1.0, max(0.0, 0.5 + chill_weight - high_energy)))

        else: # explore
            # Diversified matching, slightly reward difference
            return 0.5 + (1.0 - similarity) * 0.3

    # ── Stage 3: Emotional Balancing (Wellbeing Guard) ──
    def apply_wellbeing_guard(self, ranked_posts: List[Dict[str, Any]], user_profile: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Ensures a balanced stream of content.
        - Caps negative posts streak at 3 to prevent doom-scrolling.
        - Injects break suggestions for long sessions.
        """
        balanced_feed = []
        negative_streak = 0
        max_negative_streak = 3

        session_minutes = user_profile.get('current_session_minutes', 0)
        
        for post in ranked_posts:
            # Estimate post valence
            p_vec = post.get('ai_emotion_vector', {})
            post_valence = 0.0
            if p_vec:
                post_valence = (p_vec.get('joy', 0) + p_vec.get('trust', 0) + p_vec.get('anticipation', 0)) - \
                               (p_vec.get('sadness', 0) + p_vec.get('fear', 0) + p_vec.get('anger', 0) + p_vec.get('disgust', 0))
            
            if post_valence < -0.3:
                negative_streak += 1
                if negative_streak > max_negative_streak:
                    # Inject positive breaker card
                    balanced_feed.append(self._create_positive_breaker_card())
                    negative_streak = 0
                    continue
            else:
                negative_streak = 0

            balanced_feed.append(post)

        # Session duration break suggestion
        if session_minutes >= 30:
            # Inject break card after the 4th item if not already present
            if len(balanced_feed) >= 4:
                balanced_feed.insert(4, self._create_session_break_card(session_minutes))
            else:
                balanced_feed.append(self._create_session_break_card(session_minutes))

        return balanced_feed

    def _generate_reason_text(self, mode: str, resonance: float, taste: float, is_following: bool) -> str:
        if is_following:
            return "Đăng bởi người bạn quan tâm"
        if mode == "gentle_uplift" and resonance > 0.7:
            return "Một chút năng lượng tích cực dành cho bạn"
        if mode == "empathetic_mirror" and resonance > 0.7:
            return "Bài viết đồng cảm với tâm trạng của bạn"
        if mode == "deep_chill" and resonance > 0.7:
            return "Vibe thư giãn thích hợp lúc này"
        if taste > 0.75:
            return "Phù hợp với sở thích của bạn"
        return "Gợi ý ngẫu nhiên khám phá"

    def _create_positive_breaker_card(self) -> Dict[str, Any]:
        return {
            'post_id': f"breaker_{random.randint(1000, 9999)}",
            'user_id': 'system_wellbeing',
            'content': '✨ **Góc tươi sáng**: Hãy cùng nhìn vào điều tích cực. Một nụ cười hay một hít thở sâu có thể thay đổi cảm giác hiện tại của bạn. Bạn có muốn xem thêm những chia sẻ ấm áp không?',
            'media_type': 'none',
            'media_urls': [],
            'ai_emotion_vector': {'joy': 0.8, 'trust': 0.2},
            'reactions_count': 0,
            'comments_count': 0,
            'is_breaker': True,
            'breaker_type': 'positive_inject',
            'author_name': 'Wellbeing Guard',
            'author_username': 'wellbeing',
            'author_dominant_emotion': 'joy',
            'created_at': datetime.now(timezone.utc)
        }

    def _create_session_break_card(self, minutes: int) -> Dict[str, Any]:
        return {
            'post_id': f"break_{random.randint(1000, 9999)}",
            'user_id': 'system_wellbeing',
            'content': f'🌊 **Đã đến lúc nghỉ ngơi**: Bạn đã lướt AURA liên tục được {minutes} phút rồi. Hãy nhắm mắt thư giãn 30 giây, uống một cốc nước ấm hoặc vươn vai nhé! 💧',
            'media_type': 'none',
            'media_urls': [],
            'ai_emotion_vector': {'trust': 0.9, 'joy': 0.1},
            'reactions_count': 0,
            'comments_count': 0,
            'is_breaker': True,
            'breaker_type': 'session_break',
            'author_name': 'Wellbeing Guard',
            'author_username': 'wellbeing',
            'author_dominant_emotion': 'trust',
            'created_at': datetime.now(timezone.utc)
        }

    def _get_mock_posts(self) -> List[Dict[str, Any]]:
        return [
            {
                'id': 'mock_1',
                'post_id': 'mock_1',
                'user_id': 'author_1',
                'content': 'Hôm nay tôi cảm thấy thật tuyệt vời khi được nhìn thấy hoàng hôn trên biển. Có ai cũng thích ngắm hoàng hôn không? 🌅',
                'media_type': 'image',
                'media_urls': ['https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600'],
                'ai_emotion_vector': {'joy': 0.6, 'trust': 0.2, 'anticipation': 0.2},
                'reactions_count': 24,
                'comments_count': 12,
                'status': 'active',
                'created_at': datetime.now(timezone.utc),
                'author_name': 'Minh Anh',
                'author_username': 'minhanh',
                'author_dominant_emotion': 'joy',
                'is_demo_data': True
            },
            {
                'id': 'mock_2',
                'post_id': 'mock_2',
                'user_id': 'author_2',
                'content': 'Làm việc mệt mỏi cả ngày, cuối cùng cũng hoàn thành tính năng khó nhằn. Code chạy mượt không một bug, cảm xúc vỡ òa 🚀',
                'media_type': 'none',
                'media_urls': [],
                'ai_emotion_vector': {'joy': 0.5, 'anticipation': 0.3, 'surprise': 0.2},
                'reactions_count': 42,
                'comments_count': 23,
                'status': 'active',
                'created_at': datetime.now(timezone.utc),
                'author_name': 'Hoàng Dũng',
                'author_username': 'hoangdung',
                'author_dominant_emotion': 'joy',
                'is_demo_data': True
            },
            {
                'id': 'mock_3',
                'post_id': 'mock_3',
                'user_id': 'author_3',
                'content': 'Nghe một chút nhạc lofi, nhâm nhi tách trà ấm giữa trời mưa ngắm thành phố trôi chậm lại. Cảm thấy bình yên đến lạ ☕🌧️',
                'media_type': 'image',
                'media_urls': ['https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600'],
                'ai_emotion_vector': {'trust': 0.5, 'joy': 0.3, 'sadness': 0.2},
                'reactions_count': 18,
                'comments_count': 8,
                'status': 'active',
                'created_at': datetime.now(timezone.utc),
                'author_name': 'Thu Hà',
                'author_username': 'thuha_dreamer',
                'author_dominant_emotion': 'trust',
                'is_demo_data': True
            },
            {
                'id': 'mock_4',
                'post_id': 'mock_4',
                'user_id': 'author_4',
                'content': 'Cuối tuần trôi qua nhanh quá, ngày mai lại bắt đầu chuỗi ngày làm việc bận rộn rồi. Hơi áp lực nhưng cố lên nhé mọi người! 💪',
                'media_type': 'none',
                'media_urls': [],
                'ai_emotion_vector': {'anticipation': 0.4, 'trust': 0.3, 'sadness': 0.2, 'fear': 0.1},
                'reactions_count': 31,
                'comments_count': 18,
                'status': 'active',
                'created_at': datetime.now(timezone.utc),
                'author_name': 'Khánh Linh',
                'author_username': 'khanhlinh',
                'author_dominant_emotion': 'anticipation',
                'is_demo_data': True
            }
        ]


# Singleton instance
rec_pipeline = DeepRecommendationPipeline()
