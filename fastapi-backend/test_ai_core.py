"""
AURA Social – Local AI Core Test Script
"""
import os
import sys
import asyncio
from datetime import datetime, timezone, timedelta

# Add current directory to python path
sys.path.append(os.path.abspath(os.path.dirname(__file__)))

# Mock get_settings before imports to bypass actual environment checks
from app.config import get_settings
settings = get_settings()
settings.internal_api_key = "test-key"

from app.ml.model_loader import model_loader
from app.ml.emotion_engine import emotion_inference_engine, EMOTIONS
from app.ml.rec_engine import rec_pipeline
from app.ml.soul_engine import soul_engine
from app.ml.moderation_engine import content_moderator
from app.ml.prompt_engine import prompt_engine
from app.ml.analytics_engine import weekly_analytics_engine
from app.models.emotion import BehavioralEvent


async def run_tests():
    print("🧪 STARTING AURA SOCIAL CORE AI TESTS 🧪")
    
    # ── Test 1: Model Loader & Embedding ──
    print("\n1. Testing Model Loader & Sentence Embedding...")
    try:
        model_loader.load_all()
        
        sample_text = "Hôm nay tôi thấy rất vui và hạnh phúc khi dự án chạy thành công! 🌟"
        print(f"Text: '{sample_text}'")
        
        # Test sentence embedding
        emb = model_loader.get_sentence_embedding(sample_text)
        print(f"✅ Embedding generated. Dimension: {len(emb)}, first 5 values: {emb[:5]}")
        assert len(emb) == 384, f"Expected 384 dimensions, got {len(emb)}"
    except Exception as e:
        print(f"❌ Test 1 Failed: {e}")
        return

    # ── Test 2: Emotion Inference (Texts) ──
    print("\n2. Testing Emotion Inference on Texts...")
    try:
        sample_texts = [
            "Hôm nay tôi buồn quá, chẳng muốn làm gì cả.",
            "Bực mình thực sự, code lỗi mãi không chạy được!",
            "Cảm giác bình yên chill chill ngắm mưa rơi ngoài cửa sổ."
        ]
        
        for t in sample_texts:
            res = emotion_inference_engine.analyze_texts([t])
            vector = res['vector']
            dominant_idx = vector.index(max(vector))
            dominant_emotion = EMOTIONS[dominant_idx]
            print(f"Text: '{t}' -> Dominant Emotion: {dominant_emotion} (score: {vector[dominant_idx]:.3f})")
            print(f"   Vector: { {EMOTIONS[i]: round(vector[i], 3) for i in range(8)} }")
    except Exception as e:
        print(f"❌ Test 2 Failed: {e}")
        return

    # ── Test 3: Emotion Inference (Behavioral Signals) ──
    print("\n3. Testing Emotion Inference on Behavioral Signals...")
    try:
        events = [
            BehavioralEvent(event_type="scroll", timestamp=1710000000.0, metadata={"scroll_speed": 4.5}),
            BehavioralEvent(event_type="scroll", timestamp=1710000002.0, metadata={"scroll_speed": 3.8}),
            BehavioralEvent(event_type="dwell", timestamp=1710000005.0, duration_ms=1200),
            BehavioralEvent(event_type="dwell", timestamp=1710000008.0, duration_ms=900)
        ]
        
        res = emotion_inference_engine.analyze_behavioral(events)
        print("Fast scroll, low dwell events:")
        print(f"   Arousal: {res['arousal']:.2f}, Depth: {res['depth']:.2f}, Social energy: {res['social_energy']:.2f}")
        print(f"   Vector: { [round(v, 3) for v in res['vector']] }")
        
        # Test full fusion
        temporal_res = emotion_inference_engine.analyze_temporal({"hour": 23}) # Late night
        social_res = emotion_inference_engine.analyze_social({"reciprocity_rate": 0.8})
        interaction_res = emotion_inference_engine.analyze_interactions({"reactions": {"joy": 5, "trust": 3}})
        text_res = emotion_inference_engine.analyze_texts(["Hôm nay mọi chuyện khá ổn"])
        
        fused = emotion_inference_engine.fuse_signals(
            behavioral=res,
            interaction=interaction_res,
            text=text_res,
            temporal=temporal_res,
            social=social_res
        )
        print("Fused Vector:")
        print(f"   Vector: {fused['emotion_vector']}")
        print(f"   Valence: {fused['valence']:.3f}, Arousal: {fused['arousal']:.3f}, Dominance: {fused['dominance']:.3f}")
        
        mode = emotion_inference_engine.detect_emotional_mode(fused)
        print(f"   Detected Mode: {mode}")
    except Exception as e:
        print(f"❌ Test 3 Failed: {e}")
        return

    # ── Test 4: Deep Recommendation Pipeline ──
    print("\n4. Testing Recommendation Pipeline Scoring...")
    try:
        user_profile = {
            'uid': 'test_user_1',
            'display_name': 'Tester',
            'interests': ['coding', 'music'],
            'content_preference_vector': [0.1] * 384,
            'following_ids': ['author_1'],
            'emotional_mode': 'gentle_uplift',
            'current_session_minutes': 5
        }
        
        user_emotion = {
            'joy': 0.1, 'trust': 0.1, 'anticipation': 0.1, 'surprise': 0.1,
            'sadness': 0.4, 'fear': 0.1, 'anger': 0.05, 'disgust': 0.05
        } # Sad user
        
        # Get mock candidates
        candidates = rec_pipeline._get_mock_posts()
        
        # Add random content_embeddings to candidates
        for c in candidates:
            c['content_embedding'] = [0.12] * 384
            c['ai_emotion_vector'] = c.get('ai_emotion_vector', {'joy': 0.125})
            c['created_at'] = datetime.now(timezone.utc)
            
        ranked = rec_pipeline.score_candidates(user_profile, candidates, user_emotion)
        print("Ranked posts:")
        for idx, post in enumerate(ranked):
            print(f"   {idx+1}. ID: {post['post_id']} | Score: {post['relevance_score']:.4f} | Reason: {post['relevance_reason']}")
            
        # Test Wellbeing Guard filter (doom scroll / negative streak)
        # Mock 5 consecutive negative posts
        neg_candidates = []
        for i in range(5):
            neg_candidates.append({
                'post_id': f'neg_{i}',
                'user_id': 'author_bad',
                'content': 'Mọi chuyện thật tồi tệ và chán nản...',
                'ai_emotion_vector': {'sadness': 0.7, 'fear': 0.3},
                'created_at': datetime.now(timezone.utc)
            })
            
        final_feed = rec_pipeline.apply_wellbeing_guard(neg_candidates, user_profile)
        print(f"Wellbeing Guard test: input 5 negative posts -> output feed length {len(final_feed)}")
        print("Feed items types:")
        for p in final_feed:
            is_breaker = p.get('is_breaker', False)
            print(f"   Item: {p['post_id']} | Is Breaker: {is_breaker} | Author: {p.get('author_name', 'user')}")
            
    except Exception as e:
        print(f"❌ Test 4 Failed: {e}")
        return

    # ── Test 5: Soul Connect Engine ──
    print("\n5. Testing Soul Connect Engine...")
    try:
        user_a = {
            'display_name': 'User A',
            'interests': ['coding', 'music', 'gaming'],
            'content_preference_vector': [0.1] * 384,
            'current_emotion_vector': {'joy': 0.3, 'trust': 0.3, 'anticipation': 0.4},
            'weekly_emotion_pattern': [[0.2] * 8] * 7,
            'peak_activity_hours': [9, 10, 11]
        }
        
        user_b = {
            'display_name': 'User B',
            'interests': ['music', 'gaming', 'art'],
            'content_preference_vector': [0.11] * 384,
            'current_emotion_vector': {'joy': 0.25, 'trust': 0.35, 'anticipation': 0.4},
            'weekly_emotion_pattern': [[0.21] * 8] * 7,
            'peak_activity_hours': [10, 14, 15]
        }
        
        res = soul_engine.calculate_soul_score(user_a, user_b)
        print(f"Compatibility between User A and User B:")
        print(f"   Soul Score: {res['soul_score']:.3f} | Connection Type: {res['connection_type']}")
        print(f"   Reason: {res['reason']}")
        print(f"   Breakdown: {res['breakdown']}")
        
    except Exception as e:
        print(f"❌ Test 5 Failed: {e}")
        return

    # ── Test 6: Content Moderation Engine (Phase 5) ──
    print("\n6. Testing Content Moderation Engine...")
    try:
        toxic_text = "Hôm nay thấy đm chán vcl, muốn kết liễu cuộc đời cho rảnh nợ."
        safe_text = "Chào mọi người, chúc một ngày mới tốt lành và nhiều niềm vui nhé! ☀️"
        
        # Test safe content
        res_safe = content_moderator.analyze_text(safe_text)
        print(f"Safe text test: is_toxic = {res_safe['is_toxic']} (score: {res_safe['toxicity_score']})")
        assert not res_safe['is_toxic'], "Expected safe text to be safe"
        
        # Test toxic content
        res_toxic = content_moderator.analyze_text(toxic_text)
        print(f"Toxic/Self-Harm test: is_toxic = {res_toxic['is_toxic']} (score: {res_toxic['toxicity_score']})")
        print(f"   Flagged: {res_toxic['flagged_categories']}")
        print(f"   Sanitized: {res_toxic['cleaned_text']}")
        assert res_toxic['is_toxic'], "Expected toxic text to be flagged"
        assert "self_harm" in res_toxic['flagged_categories'], "Expected self-harm to be flagged"
        
    except Exception as e:
        print(f"❌ Test 6 Failed: {e}")
        return

    # ── Test 7: Empathetic AI Prompt Engine (Phase 5) ──
    print("\n7. Testing Empathetic AI Prompt Engine...")
    try:
        # Icebreakers for stressed partner
        ice = prompt_engine.generate_icebreakers("joy", "stressed", "Twin Flame")
        print(f"Icebreakers (Stressed partner, Twin Flame):")
        for i, prompt in enumerate(ice):
            print(f"   {i+1}. {prompt}")
        assert len(ice) == 3, "Expected 3 icebreakers"
        
        # Reply suggestions for sad message
        replies = prompt_engine.suggest_replies("Mình thấy mệt mỏi quá, làm việc áp lực quá mức...", "stressed", "sad")
        print(f"Reply suggestions for sad message:")
        for i, reply in enumerate(replies):
            print(f"   {i+1}. {reply}")
        assert len(replies) == 3, "Expected 3 reply suggestions"
        
    except Exception as e:
        print(f"❌ Test 7 Failed: {e}")
        return

    # ── Test 8: Weekly Emotional Analytics & Self-Care Report (Phase 5) ──
    print("\n8. Testing Weekly Emotional Analytics & Self-Care Report...")
    try:
        # Construct mock 7-day emotional history
        mock_history = [
            {'timestamp': datetime.now() - timedelta(days=6), 'dominant_emotion': 'sadness', 'emotion_vector': {'sadness': 0.6, 'fear': 0.2, 'joy': 0.1, 'trust': 0.1}},
            {'timestamp': datetime.now() - timedelta(days=5), 'dominant_emotion': 'sadness', 'emotion_vector': {'sadness': 0.5, 'fear': 0.3, 'joy': 0.1, 'trust': 0.1}},
            {'timestamp': datetime.now() - timedelta(days=4), 'dominant_emotion': 'stressed', 'emotion_vector': {'anger': 0.5, 'sadness': 0.3, 'fear': 0.2}},
            {'timestamp': datetime.now() - timedelta(days=3), 'dominant_emotion': 'chill', 'emotion_vector': {'trust': 0.4, 'joy': 0.3, 'sadness': 0.1, 'fear': 0.1, 'anger': 0.1}},
            {'timestamp': datetime.now() - timedelta(days=2), 'dominant_emotion': 'joy', 'emotion_vector': {'joy': 0.5, 'trust': 0.3, 'sadness': 0.1, 'fear': 0.1}},
            {'timestamp': datetime.now() - timedelta(days=1), 'dominant_emotion': 'joy', 'emotion_vector': {'joy': 0.6, 'trust': 0.3, 'sadness': 0.05, 'fear': 0.05}}
        ]
        
        report = weekly_analytics_engine.generate_weekly_report("test_user_1", mock_history)
        print("Weekly Report generated:")
        print(f"   Stability Index: {report['stability_index']} ({report['stability_label']})")
        print(f"   Dominant Weekly Emotion: {report['dominant_emotion']}")
        print(f"   Weekend vs Weekday trend: {report['trends']['weekend_vs_weekday']}")
        print(f"   Personalized Letter: {report['personalized_letter']}")
        print(f"   Self-Care Activities:")
        for idx, act in enumerate(report['self_care_plan']['activities']):
            print(f"      - {act}")
        print(f"   Music Vibe Recommendation: {report['self_care_plan']['music_vibe']}")
        print(f"   Social tip: {report['self_care_plan']['social_tip']}")
        
    except Exception as e:
        print(f"❌ Test 8 Failed: {e}")
        return

    print("\n🎉 ALL AI CORE TESTS PASSED SUCCESSFULLY! 🎉")


if __name__ == "__main__":
    asyncio.run(run_tests())
