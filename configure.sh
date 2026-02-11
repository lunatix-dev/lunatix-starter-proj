#!/bin/bash

# Configuration and basic validation
CONFIG_FILE="build-config.json"
PRESET=$1
BUILD_DIR="cpp-server/build"

if [ -z "$PRESET" ]; then
    echo "Usage: $0 <preset>"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found"
    exit 1
fi

# Dependency check
COMPILER=$(jq -r '.server.common.compiler // "g++"' "$CONFIG_FILE")
if [ -f "./scripts/check-deps.sh" ]; then
    ./scripts/check-deps.sh "$COMPILER" || exit 1
fi

# Compiler Cross-Check
if [ -d "$BUILD_DIR" ]; then
    # Get the compiler currently locked into the Meson build directory
    ACTUAL_COMPILER=$(meson introspect "$BUILD_DIR" --compilers 2>/dev/null | jq -r '.host.cpp.exelist[0] // empty' 2>/dev/null)
    
    if [ -n "$ACTUAL_COMPILER" ]; then
        ACTUAL_BASE=$(basename "$ACTUAL_COMPILER")
        REQ_BASE=$(basename "$COMPILER")

        if [ "$ACTUAL_BASE" != "$REQ_BASE" ]; then
            echo -e "\033[0;33mWARNING: Requested compiler ($COMPILER) does not match the active build compiler ($ACTUAL_COMPILER).\033[0m"
            echo -e "\033[0;33mTo switch compilers, you MUST delete the build directory: rm -rf $BUILD_DIR\033[0m"
            echo ""
        fi
    fi
fi

# Helper functions for JSON parsing
get_args() {
    # $1 is "common" or "$PRESET"
    if [ "$1" == "common" ]; then
        jq -r ".server.common.args[]? // empty" "$CONFIG_FILE"
    else
        jq -r ".server.presets.\"$1\".args[]? // empty" "$CONFIG_FILE"
    fi
}

validate_preset() {
    if [ "$(jq -r ".server.presets | has(\"$PRESET\")" "$CONFIG_FILE")" != "true" ]; then
        echo "Error: Preset '$PRESET' not found in $CONFIG_FILE under .server.presets"
        exit 1
    fi
}

validate_preset

# Collect arguments from common and selected preset
ALL_ARGS=()
while IFS= read -r line; do ALL_ARGS+=("$line"); done < <(get_args "common")
while IFS= read -r line; do ALL_ARGS+=("$line"); done < <(get_args "$PRESET")

# Export environment variables
export_env() {
    # $1 is "common" or "$PRESET"
    if [ "$1" == "common" ]; then
        eval "$(jq -r ".server.common.env | to_entries | .[] | \"export \(.key)=\\\"\(.value)\\\"\"" "$CONFIG_FILE")"
    else
        eval "$(jq -r ".server.presets.\"$1\".env | to_entries | .[] | \"export \(.key)=\\\"\(.value)\\\"\"" "$CONFIG_FILE")"
    fi
}

export_env "common"
export_env "$PRESET"

# Read global C++ standard setting
CPP_STD=$(jq -r '.server.common.cpp_std // empty' "$CONFIG_FILE")
if [ -n "$CPP_STD" ]; then
    ALL_ARGS+=("-Dcpp_std=$CPP_STD")
fi

echo "Configuring server with preset: $PRESET (Standard: ${CPP_STD:-default}, Compiler: $COMPILER)"

# Run Meson inside the cpp-server directory
cd cpp-server || exit 1
CXX="$COMPILER" meson setup build --reconfigure "${ALL_ARGS[@]}"
