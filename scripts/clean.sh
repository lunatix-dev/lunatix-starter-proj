#!/bin/bash

# Script to clean build artifacts and temporary files

source "$(dirname "$0")/lib-utils.sh"

log_step "Starting Cleanup..."

# 1. Root artifacts
log_info "Cleaning root node_modules and lock files..."
rm -rf node_modules bun.lock

# 2. C++ Server
log_info "Cleaning C++ server build directory..."
rm -rf cpp-server/build

# 3. Web App
log_info "Cleaning Web App artifacts..."
rm -rf apps/web-app/dist apps/web-app/node_modules

# 4. Desktop App
log_info "Cleaning Desktop App artifacts..."
rm -rf apps/desktop-app/node_modules
rm -rf apps/desktop-app/src-tauri/target
rm -rf apps/desktop-app/src-tauri/binaries

log_step "Cleanup complete!"
