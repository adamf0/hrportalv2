#!/bin/bash

# ==============================================================================
# Script: stop_all.sh
# Purpose: Stops all running HRPortal Golang services and background workers
# ==============================================================================

echo "Stopping all HRPortal Golang processes..."

pkill -f "hrportal_api" 2>/dev/null || true
pkill -f "notification_service" 2>/dev/null || true
pkill -f "autoverifysdm_worker" 2>/dev/null || true
pkill -f "holidaysync_worker" 2>/dev/null || true
pkill -f "export_worker" 2>/dev/null || true

echo "All HRPortal services and background workers have been stopped."
