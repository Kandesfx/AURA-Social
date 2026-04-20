"""
AURA Social – Cloudflare R2 Storage Service
S3-compatible object storage for avatars, post images, etc.
"""
import boto3
from botocore.config import Config as BotoConfig
from fastapi import UploadFile
from typing import Optional
import uuid
from app.config import get_settings


class R2StorageService:
    """Cloudflare R2 storage client (S3-compatible)."""

    def __init__(self):
        settings = get_settings()
        self.bucket_name = settings.r2_bucket_name
        self.public_url = settings.r2_public_url

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

    async def upload_file(
        self,
        file: UploadFile,
        folder: str = "uploads",
        custom_filename: Optional[str] = None,
    ) -> str:
        """
        Upload file to R2 and return public URL.

        Args:
            file: FastAPI UploadFile
            folder: Subfolder in bucket (e.g., 'avatars', 'posts')
            custom_filename: Optional custom filename

        Returns:
            Public URL of the uploaded file
        """
        # Generate unique filename
        ext = file.filename.split(".")[-1] if file.filename else "jpg"
        filename = custom_filename or f"{uuid.uuid4().hex}.{ext}"
        key = f"{folder}/{filename}"

        # Read file content
        content = await file.read()

        # Upload to R2
        self.client.put_object(
            Bucket=self.bucket_name,
            Key=key,
            Body=content,
            ContentType=file.content_type or "application/octet-stream",
        )

        # Return public URL
        return f"{self.public_url}/{key}"

    async def delete_file(self, file_url: str) -> bool:
        """Delete a file from R2 by its URL."""
        try:
            # Extract key from URL
            key = file_url.replace(f"{self.public_url}/", "")
            self.client.delete_object(Bucket=self.bucket_name, Key=key)
            return True
        except Exception:
            return False

    async def upload_avatar(self, user_id: str, file: UploadFile) -> str:
        """Upload user avatar. Overwrites existing."""
        ext = file.filename.split(".")[-1] if file.filename else "jpg"
        return await self.upload_file(
            file, folder="avatars", custom_filename=f"{user_id}.{ext}"
        )

    async def upload_post_image(self, post_id: str, file: UploadFile) -> str:
        """Upload post image."""
        return await self.upload_file(file, folder=f"posts/{post_id}")


# Singleton instance
_storage: Optional[R2StorageService] = None


def get_storage() -> R2StorageService:
    """Get or create R2 storage service singleton."""
    global _storage
    if _storage is None:
        _storage = R2StorageService()
    return _storage
