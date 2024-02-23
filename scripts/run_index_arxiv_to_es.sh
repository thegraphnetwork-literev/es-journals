#!/bin/bash

set -e

source /opt/miniforge/bin/activate rxiv-rest-api

path_root=$(pwd)

server=$1

# Check if the server name was provided
if [ -z "$server" ]; then
    echo "[ERROR]: No server name provided."
    echo "Usage: $0 <server-name>"
    exit 1
fi

# Execute the indexing process
echo "[INFO]: Starting the indexing process for ${server}..."
if python ${path_root}/scripts/index_arxiv_to_es.py ${server}; then
    echo "[SUCCESS]: Indexing completed successfully for ${server}."
else
    echo "[ERROR]: Indexing process failed for ${server}."
    exit 1
fi
