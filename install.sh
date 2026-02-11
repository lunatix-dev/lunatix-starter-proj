#!/bin/bash

# One-command installation and setup script

source "$(dirname "$0")/scripts/lib-utils.sh"
CONFIG=${1:-debug}

log_step "Starting Project Installation..."

# 1. Dependency check
log_info "Checking dependencies..."
./scripts/check-deps.sh || exit 1

# 2. Workspace install
log_info "Installing dependencies via Bun..."
bun install || exit 1

# 3. Configure debug build

log_info "Running initial configuration ($CONFIG)..."
./scripts/configure.sh $CONFIG || exit 1

# 4. Build all
log_info "Building the entire project..."
./build.sh || exit 1

log_step "Installation and Build complete!"

# 5. Start the application
read -p "Would you like to start the Web application now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./start.sh web
fi
