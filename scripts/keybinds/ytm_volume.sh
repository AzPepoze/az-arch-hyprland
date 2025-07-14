#!/bin/bash

#-------------------------------------------------------
# Configuration
#-------------------------------------------------------
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
CONFIG_FILE="$SCRIPT_DIR/../../etc/ytm_volume.conf"
DEFAULT_VOLUME=1
PORT="26538"
API_BASE_URL="http://localhost:${PORT}/api/v1"
STEP=1

#-------------------------------------------------------
# Helper Functions
#-------------------------------------------------------
ensure_config_file() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Config file not found. Creating with default volume: $DEFAULT_VOLUME"
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "$DEFAULT_VOLUME" > "$CONFIG_FILE"
    fi
}

get_current_volume() {
    if [ -f "$CONFIG_FILE" ]; then
        head -n 1 "$CONFIG_FILE"
    else
        echo "$DEFAULT_VOLUME"
    fi
}

set_new_volume() {
    local new_vol=$1
    response=$(curl -s -o /dev/null -w "%{\http_code}" -X POST \
         -H "Content-Type: application/json" \
         -d "{\"volume\": ${new_vol}}" \
         "${API_BASE_URL}/volume")

    if [[ "$response" -ge 200 && "$response" -lt 300 ]]; then
        echo "$new_vol" > "$CONFIG_FILE"
        echo "New volume set to $new_vol"
    else
        echo "Error: Failed to set volume via API. HTTP status: $response"
        exit 1
    fi
}

sync_from_api() {
    echo "Attempting to sync volume from API..."
    api_volume=$(curl -s "${API_BASE_URL}/volume" | jq '.state')
    if [[ "$api_volume" =~ ^[0-9]+$ ]]; then
        echo "$api_volume" > "$CONFIG_FILE"
        echo "Successfully synced volume from API: $api_volume"
        return 0
    else
        echo "Error: Could not get current volume from API for syncing."
        return 1
    fi
}

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------
ensure_config_file
current_volume=$(get_current_volume)

if ! [[ "$current_volume" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid volume value in config file: '$current_volume'."
    if sync_from_api; then
        current_volume=$(get_current_volume)
    else
        exit 1
    fi
fi

case "$1" in
    "up")
        new_volume=$((current_volume + STEP))
        [ "$new_volume" -gt 100 ] && new_volume=100
        ;;
    "down")
        new_volume=$((current_volume - STEP))
        [ "$new_volume" -lt 0 ] && new_volume=0
        ;;
    "sync")
        sync_from_api
        exit 0
        ;;
    *)
        echo "Usage: $0 [up|down|sync]"
        exit 1
        ;;
esac

set_new_volume "$new_volume"
