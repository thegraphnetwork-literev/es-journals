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


def test_connection():
    es = Elasticsearch(
        [ES_HOST_URL], 
        basic_auth=(ES_USERNAME, ES_PASSWORD), 
        verify_certs=False
    )
    assert es.cluster.health().get("status") in ["green", "yellow"]


@pytest.mark.parametrize(
    "index_name", [
        "biorxiv",
        "medrxiv"
    ]
)
def test_index(index_name):
    es = Elasticsearch(
        [ES_HOST_URL],
        basic_auth=(ES_USERNAME, ES_PASSWORD),
        verify_certs=False
    )

    es_query = {
      "query": {
        "bool": {
          "must": {
                "query_string": {
                    "query": "(health literacy) AND (health professional)"
                }
            },
          "filter": [
            {
              "range": {
                "date": {
                  "gte": "2000-01-01",
                  "lte": "2024-03-06"
                }
              }
            }
          ]
        },
      },
      "size": 1000
    }

    response = es.search(
        index=index_name,
        body=es_query, scroll="2m"
    )
