#------------------------------------------------------------------------------
# QEDMMA Vivado Implementation Script
# Radar Systems Architect v9.0 - Forge Spec
#
# Usage: vivado -mode batch -source run_implementation.tcl -tclargs <project.xpr>
#------------------------------------------------------------------------------

# Get project file
if {$argc > 0} {
    set project_file [lindex $argv 0]
} else {
    set project_file "./vivado_project/qedmma_rx.xpr"
}

puts "Opening project: $project_file"
open_project $project_file

#------------------------------------------------------------------------------
# Implementation Settings
#------------------------------------------------------------------------------
puts "Configuring implementation settings..."

set impl_run [get_runs impl_1]

# Set implementation strategy
set_property strategy Performance_ExplorePostRoutePhysOpt $impl_run

# Opt design
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE ExploreSequentialArea $impl_run

# Place design
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE ExtraNetDelay_high $impl_run

# Physical optimization
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true $impl_run
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $impl_run

# Route design
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE AggressiveExplore $impl_run

# Post-route physical optimization
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true $impl_run
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $impl_run

#------------------------------------------------------------------------------
# Run Implementation
#------------------------------------------------------------------------------
puts "Launching implementation..."

# Ensure synthesis is done
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "Running synthesis first..."
    launch_runs synth_1 -jobs 8
    wait_on_run synth_1
}

# Reset and run implementation
reset_run impl_1
launch_runs impl_1 -jobs 8
wait_on_run impl_1

#------------------------------------------------------------------------------
# Check Results
#------------------------------------------------------------------------------
set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation status: $impl_status"

if {$impl_status ne "route_design Complete!"} {
    puts "ERROR: Implementation failed!"
    exit 1
}

# Open implemented design
open_run impl_1

#------------------------------------------------------------------------------
# Generate Reports
#------------------------------------------------------------------------------
puts "Generating implementation reports..."

set report_dir "./reports/impl"
file mkdir $report_dir

# Timing (detailed)
report_timing_summary -delay_type min_max -report_unconstrained \
    -check_timing_verbose -max_paths 100 -slack_lesser_than 0 \
    -file $report_dir/timing_summary.rpt

# Critical paths
report_timing -of_objects [get_timing_paths -max_paths 50 -slack_lesser_than 0] \
    -file $report_dir/critical_paths.rpt

# Utilization
report_utilization -hierarchical -file $report_dir/utilization_hier.rpt

# Power
report_power -file $report_dir/power.rpt

# Clock utilization
report_clock_utilization -file $report_dir/clock_utilization.rpt

# IO
report_io -file $report_dir/io.rpt

# DRC
report_drc -file $report_dir/drc.rpt

# Methodology
report_methodology -file $report_dir/methodology.rpt

#------------------------------------------------------------------------------
# Generate Bitstream
#------------------------------------------------------------------------------
puts "Generating bitstream..."

launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# Copy bitstream to output directory
set bit_dir "./output"
file mkdir $bit_dir
file copy -force ./vivado_project/qedmma_rx.runs/impl_1/qedmma_rx_top.bit $bit_dir/

#------------------------------------------------------------------------------
# Export Hardware (for Vitis/PetaLinux)
#------------------------------------------------------------------------------
puts "Exporting hardware..."

write_hw_platform -fixed -include_bit -force $bit_dir/qedmma_rx.xsa

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
puts ""
puts "=========================================="
puts "IMPLEMENTATION COMPLETE"
puts "=========================================="

# Print timing summary
set wns [get_property STATS.WNS [get_runs impl_1]]
set tns [get_property STATS.TNS [get_runs impl_1]]
set whs [get_property STATS.WHS [get_runs impl_1]]

puts "Timing Summary:"
puts "  WNS (Setup): $wns ns"
puts "  TNS (Setup): $tns ns"
puts "  WHS (Hold):  $whs ns"

if {$wns < 0} {
    puts "WARNING: Setup timing not met!"
}
if {$whs < 0} {
    puts "WARNING: Hold timing not met!"
}

puts ""
puts "Outputs:"
puts "  Bitstream: $bit_dir/qedmma_rx_top.bit"
puts "  XSA:       $bit_dir/qedmma_rx.xsa"
puts "  Reports:   $report_dir/"
puts "=========================================="

close_project
