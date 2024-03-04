import os

from pathlib import Path

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
    es = Elasticsearch([ES_HOST_URL], basic_auth=(ES_USERNAME, ES_PASSWORD), verify_certs=False)
    breakpoint()
    assert es


if __name__ == "__main__":
    test_connection()
