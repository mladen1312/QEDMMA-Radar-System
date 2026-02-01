#=============================================================================
# QEDMMA v3.2 - Vivado Build Script
# Target: Xilinx Zynq UltraScale+ ZU47DR RFSoC
# Author: Dr. Mladen Mešter
# Copyright (c) 2026
#
# Usage:
#   vivado -mode batch -source build_qedmma_v32.tcl
#   vivado -mode batch -source build_qedmma_v32.tcl -tclargs synth_only
#   vivado -mode batch -source build_qedmma_v32.tcl -tclargs impl_only
#=============================================================================

#-----------------------------------------------------------------------------
# Configuration
#-----------------------------------------------------------------------------
set PROJECT_NAME    "qedmma_v32"
set PART            "xczu47dr-2ffvg1517e"
set TOP_MODULE      "qedmma_correlator_iq_wrapper"
set BUILD_DIR       "./build"
set RTL_DIR         "../../v2/rtl"
set CONSTRAINT_DIR  "./constraints"

# Clock frequencies
set CLK_FAST_MHZ    200.0
set CLK_AXI_MHZ     100.0

# Build options
set RUN_SYNTH       1
set RUN_IMPL        1
set RUN_BITSTREAM   1
set JOBS            8

#-----------------------------------------------------------------------------
# Parse command line arguments
#-----------------------------------------------------------------------------
if {[llength $argv] > 0} {
    set arg [lindex $argv 0]
    if {$arg == "synth_only"} {
        set RUN_IMPL 0
        set RUN_BITSTREAM 0
    } elseif {$arg == "impl_only"} {
        set RUN_SYNTH 0
    }
}

#-----------------------------------------------------------------------------
# Create project
#-----------------------------------------------------------------------------
puts "============================================================"
puts " QEDMMA v3.2 - Vivado Build"
puts " Target: $PART"
puts " Top:    $TOP_MODULE"
puts "============================================================"

# Clean previous build
file delete -force $BUILD_DIR
file mkdir $BUILD_DIR

# Create project
create_project $PROJECT_NAME $BUILD_DIR -part $PART -force

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property default_lib work [current_project]

#-----------------------------------------------------------------------------
# Add RTL sources
#-----------------------------------------------------------------------------
puts "\n[INFO] Adding RTL sources..."

# Correlator modules (v3.2)
add_files -norecurse [list \
    "$RTL_DIR/correlator/qedmma_correlator_bank_v32_core.sv" \
    "$RTL_DIR/correlator/qedmma_correlator_piso_axi.sv" \
    "$RTL_DIR/correlator/qedmma_correlator_iq_wrapper.sv" \
    "$RTL_DIR/correlator/qedmma_correlator_bank_v32.sv" \
    "$RTL_DIR/correlator/qedmma_correlator_bank_top.sv" \
    "$RTL_DIR/correlator/prbs20_segmented_correlator.sv" \
    "$RTL_DIR/correlator/prbs_lfsr_generator.sv" \
    "$RTL_DIR/correlator/coherent_integrator.sv" \
]

# Frontend modules
add_files -norecurse [list \
    "$RTL_DIR/frontend/digital_agc.sv" \
    "$RTL_DIR/frontend/polyphase_decimator.sv" \
]

# Fusion modules
add_files -norecurse [glob -nocomplain "$RTL_DIR/fusion/*.sv"]

# ECCM modules
add_files -norecurse [glob -nocomplain "$RTL_DIR/eccm/*.sv"]

# Sync modules
add_files -norecurse [glob -nocomplain "$RTL_DIR/sync/*.sv"]

# Comm modules
add_files -norecurse [glob -nocomplain "$RTL_DIR/comm/*.sv"]

# Top level
add_files -norecurse [glob -nocomplain "$RTL_DIR/top/*.sv"]

# Set top module
set_property top $TOP_MODULE [current_fileset]

#-----------------------------------------------------------------------------
# Create constraints
#-----------------------------------------------------------------------------
puts "\n[INFO] Creating constraints..."

file mkdir $CONSTRAINT_DIR

# Create timing constraints
set xdc_file "$CONSTRAINT_DIR/qedmma_timing.xdc"
set fp [open $xdc_file w]

puts $fp "#============================================================"
puts $fp "# QEDMMA v3.2 Timing Constraints"
puts $fp "# Target: ZU47DR @ 200 MHz"
puts $fp "#============================================================"
puts $fp ""
puts $fp "# Primary clocks"
puts $fp "create_clock -period [expr {1000.0/$CLK_FAST_MHZ}] -name clk_fast \[get_ports clk\]"
puts $fp ""
puts $fp "# Clock groups (async)"
puts $fp "# set_clock_groups -asynchronous -group \[get_clocks clk_fast\] -group \[get_clocks clk_axi\]"
puts $fp ""
puts $fp "# Input delays (ADC interface)"
puts $fp "set_input_delay -clock clk_fast -max 1.5 \[get_ports i_adc_*\]"
puts $fp "set_input_delay -clock clk_fast -min 0.5 \[get_ports i_adc_*\]"
puts $fp ""
puts $fp "# Output delays (AXI-Stream)"
puts $fp "set_output_delay -clock clk_fast -max 1.5 \[get_ports m_axis_*\]"
puts $fp "set_output_delay -clock clk_fast -min 0.5 \[get_ports m_axis_*\]"
puts $fp ""
puts $fp "# False paths for async resets"
puts $fp "set_false_path -from \[get_ports rst_n\]"
puts $fp ""
puts $fp "# Multicycle paths for accumulator chains (if needed)"
puts $fp "# set_multicycle_path 2 -setup -from \[get_cells -hier -filter {NAME =~ *accumulators*}\]"

close $fp

add_files -fileset constrs_1 -norecurse $xdc_file

#-----------------------------------------------------------------------------
# Synthesis
#-----------------------------------------------------------------------------
if {$RUN_SYNTH} {
    puts "\n[INFO] Running synthesis..."
    
    # Synthesis settings
    set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
    set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
    set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true [get_runs synth_1]
    set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC true [get_runs synth_1]
    
    # Run synthesis
    launch_runs synth_1 -jobs $JOBS
    wait_on_run synth_1
    
    # Check for errors
    if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
        puts "ERROR: Synthesis failed!"
        exit 1
    }
    
    # Open synthesized design for reports
    open_run synth_1
    
    # Generate utilization report
    report_utilization -file "$BUILD_DIR/synth_utilization.rpt"
    report_timing_summary -file "$BUILD_DIR/synth_timing.rpt" -max_paths 100
    
    puts "\n[INFO] Synthesis complete!"
    puts "       Utilization: $BUILD_DIR/synth_utilization.rpt"
    puts "       Timing:      $BUILD_DIR/synth_timing.rpt"
}

#-----------------------------------------------------------------------------
# Implementation
#-----------------------------------------------------------------------------
if {$RUN_IMPL} {
    puts "\n[INFO] Running implementation..."
    
    # Implementation settings
    set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
    
    # Run implementation
    launch_runs impl_1 -jobs $JOBS
    wait_on_run impl_1
    
    # Check for errors
    if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
        puts "ERROR: Implementation failed!"
        exit 1
    }
    
    # Open implemented design
    open_run impl_1
    
    # Generate reports
    report_utilization -file "$BUILD_DIR/impl_utilization.rpt"
    report_timing_summary -file "$BUILD_DIR/impl_timing.rpt" -max_paths 100
    report_power -file "$BUILD_DIR/impl_power.rpt"
    report_drc -file "$BUILD_DIR/impl_drc.rpt"
    
    puts "\n[INFO] Implementation complete!"
    puts "       Utilization: $BUILD_DIR/impl_utilization.rpt"
    puts "       Timing:      $BUILD_DIR/impl_timing.rpt"
    puts "       Power:       $BUILD_DIR/impl_power.rpt"
}

#-----------------------------------------------------------------------------
# Bitstream Generation
#-----------------------------------------------------------------------------
if {$RUN_BITSTREAM} {
    puts "\n[INFO] Generating bitstream..."
    
    # Generate bitstream
    launch_runs impl_1 -to_step write_bitstream -jobs $JOBS
    wait_on_run impl_1
    
    # Copy bitstream
    file copy -force "$BUILD_DIR/$PROJECT_NAME.runs/impl_1/${TOP_MODULE}.bit" \
                     "$BUILD_DIR/qedmma_v32.bit"
    
    puts "\n[INFO] Bitstream generated: $BUILD_DIR/qedmma_v32.bit"
}

#-----------------------------------------------------------------------------
# Summary
#-----------------------------------------------------------------------------
puts "\n============================================================"
puts " QEDMMA v3.2 Build Complete"
puts "============================================================"
puts " Project:   $BUILD_DIR/$PROJECT_NAME.xpr"
puts " Bitstream: $BUILD_DIR/qedmma_v32.bit"
puts " Reports:   $BUILD_DIR/*.rpt"
puts "============================================================"

# Close project
close_project

exit 0
