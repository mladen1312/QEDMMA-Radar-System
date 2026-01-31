#------------------------------------------------------------------------------
# QEDMMA Vivado Project Creation Script
# Author: Dr. Mladen Mešter
# Copyright (c) 2026 Dr. Mladen Mešter - All Rights Reserved
#
# Target: Xilinx Zynq UltraScale+ RFSoC ZU47DR
# Board: ZCU216 Evaluation Kit (or custom)
#
# Usage: vivado -mode batch -source create_project.tcl
#------------------------------------------------------------------------------

# Project settings
set project_name "qedmma_rx"
set project_dir  "./vivado_project"
set part         "xczu47dr-ffve1156-2-e"
set board        ""

# Source directories
set rtl_dir      "../../rtl"
set tb_dir       "../../tb"
set constr_dir   "../../constraints"

#------------------------------------------------------------------------------
# Create Project
#------------------------------------------------------------------------------
puts "Creating QEDMMA project for $part..."

create_project $project_name $project_dir -part $part -force

set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property default_lib work [current_project]

#------------------------------------------------------------------------------
# Add RTL Sources
#------------------------------------------------------------------------------
puts "Adding RTL sources..."

add_files -norecurse [glob -nocomplain $rtl_dir/*.sv]
add_files -norecurse [glob -nocomplain $rtl_dir/*.v]
add_files -norecurse [glob -nocomplain $rtl_dir/*.vhd]

foreach f [get_files -filter {FILE_TYPE == "Verilog"}] {
    if {[string match "*.sv" $f]} {
        set_property FILE_TYPE SystemVerilog [get_files $f]
    }
}

set_property top qedmma_rx_top [current_fileset]

#------------------------------------------------------------------------------
# Add Constraints
#------------------------------------------------------------------------------
puts "Adding constraints..."

file mkdir $constr_dir

if {[llength [glob -nocomplain $constr_dir/*.xdc]] > 0} {
    add_files -fileset constrs_1 -norecurse [glob $constr_dir/*.xdc]
}

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
puts "=========================================="
puts "QEDMMA Project Created Successfully!"
puts "=========================================="
puts "Project: $project_dir/$project_name.xpr"
puts "Part:    $part"
puts "Top:     qedmma_rx_top"
puts "=========================================="
