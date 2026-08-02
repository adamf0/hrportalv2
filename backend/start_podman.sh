#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "======================================================================"
echo "          UNPAK HRPORTAL - STARTING SERVICES WITH PODMAN             "
echo "======================================================================"

echo "[1/5] Building hrportal-main..."
podman build -t hrportal-main:latest -f Containerfile.api .

echo "[2/5] Building hrportal-export..."
podman build -t hrportal-export:latest -f Containerfile.exportworker .

echo "[3/5] Building hrportal-notification..."
podman build -t hrportal-notification:latest -f Containerfile.notificationservice .

echo "[4/5] Building hrportal-autoverify..."
podman build -t hrportal-autoverify:latest -f Containerfile.autoverifysdm .

echo "[5/5] Building hrportal-holiday..."
podman build -t hrportal-holiday:latest -f Containerfile.holidaysync .

echo "Launching Podman containers..."
podman-compose -f podman-compose.yml up -d

echo "----------------------------------------------------------------------"
echo " All services and workers have been launched in Podman containers!"
echo "----------------------------------------------------------------------"
