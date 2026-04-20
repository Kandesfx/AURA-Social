"""
AURA Social – ML Model Loader
Loads HuggingFace models at startup.
"""
from typing import Optional


class ModelLoader:
    """
    Lazy-loads ML models khi cần.

    TODO (Person 2): Implement actual model loading
    - Emotion model: nlptown/bert-base-multilingual-uncased-sentiment
    - Embedding model: sentence-transformers/all-MiniLM-L6-v2
    """

    def __init__(self):
        self.emotion_model = None
        self.embedding_model = None
        self._loaded = False

    def load_all(self):
        """Load all models at startup."""
        if self._loaded:
            return

        print("📦 Loading ML models...")

        # TODO: Uncomment khi implement
        # from transformers import pipeline, AutoModel, AutoTokenizer
        #
        # self.emotion_model = pipeline(
        #     "sentiment-analysis",
        #     model="nlptown/bert-base-multilingual-uncased-sentiment",
        # )
        #
        # self.embedding_model = AutoModel.from_pretrained(
        #     "sentence-transformers/all-MiniLM-L6-v2"
        # )

        self._loaded = True
        print("✅ All models loaded (placeholder)")

    def get_emotion_model(self):
        """Get emotion analysis model."""
        if not self._loaded:
            self.load_all()
        return self.emotion_model

    def get_embedding_model(self):
        """Get text embedding model."""
        if not self._loaded:
            self.load_all()
        return self.embedding_model
