"""
AURA Social – FastAPI Configuration
Loads environment variables and initializes Firebase Admin SDK.
"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from .env file."""

    # API
    api_host: str = "0.0.0.0"
    api_port: int = 8080
    api_debug: bool = True
    api_version: str = "1.0.0"

    # Firebase
    firebase_service_account_path: str = "./service-account.json"

    # Cloudflare R2
    r2_account_id: str = ""
    r2_access_key_id: str = ""
    r2_secret_access_key: str = ""
    r2_bucket_name: str = "aura-social-media"
    r2_public_url: str = ""

    # Security
    internal_api_key: str = ""
    cors_origins: str = "http://localhost:3000,http://localhost:8080"

    # ML Models
    emotion_model: str = "nlptown/bert-base-multilingual-uncased-sentiment"
    embedding_model: str = "sentence-transformers/all-MiniLM-L6-v2"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    """Cached settings instance."""
    return Settings()
