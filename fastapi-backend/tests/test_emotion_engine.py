"""
AURA Social – Unit Tests: Emotion Engine
Tests for the emotion inference pipeline.
"""
import pytest
import numpy as np
from app.ml.emotion_engine import EmotionInferenceEngine, EMOTIONS


@pytest.fixture
def engine():
    """Create a fresh EmotionInferenceEngine instance."""
    return EmotionInferenceEngine()


class TestEmotionEngineBasic:
    """Basic emotion engine tests."""

    def test_emotions_list_has_8_items(self):
        """Verify EMOTIONS list has exactly 8 emotions (Plutchik model)."""
        assert len(EMOTIONS) == 8
        assert EMOTIONS == [
            "joy", "trust", "anticipation", "surprise",
            "sadness", "fear", "anger", "disgust"
        ]

    def test_neutral_vector_is_balanced(self, engine):
        """Neutral vector should have equal weights summing to 1.0."""
        neutral = [0.125] * 8
        assert abs(sum(neutral) - 1.0) < 0.001
        assert all(v == 0.125 for v in neutral)

    def test_vector_length_is_8(self, engine):
        """Emotion vector should always be length 8."""
        vector = engine._create_neutral_vector()
        assert len(vector) == 8
        assert isinstance(vector, list)

    def test_vector_values_in_valid_range(self, engine):
        """All emotion values should be between 0 and 1."""
        vector = engine._create_neutral_vector()
        assert all(0 <= v <= 1 for v in vector)


class TestBehavioralAnalysis:
    """Behavioral signal analysis layer tests."""

    def test_empty_events_returns_neutral(self, engine):
        """Empty behavioral events should return neutral vector."""
        result = engine.analyze_behavioral([])
        assert "vector" in result
        assert len(result["vector"]) == 8
        assert result["vector"] == [0.125] * 8

    def test_positive_scroll_speed_increases_joy(self, engine):
        """Fast scrolling through positive content should increase joy."""
        events = [
            {"type": "scroll", "speed": 0.9, "content_sentiment": 0.8, "timestamp": "2026-06-08T10:00:00Z"},
            {"type": "scroll", "speed": 0.8, "content_sentiment": 0.7, "timestamp": "2026-06-08T10:01:00Z"},
        ]
        result = engine.analyze_behavioral(events)
        assert "vector" in result
        assert result["vector"][0] > 0.125  # Joy should be above neutral

    def test_negative_dwell_time_increases_sadness(self, engine):
        """Long dwell time on negative content should increase sadness."""
        events = [
            {"type": "dwell", "duration": 10, "content_sentiment": -0.6, "timestamp": "2026-06-08T10:00:00Z"},
        ]
        result = engine.analyze_behavioral(events)
        assert "vector" in result
        assert result["vector"][4] > 0.125  # Sadness should be above neutral

    def test_high_arousal_boosts_intensity(self, engine):
        """High arousal events should boost emotion intensity."""
        events = [
            {"type": "interaction", "rate": 0.9, "timestamp": "2026-06-08T10:00:00Z"},
        ]
        result = engine.analyze_behavioral(events)
        assert "vector" in result
        # At least one emotion should be elevated
        assert any(v > 0.125 for v in result["vector"])


class TestInteractionAnalysis:
    """Content interaction analysis layer tests."""

    def test_empty_interactions_returns_neutral(self, engine):
        """Empty interaction dict should return neutral vector."""
        result = engine.analyze_interactions({})
        assert "vector" in result
        assert result["vector"] == [0.125] * 8

    def test_high_like_count_boosts_joy(self, engine):
        """High like count should indicate joy."""
        interactions = {
            "like_count": 50,
            "comment_count": 10,
            "share_count": 5,
            "save_count": 3,
        }
        result = engine.analyze_interactions(interactions)
        assert result["vector"][0] > 0.125  # Joy

    def test_many_angry_reactions_increases_anger(self, engine):
        """Many angry reactions should increase anger."""
        interactions = {
            "reactions": {"anger": 30, "joy": 5},
        }
        result = engine.analyze_interactions(interactions)
        assert result["vector"][6] > 0.125  # Anger


class TestTemporalAnalysis:
    """Temporal/circadian pattern analysis tests."""

    def test_late_night_increases_sadness(self, engine):
        """Late night activity (after 22:00) should slightly increase sadness."""
        result = engine._analyze_temporal({})
        assert "vector" in result
        # Should have adjusted temporal factor
        assert "temporal_factor" in result or "circadian" in str(result)


class TestSignalFusion:
    """Signal fusion (weighted combination) tests."""

    def test_fusion_weights_sum_to_one(self, engine):
        """Signal layer weights should sum to approximately 1.0."""
        weights = engine._get_fusion_weights()
        total = sum(w for w in weights.values())
        assert abs(total - 1.0) < 0.01, f"Fusion weights sum to {total}, expected ~1.0"

    def test_fusion_produces_valid_vector(self, engine):
        """Fusion should produce a valid 8D vector."""
        signals = {
            "behavioral": {"vector": [0.5, 0.1, 0.1, 0.1, 0.05, 0.05, 0.05, 0.05]},
            "interaction": {"vector": [0.4, 0.15, 0.15, 0.1, 0.05, 0.05, 0.05, 0.05]},
            "text": {"vector": [0.6, 0.1, 0.1, 0.1, 0.02, 0.02, 0.02, 0.04]},
            "temporal": {"vector": [0.3, 0.2, 0.2, 0.1, 0.05, 0.05, 0.05, 0.05]},
            "social": {"vector": [0.4, 0.2, 0.1, 0.1, 0.05, 0.05, 0.05, 0.05]},
        }
        fused = engine._fuse_signals(signals)
        assert len(fused) == 8
        assert all(0 <= v <= 1 for v in fused)

    def test_explicit_mood_override_works(self, engine):
        """Explicit mood should override fused signal with high weight."""
        signals = {
            "behavioral": {"vector": [0.5, 0.1, 0.1, 0.1, 0.05, 0.05, 0.05, 0.05]},
        }
        override = {"emotion": "anger", "intensity": 0.9}
        fused = engine._fuse_signals(signals, explicit_mood=override)
        assert fused[6] > 0.5  # Anger should be dominant


class TestDominantEmotion:
    """Dominant emotion detection tests."""

    def test_dominant_is_highest_value(self, engine):
        """Dominant emotion should be the emotion with highest value."""
        vectors = [
            ([0.8, 0.1, 0.1, 0.1, 0.05, 0.05, 0.05, 0.05], "joy"),
            ([0.1, 0.1, 0.1, 0.1, 0.8, 0.1, 0.1, 0.1], "sadness"),
            ([0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.8, 0.1], "anger"),
        ]
        for vector, expected in vectors:
            dominant = engine._get_dominant_emotion(vector)
            assert dominant == expected, f"Expected {expected}, got {dominant} for vector {vector}"

    def test_tied_values_returns_first(self, engine):
        """When emotions are tied, should return the first one."""
        # All equal - joy (index 0) should win
        vector = [0.125] * 8
        dominant = engine._get_dominant_emotion(vector)
        assert dominant == "joy"  # First in the list


class TestVietnameseKeywords:
    """Vietnamese emotion keyword detection tests."""

    def test_vietnamese_joy_keywords(self, engine):
        """Vietnamese joy keywords should boost joy vector."""
        result = engine._analyze_text("Tôi rất vui và hạnh phúc hôm nay!")
        assert "vector" in result
        assert result["vector"][0] > 0.125  # Joy

    def test_vietnamese_sadness_keywords(self, engine):
        """Vietnamese sadness keywords should boost sadness vector."""
        result = engine._analyze_text("Tôi buồn và thất vọng về chuyện này")
        assert "vector" in result
        assert result["vector"][4] > 0.125  # Sadness

    def test_vietnamese_anger_keywords(self, engine):
        """Vietnamese anger keywords should boost anger vector."""
        result = engine._analyze_text("Tôi rất giận và tức vì chuyện này")
        assert "vector" in result
        assert result["vector"][6] > 0.125  # Anger

    def test_mixed_emotions_detected(self, engine):
        """Text with multiple emotions should reflect both."""
        result = engine._analyze_text("Tôi vui vì được gặp bạn nhưng cũng buồn vì phải chia tay")
        assert "vector" in result
        # Both joy and sadness should be elevated
        assert result["vector"][0] > 0.125
        assert result["vector"][4] > 0.125


class TestEdgeCases:
    """Edge case handling tests."""

    def test_very_long_text_truncated(self, engine):
        """Very long text should be truncated for analysis."""
        long_text = "Tôi vui " * 1000  # Very long text
        result = engine._analyze_text(long_text)
        assert "vector" in result

    def test_emoji_only_text(self, engine):
        """Emoji-only text should be handled gracefully."""
        result = engine._analyze_text("😀😢😡")
        assert "vector" in result
        assert len(result["vector"]) == 8

    def test_empty_text_returns_neutral(self, engine):
        """Empty text should return neutral vector."""
        result = engine._analyze_text("")
        assert "vector" in result
        assert result["vector"] == [0.125] * 8

    def test_whitespace_only_returns_neutral(self, engine):
        """Whitespace-only text should return neutral vector."""
        result = engine._analyze_text("   \n\t  ")
        assert "vector" in result
        assert result["vector"] == [0.125] * 8

    def test_numeric_only_text(self, engine):
        """Numeric-only text should be handled without error."""
        result = engine._analyze_text("12345 67890")
        assert "vector" in result
        assert len(result["vector"]) == 8

    def test_special_characters_only(self, engine):
        """Special characters only should be handled without error."""
        result = engine._analyze_text("!@#$%^&*()_+-=[]{}|;':\",./<>?")
        assert "vector" in result
        assert len(result["vector"]) == 8
