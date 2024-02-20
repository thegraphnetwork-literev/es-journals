import json
from pathlib import Path

import typer
from loguru import logger

app = typer.Typer()

logger.add("/tmp/merge_arxiv_data_{time}.log", rotation="10 MB", level="INFO")


@app.command()
def merge_json_files(full_data_path: Path, downloaded_data_path: Path):
    """
    Merge the data from a new JSON file into an existing JSON file, avoiding duplicates based on the 'title' and 'version' fields.
    """
    existing_titles_versions = set()
    existing_data = []

    # Load existing data
    if full_data_path.exists():
        with full_data_path.open("r", encoding="utf-8") as f:
            existing_data = json.load(f)
            for entry in existing_data:
                unique_key = f"{entry.get('title', '')}_{entry.get('version', '')}"
                existing_titles_versions.add(unique_key)

    # Load new data
    try:
        with downloaded_data_path.open("r", encoding="utf-8") as f:
            new_data = json.load(f)
            new_entries_added = 0

            for entry in new_data:
                unique_key = f"{entry.get('title', '')}_{entry.get('version', '')}"
                if unique_key not in existing_titles_versions:
                    existing_data.append(entry)
                    new_entries_added += 1

            logger.info(f"Added {new_entries_added} new entries.")

    except FileNotFoundError:
        logger.error(f"Downloaded data file not found: {downloaded_data_path}")

    # Save merged data
    with full_data_path.open("w", encoding="utf-8") as f:
        json.dump(existing_data, f, indent=4)
        logger.info(f"Merged data saved to {full_data_path}")


if __name__ == "__main__":
    app()
