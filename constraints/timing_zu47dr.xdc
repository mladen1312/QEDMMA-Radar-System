#------------------------------------------------------------------------------
# QEDMMA Timing Constraints for Zynq UltraScale+ RFSoC ZU47DR
# Author: Dr. Mladen Mešter
# Copyright (c) 2026 Dr. Mladen Mešter - All Rights Reserved
#
# Target: ZCU216 Evaluation Kit (or custom board)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Clock Definitions
#------------------------------------------------------------------------------

# ADC Tile Clock (from RFSoC ADC)
create_clock -period 0.800 -name adc_clk [get_ports adc_clk]

# AXI-Stream Processing Clock (250 MHz)
create_clock -period 4.000 -name axis_clk [get_ports axis_clk]

# AXI-Lite Register Clock (100-250 MHz)
create_clock -period 4.000 -name axi_clk [get_ports axi_clk]

#------------------------------------------------------------------------------
# Clock Domain Crossing
#------------------------------------------------------------------------------

set_clock_groups -asynchronous \
    -group [get_clocks adc_clk] \
    -group [get_clocks axis_clk]

set_clock_groups -asynchronous \
    -group [get_clocks axis_clk] \
    -group [get_clocks axi_clk]

#------------------------------------------------------------------------------
# Input Constraints
#------------------------------------------------------------------------------

set_input_delay -clock adc_clk -max 0.300 [get_ports {adc_data[*]}]
set_input_delay -clock adc_clk -min 0.100 [get_ports {adc_data[*]}]

set_input_delay -clock axis_clk -max 3.000 [get_ports pps_in]
set_input_delay -clock axis_clk -min 0.000 [get_ports pps_in]

set_false_path -from [get_ports pps_in] -to [get_clocks axis_clk]

#------------------------------------------------------------------------------
# Output Constraints
#------------------------------------------------------------------------------

set_output_delay -clock axis_clk -max 1.500 [get_ports {m_axis_tdata[*]}]
set_output_delay -clock axis_clk -min 0.500 [get_ports {m_axis_tdata[*]}]
set_output_delay -clock axis_clk -max 1.500 [get_ports m_axis_tvalid]
set_output_delay -clock axis_clk -min 0.500 [get_ports m_axis_tvalid]

#------------------------------------------------------------------------------
# False Paths
#------------------------------------------------------------------------------

set_false_path -from [get_cells */cfg_*_reg*]
set_false_path -from [get_ports rst_n]
set_false_path -from [get_cells */VERSION_reg*]

#------------------------------------------------------------------------------
# End of Constraints
#------------------------------------------------------------------------------
