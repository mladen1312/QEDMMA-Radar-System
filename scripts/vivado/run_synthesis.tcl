#------------------------------------------------------------------------------
# QEDMMA Vivado Synthesis Script
# Author: Dr. Mladen Mešter
# Copyright (c) 2026 Dr. Mladen Mešter - All Rights Reserved
#
# Usage: vivado -mode batch -source run_synthesis.tcl -tclargs <project.xpr>
#------------------------------------------------------------------------------

if {$argc > 0} {
    set project_file [lindex $argv 0]
} else {
    set project_file "./vivado_project/qedmma_rx.xpr"
}

puts "Opening project: $project_file"
open_project $project_file

puts "Configuring synthesis settings..."

set synth_run [get_runs synth_1]
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true $synth_run

puts "Launching synthesis..."
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "Synthesis status: $synth_status"

open_run synth_1

set report_dir "./reports/synth"
file mkdir $report_dir

report_utilization -file $report_dir/utilization.rpt
report_timing_summary -file $report_dir/timing_summary.rpt
report_clocks -file $report_dir/clocks.rpt

puts "=========================================="
puts "SYNTHESIS COMPLETE"
puts "Reports saved to: $report_dir"
puts "=========================================="

close_project
