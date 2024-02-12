#!/bin/bash

# Get the server name from the command-line argument
server=$1

most_recent_file=$(ls -1 data/rxivx/${server}/downloaded | sort -r | head -n 1)
latest_date=$(echo $most_recent_file | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | tail -1)
current_date=$(date +'%Y-%m-%d')
output_filename="${server}_${latest_date}_${current_date}.json"

echo "Downloading ${output_filename} database"

makim scheduler.download-rxivr --server ${server} --begin ${latest_date} --end ${current_date} --target data/rxivx/${server}/downloaded/

python merge_arxiv_data.py "data/rxivx/${server}/final/${server}_full_data.json" "data/rxivx/${server}/downloaded/${output_filename}"
