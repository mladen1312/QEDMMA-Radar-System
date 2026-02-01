#=============================================================================
# QEDMMA v3.1 - QSPI Flash Programming Script
# Target: MT25QU01G QSPI Flash
# Author: Dr. Mladen Mešter
#=============================================================================

set BOOT_BIN "BOOT.BIN"
set IMAGE_UB "image.ub"
set QSPI_SIZE 0x8000000

puts "=============================================="
puts " QEDMMA v3.1 QSPI Flash Programming"
puts "=============================================="

# Connect
open_hw_manager
connect_hw_server
open_hw_target

# Get device
set device [get_hw_devices xczu47dr*]
current_hw_device $device

# Create flash device
create_hw_cfgmem -hw_device $device -mem_dev [lindex [get_cfgmem_parts mt25qu01g-spi-x1_x2_x4] 0]

# Set properties
set_property PROGRAM.ADDRESS_RANGE {use_file} [get_property PROGRAM.HW_CFGMEM $device]
set_property PROGRAM.FILES [list $BOOT_BIN] [get_property PROGRAM.HW_CFGMEM $device]
set_property PROGRAM.PRM_FILE {} [get_property PROGRAM.HW_CFGMEM $device]
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [get_property PROGRAM.HW_CFGMEM $device]
set_property PROGRAM.BLANK_CHECK 0 [get_property PROGRAM.HW_CFGMEM $device]
set_property PROGRAM.ERASE 1 [get_property PROGRAM.HW_CFGMEM $device]
set_property PROGRAM.CFG_PROGRAM 1 [get_property PROGRAM.HW_CFGMEM $device]
set_property PROGRAM.VERIFY 1 [get_property PROGRAM.HW_CFGMEM $device]

# Program
puts "Erasing and programming QSPI flash..."
program_hw_cfgmem -hw_cfgmem [get_property PROGRAM.HW_CFGMEM $device]

puts "QSPI programming complete!"

close_hw_target
disconnect_hw_server
close_hw_manager
