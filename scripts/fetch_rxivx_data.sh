#!/bin/bash

set -e

# Find the path to the Conda executable
conda_path=$(find / -type d -path "*/envs/es-journals" 2>/dev/null | head -n 1)

if [ -z "$conda_path" ]; then
    echo "Conda executable not found. Please ensure Conda is installed and added to your PATH."
    exit 1
fi

# Activate the Python environment
activate_path="$(dirname "$(dirname "$conda_path")")/bin/activate"
source "$activate_path" es-journals

# Get the current working directory

path_root=$(pwd)

# Source the environment variables
if [ -f $path_root/.env ]; then
    source $path_root/.env
else
    echo ".env file not found"
    exit 1
fi

# Check if the server name was provided
server="$1"

if [ -z "$server" ]; then
    echo "[ERROR]: No server name provided."
    echo "Usage: $0 <server-name>"
    exit 1
fi

# Use the ELASTIC_VOLUME variable
downloaded_path="$(dirname "$ELASTIC_VOLUME")/rxivx/${server}/downloaded"

# Ensure the directory exists
if [ ! -d "${downloaded_path}" ]; then
    echo "[ERROR]: Download directory does not exist: ${downloaded_path}"
    exit 1
fi

# Find the most recent file within the downloaded directory
most_recent_file=$(find "${downloaded_path}" -type f -printf "%T+ %p\n" | sort -r | head -n 1 | cut -d" " -f2-)

if [ -z "$most_recent_file" ]; then
    echo "[ERROR]: No recent file found in ${downloaded_path}"
    exit 1
fi

# Extract dates for filename construction
latest_date=$(basename "$most_recent_file" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | tail -1)
current_date=$(date +'%Y-%m-%d')
output_filename="${server}_${latest_date}_${current_date}.json"

# Start the download process
echo "[INFO]: Starting the download process for ${server}..."
if makim scheduler.download-rxivr --server "${server}" --begin "${latest_date}" --end "${current_date}" --target "${downloaded_path}/" ; then
    echo "[SUCCESS]: Download completed successfully for ${server}."

    # Proceed with the indexing process
    if python "${path_root}/scripts/index_arxiv_to_es.py" "${server}"; then
        # Delete the oldest file after successful download and index
        echo "[INFO]: Deleting the oldest file: $(basename "${most_recent_file}")"
        rm -f "${most_recent_file}"
    else
        echo "[ERROR]: Indexing process failed for ${server}."
        exit 1
    fi
else
    echo "[ERROR]: Download process failed for ${server}."
    exit 1
fi

echo "[SUCCESS]: All processes completed successfully for ${server}."
