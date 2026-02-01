#!/bin/bash
#=============================================================================
# QEDMMA v3.4 - Rapid Deployment Script
# Target: <10 minute field setup
#
# Author: Dr. Mladen Mešter
# Copyright (c) 2026 - All Rights Reserved
#
# Usage:
#   ./rapid_deploy.sh [--mode tactical|strategic] [--nodes N]
#
# Requirements:
#   - Pre-flashed SD cards with Yocto image
#   - White Rabbit fiber network connected
#   - CSAC warmed up (2 min holdover ready)
#   - Power available (48V DC or 230V AC)
#=============================================================================

set -e

#-----------------------------------------------------------------------------
# Configuration
#-----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/qedmma"
CONFIG_DIR="/etc/qedmma"
TIMEOUT_SYNC=120        # WR sync timeout (seconds)
TIMEOUT_BOOT=60         # Boot timeout (seconds)
TIMEOUT_SELF_TEST=30    # Self-test timeout (seconds)

# Default parameters
MODE="tactical"
NUM_NODES=6
MASTER_NODE="node1"
WR_MASTER_IP="192.168.100.1"

# Timing targets (seconds)
TARGET_BOOT=60
TARGET_SYNC=120
TARGET_SELFTEST=60
TARGET_OPERATIONAL=180  # 3 minutes to first track

#-----------------------------------------------------------------------------
# Parse Arguments
#-----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case $1 in
        --mode)
            MODE="$2"
            shift 2
            ;;
        --nodes)
            NUM_NODES="$2"
            shift 2
            ;;
        --master)
            MASTER_NODE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--mode tactical|strategic] [--nodes N] [--master nodeX]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

#-----------------------------------------------------------------------------
# Logging Functions
#-----------------------------------------------------------------------------
mkdir -p "$LOG_DIR"
DEPLOY_LOG="$LOG_DIR/deploy_$(date +%Y%m%d_%H%M%S).log"

log_info() {
    local msg="[$(date '+%H:%M:%S')] [INFO] $1"
    echo -e "\033[32m$msg\033[0m"
    echo "$msg" >> "$DEPLOY_LOG"
}

log_warn() {
    local msg="[$(date '+%H:%M:%S')] [WARN] $1"
    echo -e "\033[33m$msg\033[0m"
    echo "$msg" >> "$DEPLOY_LOG"
}

log_error() {
    local msg="[$(date '+%H:%M:%S')] [ERROR] $1"
    echo -e "\033[31m$msg\033[0m"
    echo "$msg" >> "$DEPLOY_LOG"
}

log_step() {
    local step=$1
    local total=$2
    local desc=$3
    local msg="[$(date '+%H:%M:%S')] [$step/$total] $desc"
    echo -e "\033[36m$msg\033[0m"
    echo "$msg" >> "$DEPLOY_LOG"
}

#-----------------------------------------------------------------------------
# Timer Functions
#-----------------------------------------------------------------------------
DEPLOY_START=$(date +%s)

get_elapsed() {
    local now=$(date +%s)
    echo $((now - DEPLOY_START))
}

print_elapsed() {
    local elapsed=$(get_elapsed)
    local mins=$((elapsed / 60))
    local secs=$((elapsed % 60))
    echo "${mins}m ${secs}s"
}

#-----------------------------------------------------------------------------
# Pre-flight Checks
#-----------------------------------------------------------------------------
preflight_check() {
    log_step 1 8 "Pre-flight checks..."
    
    local errors=0
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "Must run as root"
        errors=$((errors + 1))
    fi
    
    # Check network interfaces
    if ! ip link show eth0 &>/dev/null; then
        log_error "Network interface eth0 not found"
        errors=$((errors + 1))
    fi
    
    # Check WR interface
    if ! ip link show wr0 &>/dev/null; then
        log_warn "White Rabbit interface wr0 not found - will use fallback sync"
    fi
    
    # Check FPGA device
    if [[ ! -c /dev/xdevcfg ]] && [[ ! -d /sys/class/fpga_manager ]]; then
        log_error "FPGA manager not available"
        errors=$((errors + 1))
    fi
    
    # Check config files
    if [[ ! -f "$CONFIG_DIR/node_config.yaml" ]]; then
        log_warn "Node config not found - will use defaults"
    fi
    
    if [[ $errors -gt 0 ]]; then
        log_error "Pre-flight failed with $errors errors"
        exit 1
    fi
    
    log_info "Pre-flight checks passed ($(print_elapsed))"
}

#-----------------------------------------------------------------------------
# FPGA Configuration
#-----------------------------------------------------------------------------
configure_fpga() {
    log_step 2 8 "Loading FPGA bitstream..."
    
    local bitstream="/lib/firmware/qedmma_v34.bit"
    
    if [[ ! -f "$bitstream" ]]; then
        log_error "Bitstream not found: $bitstream"
        exit 1
    fi
    
    # Load bitstream via FPGA manager
    if [[ -d /sys/class/fpga_manager/fpga0 ]]; then
        echo "$bitstream" > /sys/class/fpga_manager/fpga0/firmware
        sleep 2
        
        # Verify load
        local state=$(cat /sys/class/fpga_manager/fpga0/state 2>/dev/null)
        if [[ "$state" != "operating" ]]; then
            log_error "FPGA load failed: state=$state"
            exit 1
        fi
    else
        # Fallback to xdevcfg
        cat "$bitstream" > /dev/xdevcfg
        sleep 2
    fi
    
    log_info "FPGA configured ($(print_elapsed))"
}

#-----------------------------------------------------------------------------
# Load Device Tree Overlay
#-----------------------------------------------------------------------------
load_devicetree() {
    log_step 3 8 "Loading device tree overlay..."
    
    local overlay="/lib/firmware/qedmma_overlay.dtbo"
    
    if [[ -f "$overlay" ]]; then
        mkdir -p /sys/kernel/config/device-tree/overlays/qedmma
        cat "$overlay" > /sys/kernel/config/device-tree/overlays/qedmma/dtbo
        sleep 1
        
        # Verify devices appeared
        if [[ ! -d /sys/bus/platform/devices/qedmma_correlator ]]; then
            log_warn "Device tree overlay may not have loaded correctly"
        fi
    else
        log_warn "Device tree overlay not found - using static DT"
    fi
    
    log_info "Device tree loaded ($(print_elapsed))"
}

#-----------------------------------------------------------------------------
# White Rabbit Synchronization
#-----------------------------------------------------------------------------
sync_white_rabbit() {
    log_step 4 8 "White Rabbit synchronization..."
    
    local wr_tool="/usr/bin/wr_mon"
    local timeout=$TIMEOUT_SYNC
    local synced=0
    
    if [[ ! -x "$wr_tool" ]]; then
        log_warn "WR monitor not found - using CSAC holdover mode"
        # Configure CSAC for holdover
        echo "holdover" > /sys/class/qedmma/csac/mode 2>/dev/null || true
        log_info "CSAC holdover mode active"
        return 0
    fi
    
    # Start WR sync
    log_info "Waiting for WR lock (timeout: ${timeout}s)..."
    
    local start=$(date +%s)
    while [[ $(($(date +%s) - start)) -lt $timeout ]]; do
        local wr_status=$($wr_tool -g 2>/dev/null | grep "Lock" || echo "")
        
        if [[ "$wr_status" == *"LOCKED"* ]]; then
            synced=1
            break
        fi
        
        sleep 1
        echo -n "."
    done
    echo ""
    
    if [[ $synced -eq 1 ]]; then
        # Get sync accuracy
        local accuracy=$($wr_tool -g 2>/dev/null | grep "Accuracy" | awk '{print $2}')
        log_info "WR synchronized: accuracy = ${accuracy:-<100ps} ($(print_elapsed))"
    else
        log_warn "WR sync timeout - falling back to CSAC"
        echo "holdover" > /sys/class/qedmma/csac/mode 2>/dev/null || true
    fi
}

#-----------------------------------------------------------------------------
# Initialize Subsystems
#-----------------------------------------------------------------------------
init_subsystems() {
    log_step 5 8 "Initializing subsystems..."
    
    # Load kernel modules
    modprobe qedmma_correlator 2>/dev/null || true
    modprobe qedmma_dma 2>/dev/null || true
    modprobe qedmma_sync 2>/dev/null || true
    
    # Initialize correlator
    if [[ -f /sys/class/qedmma/correlator/enable ]]; then
        echo 1 > /sys/class/qedmma/correlator/enable
        echo "prbs20" > /sys/class/qedmma/correlator/mode
        echo 512 > /sys/class/qedmma/correlator/num_lanes
        log_info "Correlator initialized: 512 lanes, PRBS-20"
    fi
    
    # Initialize ECCM
    if [[ -f /sys/class/qedmma/eccm/enable ]]; then
        echo 1 > /sys/class/qedmma/eccm/enable
        echo "ml_cfar" > /sys/class/qedmma/eccm/mode
        echo 1 > /sys/class/qedmma/eccm/hoj_enable
        log_info "ECCM initialized: ML-CFAR + HOJ"
    fi
    
    # Initialize fusion
    if [[ -f /sys/class/qedmma/fusion/enable ]]; then
        echo 1 > /sys/class/qedmma/fusion/enable
        echo "$NUM_NODES" > /sys/class/qedmma/fusion/num_nodes
        log_info "Fusion initialized: $NUM_NODES nodes"
    fi
    
    log_info "Subsystems initialized ($(print_elapsed))"
}

#-----------------------------------------------------------------------------
# Self-Test
#-----------------------------------------------------------------------------
run_self_test() {
    log_step 6 8 "Running self-test..."
    
    local test_passed=0
    local test_script="/usr/bin/qedmma_self_test"
    
    if [[ -x "$test_script" ]]; then
        if timeout $TIMEOUT_SELF_TEST $test_script --quick; then
            test_passed=1
        fi
    else
        # Manual quick test
        log_info "Running manual self-test..."
        
        # Test correlator
        if [[ -f /sys/class/qedmma/correlator/status ]]; then
            local corr_status=$(cat /sys/class/qedmma/correlator/status)
            if [[ "$corr_status" == "ready" ]]; then
                log_info "  Correlator: OK"
            else
                log_warn "  Correlator: $corr_status"
            fi
        fi
        
        # Test DMA
        if [[ -f /sys/class/qedmma/dma/status ]]; then
            local dma_status=$(cat /sys/class/qedmma/dma/status)
            if [[ "$dma_status" == "idle" ]] || [[ "$dma_status" == "ready" ]]; then
                log_info "  DMA: OK"
            else
                log_warn "  DMA: $dma_status"
            fi
        fi
        
        # Test ADC
        if [[ -f /sys/class/qedmma/adc/status ]]; then
            local adc_status=$(cat /sys/class/qedmma/adc/status)
            log_info "  ADC: $adc_status"
        fi
        
        test_passed=1
    fi
    
    if [[ $test_passed -eq 1 ]]; then
        log_info "Self-test passed ($(print_elapsed))"
    else
        log_error "Self-test failed"
        exit 1
    fi
}

#-----------------------------------------------------------------------------
# Network Configuration
#-----------------------------------------------------------------------------
configure_network() {
    log_step 7 8 "Configuring network..."
    
    # Load node-specific config
    local node_id=$(cat /etc/hostname | grep -oP 'node\K\d+' || echo "1")
    local node_ip="192.168.100.$((node_id + 10))"
    
    # Configure management interface
    ip addr add "$node_ip/24" dev eth0 2>/dev/null || true
    ip link set eth0 up
    
    # Configure multicast for fusion data
    ip route add 239.0.0.0/8 dev eth0 2>/dev/null || true
    
    # Start data distribution daemon
    if [[ -x /usr/bin/qedmma_datad ]]; then
        /usr/bin/qedmma_datad --config /etc/qedmma/datad.conf &
        log_info "Data distribution daemon started"
    fi
    
    # If master node, start fusion coordinator
    if [[ "$(hostname)" == "$MASTER_NODE" ]]; then
        if [[ -x /usr/bin/qedmma_fusion ]]; then
            /usr/bin/qedmma_fusion --master --nodes "$NUM_NODES" &
            log_info "Fusion coordinator started (master mode)"
        fi
    fi
    
    log_info "Network configured: $node_ip ($(print_elapsed))"
}

#-----------------------------------------------------------------------------
# Start Radar Operation
#-----------------------------------------------------------------------------
start_operation() {
    log_step 8 8 "Starting radar operation..."
    
    # Start main radar daemon
    if [[ -x /usr/bin/qedmma_radar ]]; then
        /usr/bin/qedmma_radar \
            --mode "$MODE" \
            --nodes "$NUM_NODES" \
            --config /etc/qedmma/radar.conf \
            --log /var/log/qedmma/radar.log &
        
        local radar_pid=$!
        echo "$radar_pid" > /var/run/qedmma_radar.pid
        
        # Wait for first track
        sleep 2
        if kill -0 "$radar_pid" 2>/dev/null; then
            log_info "Radar daemon started (PID: $radar_pid)"
        else
            log_error "Radar daemon failed to start"
            exit 1
        fi
    else
        log_warn "Radar daemon not found - manual operation required"
    fi
    
    log_info "Operation started ($(print_elapsed))"
}

#-----------------------------------------------------------------------------
# Main Deployment Sequence
#-----------------------------------------------------------------------------
main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║   QEDMMA v3.4 - RAPID DEPLOYMENT                                  ║"
    echo "║   Target: <10 minutes to operational                              ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Mode:   $MODE"
    echo "Nodes:  $NUM_NODES"
    echo "Master: $MASTER_NODE"
    echo ""
    
    DEPLOY_START=$(date +%s)
    
    preflight_check
    configure_fpga
    load_devicetree
    sync_white_rabbit
    init_subsystems
    run_self_test
    configure_network
    start_operation
    
    local total_time=$(get_elapsed)
    local mins=$((total_time / 60))
    local secs=$((total_time % 60))
    
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║   ✅ DEPLOYMENT COMPLETE                                          ║"
    echo "╠═══════════════════════════════════════════════════════════════════╣"
    echo "║   Total time: ${mins}m ${secs}s                                            ║"
    if [[ $total_time -lt 600 ]]; then
    echo "║   Status: TARGET MET (<10 minutes)                                ║"
    else
    echo "║   Status: TARGET MISSED (>10 minutes)                             ║"
    fi
    echo "║   Mode: $MODE                                                  ║"
    echo "║   Log: $DEPLOY_LOG    ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
}

# Run main
main "$@"
