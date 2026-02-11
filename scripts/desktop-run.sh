#!/bin/bash

# Modular script to run desktop app with correct environment

# Source libraries
source "$(dirname "$0")/lib-utils.sh"
source "$(dirname "$0")/lib-config.sh"

# Load desktop environment
load_desktop_config

# Execute tauri command
cd apps/desktop-app || exit 1

# Auto-install if node_modules is missing
if [ ! -d "node_modules" ]; then
    log_info "node_modules missing in desktop-app, installing..."
    bun install || exit 1
fi

bun run tauri "$@"
