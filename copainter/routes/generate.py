"""API routes for image-generation endpoints used by the iOS app.

This file keeps the HTTP request/response flow simple: validate the upload,
save it locally, generate an outline image with OpenAI, and return the final
outline URL in the same JSON shape the app already expects.
"""

from fastapi import APIRouter, File, HTTPException, Request, UploadFile

from services.image_service import save_uploaded_image
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

    response = {
        "image_id": image_id,
        "result_image_url": f"{base_url}/uploads/{outline_filename}",
        "status": "completed",
    }

    print(f"Returning JSON response: {response}")

    return response
