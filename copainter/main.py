"""Main FastAPI application entrypoint for the copainter backend.

This file creates the FastAPI app, makes sure the uploads folder exists,
registers API routes, and exposes uploaded files as static files so the iOS app
can load generated outline images from returned URLs.
"""

from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from routes.generate import router as generate_router


# Store uploaded files in a local folder beside the app code.
UPLOADS_DIR = Path("uploads")
UPLOADS_DIR.mkdir(exist_ok=True)

# Load local environment variables from copainter/.env for local development.
load_dotenv()

app = FastAPI(title="Minimal iOS App Backend")

# Register API endpoints from the routes package.
app.include_router(generate_router)

# Serve uploaded files so the frontend can access them by URL.
app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")
