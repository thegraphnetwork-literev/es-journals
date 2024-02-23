import json
import os
import time
from pathlib import Path
from typing import Optional
import hashlib

import typer
from dotenv import load_dotenv
from elasticsearch import Elasticsearch
from loguru import logger

load_dotenv()

app = typer.Typer()


index_name_placeholder = "index_name"
log_filename = (
    f"/tmp/elasticrxivx_{index_name_placeholder}_{time.strftime('%Y%m%d-%H%M%S')}.log"
)

ES_HOST = os.getenv("ES_HOST", "https://localhost:9200")
ES_USERNAME = os.getenv("ES_USERNAME", "elastic")
ES_PASSWORD = os.getenv("ES_PASSWORD", "")


def create_es_client(host: str, username: str, password: str) -> Elasticsearch:
    """
    Creates an Elasticsearch client using the provided credentials.
    """
    return Elasticsearch([host], basic_auth=(username, password))

def generate_document_id(doc: dict) -> str:
    """
    Generates a unique ID for a document.
    This example uses a hash of the document's content, but you can modify
    it to use other unique fields from your document.
    """
    doc_string = json.dumps(doc, sort_keys=True)
    return hashlib.sha256(doc_string.encode('utf-8')).hexdigest()

def index_json_data(es_client: Elasticsearch, file_path: str, index_name: str) -> None:
    """
    Reads data from a JSON file and indexes it into Elasticsearch,
    using a unique ID for each document to avoid duplicates.
    """
    try:
        with open(file_path, "r", encoding="utf-8") as file:
            data = json.load(file)

        successful_docs = 0
        for doc in data:
            doc_id = generate_document_id(doc)  # Generate a unique ID for the document
            try:
                res = es_client.index(index=index_name, id=doc_id, document=doc)
                successful_docs += 1
            except Exception as doc_error:
                logger.error(f"Failed to index document: {doc_error}")

        logger.info(
            f"Total documents indexed successfully: {successful_docs}/{len(data)}"
        )
    except Exception as e:
        logger.error(f"Failed to index data for {index_name}: {e}")

def find_arxiv_path(index_name: str) -> Optional[str]:
    """
    Constructs the absolute file path for the specified database name.
    """
    if index_name:
        base_dir = Path(__file__).resolve().parent.parent
        file_path = (
            base_dir / f"data/rxivx/{index_name}/final/{index_name}_full_data.json"
        )
        return str(file_path)
    else:
        logger.info("No index name provided.")
        return None


def validate_index_name(index_name: str):
    valid_indices = ["biorxiv", "medrxiv"]
    if index_name not in valid_indices:
        logger.error(
            f"Invalid index name: {index_name}. Valid options are 'biorxiv' or 'medrxiv'."
        )
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
    start_time = time.time()
    logger.info(f"Starting indexing for {index_name}")

    es_client = create_es_client(ES_HOST, ES_USERNAME, ES_PASSWORD)
    file_path = find_arxiv_path(index_name)
    if file_path:
        index_json_data(es_client, file_path, index_name)
        end_time = time.time()
        total_time = end_time - start_time
        logger.info(
            f"Completed indexing for {index_name}. Total time: {total_time:.2f} seconds"
        )
    else:
        logger.info(f"No data indexed for {index_name}.")


if __name__ == "__main__":
    app()
