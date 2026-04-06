"""API routes for image-generation endpoints used by the iOS app.

This file keeps the HTTP request/response flow simple: validate the upload,
save it locally, generate an outline image with OpenAI, and return the final
outline URL in the same JSON shape the app already expects. It also exposes a
simple GET /uploads endpoint for local gallery history.
"""

from datetime import datetime, timezone

from fastapi import APIRouter, File, HTTPException, Request, UploadFile

from services.image_service import save_uploaded_image
from services.metadata_service import (
    append_metadata_record,
    get_all_metadata_records_newest_first,
)
from services.openai_image_service import generate_outline_image


router = APIRouter()


@router.post("/generate-outline")
async def generate_outline(request: Request, file: UploadFile = File(...)) -> dict:
    """Accept an uploaded image, generate an outline image, and return its URL."""

    print("POST /generate-outline request received")

    if not file.filename:
        print("Request rejected: no filename was provided")
        raise HTTPException(status_code=400, detail="A file must be provided.")

    image_id, _saved_upload_filename, saved_upload_path = await save_uploaded_image(file)

    try:
        outline_filename, _outline_path = generate_outline_image(
            source_image_path=saved_upload_path,
            image_id=image_id,
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    base_url = str(request.base_url).rstrip("/")
    original_image_url = f"{base_url}/uploads/{saved_upload_path.name}"
    result_image_url = f"{base_url}/uploads/{outline_filename}"

    metadata_record = {
        "image_id": image_id,
        "original_image_url": original_image_url,
        "result_image_url": result_image_url,
        "status": "completed",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "original_filename": saved_upload_path.name,
        "result_filename": outline_filename,
    }

    try:
        append_metadata_record(metadata_record)
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    response = {
        "image_id": image_id,
        "result_image_url": result_image_url,
        "status": "completed",
    }

    print(f"Returning JSON response: {response}")

    return response


@router.get("/uploads")
async def get_uploads() -> list[dict]:
    """Return all saved upload metadata records with newest items first."""

    print("GET /uploads request received")

    try:
        records = get_all_metadata_records_newest_first()
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    print(f"Returning {len(records)} upload metadata records")
    return records
