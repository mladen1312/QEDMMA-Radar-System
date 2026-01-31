# QEDMMA Timestamp Capture - Cocotb Testbench Makefile
# Radar Systems Architect v9.0 - Forge Spec

# Simulator selection (verilator for CI, questa for local)
SIM ?= verilator
TOPLEVEL_LANG = verilog

# Source files
VERILOG_SOURCES = $(PWD)/../rtl/timestamp_capture_regs_pkg.sv
VERILOG_SOURCES += $(PWD)/../rtl/timestamp_capture.sv

# Top-level module
TOPLEVEL = timestamp_capture

# Python test module
MODULE = test_timestamp_capture

# Verilator specific flags
EXTRA_ARGS += --trace --trace-structs
EXTRA_ARGS += -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-TIMESCALEMOD

# Include cocotb makefile
include $(shell cocotb-config --makefiles)/Makefile.sim

# Custom targets
.PHONY: test clean-all lint

test: sim

lint:
	verilator --lint-only -Wall $(VERILOG_SOURCES)

clean-all: clean
	rm -rf __pycache__ *.vcd *.fst sim_build results.xml

# Wave viewer
waves:
	gtkwave dump.vcd &
