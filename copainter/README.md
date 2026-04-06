# Minimal FastAPI Backend

Small Python backend for an iOS SwiftUI app. It accepts an uploaded image,
saves it locally, and returns a fake JSON response.

## Project Structure

```text
project/
|-- main.py
|-- routes/
|   `-- generate.py
|-- services/
|   `-- image_service.py
`-- uploads/
```

## What Each File Does

- [main.py](/workspaces/iOS_apps/main.py) creates the FastAPI app, includes routes, creates the `uploads/` folder, and serves uploaded files statically.
- [routes/generate.py](/workspaces/iOS_apps/routes/generate.py) defines the `POST /generate-outline` endpoint.
- [services/image_service.py](/workspaces/iOS_apps/services/image_service.py) contains the file-saving logic.
- `uploads/` stores uploaded files locally and is created automatically when the app starts or when the first file is saved.

## API Response

The endpoint returns JSON in this shape:

```json
{
  "image_id": "string",
  "result_image_url": "http://localhost:8000/uploads/<filename>",
  "status": "completed"
}
```

## Install Dependencies

FastAPI file uploads require `python-multipart`.

```bash
pip install fastapi uvicorn python-multipart
```

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
  "result_image_url": "http://127.0.0.1:8000/uploads/2b7c7b5f-3d84-4b9c-92a5-4fd72b74b440_test.jpg",
  "status": "completed"
}
```

## Notes

- This version is intentionally minimal.
- There is no database, authentication, AWS setup, or image processing yet.
- The fake response shape matches what the iOS app expects.
