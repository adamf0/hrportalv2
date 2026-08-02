#!/bin/bash

# ==============================================================================
# Script: stop_podman.sh
# Purpose: Stops all HRPortal services & workers running in Podman Compose
# ==============================================================================

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "======================================================================"
echo "          UNPAK HRPORTAL - STOPPING PODMAN SERVICES                 "
echo "======================================================================"

if command -v podman-compose &> /dev/null; then
    COMPOSE_CMD="podman-compose"
elif podman compose version &> /dev/null; then
    COMPOSE_CMD="podman compose"
else
    echo "[ERROR] Podman compose plugin (podman-compose or podman compose) is not installed."
    exit 1
fi

$COMPOSE_CMD -f podman-compose.yml down

echo "All Podman services stopped successfully."
