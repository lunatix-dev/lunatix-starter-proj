#!/bin/bash

# Orchestration script for starting the project components

source "$(dirname "$0")/scripts/lib-utils.sh"

COMMAND=$1
shift

case $COMMAND in
    server)
        PORT=${1:-8080}
        log_step "Starting Server on port $PORT..."
        cd cpp-server && ./build/cpp-server --port "$PORT"
        ;;
    web)
        log_step "Starting Web App..."
        cd apps/web-app && bun install && bun run dev "$@"
        ;;
    web:standalone)
        log_step "Starting Web App in Standalone mode..."
        trap 'kill 0' EXIT
        bun run start:server "$1" & 
        bun run start:web -- ${2:+--port $2}
        ;;
    desktop)
        log_step "Starting Desktop App..."
        ./scripts/desktop-run.sh dev "$@"
        ;;
    desktop:standalone)
        log_step "Starting Desktop App in Standalone mode..."
        trap 'kill 0' EXIT
        # Ensure server is built and copied
        bun run copy:server
        LUNATIX_STANDALONE=1 ./scripts/desktop-run.sh dev "$@"
        ;;
    *)
        echo "Usage: $0 {server|web|web:standalone|desktop|desktop:standalone} [args...]"
        exit 1
        ;;
esac
