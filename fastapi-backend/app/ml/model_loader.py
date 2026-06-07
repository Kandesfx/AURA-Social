"""
AURA Social – ML Model Loader
Loads HuggingFace models at startup/demand.
"""
from typing import Optional, List
import torch
import numpy as np
from transformers import pipeline, AutoModel, AutoTokenizer
from app.config import get_settings


class ModelLoader:
    """
    Lazy-loads ML models when needed to optimize memory and startup time.
    """

    def __init__(self):
        self.emotion_model = None
        self.embedding_model = None
        self.embedding_tokenizer = None
        self._loaded = False

    def load_all(self):
        """Load all models."""
        if self._loaded:
            return

        print("📦 Loading ML models...")
        settings = get_settings()

        # 1. Load Emotion / Sentiment analysis model
        try:
            self.emotion_model = pipeline(
                "sentiment-analysis",
                model=settings.emotion_model,
                device="cuda" if torch.cuda.is_available() else "cpu"
            )
            print(f"✅ Loaded Emotion Model: {settings.emotion_model}")
        except Exception as e:
            print(f"❌ Failed to load Emotion Model: {e}")

        # 2. Load Text Embedding model
        try:
            self.embedding_tokenizer = AutoTokenizer.from_pretrained(settings.embedding_model)
            self.embedding_model = AutoModel.from_pretrained(settings.embedding_model)
            # Set to evaluation mode
            self.embedding_model.eval()
            if torch.cuda.is_available():
                self.embedding_model = self.embedding_model.to("cuda")
            print(f"✅ Loaded Embedding Model: {settings.embedding_model}")
        except Exception as e:
            print(f"❌ Failed to load Embedding Model: {e}")

        self._loaded = True
        print("✅ All models loaded")

    def get_emotion_model(self):
        """Get emotion analysis model pipeline."""
        if not self._loaded:
            self.load_all()
        return self.emotion_model

    def get_embedding_model_pair(self):
        """Get embedding model and tokenizer."""
        if not self._loaded:
            self.load_all()
        return self.embedding_model, self.embedding_tokenizer

    def get_sentence_embedding(self, text: str) -> List[float]:
        """
        Generate 384-dimensional sentence embedding using mean pooling.
        """
        if not self._loaded:
            self.load_all()

        if self.embedding_model is None or self.embedding_tokenizer is None:
            # Fallback to zero vector if loading failed
            return [0.0] * 384

        try:
            # Tokenize text
            encoded_input = self.embedding_tokenizer(
                [text],
                padding=True,
                truncation=True,
                max_length=512,
                return_tensors='pt'
            )

            # Move tensors to same device as model
            device = next(self.embedding_model.parameters()).device
            encoded_input = {k: v.to(device) for k, v in encoded_input.items()}

            # Run inference
            with torch.no_grad():
                model_output = self.embedding_model(**encoded_input)

            # Perform Mean Pooling
            token_embeddings = model_output[0]  # First element contains token embeddings
            attention_mask = encoded_input['attention_mask']
            input_mask_expanded = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
            
            # Sum embeddings along token dimension, then divide by mask sum
            sum_embeddings = torch.sum(token_embeddings * input_mask_expanded, 1)
            sum_mask = torch.clamp(input_mask_expanded.sum(1), min=1e-9)
            embedding = (sum_embeddings / sum_mask).cpu().numpy()[0]

            # Normalize embedding vector
            norm = np.linalg.norm(embedding)
            if norm > 0:
                embedding = embedding / norm

            return embedding.tolist()
        except Exception as e:
            print(f"⚠️ Error generating embedding: {e}")
            return [0.0] * 384


# Singleton instance of ModelLoader
model_loader = ModelLoader()
