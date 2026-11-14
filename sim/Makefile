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

UNIT_TESTS := lane_alu vec_alu vreg_file dmem ctrl_unit scalar_top
ALL_TESTS  := $(UNIT_TESTS) system

.PHONY: all test lint vectors clean help $(ALL_TESTS)

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
#------------------------------------------------------------------------------
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

# Only the system test reads the vectors, so regenerate them once here rather
# than as a prerequisite of all seven.
system: vectors

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
