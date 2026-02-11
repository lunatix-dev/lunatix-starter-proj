#!/bin/bash

# Orchestration script for building the entire project

source "$(dirname "$0")/scripts/lib-utils.sh"

RELEASE=0
STANDALONE=0

# Parse arguments
for arg in "$@"; do
    case $arg in
        --release) RELEASE=1 ;;
        --standalone) STANDALONE=1 ;;
        *) log_warn "Unknown argument: $arg" ;;
    esac
done

log_step "Starting build process (Release: $RELEASE, Standalone: $STANDALONE)"

# 1. Configure
if [ $RELEASE -eq 1 ]; then
    log_info "Configuring for Release..."
    ./scripts/configure.sh release || exit 1
else
    log_info "Configuring for Debug..."
    ./scripts/configure.sh debug || exit 1
fi

# 2. Build Web App
log_info "Building Web App..."
(cd apps/web-app && bun install && bun run build) || exit 1

# 3. Build Server and/or Desktop
if [ $STANDALONE -eq 1 ]; then
    log_info "Building in Standalone mode..."
    # Build server
    (cd cpp-server && meson compile -C build) || exit 1
    # Copy server binary to tauri binaries folder
    mkdir -p apps/desktop-app/src-tauri/binaries
    cp cpp-server/build/cpp-server apps/desktop-app/src-tauri/binaries/cpp-server-x86_64-unknown-linux-gnu
    # Build desktop
    ./scripts/desktop-run.sh build || exit 1
else
    log_info "Building Server and Desktop..."
    (cd cpp-server && meson compile -C build) || exit 1
    ./scripts/desktop-run.sh build || exit 1
fi

log_step "Build complete!"
