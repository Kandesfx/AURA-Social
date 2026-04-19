"""
AURA Social – Upload Router
File upload endpoints using Cloudflare R2.
"""
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from app.auth import get_current_user
from app.services.storage import get_storage

router = APIRouter()

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB


@router.post("/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    user: dict = Depends(get_current_user),
):
    """Upload/update user avatar."""
    _validate_image(file)
    storage = get_storage()
    url = await storage.upload_avatar(user["uid"], file)
    return {"url": url, "message": "Avatar uploaded successfully"}


@router.post("/post-image/{post_id}")
async def upload_post_image(
    post_id: str,
    file: UploadFile = File(...),
    user: dict = Depends(get_current_user),
):
    """Upload image for a post."""
    _validate_image(file)
    storage = get_storage()
    url = await storage.upload_post_image(post_id, file)
    return {"url": url, "message": "Post image uploaded successfully"}


@router.delete("/file")
async def delete_file(
    file_url: str,
    user: dict = Depends(get_current_user),
):
    """Delete a file from R2."""
    storage = get_storage()
    success = await storage.delete_file(file_url)
    if not success:
        raise HTTPException(status_code=404, detail="File not found")
    return {"message": "File deleted successfully"}


def _validate_image(file: UploadFile):
    """Validate image file type and size."""
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"File type not allowed. Allowed: {ALLOWED_IMAGE_TYPES}",
        )
    if file.size and file.size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"File too large. Max: {MAX_FILE_SIZE // (1024*1024)}MB",
        )
