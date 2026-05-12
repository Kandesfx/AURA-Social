"""
AURA Social – Firebase Admin SDK Utilities

Hỗ trợ 2 cách khởi tạo:
1. Local dev: Dùng file service-account.json
2. Cloud Run: Dùng biến môi trường FIREBASE_SERVICE_ACCOUNT_JSON
   hoặc tự động detect credentials (IAM)
"""
import os
import json
import tempfile
import firebase_admin
from firebase_admin import credentials, firestore, auth, db as rtdb
from app.config import get_settings


def init_firebase():
    """
    Initialize Firebase Admin SDK.

    Ưu tiên:
    1. FIREBASE_SERVICE_ACCOUNT_JSON env var (Cloud Run)
    2. service-account.json file (Local dev)
    3. Application Default Credentials (GCP managed)
    """
    if firebase_admin._apps:
        return firebase_admin.get_app()

    settings = get_settings()
    cred = None
    db_url = f"https://aura-social-vn-default-rtdb.firebaseio.com"

    # Cách 1: JSON string từ env var (dùng trên Cloud Run / Railway)
    json_str = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON")
    if json_str:
        service_info = json.loads(json_str)
        cred = credentials.Certificate(service_info)
        print("🔑 Firebase init: from env var FIREBASE_SERVICE_ACCOUNT_JSON")

    # Cách 2: File service-account.json (dùng local dev)
    elif os.path.exists(settings.firebase_service_account_path):
        cred = credentials.Certificate(settings.firebase_service_account_path)
        print(f"🔑 Firebase init: from file {settings.firebase_service_account_path}")

    # Cách 3: Application Default Credentials (GCP managed)
    else:
        cred = credentials.ApplicationDefault()
        print("🔑 Firebase init: from Application Default Credentials")

    firebase_admin.initialize_app(cred, {
        "databaseURL": db_url,
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
