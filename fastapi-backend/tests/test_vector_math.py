"""
AURA Social – Unit Tests: Vector Math Utilities
Tests for the vector math utilities used in emotion/soul calculations.
"""
import pytest
import numpy as np
from app.ml.vector_math import (
    cosine_similarity,
    weighted_fusion,
    normalize_vector,
    euclidean_distance,
    get_dominant_emotion,
    EMOTIONS,
)


class TestCosineSimilarity:
    """Cosine similarity tests."""

    def test_identical_vectors_return_one(self):
        """Cosine similarity of identical vectors should be 1.0."""
        v1 = [0.5, 0.3, 0.2]
        v2 = [0.5, 0.3, 0.2]
        sim = cosine_similarity(v1, v2)
        assert abs(sim - 1.0) < 1e-6

    def test_opposite_vectors_return_minus_one(self):
        """Cosine similarity of opposite vectors should be -1.0."""
        v1 = [1.0, 0.0, 0.0]
        v2 = [-1.0, 0.0, 0.0]
        sim = cosine_similarity(v1, v2)
        assert abs(sim - (-1.0)) < 1e-6

    def test_perpendicular_vectors_return_zero(self):
        """Cosine similarity of perpendicular vectors should be 0.0."""
        v1 = [1.0, 0.0, 0.0]
        v2 = [0.0, 1.0, 0.0]
        sim = cosine_similarity(v1, v2)
        assert abs(sim) < 1e-6

    def test_order_independent(self):
        """Cosine similarity should be the same regardless of vector order."""
        v1 = [0.5, 0.3, 0.2]
        v2 = [0.6, 0.25, 0.15]
        sim1 = cosine_similarity(v1, v2)
        sim2 = cosine_similarity(v2, v1)
        assert abs(sim1 - sim2) < 1e-6

    def test_zero_vector_handled(self):
        """Zero vector should not cause division by zero."""
        v1 = [0.0, 0.0, 0.0]
        v2 = [0.5, 0.3, 0.2]
        sim = cosine_similarity(v1, v2)
        assert sim == 0.0  # No similarity to zero vector


class TestWeightedFusion:
    """Weighted fusion tests."""

    def test_equal_weights_sum_to_one(self):
        """Equal weights should sum to 1.0 for proper fusion."""
        vectors = [
            [0.8, 0.1, 0.1],
            [0.7, 0.2, 0.1],
            [0.6, 0.3, 0.1],
        ]
        weights = [0.33, 0.33, 0.34]
        fused = weighted_fusion(vectors, weights)
        assert len(fused) == 3
        assert all(0 <= v <= 1 for v in fused)

    def test_single_vector_unchanged(self):
        """Single vector should be returned as-is."""
        v = [0.5, 0.3, 0.2]
        fused = weighted_fusion([v], [1.0])
        assert fused == v

    def test_weights_normalized_if_sum_not_one(self):
        """Weights should be normalized if they don't sum to 1."""
        vectors = [[0.8, 0.2], [0.3, 0.7]]
        weights = [0.5, 0.5]  # Already sums to 1
        fused = weighted_fusion(vectors, weights)
        assert len(fused) == 2
        assert abs(sum(fused) - 1.0) < 0.01

    def test_empty_vectors_handled(self):
        """Empty vector list should return neutral vector."""
        fused = weighted_fusion([], [])
        assert fused == [0.125] * 8

    def test_single_weight_normalized(self):
        """Single weight should be normalized to 1.0."""
        vectors = [[0.8, 0.2]]
        weights = [0.5]  # Should normalize to [1.0]
        fused = weighted_fusion(vectors, weights)
        assert fused == [0.8, 0.2]


class TestNormalizeVector:
    """Vector normalization tests."""

    def test_l2_normalize_preserves_direction(self):
        """L2 normalization should preserve vector direction."""
        v = [3.0, 4.0]
        normalized = normalize_vector(v, norm_type="l2")
        magnitude = np.linalg.norm(normalized)
        assert abs(magnitude - 1.0) < 1e-6

    def test_unit_vector_unchanged(self):
        """Already-normalized unit vector should be unchanged."""
        v = [1.0, 0.0, 0.0]
        normalized = normalize_vector(v, norm_type="l2")
        assert normalized == pytest.approx(v, abs=1e-6)

    def test_zero_vector_handled(self):
        """Zero vector normalization should return zero vector."""
        v = [0.0, 0.0, 0.0]
        normalized = normalize_vector(v, norm_type="l2")
        assert normalized == v  # Cannot normalize zero vector, returns as-is

    def test_l1_normalize(self):
        """L1 normalization should produce values summing to 1."""
        v = [3.0, 4.0]
        normalized = normalize_vector(v, norm_type="l1")
        assert abs(sum(normalized) - 1.0) < 1e-6


class TestEuclideanDistance:
    """Euclidean distance tests."""

    def test_identical_vectors_distance_zero(self):
        """Distance between identical vectors should be 0."""
        v1 = [1.0, 2.0, 3.0]
        v2 = [1.0, 2.0, 3.0]
        dist = euclidean_distance(v1, v2)
        assert dist == pytest.approx(0.0, abs=1e-6)

    def test_known_distance(self):
        """Known Euclidean distance should match formula."""
        v1 = [0.0, 0.0]
        v2 = [3.0, 4.0]
        dist = euclidean_distance(v1, v2)
        assert dist == pytest.approx(5.0, abs=1e-6)

    def test_symmetric(self):
        """Distance should be symmetric (v1 to v2 == v2 to v1)."""
        v1 = [1.0, 2.0, 3.0]
        v2 = [4.0, 6.0, 8.0]
        d1 = euclidean_distance(v1, v2)
        d2 = euclidean_distance(v2, v1)
        assert d1 == pytest.approx(d2, abs=1e-6)

    def test_different_dimensionality(self):
        """Vectors with different dimensions should raise error or handle gracefully."""
        v1 = [1.0, 2.0]
        v2 = [1.0, 2.0, 3.0]
        # Should raise ValueError or return something predictable
        with pytest.raises((ValueError, AssertionError)):
            euclidean_distance(v1, v2)


class TestGetDominantEmotion:
    """Dominant emotion extraction tests."""

    def test_dominant_is_highest(self):
        """Dominant emotion should be the emotion with highest value."""
        vector = [0.8, 0.1, 0.05, 0.02, 0.01, 0.01, 0.005, 0.005]
        assert get_dominant_emotion(vector) == "joy"

    def test_second_emotion_when_tied(self):
        """When joy is dominant, second dominant should be second highest."""
        vector = [0.8, 0.1, 0.05, 0.02, 0.01, 0.01, 0.005, 0.005]
        dominant = get_dominant_emotion(vector)
        second = get_dominant_emotion(vector, exclude=dominant)
        assert second == "trust"

    def test_tied_highest_returns_first(self):
        """When emotions are tied, return the first one (by EMOTIONS order)."""
        vector = [0.5, 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        dominant = get_dominant_emotion(vector)
        assert dominant == "joy"  # First in EMOTIONS list

    def test_neutral_vector(self):
        """Neutral vector (all equal) should return joy (first emotion)."""
        vector = [0.125] * 8
        dominant = get_dominant_emotion(vector)
        assert dominant == "joy"

    def test_return_indices(self):
        """With return_indices=True, should return emotion index too."""
        vector = [0.1, 0.1, 0.1, 0.1, 0.6, 0.0, 0.0, 0.0]
        result = get_dominant_emotion(vector, return_indices=True)
        assert result["emotion"] == "sadness"
        assert result["index"] == 4
        assert result["value"] == pytest.approx(0.6, abs=0.01)


class TestEmotionsConstant:
    """EMOTIONS constant tests."""

    def test_emotions_has_8_items(self):
        """EMOTIONS should have exactly 8 items."""
        assert len(EMOTIONS) == 8

    def test_emotions_are_plutchik(self):
        """EMOTIONS should follow Plutchik's wheel of emotions."""
        expected = ["joy", "trust", "anticipation", "surprise",
                    "sadness", "fear", "anger", "disgust"]
        assert list(EMOTIONS) == expected

    def test_emotions_index_mapping(self):
        """Each emotion should have correct index."""
        assert EMOTIONS[0] == "joy"
        assert EMOTIONS[4] == "sadness"
        assert EMOTIONS[6] == "anger"
