"""Service functions for saving uploaded files to the local uploads folder.

This file keeps upload-specific filesystem logic separate from the API route so
the route stays small and easy to follow.
"""

from pathlib import Path
from uuid import uuid4

from fastapi import UploadFile


UPLOADS_DIR = Path("uploads")


def build_upload_path(image_id: str, original_filename: str) -> Path:
    """Build a safe local path for an uploaded file.

    The UUID keeps filenames unique, and Path(...).name strips any directory
    parts so only the actual filename is used.
    """

    safe_original_name = Path(original_filename).name or "uploaded_image"
    return UPLOADS_DIR / f"{image_id}_{safe_original_name}"


async def save_uploaded_image(file: UploadFile) -> tuple[str, str, Path]:
    """Save an uploaded image locally and return the identifiers for later work.

    Returns:
        tuple[str, str, Path]:
            - image_id: UUID string used to group files for this request
            - saved_filename: the filename written into uploads/
            - file_path: the full local path to the saved upload
    """

    UPLOADS_DIR.mkdir(exist_ok=True)

    image_id = str(uuid4())
    file_path = build_upload_path(image_id=image_id, original_filename=file.filename or "")

    print(f"Saving uploaded file: original_name={file.filename}")
    print(f"Generated image_id={image_id}")
    print(f"Original file save path: {file_path}")

    # Read the uploaded file into memory and write it to local disk.
    # TODO: For large files, switch to chunked streaming instead of reading all at once.
    contents = await file.read()
    print(f"Read {len(contents)} bytes from upload")
    file_path.write_bytes(contents)
    print("Original upload saved successfully")

    return image_id, file_path.name, file_path
