#------------------------------------------------------------------------------
# QEDMMA Vivado Synthesis Script
# Radar Systems Architect v9.0 - Forge Spec
#
# Usage: vivado -mode batch -source run_synthesis.tcl -tclargs <project.xpr>
#------------------------------------------------------------------------------

# Get project file from arguments
if {$argc > 0} {
    set project_file [lindex $argv 0]
} else {
    set project_file "./vivado_project/qedmma_rx.xpr"
}

puts "Opening project: $project_file"
open_project $project_file

#------------------------------------------------------------------------------
# Synthesis Settings
#------------------------------------------------------------------------------
puts "Configuring synthesis settings..."

# Get synthesis run
set synth_run [get_runs synth_1]

# Set synthesis strategy (Performance_Explore for timing closure)
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]

# Additional synthesis options
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} \
    -value {-mode out_of_context} -objects $synth_run
    
# Flatten hierarchy for timing
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt $synth_run

# Enable retiming for performance
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true $synth_run

# FSM encoding
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION one_hot $synth_run

#------------------------------------------------------------------------------
# Run Synthesis
#------------------------------------------------------------------------------
puts "Launching synthesis..."

reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

#------------------------------------------------------------------------------
# Check Results
#------------------------------------------------------------------------------
set synth_status [get_property STATUS [get_runs synth_1]]
puts "Synthesis status: $synth_status"

if {$synth_status ne "synth_design Complete!"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

# Open synthesized design for analysis
open_run synth_1

#------------------------------------------------------------------------------
# Generate Reports
#------------------------------------------------------------------------------
puts "Generating synthesis reports..."

set report_dir "./reports/synth"
file mkdir $report_dir

# Utilization report
report_utilization -file $report_dir/utilization.rpt

# Timing summary
report_timing_summary -file $report_dir/timing_summary.rpt

# Clock networks
report_clocks -file $report_dir/clocks.rpt

# CDC analysis
report_cdc -file $report_dir/cdc.rpt

# Power estimate
report_power -file $report_dir/power_estimate.rpt

# DRC
report_drc -file $report_dir/drc.rpt

#------------------------------------------------------------------------------
# Resource Summary
#------------------------------------------------------------------------------
puts ""
puts "=========================================="
puts "SYNTHESIS COMPLETE"
puts "=========================================="

# Print utilization summary
set util [report_utilization -return_string]
puts $util

puts ""
puts "Reports saved to: $report_dir"
puts "=========================================="

close_project
