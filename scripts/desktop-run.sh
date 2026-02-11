#!/bin/bash

# Load environment variables from build-config.json for desktop
CONFIG_FILE="build-config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found"
    exit 1
fi

# Export variables from .desktop.env
eval "$(jq -r ".desktop.env | to_entries | .[] | \"export \(.key)=\\\"\(.value)\\\"\"" "$CONFIG_FILE")"

# Execute tauri command
cd apps/desktop-app || exit 1
bun run tauri "$@"
