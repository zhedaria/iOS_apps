"""Main FastAPI application entrypoint.

This file creates the FastAPI app, makes sure the uploads folder exists,
registers API routes, and exposes uploaded files as static files.
"""

from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from routes.generate import router as generate_router


# Store uploaded files in a local folder beside the app code.
UPLOADS_DIR = Path("uploads")
UPLOADS_DIR.mkdir(exist_ok=True)

app = FastAPI(title="Minimal iOS App Backend")

# Register API endpoints from the routes package.
app.include_router(generate_router)

# Serve uploaded files so the frontend can access them by URL.
app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")
