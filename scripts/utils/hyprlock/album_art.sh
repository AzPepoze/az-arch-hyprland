#!/bin/bash

# Path to a default image if no music is playing or no art is found
DEFAULT_ART="/path/to/your/default/image.png"

# Get album art URL from playerctl
ART_URL=$(playerctl -f "{{mpris:artUrl}}" metadata)

if [[ -n "$ART_URL" ]]; then
    # Remove the "file://" prefix
    ART_PATH="${ART_URL/file:\/\//}"
    echo "$ART_PATH"
else
    echo "$DEFAULT_ART"
fi