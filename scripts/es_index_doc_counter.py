import os
from elasticsearch import Elasticsearch
import typer
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
env_dir = Path(__file__).resolve().parent.parent
load_dotenv(env_dir / ".env")

ES_HOSTNAME = os.getenv("ES_HOSTNAME", "https://localhost:9200")
ES_USERNAME = os.getenv("ES_USERNAME", "elastic")
ES_PASSWORD = os.getenv("ES_PASSWORD", "")
ES_CERTIF = os.getenv("ES_CERTIF", "")

app = typer.Typer()


def create_es_client(
    host: str, username: str, password: str, ca_certs: str
) -> Elasticsearch:
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
    return Elasticsearch([host], basic_auth=(username, password), verify_certs=False)


def get_total_documents_in_index(es: Elasticsearch, index_name: str) -> int:
    """
    Return the total number of documents in an Elasticsearch index.

    Parameters
    ----------
    es : Elasticsearch
        The Elasticsearch client instance.
    index_name : str
        The name of the Elasticsearch index.

    Returns
    -------
    int
        The total number of documents in the specified index.
    """
    response = es.count(index=index_name, body={"query": {"match_all": {}}})
    return response["count"]


@app.command()
def main(
    index_name: str = typer.Argument(
        ..., help="The name of the Elasticsearch index to query."
    )
):
    """
    Retrieve and print the total number of documents in the specified Elasticsearch index.

    Parameters
    ----------
    index_name : str
        The name of the Elasticsearch index.

    """
    es_client = create_es_client(ES_HOSTNAME, ES_USERNAME, ES_PASSWORD, ES_CERTIF)
    total_docs = get_total_documents_in_index(es_client, index_name)
    typer.echo(f"Total documents in '{index_name}' index: {total_docs}")


if __name__ == "__main__":
    app()
