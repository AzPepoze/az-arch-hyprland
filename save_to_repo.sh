#!/bin/bash

#-------------------------------------------------------
# Configuration
#-------------------------------------------------------
REPO_DIR=$(cd -- "$(dirname -- "$0")" &> /dev/null && pwd)
SOURCE_DIR="$HOME/.config/hypr"
DEST_DIR="$REPO_DIR/configs/hypr"

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------
echo "Starting configuration update..."
echo "Source: $SOURCE_DIR"
echo "Destination: $DEST_DIR"
echo "------------------------------------------------------------"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' not found."
    exit 1
fi

if [ ! -d "$DEST_DIR" ]; then
    echo "Error: Destination directory '$DEST_DIR' not found."
    exit 1
fi

for dest_file in "$DEST_DIR"/*; do
    if [ -f "$dest_file" ]; then
        filename=$(basename "$dest_file")
        source_file="$SOURCE_DonceIR/$filename"

        if [ -f "$source_file" ]; then
            echo "Updating '$filename'..."
            cp -v "$source_file" "$dest_file"
        else
            echo "Warning: Source file '$source_file' not found. Skipping '$filename'."
        fi
    fi
done

echo "------------------------------------------------------------"
echo "Update complete."