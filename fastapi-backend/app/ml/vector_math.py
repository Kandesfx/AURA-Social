"""
AURA Social – Vector Math Utilities
Cosine similarity, emotion fusion, distance calculations.
"""
import math
from typing import Dict, List


def cosine_similarity(vec_a: Dict[str, float], vec_b: Dict[str, float]) -> float:
    """
    Cosine similarity between two emotion vectors.
    Returns value in [-1, 1], where 1 = identical.
    """
    keys = set(vec_a.keys()) | set(vec_b.keys())
    dot = sum(vec_a.get(k, 0) * vec_b.get(k, 0) for k in keys)
    norm_a = math.sqrt(sum(v ** 2 for v in vec_a.values()))
    norm_b = math.sqrt(sum(v ** 2 for v in vec_b.values()))

    if norm_a == 0 or norm_b == 0:
        return 0.0
    return dot / (norm_a * norm_b)


def weighted_fusion(
    vectors: List[Dict[str, float]],
    weights: List[float],
) -> Dict[str, float]:
    """
    Weighted fusion of multiple emotion vectors.
    Used in 5-layer emotion inference.
    """
    if not vectors or not weights:
        return {}

    total_weight = sum(weights)
    if total_weight == 0:
        return vectors[0] if vectors else {}

    keys = set()
    for v in vectors:
        keys.update(v.keys())

    result = {}
    for k in keys:
        result[k] = sum(
            v.get(k, 0) * w for v, w in zip(vectors, weights)
        ) / total_weight

    return normalize_vector(result)


def normalize_vector(vector: Dict[str, float]) -> Dict[str, float]:
    """Normalize emotion vector so values sum to 1.0."""
    total = sum(vector.values())
    if total == 0:
        return vector
    return {k: v / total for k, v in vector.items()}


def euclidean_distance(vec_a: Dict[str, float], vec_b: Dict[str, float]) -> float:
    """Euclidean distance between two emotion vectors."""
    keys = set(vec_a.keys()) | set(vec_b.keys())
    return math.sqrt(
        sum((vec_a.get(k, 0) - vec_b.get(k, 0)) ** 2 for k in keys)
    )


def dominant_emotion(vector: Dict[str, float]) -> str:
    """Get the dominant emotion from a vector."""
    if not vector:
        return "neutral"
    return max(vector, key=vector.get)
