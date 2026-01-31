# QEDMMA v2.0 Communication Controller Testbench Makefile
# Author: Dr. Mladen Mešter
# Copyright (c) 2026 Dr. Mladen Mešter - All Rights Reserved

# Simulator
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

# Source files
VERILOG_SOURCES = $(PWD)/../rtl/failover_fsm.sv
VERILOG_SOURCES += $(PWD)/../rtl/link_monitor.sv
VERILOG_SOURCES += $(PWD)/../rtl/comm_controller_top.sv

# Top-level module for each test
TOPLEVEL = failover_fsm

# Python test module
MODULE = test_failover_fsm

# Verilator flags
EXTRA_ARGS += --timing
EXTRA_ARGS += -Wno-fatal
EXTRA_ARGS += --trace --trace-structs

# Cocotb parameters
export COCOTB_RESOLVE_X = ZEROS

include $(shell cocotb-config --makefiles)/Makefile.sim

# Additional targets
.PHONY: clean_all lint

clean_all: clean
	rm -rf __pycache__ results.xml *.vcd

lint:
	verilator --lint-only -Wall ../rtl/*.sv

test_link_monitor:
	$(MAKE) TOPLEVEL=link_monitor MODULE=test_link_monitor

test_comm_top:
	$(MAKE) TOPLEVEL=comm_controller_top MODULE=test_comm_controller
