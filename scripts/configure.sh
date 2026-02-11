#!/bin/bash

# Modular configuration script for Meson/C++ server

# Source libraries
source "$(dirname "$0")/lib-utils.sh"
source "$(dirname "$0")/lib-config.sh"

PRESET=$1
BUILD_DIR="cpp-server/build"

if [ -z "$PRESET" ]; then
    echo "Usage: $0 <preset>"
    exit 1
fi

# Load configuration
load_server_config "$PRESET" || exit 1

# Dependency check
if [ -f "$(dirname "$0")/check-deps.sh" ]; then
    "$(dirname "$0")/check-deps.sh" "$COMPILER" > /dev/null || exit 1
fi

# Compiler Cross-Check
if [ -d "$BUILD_DIR" ]; then
    ACTUAL_COMPILER=$(meson introspect "$BUILD_DIR" --compilers 2>/dev/null | jq -r '.host.cpp.exelist[0] // empty' 2>/dev/null)
    
    if [ -n "$ACTUAL_COMPILER" ]; then
        ACTUAL_BASE=$(basename "$ACTUAL_COMPILER")
        REQ_BASE=$(basename "$COMPILER")

        if [ "$ACTUAL_BASE" != "$REQ_BASE" ]; then
            log_warn "Requested compiler ($COMPILER) does not match the active build compiler ($ACTUAL_COMPILER)."
            log_warn "To switch compilers, you MUST delete the build directory: rm -rf $BUILD_DIR"
            echo ""
        fi
    fi
fi

log_step "Configuring server with preset: $PRESET (Standard: ${CPP_STD}, Compiler: $COMPILER)"

# Run Meson inside the cpp-server directory
cd cpp-server || exit 1
CXX="$COMPILER" meson setup build --reconfigure "${SERVER_ARGS[@]}"
