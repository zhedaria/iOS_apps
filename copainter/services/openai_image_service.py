"""Service functions for generating outline images with OpenAI.

This file reads a saved local upload, sends it to OpenAI with a fixed outline
prompt, saves the generated outline into uploads/, and returns the new file
information back to the route.
"""

import base64
import os
from pathlib import Path

from openai import OpenAI


UPLOADS_DIR = Path("uploads")
OUTLINE_PROMPT = (
    "Create a clean black-and-white outline version of this image. Preserve the "
    "original composition and the main subject. Use crisp contour lines on a "
    "plain white background. Remove unnecessary background detail, textures, "
    "and shading. Do not add new objects. The result should look like a simple "
    "painting or drawing outline guide."
)


def generate_outline_image(source_image_path: Path, image_id: str) -> tuple[str, Path]:
    """Generate an outline image from a saved upload and store it locally.

    Prompt changes should be made in OUTLINE_PROMPT above so there is one clear
    place to edit the outline behavior later.
    """

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY is not set.")

    if not source_image_path.exists():
        raise RuntimeError(f"Uploaded source image was not found: {source_image_path}")

    UPLOADS_DIR.mkdir(exist_ok=True)

    outline_filename = f"{image_id}_outline.png"
    outline_path = UPLOADS_DIR / outline_filename

    print(f"OpenAI outline generation starting for: {source_image_path}")

    try:
        client = OpenAI(api_key=api_key)

        with source_image_path.open("rb") as image_file:
            result = client.images.edit(
                model="gpt-image-1-mini", # generating outline is deterministic, no texture or photorealistic complexity -> using cost-efficient image model
                image=image_file,
                prompt=OUTLINE_PROMPT,
                input_fidelity="low",
            )

        image_base64 = result.data[0].b64_json
        if not image_base64:
            raise RuntimeError("OpenAI returned no image data.")

        image_bytes = base64.b64decode(image_base64)
        outline_path.write_bytes(image_bytes)

        print("OpenAI outline generation succeeded")
        print(f"Generated outline save path: {outline_path}")

        return outline_filename, outline_path
    except Exception as exc:
        print(f"OpenAI outline generation failed: {exc}")
        raise RuntimeError(f"Failed to generate outline image: {exc}") from exc
