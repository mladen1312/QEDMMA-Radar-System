#------------------------------------------------------------------------------
# QEDMMA Timing Constraints for Zynq UltraScale+ RFSoC ZU47DR
# Radar Systems Architect v9.0 - Forge Spec
#
# Target: ZCU216 Evaluation Kit (or custom board)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Clock Definitions
#------------------------------------------------------------------------------

# ADC Tile Clock (from RFSoC ADC - up to 5 GSPS / 4 = 1.25 GHz per I/Q pair)
# Actual frequency depends on ADC configuration
create_clock -period 0.800 -name adc_clk [get_ports adc_clk]

# AXI-Stream Processing Clock (250 MHz typical)
create_clock -period 4.000 -name axis_clk [get_ports axis_clk]

# AXI-Lite Register Clock (100-250 MHz)
create_clock -period 4.000 -name axi_clk [get_ports axi_clk]

# PPS Reference (1 Hz - for timing, not synthesis)
# create_clock -period 1000000000.0 -name pps_clk [get_ports pps_in]

# White Rabbit Reference (125 MHz from WR PTP core)
# create_clock -period 8.000 -name wr_clk [get_ports wr_clk_in]

#------------------------------------------------------------------------------
# Clock Domain Crossing
#------------------------------------------------------------------------------

# ADC to AXIS clock domain
set_clock_groups -asynchronous \
    -group [get_clocks adc_clk] \
    -group [get_clocks axis_clk]

# AXIS to AXI-Lite
set_clock_groups -asynchronous \
    -group [get_clocks axis_clk] \
    -group [get_clocks axi_clk]

#------------------------------------------------------------------------------
# Input Constraints
#------------------------------------------------------------------------------

# ADC data inputs (from RFSoC ADC tiles - internal routing)
# These are typically source-synchronous with adc_clk
set_input_delay -clock adc_clk -max 0.300 [get_ports {adc_data[*]}]
set_input_delay -clock adc_clk -min 0.100 [get_ports {adc_data[*]}]

# PPS input (external 1PPS signal)
# Allow generous timing as it's asynchronous
set_input_delay -clock axis_clk -max 3.000 [get_ports pps_in]
set_input_delay -clock axis_clk -min 0.000 [get_ports pps_in]

# Synchronize PPS to internal clock
set_false_path -from [get_ports pps_in] -to [get_clocks axis_clk]

#------------------------------------------------------------------------------
# Output Constraints
#------------------------------------------------------------------------------

# AXI-Stream output
set_output_delay -clock axis_clk -max 1.500 [get_ports {m_axis_tdata[*]}]
set_output_delay -clock axis_clk -min 0.500 [get_ports {m_axis_tdata[*]}]
set_output_delay -clock axis_clk -max 1.500 [get_ports m_axis_tvalid]
set_output_delay -clock axis_clk -min 0.500 [get_ports m_axis_tvalid]

#------------------------------------------------------------------------------
# Multicycle Paths
#------------------------------------------------------------------------------

# CIC filter accumulator paths (internally pipelined)
# set_multicycle_path 2 -setup -from [get_cells */cic_*_integ*] -to [get_cells */cic_*_integ*]
# set_multicycle_path 1 -hold  -from [get_cells */cic_*_integ*] -to [get_cells */cic_*_integ*]

# FFT butterfly multipliers (if using DSP48 with pipelining)
# set_multicycle_path 3 -setup -through [get_cells */u_correlator/bfly_*]
# set_multicycle_path 2 -hold  -through [get_cells */u_correlator/bfly_*]

#------------------------------------------------------------------------------
# False Paths
#------------------------------------------------------------------------------

# Configuration registers (static during operation)
set_false_path -from [get_cells */cfg_*_reg*]

# Reset paths
set_false_path -from [get_ports rst_n]

# Version registers (constant)
set_false_path -from [get_cells */VERSION_reg*]

#------------------------------------------------------------------------------
# Max Delay Constraints
#------------------------------------------------------------------------------

# TDOA output latency (from input to TDOA result)
# Target: < 100ms (250k cycles @ 250 MHz)
# This is verified in simulation, not enforced in synthesis

#------------------------------------------------------------------------------
# Physical Constraints (Floorplanning)
#------------------------------------------------------------------------------

# Place DDC near ADC tiles
# create_pblock pblock_ddc
# add_cells_to_pblock pblock_ddc [get_cells */gen_channel[*].u_ddc]
# resize_pblock pblock_ddc -add {SLICE_X0Y0:SLICE_X50Y100}

# Place correlator in high-speed region
# create_pblock pblock_corr
# add_cells_to_pblock pblock_corr [get_cells */gen_channel[*].u_correlator]
# resize_pblock pblock_corr -add {SLICE_X51Y0:SLICE_X100Y100}

#------------------------------------------------------------------------------
# Debug
#------------------------------------------------------------------------------

# Mark debug nets (for ILA insertion)
# set_property MARK_DEBUG true [get_nets */tdoa_samples*]
# set_property MARK_DEBUG true [get_nets */tdoa_valid*]
# set_property MARK_DEBUG true [get_nets */current_timestamp*]

#------------------------------------------------------------------------------
# Power Optimization
#------------------------------------------------------------------------------

# Enable clock gating
# set_property CLOCK_BUFFER_TYPE BUFGCE [get_nets axis_clk]

#------------------------------------------------------------------------------
# End of Constraints
#------------------------------------------------------------------------------
