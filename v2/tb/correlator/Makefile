# QEDMMA v3.0 Correlator - Cocotb Makefile
# [REQ-PIPELINE-CORR-001] Automated RTL simulation

# Simulator selection (verilator, icarus, questa)
SIM ?= verilator
TOPLEVEL_LANG = verilog

# RTL sources
VERILOG_SOURCES = $(PWD)/../../rtl/correlator/prbs_generator_parallel.sv
VERILOG_SOURCES += $(PWD)/../../rtl/correlator/parallel_correlator_engine.sv
VERILOG_SOURCES += $(PWD)/../../rtl/correlator/correlator_top_200m.sv

# Top-level module
TOPLEVEL = correlator_top_200m

# Python test module
MODULE = test_correlator_200m

# Verilator-specific options
ifeq ($(SIM),verilator)
    EXTRA_ARGS += --trace --trace-structs
    EXTRA_ARGS += -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC
    EXTRA_ARGS += -Wno-UNUSED -Wno-UNDRIVEN
    COMPILE_ARGS += -CFLAGS "-std=c++17"
endif

# Icarus Verilog options
ifeq ($(SIM),icarus)
    COMPILE_ARGS += -g2012
endif

# Include cocotb makefile
include $(shell cocotb-config --makefiles)/Makefile.sim

# Custom targets
.PHONY: standalone lint clean-all

# Run standalone Python tests (no RTL needed)
standalone:
	@echo "Running standalone validation..."
	python3 test_correlator_standalone.py

# Lint RTL only
lint:
	@echo "Linting RTL modules..."
	verilator --lint-only -Wall $(VERILOG_SOURCES)

# Clean everything
clean-all: clean
	rm -rf sim_build __pycache__ *.vcd *.fst results.xml
