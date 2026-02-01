# QEDMMA v3.2 - Correlator Bank Cocotb Makefile
# Author: Dr. Mladen Mešter
# Copyright (c) 2026

# Simulator selection (verilator, icarus, questa, xcelium)
SIM ?= verilator

# Top-level module
TOPLEVEL_LANG = verilog
TOPLEVEL = qedmma_correlator_bank_v32

# Python test module
MODULE = test_correlator_bank_v32

# Source files
VERILOG_SOURCES += $(PWD)/../../rtl/correlator/qedmma_correlator_bank_v32.sv

# Verilator-specific settings
ifeq ($(SIM),verilator)
    EXTRA_ARGS += --timing
    EXTRA_ARGS += -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND
    EXTRA_ARGS += --trace --trace-structs
    COMPILE_ARGS += -CFLAGS "-std=c++17"
endif

# Include cocotb makefile
include $(shell cocotb-config --makefiles)/Makefile.sim

# Clean target
clean::
	rm -rf __pycache__ results.xml *.vcd sim_build

# Quick run
run: all

.PHONY: run clean
