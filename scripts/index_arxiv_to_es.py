import json
import os
import time
from pathlib import Path
import hashlib

import typer

from dotenv import load_dotenv
from elasticsearch import Elasticsearch, exceptions
from loguru import logger
from tqdm import tqdm

load_dotenv()

app = typer.Typer()

index_name_placeholder = "index_name"
log_filename = f"/tmp/elasticrxivx_{index_name_placeholder}_{time.strftime('%Y%m%d-%H%M%S')}.log"

ES_HOSTNAME = os.getenv("ES_HOSTNAME", "https://localhost:9200")
ES_USERNAME = os.getenv("ES_USERNAME", "elastic")
ES_PASSWORD = os.getenv("ES_PASSWORD", "")
ES_CERTIF = os.getenv("ES_CERTIF", "")

def create_es_client(host: str, username: str, password: str, ca_certs: str) -> Elasticsearch:
    """
    Create an Elasticsearch client using the provided credentials.

    Parameters
    ----------
    host : str
        The host URL of the Elasticsearch instance.
    username : str
        The username for Elasticsearch authentication.
    password : str
        The password for Elasticsearch authentication.
    ca_certs : str
        Path to a CA bundle to verify SSL certificates.

    Returns
    -------
    Elasticsearch
        An instance of Elasticsearch client configured with the given credentials.
    """
    extra_args = {}
    if ca_certs:
        extra_args["ca_certs"] = ca_certs
    return Elasticsearch([host], basic_auth=(username, password), verify_certs=False, **extra_args)

def generate_document_id(doc: dict) -> str:
    """
    Generate a unique document ID based on the document's content.

    Parameters
    ----------
    doc : dict
        The document for which to generate an ID.

    Returns
    -------
    str
        A unique identifier for the document.
    """
    doc_string = json.dumps(doc, sort_keys=True)
    return hashlib.sha256(doc_string.encode('utf-8')).hexdigest()

def document_exists(es_client: Elasticsearch, index_name: str, doc_id: str) -> bool:
    """
    Check if a document exists in the specified index.

    Parameters
    ----------
    es_client : Elasticsearch
        The Elasticsearch client instance.
    index_name : str
        The name of the Elasticsearch index.
    doc_id : str
        The ID of the document to check.

    Returns
    -------
    bool
        True if the document exists, False otherwise.
    """
    try:
        return es_client.exists(index=index_name, id=doc_id)
    except exceptions.NotFoundError:
        return False

def index_json_data(es_client: Elasticsearch, file_path: str, index_name: str) -> None:
    """
    Index JSON data from a file into the specified Elasticsearch index.

    Parameters
    ----------
    es_client : Elasticsearch
        The Elasticsearch client instance.
    file_path : str
        The path to the JSON file containing the data to index.
    index_name : str
        The name of the Elasticsearch index.

    Raises
    ------
    Exception
        If the indexing process fails.
    """
    try:
        logger.info(f"Starting indexing {file_path}")

        with open(file_path, 'r', encoding='utf-8') as file:
            data = json.load(file)

        successful_docs, skipped_docs = 0, 0
        with tqdm(total=len(data)) as pbar:
            for doc in data:
                doc_id = generate_document_id(doc)
                if not document_exists(es_client, index_name, doc_id):
                    # logger.info(f"Indexing doc id {doc_id}")
                    es_client.index(index=index_name, id=doc_id, document=doc)
                    successful_docs += 1
                else:
                    skipped_docs += 1
                
                # logger.info(f"Indexing Summary: {successful_docs} new, {skipped_docs} skipped.")
                pbar.update(1)
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse JSON data from {file_path}: {e}")
        raise Exception(f"Failed to parse JSON data: {e}")
    except Exception as e:
        logger.error(f"Failed to index data for {index_name}: {e}")
        raise Exception(f"Failed to index data for {index_name}: {e}")

def find_rxiv_path(index_name: str) -> Path:
    """
    Finds the most recent JSON file path for the specified index name.

    Parameters
    ----------
    index_name : str
        The name of the index (e.g., "biorxiv" or "medrxiv").

    Returns
    -------
    Path
        The Path object pointing to the most recent JSON file.

    Raises
    ------
    FileNotFoundError
        If no files are found for the given pattern.
    """
    base_dir = Path(__file__).resolve().parent.parent
    pattern = f"data/rxivx/{index_name}/downloaded/{index_name}_*.json"
    files = list(base_dir.glob(pattern))

    if not files:
        raise FileNotFoundError(f"No files found for pattern: {pattern}")

    most_recent_file = max(files, key=os.path.getmtime)
    logger.info(f"find_rxiv_path: Found {most_recent_file}")

    return most_recent_file

def validate_index_name(index_name: str) -> str:
    """
    Validate the provided index name against known valid options.

    Parameters
    ----------
    index_name : str
        The index name to validate.

    Returns
    -------
    str
        The validated index name.

    Raises
    ------
    typer.BadParameter
        If the index name is not recognized as valid.
    """
    valid_indices = ["biorxiv", "medrxiv"]
    if index_name not in valid_indices:
        raise typer.BadParameter("Invalid index name: {index_name}. Valid options are 'biorxiv' or 'medrxiv'.")
    return index_name

@app.command()
def main(index_name: str = typer.Argument(..., callback=validate_index_name)):
    """
    Main function to run the indexing process for a given index name.

    Parameters
    ----------
    index_name : str
        The index name to process.
    """
    global log_filename
    log_filename = log_filename.replace(index_name_placeholder, index_name)
    logger.add(log_filename, rotation="10 MB", retention="10 days", level="INFO")

    logger.info(f"Starting the indexing process for {index_name}...")
    es_client = create_es_client(ES_HOSTNAME, ES_USERNAME, ES_PASSWORD, ES_CERTIF)
    file_path = find_rxiv_path(index_name)

    try:
        index_json_data(es_client, str(file_path), index_name)
        logger.info(f"Completed indexing for {index_name}.")
    except Exception as e:
        logger.error(f"Indexing process failed for {index_name}: {e}")

if __name__ == "__main__":
    app()
