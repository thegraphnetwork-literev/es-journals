import os
from pathlib import Path

import pytest
from dotenv import load_dotenv
from elasticsearch import Elasticsearch

# Load environment variables
env_dir = Path(__file__).resolve().parent.parent
load_dotenv(env_dir / ".env")

ES_HOST_URL = os.getenv("ES_HOSTNAME", "http://localhost:9200")
ES_USERNAME = os.getenv("ES_USERNAME", "elastic")
ES_PASSWORD = os.getenv("ES_PASSWORD", "")
ES_CERTIF = os.getenv("ES_CERTIF", "")


def create_es_client() -> Elasticsearch:
    """Create an Elasticsearch client with proper parameters."""
    is_https = ES_HOST_URL.startswith("https://")

    return Elasticsearch(
        hosts=[ES_HOST_URL],
        basic_auth=(ES_USERNAME, ES_PASSWORD),
        verify_certs=is_https,
        ca_certs=ES_CERTIF if is_https else None,  # type: ignore[arg-type]
    )


def test_connection():
    """Test Elasticsearch connection."""
    es = create_es_client()
    cluster_info = es.info()

    assert "cluster_name" in cluster_info


@pytest.mark.parametrize("index_name", ["biorxiv", "medrxiv"])
def test_index(index_name: str):
    """Test index query on Elasticsearch."""
    es = create_es_client()

    es_query = {
        "query": {
            "bool": {
                "must": {
                    "query_string": {
                        "query": "(health literacy) AND (health professional)"
                    }
                },
                "filter": [
                    {"range": {"date": {"gte": "2000-01-01", "lte": "2024-03-06"}}}
                ],
            },
        },
        "size": 1000,
    }

    response = es.search(index=index_name, body=es_query, params={"scroll": "2m"})  # type: ignore[call-arg]

    assert "error" not in response, f"Elasticsearch error: {response.get('error')}"

    assert response.get("hits", {}).get("total", {}).get("value", 0) > 0, (
        "No documents found!"
    )
