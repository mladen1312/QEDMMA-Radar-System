#=============================================================================
# QEDMMA v3.2 - Vivado Build Script
# Target: Xilinx Zynq UltraScale+ ZU47DR RFSoC
# Author: Dr. Mladen Mešter
# Copyright (c) 2026 - All Rights Reserved
#
# Usage:
#   vivado -mode batch -source qedmma_v32_build.tcl
#   vivado -mode batch -source qedmma_v32_build.tcl -tclargs synth_only
#   vivado -mode batch -source qedmma_v32_build.tcl -tclargs impl_only
#=============================================================================

# Configuration
set PROJECT_NAME "qedmma_v32"
set PART "xczu47dr-2ffvg1517e"
set TOP_MODULE "qedmma_correlator_iq_wrapper"
set BUILD_DIR "./build"
set RTL_DIR "../../v2/rtl"
set CONSTRAINTS_DIR "../constraints"

# Parse arguments
set build_mode "full"
if {$argc > 0} {
    set build_mode [lindex $argv 0]
}

puts "============================================================"
puts " QEDMMA v3.2 - Vivado Build Script"
puts "============================================================"
puts " Project:  $PROJECT_NAME"
puts " Part:     $PART"
puts " Top:      $TOP_MODULE"
puts " Mode:     $build_mode"
puts "============================================================"

#=============================================================================
# Create Project
#=============================================================================
puts "\n[INFO] Creating project..."

file mkdir $BUILD_DIR
cd $BUILD_DIR

create_project $PROJECT_NAME . -part $PART -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

#=============================================================================
# Add RTL Sources
#=============================================================================
puts "\n[INFO] Adding RTL sources..."

# Correlator modules
add_files -fileset sources_1 [list \
    "$RTL_DIR/correlator/qedmma_correlator_bank_v32_core.sv" \
    "$RTL_DIR/correlator/qedmma_correlator_piso_axi.sv" \
    "$RTL_DIR/correlator/qedmma_correlator_iq_wrapper.sv" \
    "$RTL_DIR/correlator/qedmma_correlator_bank_v32.sv" \
    "$RTL_DIR/correlator/qedmma_correlator_bank_top.sv" \
    "$RTL_DIR/correlator/prbs_lfsr_generator.sv" \
    "$RTL_DIR/correlator/prbs20_segmented_correlator.sv" \
    "$RTL_DIR/correlator/coherent_integrator.sv" \
]

# Frontend modules
add_files -fileset sources_1 [list \
    "$RTL_DIR/frontend/digital_agc.sv" \
    "$RTL_DIR/frontend/polyphase_decimator.sv" \
]

# Fusion modules
add_files -fileset sources_1 [glob -nocomplain "$RTL_DIR/fusion/*.sv"]

# ECCM modules
add_files -fileset sources_1 [glob -nocomplain "$RTL_DIR/eccm/*.sv"]

# Sync modules
add_files -fileset sources_1 [glob -nocomplain "$RTL_DIR/sync/*.sv"]

# Comm modules
add_files -fileset sources_1 [glob -nocomplain "$RTL_DIR/comm/*.sv"]

# Top module
add_files -fileset sources_1 [glob -nocomplain "$RTL_DIR/top/*.sv"]

set_property top $TOP_MODULE [current_fileset]

#=============================================================================
# Add Constraints
#=============================================================================
puts "\n[INFO] Adding constraints..."

# Create constraints file if not exists
if {![file exists "$CONSTRAINTS_DIR/qedmma_v32_timing.xdc"]} {
    file mkdir $CONSTRAINTS_DIR
    set xdc_file [open "$CONSTRAINTS_DIR/qedmma_v32_timing.xdc" w]
    puts $xdc_file {
# QEDMMA v3.2 Timing Constraints
# Target: ZU47DR @ 200 MHz core clock

# Primary clocks
create_clock -period 5.000 -name clk_fast [get_ports clk]
create_clock -period 10.000 -name clk_axi [get_ports clk_axi]

# Clock groups
set_clock_groups -asynchronous \
    -group [get_clocks clk_fast] \
    -group [get_clocks clk_axi]

# Input delays (ADC)
set_input_delay -clock clk_fast -max 1.0 [get_ports {i_adc_i[*] i_adc_q[*]}]
set_input_delay -clock clk_fast -min 0.5 [get_ports {i_adc_i[*] i_adc_q[*]}]

# Output delays (AXI-Stream)
set_output_delay -clock clk_axi -max 2.0 [get_ports {m_axis_tdata[*] m_axis_tvalid m_axis_tlast}]
set_output_delay -clock clk_axi -min 1.0 [get_ports {m_axis_tdata[*] m_axis_tvalid m_axis_tlast}]

# False paths for async resets
set_false_path -from [get_ports rst_n]

# Max delay for control signals
set_max_delay 5.0 -from [get_ports i_dump_trigger] -to [all_registers]
    }
    close $xdc_file
}

add_files -fileset constrs_1 "$CONSTRAINTS_DIR/qedmma_v32_timing.xdc"

#=============================================================================
# Synthesis
#=============================================================================
if {$build_mode == "full" || $build_mode == "synth_only"} {
    puts "\n[INFO] Running synthesis..."
    
    # Synthesis settings
    set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
    set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
    set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt [get_runs synth_1]
    
    # Run synthesis
    launch_runs synth_1 -jobs 8
    wait_on_run synth_1
    
    # Check for errors
    if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
        puts "ERROR: Synthesis failed!"
        exit 1
    }
    
    # Open synthesized design for reports
    open_run synth_1 -name synth_1
    
    # Generate synthesis reports
    puts "\n[INFO] Generating synthesis reports..."
    report_utilization -file "${PROJECT_NAME}_synth_util.rpt"
    report_timing_summary -file "${PROJECT_NAME}_synth_timing.rpt"
    report_power -file "${PROJECT_NAME}_synth_power.rpt"
    
    puts "\n[INFO] Synthesis complete!"
    puts "  Utilization: ${PROJECT_NAME}_synth_util.rpt"
    puts "  Timing:      ${PROJECT_NAME}_synth_timing.rpt"
    puts "  Power:       ${PROJECT_NAME}_synth_power.rpt"
}

#=============================================================================
# Implementation
#=============================================================================
if {$build_mode == "full" || $build_mode == "impl_only"} {
    puts "\n[INFO] Running implementation..."
    
    # Implementation settings
    set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
    
    # Run implementation
    launch_runs impl_1 -jobs 8
    wait_on_run impl_1
    
    # Check for errors
    if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
        puts "ERROR: Implementation failed!"
        exit 1
    }
    
    # Open implemented design
    open_run impl_1 -name impl_1
    
    # Generate implementation reports
    puts "\n[INFO] Generating implementation reports..."
    report_utilization -file "${PROJECT_NAME}_impl_util.rpt"
    report_timing_summary -file "${PROJECT_NAME}_impl_timing.rpt"
    report_power -file "${PROJECT_NAME}_impl_power.rpt"
    report_drc -file "${PROJECT_NAME}_impl_drc.rpt"
    
    puts "\n[INFO] Implementation complete!"
}

#=============================================================================
# Generate Bitstream
#=============================================================================
if {$build_mode == "full"} {
    puts "\n[INFO] Generating bitstream..."
    
    launch_runs impl_1 -to_step write_bitstream -jobs 8
    wait_on_run impl_1
    
    # Copy bitstream
    file copy -force "./qedmma_v32.runs/impl_1/${TOP_MODULE}.bit" "./${PROJECT_NAME}.bit"
    
    puts "\n[INFO] Bitstream generated: ${PROJECT_NAME}.bit"
}

#=============================================================================
# Summary
#=============================================================================
puts "\n============================================================"
puts " QEDMMA v3.2 Build Complete"
puts "============================================================"
puts " Project:   $PROJECT_NAME"
puts " Part:      $PART"
puts " Top:       $TOP_MODULE"
puts " Bitstream: ${PROJECT_NAME}.bit"
puts "============================================================"

# Print resource summary
if {[current_design] != ""} {
    puts "\nResource Utilization Summary:"
    report_utilization -hierarchical -hierarchical_depth 2
}

puts "\n[INFO] Build script complete!"
