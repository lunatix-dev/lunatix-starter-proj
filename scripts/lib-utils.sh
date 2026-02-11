#!/bin/bash

# Standardized logging and utility functions

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}==>${NC} $1"
}

ensure_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Command '$1' not found. Please install it."
        return 1
    fi
    return 0
}

# Source this file to use these functions
