"""
AURA Social – Firebase Admin SDK Utilities
"""
import firebase_admin
from firebase_admin import credentials, firestore, auth, db as rtdb
from app.config import get_settings


def init_firebase():
    """Initialize Firebase Admin SDK."""
    settings = get_settings()
    if not firebase_admin._apps:
        cred = credentials.Certificate(settings.firebase_service_account_path)
        firebase_admin.initialize_app(cred, {
            "databaseURL": f"https://{settings.firebase_service_account_path.split('/')[-1].replace('.json','')}.firebaseio.com"
        })
    return firebase_admin.get_app()


def get_firestore():
    """Get Firestore client."""
    return firestore.client()


def get_rtdb():
    """Get Realtime Database reference."""
    return rtdb.reference()


def verify_firebase_token(id_token: str) -> dict:
    """
    Verify Firebase ID token from Flutter client.

    Returns:
        Decoded token with uid, email, etc.

    Raises:
        firebase_admin.auth.InvalidIdTokenError
    """
    return auth.verify_id_token(id_token)
