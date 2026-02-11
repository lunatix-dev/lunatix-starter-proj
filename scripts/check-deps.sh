#!/bin/bash

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Checking project dependencies..."

# Function to check if a command exists
check_cmd() {
    local cmd=$1
    local name=$2
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}ERROR: $name ($cmd) is not installed.${NC}"
        return 1
    else
        echo -e "${GREEN}OK: $name is installed.${NC}"
        return 0
    fi
}

FAILED=0

# Core tools
check_cmd "bun" "Bun" || FAILED=1
check_cmd "node" "Node.js" || FAILED=1
check_cmd "jq" "jq" || FAILED=1

# C++ Server tools
check_cmd "meson" "Meson" || FAILED=1
check_cmd "ninja" "Ninja" || FAILED=1

# Use provided compiler or default to g++
COMPILER=${1:-g++}
check_cmd "$COMPILER" "C++ Compiler ($COMPILER)" || FAILED=1
check_cmd "pkg-config" "pkg-config" || FAILED=1

# Rust/Desktop tools
check_cmd "rustc" "Rust Compiler" || FAILED=1
check_cmd "cargo" "Cargo" || FAILED=1

if [ $FAILED -ne 0 ]; then
    echo ""
    echo -e "${RED}Some dependencies are missing. Please install them to proceed.${NC}"
    exit 1
fi

echo -e "${GREEN}All dependencies met.${NC}"
exit 0
