#!/bin/bash

set -e

# Detect Conda or Micromamba
if command -v micromamba &> /dev/null; then
    echo "Using Micromamba..."
    eval "$(micromamba shell hook --shell bash)"
    micromamba activate es-journals

elif command -v conda &> /dev/null; then
    echo "Using Conda-based environment (Miniconda/Miniforge)..."

    # Find Conda base path
    CONDA_BASE=$(conda info --base)

    if [ -z "$CONDA_BASE" ]; then
        echo "Error: Conda installation not found."
        exit 1
    fi

    source "$CONDA_BASE/etc/profile.d/conda.sh"
    conda activate es-journals
else
    echo "Error: Neither Micromamba nor Conda (Miniconda/Miniforge) is installed."
    exit 1
fi

# Get the current working directory

PATH_ROOT=$(pwd)

# Source the environment variables
if [ -f "$PATH_ROOT"/.env ]; then
    source "$PATH_ROOT"/.env
else
    echo ".env file not found"
    exit 1
fi

# Check if the index name was provided
INDEX_NAME="$1"

if [ -z "$INDEX_NAME" ]; then
    echo "[ERROR]: No index name provided."
    echo "Usage: $0 <server-name>"
    exit 1
fi

# Use the ES_HOST_VOLUME variable
DOWNLOADED_PATH="$(dirname "${ES_HOST_VOLUME}")/rxivx/${INDEX_NAME}/downloaded"

echo "[INFO]: The path to download has been generated ${DOWNLOADED_PATH}..."

# Ensure the directory exists
if [ ! -d "${DOWNLOADED_PATH}" ]; then
    echo "[ERROR]: Download directory does not exist: ${DOWNLOADED_PATH}"
    exit 1
fi

# Find the most recent file within the downloaded directory
most_recent_file=$(find "${DOWNLOADED_PATH}" -type f -printf "%T+ %p\n" | sort -r | head -n 1 | cut -d" " -f2-)

if [ -z "$most_recent_file" ]; then
    echo "[ERROR]: No recent file found in ${DOWNLOADED_PATH}"
    exit 1
fi

# Extract dates for filename construction
latest_date=$(basename "$most_recent_file" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | tail -1)
current_date=$(date +'%Y-%m-%d')

# Start the download process
echo "[INFO]: Starting the download process for ${INDEX_NAME}..."
if makim scheduler.download-rxivr --server "${INDEX_NAME}" --begin "${latest_date}" --end "${current_date}" --target "${DOWNLOADED_PATH}/" ; then
    echo "[SUCCESS]: Download completed successfully for ${INDEX_NAME}."

    # Proceed with the indexing process
    if python "${PATH_ROOT}/scripts/index_arxiv_to_es.py" "${INDEX_NAME}"; then
        # Delete the oldest file after successful download and index
        echo "[INFO]: Deleting the oldest file: $(basename "${most_recent_file}")"
        rm -f "${most_recent_file}"
    else
        echo "[ERROR]: Indexing process failed for ${INDEX_NAME}."
        exit 1
    fi
else
    echo "[ERROR]: Download process failed for ${INDEX_NAME}."
    exit 1
fi

echo "[SUCCESS]: All processes completed successfully for ${INDEX_NAME}."
