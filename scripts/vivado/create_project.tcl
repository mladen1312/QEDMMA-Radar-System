#------------------------------------------------------------------------------
# QEDMMA Vivado Project Creation Script
# Radar Systems Architect v9.0 - Forge Spec
#
# Target: Xilinx Zynq UltraScale+ RFSoC ZU47DR
# Board: ZCU216 Evaluation Kit (or custom)
#
# Usage: vivado -mode batch -source create_project.tcl
#------------------------------------------------------------------------------

# Project settings
set project_name "qedmma_rx"
set project_dir  "./vivado_project"
set part         "xczu47dr-ffve1156-2-e"  ;# ZU47DR RFSoC
set board        ""  ;# Custom board, no board file

# Source directories
set rtl_dir      "../../rtl"
set tb_dir       "../../tb"
set constr_dir   "../../constraints"

#------------------------------------------------------------------------------
# Create Project
#------------------------------------------------------------------------------
puts "Creating QEDMMA project for $part..."

create_project $project_name $project_dir -part $part -force

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property default_lib work [current_project]

#------------------------------------------------------------------------------
# Add RTL Sources
#------------------------------------------------------------------------------
puts "Adding RTL sources..."

# Core modules
add_files -norecurse [glob -nocomplain $rtl_dir/*.sv]
add_files -norecurse [glob -nocomplain $rtl_dir/*.v]
add_files -norecurse [glob -nocomplain $rtl_dir/*.vhd]

# Set SystemVerilog file type
foreach f [get_files -filter {FILE_TYPE == "Verilog"}] {
    if {[string match "*.sv" $f]} {
        set_property FILE_TYPE SystemVerilog [get_files $f]
    }
}

# Set top module
set_property top qedmma_rx_top [current_fileset]

#------------------------------------------------------------------------------
# Add Constraints
#------------------------------------------------------------------------------
puts "Adding constraints..."

# Create constraints directory if needed
file mkdir $constr_dir

# Add XDC files
if {[llength [glob -nocomplain $constr_dir/*.xdc]] > 0} {
    add_files -fileset constrs_1 -norecurse [glob $constr_dir/*.xdc]
}

#------------------------------------------------------------------------------
# Add Simulation Sources
#------------------------------------------------------------------------------
puts "Adding simulation sources..."

# Create simulation fileset
if {[get_filesets -quiet sim_1] eq ""} {
    create_fileset -simset sim_1
}

# Add testbenches (if Verilog/VHDL testbenches exist)
if {[llength [glob -nocomplain $tb_dir/*.sv]] > 0} {
    add_files -fileset sim_1 -norecurse [glob $tb_dir/*.sv]
}

#------------------------------------------------------------------------------
# Configure IP Catalog
#------------------------------------------------------------------------------
puts "Configuring IP settings..."

# Set IP repository paths (for custom IP)
# set_property ip_repo_paths [list "./ip_repo"] [current_project]
# update_ip_catalog

#------------------------------------------------------------------------------
# Create Block Design (Optional - for SoC integration)
#------------------------------------------------------------------------------
proc create_bd_design_qedmma {} {
    # Create block design
    create_bd_design "qedmma_system"
    
    # Add Zynq UltraScale+ Processing System
    create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 zynq_ultra_ps_e_0
    
    # Configure PS for RFSoC
    # (Would add detailed configuration here)
    
    # Add custom RTL as module reference
    create_bd_cell -type module -reference qedmma_rx_top qedmma_rx_0
    
    # Connect clocks and resets
    # (Would add connections here)
    
    # Validate and save
    validate_bd_design
    save_bd_design
}

# Uncomment to create block design:
# create_bd_design_qedmma

#------------------------------------------------------------------------------
# Run Synthesis (Optional)
#------------------------------------------------------------------------------
# Uncomment to run synthesis immediately:
# launch_runs synth_1 -jobs 8
# wait_on_run synth_1

puts "=========================================="
puts "QEDMMA Project Created Successfully!"
puts "=========================================="
puts "Project: $project_dir/$project_name.xpr"
puts "Part:    $part"
puts "Top:     qedmma_rx_top"
puts ""
puts "Next steps:"
puts "  1. Open project in Vivado GUI"
puts "  2. Run 'create_bd_design_qedmma' for block design"
puts "  3. Add constraints (timing, pins)"
puts "  4. Run synthesis and implementation"
puts "=========================================="
