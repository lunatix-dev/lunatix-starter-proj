#!/bin/bash

# Configuration parsing library using jq

CONFIG_FILE="build-config.json"

# Source utilities if not already sourced
if [ -z "$NC" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/lib-utils.sh"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    log_error "$CONFIG_FILE not found in $(pwd)"
    exit 1
fi

get_config_val() {
    jq -r "$1" "$CONFIG_FILE"
}

# Load server configuration for a specific preset
load_server_config() {
    local preset=$1
    
    # Validate preset
    if [ "$(get_config_val ".server.presets | has(\"$preset\")")" != "true" ]; then
        log_error "Preset '$preset' not found in $CONFIG_FILE under .server.presets"
        return 1
    fi

    # Export compiler
    export COMPILER=$(get_config_val ".server.common.compiler // \"g++\"")
    
    # Export C++ standard
    export CPP_STD=$(get_config_val ".server.common.cpp_std // \"c++23\"")

    # Collect arguments
    ALL_ARGS=()
    while IFS= read -r line; do ALL_ARGS+=("$line"); done < <(jq -r ".server.common.args[]? // empty" "$CONFIG_FILE")
    while IFS= read -r line; do ALL_ARGS+=("$line"); done < <(jq -r ".server.presets.\"$preset\".args[]? // empty" "$CONFIG_FILE")
    
    if [ -n "$CPP_STD" ]; then
        ALL_ARGS+=("-Dcpp_std=$CPP_STD")
    fi
    export SERVER_ARGS=("${ALL_ARGS[@]}")

    # Export environment variables
    eval "$(jq -r ".server.common.env | to_entries | .[] | \"export \(.key)=\\\"\(.value)\\\"\"" "$CONFIG_FILE")"
    eval "$(jq -r ".server.presets.\"$preset\".env | to_entries | .[] | \"export \(.key)=\\\"\(.value)\\\"\"" "$CONFIG_FILE")"
    
    return 0
}

# Load desktop configuration
load_desktop_config() {
    eval "$(jq -r ".desktop.env | to_entries | .[] | \"export \(.key)=\\\"\(.value)\\\"\"" "$CONFIG_FILE")"
}
