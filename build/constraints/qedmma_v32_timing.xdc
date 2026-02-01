#=============================================================================
# QEDMMA v3.2 - Timing Constraints
# Target: Xilinx Zynq UltraScale+ ZU47DR RFSoC
# Author: Dr. Mladen Mešter
# Copyright (c) 2026 - All Rights Reserved
#=============================================================================

#-----------------------------------------------------------------------------
# Primary Clocks
#-----------------------------------------------------------------------------
# Fast clock (200 MHz) - ADC/correlator domain
create_clock -period 5.000 -name clk_fast [get_ports clk]

# AXI clock (100 MHz) - PS interface domain  
# Uncomment if separate AXI clock
# create_clock -period 10.000 -name clk_axi [get_ports clk_axi]

#-----------------------------------------------------------------------------
# Clock Domain Crossings
#-----------------------------------------------------------------------------
# set_clock_groups -asynchronous \
#     -group [get_clocks clk_fast] \
#     -group [get_clocks clk_axi]

#-----------------------------------------------------------------------------
# Input Delays - ADC Interface
#-----------------------------------------------------------------------------
# ADC I channel (16-bit signed)
set_input_delay -clock clk_fast -max 1.500 [get_ports {i_adc_i[*]}]
set_input_delay -clock clk_fast -min 0.500 [get_ports {i_adc_i[*]}]

# ADC Q channel (16-bit signed)
set_input_delay -clock clk_fast -max 1.500 [get_ports {i_adc_q[*]}]
set_input_delay -clock clk_fast -min 0.500 [get_ports {i_adc_q[*]}]

# Valid signal
set_input_delay -clock clk_fast -max 1.000 [get_ports i_valid]
set_input_delay -clock clk_fast -min 0.500 [get_ports i_valid]

#-----------------------------------------------------------------------------
# Input Delays - Control Interface
#-----------------------------------------------------------------------------
set_input_delay -clock clk_fast -max 2.000 [get_ports i_dump_trigger]
set_input_delay -clock clk_fast -min 0.500 [get_ports i_dump_trigger]

set_input_delay -clock clk_fast -max 2.000 [get_ports {i_lfsr_seed[*]}]
set_input_delay -clock clk_fast -min 0.500 [get_ports {i_lfsr_seed[*]}]

set_input_delay -clock clk_fast -max 2.000 [get_ports i_seed_load]
set_input_delay -clock clk_fast -min 0.500 [get_ports i_seed_load]

set_input_delay -clock clk_fast -max 2.000 [get_ports i_enable]
set_input_delay -clock clk_fast -min 0.500 [get_ports i_enable]

#-----------------------------------------------------------------------------
# Output Delays - AXI-Stream Interface
#-----------------------------------------------------------------------------
set_output_delay -clock clk_fast -max 2.000 [get_ports {m_axis_tdata[*]}]
set_output_delay -clock clk_fast -min 0.500 [get_ports {m_axis_tdata[*]}]

set_output_delay -clock clk_fast -max 2.000 [get_ports m_axis_tvalid]
set_output_delay -clock clk_fast -min 0.500 [get_ports m_axis_tvalid]

set_output_delay -clock clk_fast -max 2.000 [get_ports m_axis_tlast]
set_output_delay -clock clk_fast -min 0.500 [get_ports m_axis_tlast]

set_output_delay -clock clk_fast -max 2.000 [get_ports {m_axis_tid[*]}]
set_output_delay -clock clk_fast -min 0.500 [get_ports {m_axis_tid[*]}]

# AXI-Stream ready (input)
set_input_delay -clock clk_fast -max 1.500 [get_ports m_axis_tready]
set_input_delay -clock clk_fast -min 0.500 [get_ports m_axis_tready]

#-----------------------------------------------------------------------------
# Output Delays - Status Interface
#-----------------------------------------------------------------------------
set_output_delay -clock clk_fast -max 2.500 [get_ports {o_chip_count[*]}]
set_output_delay -clock clk_fast -min 0.500 [get_ports {o_chip_count[*]}]

set_output_delay -clock clk_fast -max 2.500 [get_ports {o_peak_lane[*]}]
set_output_delay -clock clk_fast -min 0.500 [get_ports {o_peak_lane[*]}]

set_output_delay -clock clk_fast -max 2.500 [get_ports {o_peak_magnitude[*]}]
set_output_delay -clock clk_fast -min 0.500 [get_ports {o_peak_magnitude[*]}]

set_output_delay -clock clk_fast -max 2.500 [get_ports o_processing]
set_output_delay -clock clk_fast -min 0.500 [get_ports o_processing]

#-----------------------------------------------------------------------------
# False Paths
#-----------------------------------------------------------------------------
# Asynchronous reset
set_false_path -from [get_ports rst_n]

# LFSR seed (quasi-static)
set_false_path -from [get_ports {i_lfsr_seed[*]}]

#-----------------------------------------------------------------------------
# Multicycle Paths
#-----------------------------------------------------------------------------
# Peak detector has multiple cycles to settle
# set_multicycle_path 2 -setup -from [get_cells -hier -filter {NAME =~ *peak*}]
# set_multicycle_path 1 -hold -from [get_cells -hier -filter {NAME =~ *peak*}]

#-----------------------------------------------------------------------------
# Max Delays
#-----------------------------------------------------------------------------
# Dump trigger to accumulator clear
set_max_delay 5.000 -from [get_ports i_dump_trigger] -to [get_cells -hier -filter {NAME =~ *accumulators*}]

#-----------------------------------------------------------------------------
# Physical Constraints (Example - adjust for actual board)
#-----------------------------------------------------------------------------
# set_property PACKAGE_PIN AA1 [get_ports clk]
# set_property IOSTANDARD LVDS [get_ports clk]

# set_property PACKAGE_PIN AB1 [get_ports rst_n]
# set_property IOSTANDARD LVCMOS18 [get_ports rst_n]

#-----------------------------------------------------------------------------
# Configuration
#-----------------------------------------------------------------------------
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
