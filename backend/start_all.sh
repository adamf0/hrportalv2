#!/bin/bash

# ==============================================================================
# Script: start_all.sh
# Purpose: Compiles and runs all 5 separated HRPortal Golang services/workers
# ==============================================================================

set -e

# Set directory to script location
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

BIN_DIR="$DIR/bin"
mkdir -p "$BIN_DIR"

echo "======================================================================"
echo "          UNPAK HRPORTAL - COMPILING & STARTING ALL SERVICES          "
echo "======================================================================"

echo "[1/5] Building Main API Server (main.go)..."
go build -o "$BIN_DIR/hrportal_api" ./main.go

echo "[2/5] Building Notification Microservice (cmd/notificationservice)..."
go build -o "$BIN_DIR/notification_service" ./cmd/notificationservice/main.go

echo "[3/5] Building SDM Auto-Verify Worker (cmd/autoverifysdm)..."
go build -o "$BIN_DIR/autoverifysdm_worker" ./cmd/autoverifysdm/main.go

echo "[4/5] Building Holiday Sync Worker (cmd/holidaysync)..."
go build -o "$BIN_DIR/holidaysync_worker" ./cmd/holidaysync/main.go

echo "[5/5] Building Export Queue Worker (cmd/exportworker)..."
go build -o "$BIN_DIR/export_worker" ./cmd/exportworker/main.go

echo "----------------------------------------------------------------------"
echo " All 5 binaries compiled successfully! Starting services in background..."
echo "----------------------------------------------------------------------"

# Ensure environment variables
export PORT=${PORT:-3000}
export NOTIF_PORT=${NOTIF_PORT:-3001}

# Array to store process PIDs
PIDS=()

# Trap SIGINT (Ctrl+C) and SIGTERM to kill all child processes gracefully
cleanup() {
    echo ""
    echo "======================================================================"
    echo " Shutting down all HRPortal Golang services & background workers..."
    echo "======================================================================"
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
        fi
    done
    wait 2>/dev/null
    echo "All services stopped cleanly."
    exit 0
}

trap cleanup SIGINT SIGTERM

# 1. Start Main API Server
"$BIN_DIR/hrportal_api" &
PID_API=$!
PIDS+=($PID_API)
echo "[ONLINE] Main API Server running on PID $PID_API (Port: $PORT)"

# 2. Start Notification Microservice
PORT=$NOTIF_PORT "$BIN_DIR/notification_service" &
PID_NOTIF=$!
PIDS+=($PID_NOTIF)
echo "[ONLINE] Notification Service running on PID $PID_NOTIF (Port: $NOTIF_PORT)"

# 3. Start SDM Auto-Verify Worker
"$BIN_DIR/autoverifysdm_worker" &
PID_SDM=$!
PIDS+=($PID_SDM)
echo "[ONLINE] SDM Auto-Verify Worker running on PID $PID_SDM"

# 4. Start Holiday Sync Worker
"$BIN_DIR/holidaysync_worker" &
PID_HOLIDAY=$!
PIDS+=($PID_HOLIDAY)
echo "[ONLINE] Holiday Sync Worker running on PID $PID_HOLIDAY"

# 5. Start Export Worker
"$BIN_DIR/export_worker" &
PID_EXPORT=$!
PIDS+=($PID_EXPORT)
echo "[ONLINE] Export Queue Worker running on PID $PID_EXPORT"

echo "======================================================================"
echo " All 5 services are RUNNING! Press Ctrl+C to stop all services."
echo "======================================================================"

# Wait for all background processes
wait
