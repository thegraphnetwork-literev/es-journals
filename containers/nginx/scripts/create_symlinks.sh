#!/bin/bash

SOURCE_DIR="/etc/nginx/sites-available"
DEST_DIR="/etc/nginx/sites-enabled"

for file in "$SOURCE_DIR"/*; do
    filename=$(basename "$file")
    ln -s "$file" "$DEST_DIR/$filename"
done
