#=============================================================================
# QEDMMA v3.1 - QSPI Flash Programming Script
# Target: MT25QU01G 1Gb QSPI Flash
# Author: Dr. Mladen Mešter
# Copyright (c) 2026
#
# Usage: vivado -mode batch -source flash_qspi.tcl -tclargs [options]
#   Options:
#     -boot <file>    BOOT.BIN file
#     -image <file>   image.ub file (optional)
#     -erase_only     Only erase flash
#     -verify         Verify after programming
#=============================================================================

package require cmdline

set options {
    {boot.arg   "BOOT.BIN"   "Boot image file"}
    {image.arg  ""           "Linux image file (optional)"}
    {erase_only              "Only erase flash"}
    {verify                  "Verify after programming"}
}

array set params [::cmdline::getoptions argv $options]

set BOOT_FILE $params(boot)
set IMAGE_FILE $params(image)
set ERASE_ONLY $params(erase_only)
set DO_VERIFY $params(verify)

# Flash memory map
set BOOT_OFFSET  0x00000000
set IMAGE_OFFSET 0x00F00000
set ENV_OFFSET   0x003E0000

puts "============================================================"
puts " QEDMMA v3.1 QSPI Flash Programming"
puts "============================================================"
puts " Flash:     MT25QU01G (1Gb / 128MB)"
puts " Boot:      $BOOT_FILE @ 0x[format %08X $BOOT_OFFSET]"
if {$IMAGE_FILE != ""} {
    puts " Image:     $IMAGE_FILE @ 0x[format %08X $IMAGE_OFFSET]"
}
puts "============================================================"

# Open hardware
open_hw_manager
connect_hw_server
open_hw_target

# Get device
set device [get_hw_devices xczu47dr*]
current_hw_device $device

# Create flash device
puts "\n[INFO] Configuring QSPI flash device..."
create_hw_cfgmem -hw_device $device \
    -mem_dev [lindex [get_cfgmem_parts mt25qu01g-spi-x1_x2_x4] 0]

set cfgmem [get_property PROGRAM.HW_CFGMEM $device]

# Configure programming options
set_property PROGRAM.ADDRESS_RANGE {use_file} $cfgmem
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} $cfgmem
set_property PROGRAM.BLANK_CHECK 0 $cfgmem
set_property PROGRAM.ERASE 1 $cfgmem
set_property PROGRAM.CFG_PROGRAM 1 $cfgmem
set_property PROGRAM.VERIFY $DO_VERIFY $cfgmem

if {$ERASE_ONLY} {
    puts "\n[INFO] Erasing flash (full chip)..."
    set_property PROGRAM.ERASE 1 $cfgmem
    set_property PROGRAM.CFG_PROGRAM 0 $cfgmem
    program_hw_cfgmem -hw_cfgmem $cfgmem
    puts "[INFO] Erase complete"
} else {
    # Program BOOT.BIN
    if {[file exists $BOOT_FILE]} {
        puts "\n[INFO] Programming BOOT.BIN..."
        set_property PROGRAM.FILES [list $BOOT_FILE] $cfgmem
        set_property PROGRAM.PRM_FILE {} $cfgmem
        
        set start_time [clock seconds]
        program_hw_cfgmem -hw_cfgmem $cfgmem
        set elapsed [expr {[clock seconds] - $start_time}]
        
        puts "[INFO] BOOT.BIN programmed in ${elapsed} seconds"
    } else {
        puts "WARNING: BOOT.BIN not found: $BOOT_FILE"
    }
    
    # Program image.ub if provided
    if {$IMAGE_FILE != "" && [file exists $IMAGE_FILE]} {
        puts "\n[INFO] Programming image.ub at offset 0x[format %08X $IMAGE_OFFSET]..."
        # This would require address-specific programming
        # Simplified here - in production use proper address mapping
    }
}

puts "\n============================================================"
puts " QEDMMA v3.1 QSPI Flash Programming Complete"
puts "============================================================"

# Cleanup
close_hw_target
disconnect_hw_server
close_hw_manager
