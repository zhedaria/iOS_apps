"""Service functions for storing simple local upload metadata in JSON.

This file keeps history/gallery persistence separate from the route so the API
layer can stay small and beginner-friendly.
"""

import json
from pathlib import Path
from typing import Any


DATA_DIR = Path("data")
METADATA_FILE = DATA_DIR / "uploads_metadata.json"


def ensure_metadata_file_exists() -> Path:
    """Create the metadata folder and JSON file if they do not exist yet."""

    DATA_DIR.mkdir(exist_ok=True)

    if not METADATA_FILE.exists():
        METADATA_FILE.write_text("[]\n", encoding="utf-8")
        print(f"Metadata file created: {METADATA_FILE}")

    return METADATA_FILE


def load_metadata_records() -> list[dict[str, Any]]:
    """Load all metadata records from disk.

    Returns an empty list when the file is empty. Raises a useful error if the
    file contains malformed JSON or an unexpected JSON shape.
    """

    metadata_file = ensure_metadata_file_exists()
    raw_text = metadata_file.read_text(encoding="utf-8").strip()

    if not raw_text:
        return []

    try:
        records = json.loads(raw_text)
    except json.JSONDecodeError as exc:
        raise RuntimeError(
            f"Metadata file is malformed: {metadata_file}. Fix or replace the JSON file."
        ) from exc

    if not isinstance(records, list):
        raise RuntimeError(
            f"Metadata file must contain a JSON array: {metadata_file}"
        )

    return records


def append_metadata_record(record: dict[str, Any]) -> None:
    """Append one upload record to the local metadata JSON file."""

    records = load_metadata_records()
    records.append(record)
    ensure_metadata_file_exists().write_text(
        json.dumps(records, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Metadata record appended for image_id={record['image_id']}")


def get_all_metadata_records_newest_first() -> list[dict[str, Any]]:
    """Return all metadata records sorted with the newest records first."""

    records = load_metadata_records()
    return sorted(
        records,
        key=lambda record: record.get("created_at", ""),
        reverse=True,
    )
