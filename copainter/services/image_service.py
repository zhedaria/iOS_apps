"""Service functions for working with uploaded images.

This file keeps file-saving logic separate from the API route so the route
stays easy to read and later changes are easier to make.
"""

from pathlib import Path
from uuid import uuid4

from fastapi import UploadFile


UPLOADS_DIR = Path("uploads")


async def save_uploaded_image(file: UploadFile) -> tuple[str, str]:
    """Save an uploaded image locally and return its IDs.

    Returns:
        tuple[str, str]:
            - image_id: a UUID string for the uploaded image
            - saved_filename: the filename written to the uploads folder
    """

    UPLOADS_DIR.mkdir(exist_ok=True)

    image_id = str(uuid4())
    saved_filename = f"{image_id}_{file.filename}"
    file_path = UPLOADS_DIR / saved_filename

    print(f"Saving uploaded file: original_name={file.filename}")
    print(f"Generated image_id={image_id}")
    print(f"Writing file to: {file_path}")

    # Read the uploaded file into memory and write it to local disk.
    # TODO: For large files, switch to chunked streaming instead of reading all at once.
    contents = await file.read()
    print(f"Read {len(contents)} bytes from upload")
    file_path.write_bytes(contents)
    print("File saved successfully")

    return image_id, saved_filename
