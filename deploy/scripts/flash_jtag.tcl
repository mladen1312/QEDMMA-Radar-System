#=============================================================================
# QEDMMA v3.1 - JTAG Flashing Script
# Target: Xilinx Zynq UltraScale+ ZU47DR
# Author: Dr. Mladen Mešter
# Copyright (c) 2026
#
# Usage: vivado -mode batch -source flash_jtag.tcl
#=============================================================================

# Configuration
set BIT_FILE "qedmma_v3.bit"
set LTX_FILE "qedmma_v3.ltx"
set DEVICE "xczu47dr"
set CABLE_SERIAL ""

puts "=============================================="
puts " QEDMMA v3.1 JTAG Flashing Utility"
puts "=============================================="

# Open hardware manager
open_hw_manager

# Connect to hardware server
connect_hw_server -allow_non_jtag

# Get available targets
set targets [get_hw_targets]
puts "Available targets: $targets"

# Open first target (or specific cable)
if {$CABLE_SERIAL != ""} {
    open_hw_target [get_hw_targets *$CABLE_SERIAL*]
} else {
    open_hw_target [lindex $targets 0]
}

# Get device
set device [get_hw_devices $DEVICE*]
puts "Programming device: $device"

# Set programming file
set_property PROGRAM.FILE $BIT_FILE $device

# Program device
puts "Programming FPGA..."
program_hw_devices $device

# Verify
refresh_hw_device $device
puts "Programming complete!"

# Optional: Load debug probes
if {[file exists $LTX_FILE]} {
    puts "Loading debug probes..."
    set_property PROBES.FILE $LTX_FILE $device
    refresh_hw_device $device
}

puts "=============================================="
puts " QEDMMA v3.1 FPGA Configuration Complete"
puts "=============================================="

# Close
close_hw_target
disconnect_hw_server
close_hw_manager
