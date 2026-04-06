"""API routes for image generation-related endpoints.

Right now this file contains one simple endpoint that accepts an uploaded
image, saves it locally, and returns a fake completed response.
"""

from fastapi import APIRouter, File, HTTPException, Request, UploadFile

from services.image_service import save_uploaded_image


router = APIRouter()


@router.post("/generate-outline")
async def generate_outline(request: Request, file: UploadFile = File(...)) -> dict:
    """Accept an image upload and return a fake completed response.

    The file is saved locally using a UUID-based prefix so filenames stay
    unique while still preserving the original filename for readability.
    """

    print("POST /generate-outline request received")

    if not file.filename:
        print("Request rejected: no filename was provided")
        raise HTTPException(status_code=400, detail="A file must be provided.")

    image_id, saved_filename = await save_uploaded_image(file)

    base_url = str(request.base_url).rstrip("/")

    response = {
        "image_id": image_id,
        "result_image_url": f"{base_url}/uploads/{saved_filename}",
        "status": "completed",
    }

    print(f"Returning JSON response: {response}")

    return response
