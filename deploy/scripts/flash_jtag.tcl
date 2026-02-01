#=============================================================================
# QEDMMA v3.1 - JTAG Flashing Script
# Target: Xilinx Zynq UltraScale+ ZU47DR
# Author: Dr. Mladen Mešter
# Copyright (c) 2026
#
# Usage: vivado -mode batch -source flash_jtag.tcl -tclargs [options]
#   Options:
#     -bit <file>     Bitstream file (default: qedmma_v3.bit)
#     -ltx <file>     Debug probes file (optional)
#     -cable <serial> Specific JTAG cable serial number
#     -verify         Verify after programming
#=============================================================================

package require cmdline

# Parse command line arguments
set options {
    {bit.arg    "qedmma_v3.bit"  "Bitstream file"}
    {ltx.arg    ""               "Debug probes file (optional)"}
    {cable.arg  ""               "JTAG cable serial number"}
    {verify                      "Verify after programming"}
}

array set params [::cmdline::getoptions argv $options]

set BIT_FILE $params(bit)
set LTX_FILE $params(ltx)
set CABLE_SERIAL $params(cable)
set DO_VERIFY $params(verify)
set DEVICE_PART "xczu47dr*"

puts "============================================================"
puts " QEDMMA v3.1 JTAG Flashing Utility"
puts "============================================================"
puts " Bitstream: $BIT_FILE"
puts " Device:    Zynq UltraScale+ ZU47DR"
puts "============================================================"

# Verify bitstream exists
if {![file exists $BIT_FILE]} {
    puts "ERROR: Bitstream file not found: $BIT_FILE"
    exit 1
}

# Open hardware manager
puts "\n[INFO] Opening hardware manager..."
open_hw_manager

# Connect to hardware server
puts "[INFO] Connecting to hardware server..."
connect_hw_server -allow_non_jtag

# Get available targets
set targets [get_hw_targets]
puts "[INFO] Available JTAG targets:"
foreach t $targets {
    puts "       - $t"
}

# Open target
if {$CABLE_SERIAL != ""} {
    puts "[INFO] Opening target with serial: $CABLE_SERIAL"
    set target [get_hw_targets *$CABLE_SERIAL*]
} else {
    puts "[INFO] Opening first available target"
    set target [lindex $targets 0]
}

if {$target == ""} {
    puts "ERROR: No JTAG target found"
    disconnect_hw_server
    close_hw_manager
    exit 1
}

open_hw_target $target

# Get device
set device [get_hw_devices $DEVICE_PART]
if {$device == ""} {
    puts "ERROR: ZU47DR device not found on JTAG chain"
    close_hw_target
    disconnect_hw_server
    close_hw_manager
    exit 1
}

puts "[INFO] Found device: $device"
current_hw_device $device

# Set programming file
set_property PROGRAM.FILE $BIT_FILE $device

# Program device
puts "\n[INFO] Programming FPGA..."
puts "       This may take 30-60 seconds..."

set start_time [clock seconds]
program_hw_devices $device
set end_time [clock seconds]
set elapsed [expr {$end_time - $start_time}]

puts "[INFO] Programming completed in ${elapsed} seconds"

# Refresh device
refresh_hw_device $device

# Verify if requested
if {$DO_VERIFY} {
    puts "\n[INFO] Verifying programming..."
    # Read back and compare (simplified check)
    set done_pin [get_property DONE_PIN $device]
    if {$done_pin == 1} {
        puts "[INFO] DONE pin HIGH - Configuration successful"
    } else {
        puts "ERROR: DONE pin LOW - Configuration may have failed"
    }
}

# Load debug probes if provided
if {$LTX_FILE != "" && [file exists $LTX_FILE]} {
    puts "\n[INFO] Loading debug probes: $LTX_FILE"
    set_property PROBES.FILE $LTX_FILE $device
    refresh_hw_device $device
    puts "[INFO] Debug probes loaded - ILA cores available"
}

# Report final status
puts "\n============================================================"
puts " QEDMMA v3.1 FPGA Configuration Complete"
puts "============================================================"
puts " Device:     $device"
puts " Bitstream:  $BIT_FILE"
puts " Status:     SUCCESS"
puts "============================================================"

# Cleanup
close_hw_target
disconnect_hw_server
close_hw_manager

puts "\n[INFO] JTAG session closed"
exit 0
