"""
AURA Social – Cloudflare R2 Storage Service
S3-compatible object storage for avatars, post images, etc.
"""
import asyncio
import logging
import boto3
from botocore.config import Config as BotoConfig
from fastapi import UploadFile
from typing import Optional
import uuid
from app.config import get_settings

logger = logging.getLogger(__name__)


def _get_accessible_base_url(request=None) -> str:
    """
    Build an accessible base URL from the incoming request.
    
    Replaces host bindings like 0.0.0.0 that are unreachable from
    client devices with 10.0.2.2 (Android emulator → host machine).
    For physical devices, set API_URL to the machine's LAN IP.
    """
    if request:
        base_url = str(request.base_url).rstrip("/")
        # 0.0.0.0 is the server bind address – not reachable from clients
        base_url = base_url.replace("://0.0.0.0:", "://10.0.2.2:")
        base_url = base_url.replace("://0.0.0.0", "://10.0.2.2")
        return base_url
    return "http://10.0.2.2:8000"


class R2StorageService:
    """Cloudflare R2 storage client (S3-compatible)."""

    def __init__(self):
        settings = get_settings()
        self.bucket_name = settings.r2_bucket_name
        self.public_url = settings.r2_public_url

        # Check if R2 is configured correctly
        self.is_r2_configured = True
        if not settings.r2_account_id or settings.r2_account_id in ("", "your_cloudflare_account_id"):
            self.is_r2_configured = False
        if not settings.r2_access_key_id or settings.r2_access_key_id in ("", "your_r2_access_key"):
            self.is_r2_configured = False
        if not settings.r2_secret_access_key or settings.r2_secret_access_key in ("", "your_r2_secret_key"):
            self.is_r2_configured = False

        if self.is_r2_configured:
            try:
                self.client = boto3.client(
                    "s3",
                    endpoint_url=f"https://{settings.r2_account_id}.r2.cloudflarestorage.com",
                    aws_access_key_id=settings.r2_access_key_id,
                    aws_secret_access_key=settings.r2_secret_access_key,
                    config=BotoConfig(
                        signature_version="s3v4",
                        region_name="auto",
                    ),
                )
            except Exception as e:
                print(f"⚠️ Failed to init boto3 client, falling back to local storage: {e}")
                self.is_r2_configured = False
        else:
            print("⚠️ Cloudflare R2 is not fully configured. Using local storage fallback.")

    async def upload_file(
        self,
        file: UploadFile,
        folder: str = "uploads",
        custom_filename: Optional[str] = None,
        request = None,
    ) -> str:
        """
        Upload file to R2 and return public URL. Fallback to local storage if R2 is not configured.

        Args:
            file: FastAPI UploadFile
            folder: Subfolder in bucket (e.g., 'avatars', 'posts')
            custom_filename: Optional custom filename
            request: Optional FastAPI Request to build local URL

        Returns:
            Public URL of the uploaded file
        """
        # Generate unique filename
        ext = file.filename.split(".")[-1] if file.filename else "jpg"
        filename = custom_filename or f"{uuid.uuid4().hex}.{ext}"
        key = f"{folder}/{filename}"

        # Read file content
        content = await file.read()

        if self.is_r2_configured:
            # Upload to R2 using executor (put_object is synchronous/blocking)
            try:
                loop = asyncio.get_event_loop()
                await loop.run_in_executor(
                    None,
                    lambda: self.client.put_object(
                        Bucket=self.bucket_name,
                        Key=key,
                        Body=content,
                        ContentType=file.content_type or "application/octet-stream",
                    ),
                )
                logger.info(f"✅ R2 upload success: {key} ({len(content)} bytes)")
            except Exception as e:
                logger.error(f"❌ R2 upload failed for {key}: {e}")
                raise
            # Return public URL
            return f"{self.public_url}/{key}"
        else:
            # Save file locally
            import os
            target_dir = os.path.join("static", folder)
            os.makedirs(target_dir, exist_ok=True)
            target_path = os.path.join(target_dir, filename)

            with open(target_path, "wb") as f:
                f.write(content)

            # Return accessible local URL based on incoming request
            base_url = _get_accessible_base_url(request)
            return f"{base_url}/static/{key}"

    async def delete_file(self, file_url: str) -> bool:
        """Delete a file from R2 or local storage by its URL."""
        try:
            # Extract key from URL (strip query parameters first)
            clean_url = file_url.split("?")[0]
            
            if self.is_r2_configured:
                key = clean_url.replace(f"{self.public_url}/", "")
                self.client.delete_object(Bucket=self.bucket_name, Key=key)
                return True
            else:
                import os
                if "/static/" in clean_url:
                    key = clean_url.split("/static/")[-1]
                    local_path = os.path.join("static", key)
                    if os.path.exists(local_path):
                        os.remove(local_path)
                        return True
                return False
        except Exception:
            return False

    async def upload_avatar(self, user_id: str, file: UploadFile, request = None) -> str:
        """Upload user avatar. Overwrites existing."""
        import time
        ext = file.filename.split(".")[-1] if file.filename else "jpg"
        url = await self.upload_file(
            file, folder="avatars", custom_filename=f"{user_id}.{ext}", request=request
        )
        return f"{url}?t={int(time.time())}"

    async def upload_post_image(self, post_id: str, file: UploadFile, request = None) -> str:
        """Upload post image."""
        return await self.upload_file(file, folder=f"posts/{post_id}", request=request)


# Singleton instance
_storage: Optional[R2StorageService] = None


def get_storage() -> R2StorageService:
    """Get or create R2 storage service singleton."""
    global _storage
    if _storage is None:
        _storage = R2StorageService()
    return _storage
