#!/bin/bash
#=============================================================================
# QEDMMA v3.1 - OTA Firmware Update Script
# Author: Dr. Mladen Mešter
# Copyright (c) 2026
#=============================================================================

set -e

VERSION="3.1.0"
FIRMWARE_URL="https://update.qedmma.com/firmware"
FIRMWARE_DIR="/lib/firmware/xilinx/qedmma"
BACKUP_DIR="/lib/firmware/xilinx/qedmma.backup"
TEMP_DIR="/tmp/qedmma_update"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[QEDMMA]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root"
fi

echo "=============================================="
echo " QEDMMA v3.1 OTA Update Utility"
echo "=============================================="

# Parse arguments
FORCE_UPDATE=0
CHECK_ONLY=0
LOCAL_FILE=""

while getopts "fcl:" opt; do
    case $opt in
        f) FORCE_UPDATE=1 ;;
        c) CHECK_ONLY=1 ;;
        l) LOCAL_FILE="$OPTARG" ;;
        *) echo "Usage: $0 [-f] [-c] [-l local_file]"; exit 1 ;;
    esac
done

# Get current version
CURRENT_VERSION=$(cat /etc/qedmma/version 2>/dev/null || echo "0.0.0")
log "Current version: $CURRENT_VERSION"

# Check for updates
if [ -z "$LOCAL_FILE" ]; then
    log "Checking for updates..."
    LATEST_VERSION=$(curl -s "$FIRMWARE_URL/latest.txt" 2>/dev/null || echo "")
    
    if [ -z "$LATEST_VERSION" ]; then
        error "Failed to check for updates"
    fi
    
    log "Latest version: $LATEST_VERSION"
    
    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ] && [ "$FORCE_UPDATE" -eq 0 ]; then
        log "Already up to date!"
        exit 0
    fi
    
    if [ "$CHECK_ONLY" -eq 1 ]; then
        echo "Update available: $LATEST_VERSION"
        exit 0
    fi
fi

# Create temp directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download or copy firmware
if [ -n "$LOCAL_FILE" ]; then
    log "Using local file: $LOCAL_FILE"
    cp "$LOCAL_FILE" firmware.tar.gz
else
    log "Downloading firmware v$LATEST_VERSION..."
    curl -L -o firmware.tar.gz "$FIRMWARE_URL/qedmma-$LATEST_VERSION.tar.gz"
fi

# Verify checksum
log "Verifying checksum..."
if [ -n "$LOCAL_FILE" ]; then
    warn "Skipping checksum verification for local file"
else
    curl -s -o firmware.sha256 "$FIRMWARE_URL/qedmma-$LATEST_VERSION.sha256"
    sha256sum -c firmware.sha256 || error "Checksum verification failed!"
fi

# Extract
log "Extracting firmware..."
tar -xzf firmware.tar.gz

# Backup current firmware
log "Backing up current firmware..."
rm -rf "$BACKUP_DIR"
cp -r "$FIRMWARE_DIR" "$BACKUP_DIR"

# Stop QEDMMA services
log "Stopping QEDMMA services..."
systemctl stop qedmma-radar.service || true
systemctl stop qedmma-control.service || true

# Install new firmware
log "Installing new firmware..."
cp -f *.bit "$FIRMWARE_DIR/"
cp -f *.dtbo "$FIRMWARE_DIR/"
cp -f *.xclbin "$FIRMWARE_DIR/" 2>/dev/null || true

# Update version file
echo "$LATEST_VERSION" > /etc/qedmma/version

# Reload FPGA
log "Reloading FPGA configuration..."
echo "qedmma_v3.bit" > /sys/class/fpga_manager/fpga0/firmware

# Start services
log "Starting QEDMMA services..."
systemctl start qedmma-control.service
systemctl start qedmma-radar.service

# Verify
sleep 5
if systemctl is-active --quiet qedmma-radar.service; then
    log "Update successful! Now running v$LATEST_VERSION"
else
    warn "Services failed to start, rolling back..."
    cp -r "$BACKUP_DIR"/* "$FIRMWARE_DIR/"
    systemctl start qedmma-radar.service
    error "Update failed, rolled back to previous version"
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo "=============================================="
echo " QEDMMA OTA Update Complete!"
echo "=============================================="
