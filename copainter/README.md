# Minimal FastAPI Backend

Small Python backend for an iOS SwiftUI app. It accepts an uploaded image,
saves it locally, sends that image to OpenAI to generate a clean outline
version, saves the generated outline locally, and returns the outline image URL
in JSON. It also keeps a simple local metadata history for gallery-style
loading.

## Project Structure

```text
project/
|-- main.py
|-- routes/
|   `-- generate.py
|-- services/
|   |-- image_service.py
|   |-- metadata_service.py
|   `-- openai_image_service.py
|-- data/
|   `-- uploads_metadata.json
`-- uploads/
```

## What Each File Does

- `main.py` creates the FastAPI app, includes routes, creates the `uploads/` folder, and serves uploaded files statically.
- `routes/generate.py` defines the `POST /generate-outline` endpoint and returns the JSON response expected by the iOS app.
- `services/image_service.py` saves the original uploaded image locally and returns its file information.
- `services/metadata_service.py` stores and loads simple upload history records from a local JSON file.
- `services/openai_image_service.py` reads the saved upload, calls OpenAI with the fixed outline prompt, and saves the generated outline image locally.
- `data/uploads_metadata.json` stores one metadata record per successful upload/generation.
- `uploads/` stores both the original uploaded image and the generated outline image.

## API Response

The endpoint returns JSON in this shape:

```json
{
  "image_id": "string",
  "result_image_url": "http://localhost:8000/uploads/<filename>",
  "status": "completed"
}
```

## Upload History Endpoint

The backend also exposes:

```text
GET /uploads
```

This returns all metadata records in newest-first order for a simple local
gallery/history view.

## Install Dependencies

FastAPI file uploads require `python-multipart`, OpenAI image generation
requires the official `openai` Python SDK, and local `.env` loading uses
`python-dotenv`.

```bash
pip install fastapi uvicorn python-multipart openai python-dotenv
```

## Environment Variables

Set this environment variable before running the server:

```bash
export OPENAI_API_KEY="your_openai_api_key_here"
```

This project also loads `copainter/.env` automatically at startup for local
development, so putting `OPENAI_API_KEY=...` in that file now works too.

## Run The Server

```bash
uvicorn main:app --reload
```

The server will run at:

```text
http://127.0.0.1:8000
```

## Test The Endpoint With curl

```bash
curl -X POST \
  -F "file=@test.jpg" \
  http://127.0.0.1:8000/generate-outline
```

Example response:

```json
{
  "image_id": "2b7c7b5f-3d84-4b9c-92a5-4fd72b74b440",
  "result_image_url": "http://127.0.0.1:8000/uploads/2b7c7b5f-3d84-4b9c-92a5-4fd72b74b440_outline.png",
  "status": "completed"
}
```

## Notes

- This version is intentionally minimal.
- The `POST /generate-outline` route is unchanged, but it now returns the generated outline image URL instead of the original upload URL.
- Successful generations are also written to `data/uploads_metadata.json`.
- `GET /uploads` returns the saved metadata history in newest-first order.
- The fixed outline prompt lives in `services/openai_image_service.py` as `OUTLINE_PROMPT`.
- There is no database, authentication, AWS setup, or background job system.
- If you want different outline behavior later, edit `OUTLINE_PROMPT` in one place.
