#!/bin/bash
#=============================================================================
# QEDMMA v3.4 - Multi-Node Cluster Orchestration
# Deploys entire 6-node cluster in <10 minutes
#
# Author: Dr. Mladen Mešter
# Copyright (c) 2026 - All Rights Reserved
#
# Usage:
#   ./orchestrate_cluster.sh [--nodes "node1 node2 ..."]
#=============================================================================

set -e

# Default node list
NODES="node1 node2 node3 node4 node5 node6"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
DEPLOY_SCRIPT="/opt/qedmma/deploy/rapid/rapid_deploy.sh"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --nodes)
            NODES="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║   QEDMMA v3.4 - CLUSTER ORCHESTRATION                             ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Nodes: $NODES"
echo ""

START_TIME=$(date +%s)

#-----------------------------------------------------------------------------
# Phase 1: Parallel Boot & FPGA Load (all nodes simultaneously)
#-----------------------------------------------------------------------------
echo "[PHASE 1] Parallel FPGA configuration..."

pids=""
for node in $NODES; do
    echo "  Starting $node..."
    ssh $SSH_OPTS root@$node "$DEPLOY_SCRIPT --mode tactical &" &
    pids="$pids $!"
done

# Wait for all nodes
for pid in $pids; do
    wait $pid 2>/dev/null || true
done

echo "  All nodes initiated"

#-----------------------------------------------------------------------------
# Phase 2: White Rabbit Sync Verification
#-----------------------------------------------------------------------------
echo ""
echo "[PHASE 2] White Rabbit sync verification..."

sync_ok=0
for attempt in $(seq 1 30); do
    all_synced=1
    
    for node in $NODES; do
        status=$(ssh $SSH_OPTS root@$node "cat /sys/class/qedmma/wr/status 2>/dev/null || echo 'unknown'")
        if [[ "$status" != "locked" ]] && [[ "$status" != "holdover" ]]; then
            all_synced=0
        fi
    done
    
    if [[ $all_synced -eq 1 ]]; then
        sync_ok=1
        break
    fi
    
    echo -n "."
    sleep 2
done
echo ""

if [[ $sync_ok -eq 1 ]]; then
    echo "  ✅ All nodes synchronized"
else
    echo "  ⚠️ Some nodes may not be synchronized"
fi

#-----------------------------------------------------------------------------
# Phase 3: Verify All Nodes Operational
#-----------------------------------------------------------------------------
echo ""
echo "[PHASE 3] Verifying operational status..."

operational=0
for node in $NODES; do
    status=$(ssh $SSH_OPTS root@$node "pgrep -x qedmma_radar >/dev/null && echo 'running' || echo 'stopped'" 2>/dev/null)
    if [[ "$status" == "running" ]]; then
        echo "  ✅ $node: OPERATIONAL"
        operational=$((operational + 1))
    else
        echo "  ❌ $node: NOT RUNNING"
    fi
done

#-----------------------------------------------------------------------------
# Summary
#-----------------------------------------------------------------------------
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINS=$((ELAPSED / 60))
SECS=$((ELAPSED % 60))

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║   CLUSTER DEPLOYMENT SUMMARY                                      ║"
echo "╠═══════════════════════════════════════════════════════════════════╣"
echo "║   Total nodes:      $(echo $NODES | wc -w)                                               ║"
echo "║   Operational:      $operational                                               ║"
echo "║   Deployment time:  ${MINS}m ${SECS}s                                          ║"
if [[ $ELAPSED -lt 600 ]]; then
echo "║   Status:           ✅ TARGET MET (<10 min)                       ║"
else
echo "║   Status:           ⚠️ TARGET MISSED                              ║"
fi
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

exit $(($(echo $NODES | wc -w) - operational))
