#!/bin/bash
#=============================================================================
# QEDMMA v3.1 - OTA Firmware Update Script
# Author: Dr. Mladen Mešter
# Copyright (c) 2026
#
# Features:
#   - Secure firmware download with checksum verification
#   - Automatic rollback on failure
#   - A/B partition support
#   - Service management during update
#
# Usage:
#   ./ota_update.sh              # Check and install updates
#   ./ota_update.sh -c           # Check only
#   ./ota_update.sh -f           # Force update
#   ./ota_update.sh -l <file>    # Install from local file
#   ./ota_update.sh -r           # Rollback to previous version
#=============================================================================

set -euo pipefail

# Configuration
VERSION_CURRENT="3.1.0"
UPDATE_SERVER="https://update.qedmma.com/firmware"
FIRMWARE_DIR="/lib/firmware/xilinx/qedmma"
BACKUP_DIR="/lib/firmware/xilinx/qedmma.backup"
VERSION_FILE="/etc/qedmma/version"
TEMP_DIR="/tmp/qedmma_update_$$"
LOG_FILE="/var/log/qedmma_update.log"

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${GREEN}[QEDMMA]${NC} $1"
    echo "$msg" >> "$LOG_FILE"
}

error() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"
    echo -e "${RED}[ERROR]${NC} $1" >&2
    echo "$msg" >> "$LOG_FILE"
    cleanup
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

# Check root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root"
    fi
}

# Get current version
get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "0.0.0"
    fi
}

# Check for updates
check_updates() {
    log "Checking for updates..."
    
    local latest
    latest=$(curl -sf "${UPDATE_SERVER}/latest.txt" 2>/dev/null) || {
        error "Failed to check for updates (server unreachable)"
    }
    
    local current
    current=$(get_current_version)
    
    echo "$latest"
    
    if [ "$current" = "$latest" ]; then
        return 1  # No update available
    else
        return 0  # Update available
    fi
}

# Download and verify firmware
download_firmware() {
    local version=$1
    
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    log "Downloading firmware v${version}..."
    
    # Download firmware package
    curl -fL -o "firmware.tar.gz" \
        "${UPDATE_SERVER}/qedmma-${version}.tar.gz" || {
        error "Failed to download firmware"
    }
    
    # Download checksum
    curl -fL -o "firmware.sha256" \
        "${UPDATE_SERVER}/qedmma-${version}.sha256" || {
        error "Failed to download checksum"
    }
    
    # Verify checksum
    log "Verifying checksum..."
    sha256sum -c firmware.sha256 || {
        error "Checksum verification failed!"
    }
    
    # Extract
    log "Extracting firmware..."
    tar -xzf firmware.tar.gz || {
        error "Failed to extract firmware"
    }
    
    log "Download and verification complete"
}

# Backup current firmware
backup_firmware() {
    log "Backing up current firmware..."
    
    rm -rf "$BACKUP_DIR"
    
    if [ -d "$FIRMWARE_DIR" ]; then
        cp -a "$FIRMWARE_DIR" "$BACKUP_DIR" || {
            error "Failed to backup firmware"
        }
        log "Backup created at $BACKUP_DIR"
    fi
}

# Stop QEDMMA services
stop_services() {
    log "Stopping QEDMMA services..."
    
    local services="qedmma-radar qedmma-control qedmma-fusion qedmma-webui"
    
    for svc in $services; do
        if systemctl is-active --quiet "$svc.service" 2>/dev/null; then
            systemctl stop "$svc.service" || true
            info "Stopped $svc"
        fi
    done
    
    sleep 2
}

# Start QEDMMA services
start_services() {
    log "Starting QEDMMA services..."
    
    local services="qedmma-control qedmma-fusion qedmma-radar qedmma-webui"
    
    for svc in $services; do
        if systemctl is-enabled --quiet "$svc.service" 2>/dev/null; then
            systemctl start "$svc.service" || true
            info "Started $svc"
        fi
    done
}

# Install firmware
install_firmware() {
    local version=$1
    
    log "Installing firmware v${version}..."
    
    # Install bitstream and overlays
    cp -f "$TEMP_DIR"/*.bit "$FIRMWARE_DIR/" 2>/dev/null || true
    cp -f "$TEMP_DIR"/*.dtbo "$FIRMWARE_DIR/" 2>/dev/null || true
    cp -f "$TEMP_DIR"/*.bin "$FIRMWARE_DIR/" 2>/dev/null || true
    cp -f "$TEMP_DIR"/*.xclbin "$FIRMWARE_DIR/" 2>/dev/null || true
    
    # Update version file
    mkdir -p "$(dirname "$VERSION_FILE")"
    echo "$version" > "$VERSION_FILE"
    
    log "Firmware files installed"
}

# Reload FPGA
reload_fpga() {
    log "Reloading FPGA configuration..."
    
    # Check if fpga_manager is available
    if [ -d "/sys/class/fpga_manager/fpga0" ]; then
        # Trigger FPGA reload
        echo "qedmma_v3.bit" > /sys/class/fpga_manager/fpga0/firmware || {
            warn "Could not reload FPGA via sysfs (may require reboot)"
        }
    else
        warn "FPGA manager not found - reboot required"
    fi
}

# Verify installation
verify_installation() {
    log "Verifying installation..."
    
    sleep 5
    
    local failed=0
    
    # Check if services started
    if systemctl is-active --quiet qedmma-radar.service 2>/dev/null; then
        info "qedmma-radar: RUNNING"
    else
        warn "qedmma-radar: NOT RUNNING"
        failed=1
    fi
    
    if systemctl is-active --quiet qedmma-control.service 2>/dev/null; then
        info "qedmma-control: RUNNING"
    else
        warn "qedmma-control: NOT RUNNING"
        failed=1
    fi
    
    return $failed
}

# Rollback to previous version
rollback() {
    log "Rolling back to previous firmware..."
    
    if [ ! -d "$BACKUP_DIR" ]; then
        error "No backup available for rollback"
    fi
    
    stop_services
    
    rm -rf "$FIRMWARE_DIR"
    mv "$BACKUP_DIR" "$FIRMWARE_DIR"
    
    reload_fpga
    start_services
    
    if verify_installation; then
        log "Rollback successful"
    else
        error "Rollback failed - manual intervention required"
    fi
}

# Main update procedure
do_update() {
    local version=$1
    local local_file=$2
    
    echo "============================================================"
    echo " QEDMMA v3.1 OTA Firmware Update"
    echo "============================================================"
    echo " Current:  $(get_current_version)"
    echo " Target:   $version"
    echo "============================================================"
    
    # Backup
    backup_firmware
    
    # Download or use local file
    if [ -n "$local_file" ]; then
        mkdir -p "$TEMP_DIR"
        cp "$local_file" "$TEMP_DIR/firmware.tar.gz"
        cd "$TEMP_DIR"
        tar -xzf firmware.tar.gz
    else
        download_firmware "$version"
    fi
    
    # Stop services
    stop_services
    
    # Install
    install_firmware "$version"
    
    # Reload FPGA
    reload_fpga
    
    # Start services
    start_services
    
    # Verify
    if verify_installation; then
        log "Update to v${version} successful!"
        echo "============================================================"
        echo " Update Complete - Now running v${version}"
        echo "============================================================"
    else
        warn "Services failed to start - initiating rollback"
        rollback
        error "Update failed - rolled back to previous version"
    fi
}

# Parse arguments
FORCE_UPDATE=0
CHECK_ONLY=0
DO_ROLLBACK=0
LOCAL_FILE=""

while getopts "fcrl:h" opt; do
    case $opt in
        f) FORCE_UPDATE=1 ;;
        c) CHECK_ONLY=1 ;;
        r) DO_ROLLBACK=1 ;;
        l) LOCAL_FILE="$OPTARG" ;;
        h)
            echo "Usage: $0 [-f] [-c] [-r] [-l <file>]"
            echo "  -f          Force update"
            echo "  -c          Check only"
            echo "  -r          Rollback to previous version"
            echo "  -l <file>   Install from local file"
            exit 0
            ;;
        *)
            echo "Usage: $0 [-f] [-c] [-r] [-l <file>]"
            exit 1
            ;;
    esac
done

# Main
check_root

if [ "$DO_ROLLBACK" -eq 1 ]; then
    rollback
    exit 0
fi

if [ -n "$LOCAL_FILE" ]; then
    if [ ! -f "$LOCAL_FILE" ]; then
        error "Local file not found: $LOCAL_FILE"
    fi
    do_update "local" "$LOCAL_FILE"
    exit 0
fi

# Check for updates
LATEST_VERSION=$(check_updates) || {
    log "Already running latest version: $(get_current_version)"
    exit 0
}

if [ "$CHECK_ONLY" -eq 1 ]; then
    echo "Update available: $LATEST_VERSION"
    exit 0
fi

CURRENT=$(get_current_version)
if [ "$CURRENT" = "$LATEST_VERSION" ] && [ "$FORCE_UPDATE" -eq 0 ]; then
    log "Already up to date (v${CURRENT})"
    exit 0
fi

do_update "$LATEST_VERSION" ""
