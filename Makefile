#==============================================================================
# Project 11: 4-Lane SIMD Vector Unit
# Top-level Makefile
#
# Delegates build and simulation commands to sim/ directory so that relative
# paths ($readmemh data vectors and $dumpfile waveforms) resolve consistently.
#
# Quickstart (3 commands):
#   make lint         # Elaborate and syntax-check all RTL and testbenches
#   make test         # Compile and run all unit and integration testbenches
#   make system       # Run the golden-model-verified system testbench
#==============================================================================

SIM_DIR := sim

# Unit and integration test names
TESTS := lane_alu vec_alu vreg_file dmem ctrl_unit scalar_top simd_top integration system

.PHONY: all help test lint vectors clean $(TESTS)

all: test

help:
	@echo "Project 11 SIMD Vector Unit - Build and Simulation Targets:"
	@echo "  make lint           Compile and elaborate all testbenches (syntax check)"
	@echo "  make test           Compile and run all testbenches"
	@echo "  make system         Run the system integration testbench (tb_system)"
	@echo "  make vectors        Generate golden vectors using golden_model.py"
	@echo "  make <test>         Run a single testbench (e.g., make ctrl_unit, make simd_top)"
	@echo "  make wave-<test>    Open simulation waveform in GTKWave (e.g., make wave-ctrl_unit)"
	@echo "  make clean          Clean build artifacts, waveforms, and temporary files"

# 3 Primary Commands
lint:
	$(MAKE) -C $(SIM_DIR) lint

test:
	$(MAKE) -C $(SIM_DIR) test

vectors:
	$(MAKE) -C $(SIM_DIR) vectors

# Individual testbench and system targets
$(TESTS):
	$(MAKE) -C $(SIM_DIR) $@

# GTKWave visualization targets
wave-%:
	$(MAKE) -C $(SIM_DIR) $@

clean:
	$(MAKE) -C $(SIM_DIR) clean
