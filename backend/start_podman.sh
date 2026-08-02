#!/bin/bash

# ==============================================================================
# Script: start_podman.sh
# Purpose: Builds and runs all HRPortal services & workers using Podman Compose
# ==============================================================================

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "======================================================================"
echo "          UNPAK HRPORTAL - STARTING SERVICES WITH PODMAN             "
echo "======================================================================"

if command -v podman-compose &> /dev/null; then
    COMPOSE_CMD="podman-compose"
elif podman compose version &> /dev/null; then
    COMPOSE_CMD="podman compose"
else
    echo "[ERROR] Podman compose plugin (podman-compose or podman compose) is not installed."
    echo "Please install podman and podman-compose."
    exit 1
fi

echo "Using compose command: $COMPOSE_CMD"
$COMPOSE_CMD -f podman-compose.yml up -d --build

echo "----------------------------------------------------------------------"
echo " All services and workers have been launched in Podman containers!"
echo "----------------------------------------------------------------------"
