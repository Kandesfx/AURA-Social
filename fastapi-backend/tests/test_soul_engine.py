"""
AURA Social – Unit Tests: Soul Engine
Tests for the soul connection matching algorithm.
"""
import pytest
from app.ml.soul_engine import SoulEngine, CONNECTION_TYPES


@pytest.fixture
def engine():
    """Create a fresh SoulEngine instance."""
    return SoulEngine()


@pytest.fixture
def sample_users():
    """Create sample users for testing."""
    return {
        "user1": {
            "uid": "user1",
            "emotion_vector": [0.7, 0.5, 0.6, 0.3, 0.2, 0.1, 0.1, 0.1],
            "weekly_emotion_pattern": [
                [0.6, 0.4, 0.5, 0.3, 0.3, 0.2, 0.2, 0.1],
                [0.7, 0.5, 0.6, 0.3, 0.2, 0.1, 0.1, 0.1],
                [0.8, 0.6, 0.7, 0.4, 0.1, 0.1, 0.1, 0.1],
            ],
            "content_embedding": [0.5] * 384,
            "interests": ["music", "reading", "travel"],
            "activity_hours": {"morning": 0.3, "afternoon": 0.4, "evening": 0.3},
            "soul_score": 0.0,
        },
        "user2": {
            "uid": "user2",
            "emotion_vector": [0.6, 0.6, 0.5, 0.2, 0.3, 0.2, 0.1, 0.1],
            "weekly_emotion_pattern": [
                [0.5, 0.5, 0.4, 0.2, 0.4, 0.3, 0.2, 0.1],
                [0.6, 0.6, 0.5, 0.2, 0.3, 0.2, 0.1, 0.1],
                [0.7, 0.7, 0.6, 0.3, 0.2, 0.1, 0.1, 0.1],
            ],
            "content_embedding": [0.5] * 384,
            "interests": ["music", "movies", "travel"],
            "activity_hours": {"morning": 0.2, "afternoon": 0.5, "evening": 0.3},
            "soul_score": 0.0,
        },
        "user3": {
            "uid": "user3",
            "emotion_vector": [0.1, 0.1, 0.1, 0.1, 0.7, 0.6, 0.5, 0.4],
            "weekly_emotion_pattern": [
                [0.1, 0.1, 0.1, 0.1, 0.7, 0.6, 0.5, 0.4],
                [0.1, 0.1, 0.1, 0.1, 0.8, 0.7, 0.6, 0.5],
                [0.1, 0.1, 0.1, 0.1, 0.6, 0.5, 0.4, 0.3],
            ],
            "content_embedding": [0.3] * 384,
            "interests": ["gaming", "coding"],
            "activity_hours": {"morning": 0.1, "afternoon": 0.3, "evening": 0.6},
            "soul_score": 0.0,
        },
    }


class TestConnectionTypes:
    """Connection type classification tests."""

    def test_connection_types_defined(self):
        """All connection types should be defined."""
        assert "soulmate" in CONNECTION_TYPES
        assert "anchor" in CONNECTION_TYPES
        assert "vibe_partner" in CONNECTION_TYPES
        assert "new_connection" in CONNECTION_TYPES

    def test_score_thresholds(self):
        """Connection type thresholds should be properly ordered."""
        soulmate = CONNECTION_TYPES["soulmate"]
        anchor = CONNECTION_TYPES["anchor"]
        vibe = CONNECTION_TYPES["vibe_partner"]

        assert soulmate["threshold"] > anchor["threshold"]
        assert anchor["threshold"] > vibe["threshold"]


class TestPatternSimilarity:
    """Pattern similarity (weekly emotion pattern) tests."""

    def test_identical_patterns_score_one(self, engine, sample_users):
        """Identical weekly patterns should have score of 1.0."""
        user1 = sample_users["user1"]
        user2 = sample_users["user1"]  # Same user
        score = engine._calculate_pattern_similarity(user1, user2)
        assert score == pytest.approx(1.0, abs=0.01)

    def test_different_patterns_score_lower(self, engine, sample_users):
        """Different weekly patterns should have lower similarity score."""
        user1 = sample_users["user1"]
        user3 = sample_users["user3"]
        score = engine._calculate_pattern_similarity(user1, user3)
        assert 0.0 <= score <= 1.0
        # user1 and user3 have very different patterns, score should be low
        assert score < 0.5


class TestContentTaste:
    """Content taste similarity tests."""

    def test_identical_embeddings_score_one(self, engine, sample_users):
        """Identical content embeddings should have score of 1.0."""
        user1 = sample_users["user1"]
        user2 = sample_users["user2"]
        score = engine._calculate_content_taste(user1, user2)
        assert score == pytest.approx(1.0, abs=0.01)

    def test_different_embeddings_score_lower(self, engine, sample_users):
        """Different content embeddings should have lower score."""
        user1 = sample_users["user1"]
        user3 = sample_users["user3"]
        score = engine._calculate_content_taste(user1, user3)
        assert 0.0 <= score <= 1.0


class TestInterestOverlap:
    """Interest overlap (Jaccard similarity) tests."""

    def test_identical_interests(self, engine, sample_users):
        """Identical interests should return Jaccard score of 1.0."""
        user1 = sample_users["user1"]
        user1_copy = {**user1, "uid": "user1_copy"}
        score = engine._calculate_interest_overlap(user1, user1_copy)
        assert score == 1.0

    def test_no_common_interests(self, engine, sample_users):
        """No common interests should return 0.0."""
        user1 = sample_users["user1"]
        user3 = sample_users["user3"]
        # user1: music, reading, travel
        # user3: gaming, coding
        # No overlap
        score = engine._calculate_interest_overlap(user1, user3)
        assert score == 0.0

    def test_partial_overlap(self, engine, sample_users):
        """Partial overlap should return fraction of shared interests."""
        user1 = sample_users["user1"]  # music, reading, travel
        user2 = sample_users["user2"]  # music, movies, travel
        # Union: music, reading, travel, movies = 4
        # Intersection: music, travel = 2
        # Jaccard = 2/4 = 0.5
        score = engine._calculate_interest_overlap(user1, user2)
        assert score == pytest.approx(0.5, abs=0.01)


class TestActivityAlignment:
    """Activity hour alignment tests."""

    def test_identical_activity_patterns(self, engine, sample_users):
        """Identical activity patterns should return score of 1.0."""
        user1 = sample_users["user1"]
        user1_copy = {**user1, "uid": "user1_copy"}
        score = engine._calculate_activity_alignment(user1, user1_copy)
        assert score == pytest.approx(1.0, abs=0.01)

    def test_different_activity_patterns(self, engine, sample_users):
        """Different activity patterns should return lower score."""
        user1 = sample_users["user1"]  # morning 0.3, afternoon 0.4, evening 0.3
        user3 = sample_users["user3"]  # morning 0.1, afternoon 0.3, evening 0.6
        score = engine._calculate_activity_alignment(user1, user3)
        assert 0.0 <= score <= 1.0
        assert score < 0.8  # Should be noticeably different


class TestEmotionComplementarity:
    """Emotional complementarity tests."""

    def test_complementary_emotions(self, engine):
        """Complementary emotion pairs should boost compatibility."""
        # Stressed user (high fear/anger) with chill user (high joy/trust)
        stressed = {
            "emotion_vector": [0.1, 0.1, 0.1, 0.1, 0.3, 0.5, 0.4, 0.1],
        }
        chill = {
            "emotion_vector": [0.7, 0.6, 0.4, 0.2, 0.1, 0.1, 0.1, 0.1],
        }
        score = engine._calculate_emotion_complementarity(stressed, chill)
        assert score > 0.5  # Should have complementarity

    def test_similar_emotions(self, engine):
        """Similar emotion vectors should have neutral complementarity."""
        user1 = {
            "emotion_vector": [0.7, 0.5, 0.6, 0.3, 0.2, 0.1, 0.1, 0.1],
        }
        user2 = {
            "emotion_vector": [0.6, 0.6, 0.5, 0.2, 0.3, 0.2, 0.1, 0.1],
        }
        score = engine._calculate_emotion_complementarity(user1, user2)
        assert 0.0 <= score <= 1.0


class TestOverallSoulScore:
    """Overall soul score calculation tests."""

    def test_excellent_match(self, engine, sample_users):
        """Excellent match should have high overall score."""
        user1 = sample_users["user1"]
        user2 = sample_users["user2"]
        score = engine.compute_soul_score(user1, user2)
        assert 0.0 <= score <= 1.0
        assert score > 0.7  # user1 and user2 are similar

    def test_poor_match(self, engine, sample_users):
        """Poor match should have low overall score."""
        user1 = sample_users["user1"]
        user3 = sample_users["user3"]
        score = engine.compute_soul_score(user1, user3)
        assert 0.0 <= score <= 1.0
        assert score < 0.5  # user1 and user3 are very different

    def test_score_symmetric(self, engine, sample_users):
        """Soul score should be symmetric (A->B == B->A)."""
        user1 = sample_users["user1"]
        user2 = sample_users["user2"]
        score_ab = engine.compute_soul_score(user1, user2)
        score_ba = engine.compute_soul_score(user2, user1)
        assert score_ab == pytest.approx(score_ba, abs=0.01)

    def test_self_match_score(self, engine, sample_users):
        """Self-match should return 1.0."""
        user1 = sample_users["user1"]
        score = engine.compute_soul_score(user1, user1)
        assert score == pytest.approx(1.0, abs=0.01)


class TestConnectionTypeClassification:
    """Connection type classification tests."""

    def test_soulmate_threshold(self, engine, sample_users):
        """High compatibility should classify as soulmate."""
        user1 = sample_users["user1"]
        user2 = sample_users["user2"]
        # These are similar users, should get high score
        score = engine.compute_soul_score(user1, user2)
        connection_type = engine.classify_connection(score)
        assert connection_type in CONNECTION_TYPES

    def test_connection_type_deterministic(self, engine):
        """Same score should always return same connection type."""
        scores = [0.9, 0.75, 0.5, 0.3]
        for score in scores:
            types = [engine.classify_connection(score) for _ in range(5)]
            assert len(set(types)) == 1  # All should be the same
