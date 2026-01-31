#------------------------------------------------------------------------------
# QEDMMA Vivado Implementation Script
# Author: Dr. Mladen Mešter
# Copyright (c) 2026 Dr. Mladen Mešter - All Rights Reserved
#
# Usage: vivado -mode batch -source run_implementation.tcl -tclargs <project.xpr>
#------------------------------------------------------------------------------

if {$argc > 0} {
    set project_file [lindex $argv 0]
} else {
    set project_file "./vivado_project/qedmma_rx.xpr"
}

puts "Opening project: $project_file"
open_project $project_file

set impl_run [get_runs impl_1]
set_property strategy Performance_ExplorePostRoutePhysOpt $impl_run

puts "Launching implementation..."

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "Running synthesis first..."
    launch_runs synth_1 -jobs 8
    wait_on_run synth_1
}

reset_run impl_1
launch_runs impl_1 -jobs 8
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation status: $impl_status"

open_run impl_1

set report_dir "./reports/impl"
file mkdir $report_dir

report_timing_summary -file $report_dir/timing_summary.rpt
report_utilization -hierarchical -file $report_dir/utilization_hier.rpt
report_power -file $report_dir/power.rpt

puts "Generating bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

set bit_dir "./output"
file mkdir $bit_dir
file copy -force ./vivado_project/qedmma_rx.runs/impl_1/qedmma_rx_top.bit $bit_dir/
write_hw_platform -fixed -include_bit -force $bit_dir/qedmma_rx.xsa

puts "=========================================="
puts "IMPLEMENTATION COMPLETE"
puts "Bitstream: $bit_dir/qedmma_rx_top.bit"
puts "XSA:       $bit_dir/qedmma_rx.xsa"
puts "=========================================="

close_project
