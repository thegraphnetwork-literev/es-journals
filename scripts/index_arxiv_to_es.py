import json
import os
import time
from pathlib import Path
import hashlib
import typer
from dotenv import load_dotenv
from elasticsearch import Elasticsearch, exceptions
from loguru import logger

load_dotenv()

app = typer.Typer()

index_name_placeholder = "index_name"
log_filename = (
    f"/tmp/elasticrxivx_{index_name_placeholder}_{time.strftime('%Y%m%d-%H%M%S')}.log"
)

ES_HOSTNAME = os.getenv("ES_HOSTNAME", "https://localhost:9200")
ES_USERNAME = os.getenv("ES_USERNAME", "elastic")
ES_PASSWORD = os.getenv("ES_PASSWORD", "")


def create_es_client(host: str, username: str, password: str) -> Elasticsearch:
    return Elasticsearch([host], basic_auth=(username, password), verify_certs=False)


def generate_document_id(doc: dict) -> str:
    doc_string = json.dumps(doc, sort_keys=True)
    return hashlib.sha256(doc_string.encode("utf-8")).hexdigest()


def document_exists(es_client: Elasticsearch, index_name: str, doc_id: str) -> bool:
    try:
        return es_client.exists(index=index_name, id=doc_id)
    except exceptions.NotFoundError:
        return False


def index_json_data(es_client: Elasticsearch, file_path: str, index_name: str) -> None:
    try:
        with open(file_path, "r", encoding="utf-8") as file:
            data = json.load(file)

        successful_docs = 0
        for doc in data:
            doc_id = generate_document_id(doc)
            if not document_exists(es_client, index_name, doc_id):
                try:
                    res = es_client.index(index=index_name, id=doc_id, document=doc)
                    successful_docs += 1
                except Exception as doc_error:
                    logger.error(f"Failed to index document: {doc_error}")
            else:
                logger.info(f"Document with ID {doc_id} already exists. Skipping.")

        logger.info(
            f"Total new documents indexed successfully: {successful_docs}/{len(data)}"
        )
    except Exception as e:
        logger.error(f"Failed to index data for {index_name}: {e}")


def find_arxiv_path(index_name: str) -> Path:
    """
    Finds the most recent JSON file path for the specified index name.

    Parameters:
        index_name (str): The name of the index (e.g., "biorxiv" or "medrxiv").

    Returns:
        Path: The Path object pointing to the most recent JSON file.
    """
    base_dir = Path(__file__).resolve().parent.parent
    pattern = f"data/rxivx/{index_name}/downloaded/{index_name}_*.json"
    files = list(base_dir.glob(pattern))
    if not files:
        logger.error(f"No files found for pattern: {pattern}")
        raise FileNotFoundError(f"No files found for pattern: {pattern}")
    # Sort the files by modification time in descending order
    files.sort(key=lambda x: x.stat().st_mtime, reverse=False)
    # Return the most recent file
    # breakpoint()
    return files[0]


def validate_index_name(index_name: str):
    valid_indices = ["biorxiv", "medrxiv"]
    if index_name not in valid_indices:
        raise typer.BadParameter(
            f"Invalid index name: {index_name}. Valid options are 'biorxiv' or 'medrxiv'."
        )
    return index_name


@app.command()
def main(index_name: str = typer.Argument(..., callback=validate_index_name)):
    global log_filename
    log_filename = log_filename.replace(index_name_placeholder, index_name)
    logger.add(log_filename, rotation="10 MB", retention="10 days", level="INFO")

    logger.info("Script started.")
    es_client = create_es_client(ES_HOSTNAME, ES_USERNAME, ES_PASSWORD)
    file_path = find_arxiv_path(index_name)
    index_json_data(es_client, file_path, index_name)
    logger.info(f"Completed indexing for {index_name}.")


if __name__ == "__main__":
    app()
