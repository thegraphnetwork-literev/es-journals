#!/bin/bash

set -e

# Activate conda enviroment
source /opt/miniforge/bin/activate rxiv-rest-api

# Capture the current working directory
path_root=$(pwd)

# Get the server name from the command-line argument
server=$1

most_recent_file=$(ls -1 ${path_root}/src/data/rxivx/${server}/downloaded | sort -r | head -n 1)
latest_date=$(echo $most_recent_file | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | tail -1)
current_date=$(date +'%Y-%m-%d')
output_filename="${server}_${latest_date}_${current_date}.json"


# Execute the download process
if makim scheduler.download-rxivr --server ${server} --begin ${latest_date} --end ${current_date} --target ${path_root}/src/data/rxivx/${server}/downloaded/ ; then
    echo "[II] INFO: The latest database file generated is ${output_filename}"
    if python ${path_root}/src/merge_arxiv_data.py "${path_root}/src/data/rxivx/${server}/final/${server}_full_data.json" "src/data/rxivx/${server}/downloaded/${output_filename}"; then
        echo "[II] INFO: Merge in the full database completed successfully."

        # If both download and merge were successful, delete the most recent file
        echo "[II] INFO: Deleting the most old file: ${most_recent_file}"
        rm "${path_root}/src/data/rxivx/${server}/downloaded/${most_recent_file}"
    else
        echo "[II] ERROR: Merge process failed."
        exit 1
    fi

    echo "[II] SUCCESS: All processes completed successfully."

else
    echo "[II] ERROR: Download process failed."
    exit 1
fi
