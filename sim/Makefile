#==============================================================================
# Project 11, SIMD Vector Unit - simulation driver.
#
# Always run from this directory (or with -C sim): every $readmemh path in the
# RTL and every $dumpfile path in the testbenches is relative to sim/, so
# running from the repository root silently produces zeros instead of data.
#
#   make vectors     regenerate the golden vectors (deterministic, fixed seed)
#   make test        compile and run every testbench
#   make lint        compile everything, run nothing  (what CI gates on)
#   make lane_alu    compile and run one testbench
#   make wave-system open the system-test waveform in GTKWave
#   make clean       remove build/, waves/ and generated vectors
#
# Owner: Taj. Add a testbench by adding its name to UNIT_TESTS - the pattern
# rules do the rest.
#==============================================================================

IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave
PYTHON   ?= python3

RTL_DIR    := ../rtl
SCALAR_DIR := ../scalar
TB_DIR     := ../tb
GOLDEN_DIR := ../golden

BUILD   := build
WAVES   := waves
VECTORS := vectors

# -I is needed for `include "simd_defs.vh". DEFS is the hook for one-off
# defines, e.g.  make system DEFS=-DDUT_READY
IFLAGS := -g2005 -Wall -I $(RTL_DIR) $(DEFS)

RTL := $(wildcard $(RTL_DIR)/*.v) $(wildcard $(SCALAR_DIR)/*.v)

#------------------------------------------------------------------------------
# Integration test status:
# simd_top is NOT in `make test` or CI until the real vreg_file, dmem and
# vec_alu are on main; it passes against stubs via `make -C sim simd_top STUBS=1`;
# when the real modules arrive, add simd_top back into UNIT_TESTS/ALL_TESTS.
#------------------------------------------------------------------------------
UNIT_TESTS := lane_alu vec_alu vreg_file dmem ctrl_unit scalar_top
ALL_TESTS  := $(UNIT_TESTS) system

.PHONY: all test lint vectors clean help $(ALL_TESTS) simd_top integration

all: test

help:
	@echo "targets: vectors, test, lint, clean, $(ALL_TESTS)"

#------------------------------------------------------------------------------
# Golden vectors. Deterministic, so this is safe to re-run at any time; the
# committed files must always equal what the current model produces.
#------------------------------------------------------------------------------
vectors:
	@$(PYTHON) $(GOLDEN_DIR)/gen_vectors.py --out $(VECTORS) --quiet

#------------------------------------------------------------------------------
# Compile. One executable per testbench, every RTL file in the project linked
# in, so a port mismatch in someone else's module fails here rather than in
# their branch only.
#
# default: real RTL. Stubs only when explicitly requested via STUBS=1.
#------------------------------------------------------------------------------
ifdef STUBS
SIMD_TOP_SRC := $(RTL_DIR)/simd_top.v $(RTL_DIR)/ctrl_unit.v \
                $(RTL_DIR)/instr_mem.v $(wildcard stubs/*.v)
else
SIMD_TOP_SRC := $(RTL)
endif

$(BUILD)/simd_top.vvp: $(TB_DIR)/tb_simd_top.v $(SIMD_TOP_SRC) | $(BUILD)
ifndef STUBS
	@if ! grep -Eq '^[[:space:]]*reg[[:space:]]+(\[[^]]+\][[:space:]]+)*mem[[:space:]]*\[' $(RTL_DIR)/dmem.v; then \
	    echo "ERROR: rtl/dmem.v is still a placeholder (missing 'mem' array). Run with STUBS=1 until teammates' modules land on main."; \
	    exit 1; \
	fi
endif
	$(IVERILOG) $(IFLAGS) -s tb_simd_top -o $@ $(TB_DIR)/tb_simd_top.v $(SIMD_TOP_SRC)

$(BUILD)/%.vvp: $(TB_DIR)/tb_%.v $(RTL) | $(BUILD)
	$(IVERILOG) $(IFLAGS) -s tb_$* -o $@ $(TB_DIR)/tb_$*.v $(RTL)

$(BUILD) $(WAVES):
	@mkdir -p $@

lint: $(addprefix $(BUILD)/,$(addsuffix .vvp,$(ALL_TESTS)))
	@echo ""
	@echo "lint: all $(words $(ALL_TESTS)) testbenches elaborate"

#------------------------------------------------------------------------------
# Run. `make lane_alu` runs one; `make test` runs all of them and is the thing
# to screen-record for the video.
#------------------------------------------------------------------------------
$(ALL_TESTS): % : $(BUILD)/%.vvp | $(WAVES)
	@echo ""
	@echo "=== tb_$@ ======================================================"
	@$(VVP) $<

simd_top: $(BUILD)/simd_top.vvp | $(WAVES)
	@echo ""
	@echo "=== tb_simd_top ======================================================"
	@$(VVP) $<

integration: vectors
	@if ! grep -Eq '^[[:space:]]*reg[[:space:]]+(\[[^]]+\][[:space:]]+)*mem[[:space:]]*\[' $(RTL_DIR)/dmem.v; then \
	    echo "ERROR: rtl/dmem.v is still a placeholder (missing 'mem' array). Integration test requires real RTL from Satya on main."; \
	    exit 1; \
	fi
	@mkdir -p $(BUILD) $(WAVES)
	$(IVERILOG) $(IFLAGS) -s tb_simd_top -o $(BUILD)/simd_top_real.vvp $(TB_DIR)/tb_simd_top.v $(RTL)
	@echo ""
	@echo "=== tb_simd_top (real RTL) ==========================================="
	@$(VVP) $(BUILD)/simd_top_real.vvp

# Only the system test reads the vectors, so regenerate them once here rather
# than as a prerequisite of all seven.
system: vectors
simd_top: vectors
integration: vectors

test: vectors
	@rc=0; \
	for t in $(ALL_TESTS); do \
	    $(MAKE) --no-print-directory $$t || rc=1; \
	done; \
	echo ""; \
	if [ $$rc -eq 0 ]; then echo "all testbenches ran"; \
	else echo "at least one testbench failed to build or run"; fi; \
	exit $$rc

#------------------------------------------------------------------------------
# Waveforms. The report needs screenshots from tb_vreg_file, tb_vec_alu and
# tb_system; GTKWave is interactive, so these are never part of `make test`.
#------------------------------------------------------------------------------
wave-%: %
	@test -f $(WAVES)/tb_$*.vcd || (echo "tb_$* produced no VCD - does it call \$$dumpfile?" && false)
	$(GTKWAVE) $(WAVES)/tb_$*.vcd &

clean:
	rm -rf $(BUILD) $(WAVES) $(VECTORS)/*.hex
