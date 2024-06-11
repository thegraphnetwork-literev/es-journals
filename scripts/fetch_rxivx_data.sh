#!/bin/bash

set -e

# Find the path to the Conda executable
CONDA_PATH=$(find / -type d -path "*/envs/es-journals" 2>/dev/null | head -n 1)

if [ -z "$CONDA_PATH" ]; then
    echo "Conda executable not found. Please ensure Conda is installed and added to your PATH."
    exit 1
fi

# Activate the Python environment
activate_path="$(dirname "$(dirname "$CONDA_PATH")")/bin/activate"
source "$activate_path" es-journals

# Get the current working directory

PATH_ROOT=$(pwd)

# Source the environment variables
if [ -f $PATH_ROOT/.env ]; then
    source $PATH_ROOT/.env
else
    echo ".env file not found"
    exit 1
fi

# Check if the SERVER name was provided
SERVER="$1"

if [ -z "$SERVER" ]; then
    echo "[ERROR]: No SERVER name provided."
    echo "Usage: $0 <SERVER-name>"
    exit 1
fi

# Use the ES_HOST_VOLUME variable
DOWNLOADED_PATH="$(dirname "${ES_HOST_VOLUME}")/rxivx/${SERVER}/downloaded"

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
output_filename="${SERVER}_${latest_date}_${current_date}.json"

# Start the download process
echo "[INFO]: Starting the download process for ${SERVER}..."
if makim scheduler.download-rxivr --server "${SERVER}" --begin "${latest_date}" --end "${current_date}" --target "${DOWNLOADED_PATH}/" ; then
    echo "[SUCCESS]: Download completed successfully for ${SERVER}."

    # Proceed with the indexing process
    if python "${PATH_ROOT}/scripts/index_arxiv_to_es.py" "${SERVER}"; then
        # Delete the oldest file after successful download and index
        echo "[INFO]: Deleting the oldest file: $(basename "${most_recent_file}")"
        rm -f "${most_recent_file}"
    else
        echo "[ERROR]: Indexing process failed for ${SERVER}."
        exit 1
    fi
else
    echo "[ERROR]: Download process failed for ${SERVER}."
    exit 1
fi

echo "[SUCCESS]: All processes completed successfully for ${SERVER}."
