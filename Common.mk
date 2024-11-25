# Common variable definitions and rules required for both simulation and synthesis.

# Non-code, but user-created, assets; fonts, etc.
ASSET_DIR = assets
# Human-written, non-hardware-specific Verilog.
GATEWARE_DIR = src
# C++ test scripts, of form tb_<module>.cpp
TEST_DIR = test
# Machine-generated (e.g. LiteX) verilog.
GENERATE_DIR = generated
# Final outputs (DFU, executables, etc)
OUT_DIR = out
# Intermediate build files
BUILD_DIR = build
# Generated simulation code
SIM_GEN_DIR = verilator
# Miscellaneous scripts to help along the way
TOOLSDIR = tools
# Temporary folder for test logs that failed
FAIL_DIR = failed_logs
# Test logs
LOG_DIR = logs
# Test waveforms
WAVE_DIR = waveforms

# Directories we might have to create on a fresh build
DIRS = $(GENERATE_DIR) $(OUT_DIR) $(BUILD_DIR) $(SIM_GEN_DIR) $(LOG_DIR) $(FAIL_DIR) $(WAVE_DIR)

# Configuration data
CFG = mollusc.cfg $(TOOLSDIR)/getcfg.py
CPU_SPEED = $(shell tools/getcfg.py mollusc.cfg CPU speed)
RESET_VECTOR = $(shell tools/getcfg.py mollusc.cfg Layout reset)

N_PORTS_HOST = 2
N_PORTS_NARROW = 3
N_PORTS_IO = 1

COMMONGENS = wb_mux_host.v wb_mux_narrow.v wb_mux_io.v

GATEWARE = $(wildcard $(GATEWARE_DIR)/*.v) $(wildcard external/verilog-wishbone/rtl/*.v) $(foreach g,$(COMMONGENS),$(GENERATE_DIR)/$(g)) 

# Rules common to all builds
.PHONY: clean lint

$(DIRS): %:
	mkdir -p $@

clean:
	rm -rf $(DIRS)

# TOOLS
# No real pattern here, tools can be in a variety of languages based on convenience
$(OUT_DIR)/png2hex: $(TOOLSDIR)/png2hex.c | $(OUT_DIR)
	gcc -o $@ $^ -lpng

# this rule is kinda cursed but it makes me happy
$(BUILD_DIR)/charset.hex: $(OUT_DIR)/png2hex $(ASSET_DIR)/charset.png | $(BUILD_DIR)
	$^ $@

$(BUILD_DIR)/myst.hex: $(TOOLSDIR)/maketext.py
	$^

# Non-hardware-or-sim-specific generated files
$(GENERATE_DIR)/wb_mux_host.v: external/verilog-wishbone/rtl/wb_mux.py | $(GENERATE_DIR)
	$< -p $(N_PORTS_HOST) -n wb_mux_host -o $@
$(GENERATE_DIR)/wb_mux_narrow.v: external/verilog-wishbone/rtl/wb_mux.py | $(GENERATE_DIR)
	$< -p $(N_PORTS_NARROW) -n wb_mux_narrow -o $@
$(GENERATE_DIR)/wb_mux_io.v: external/verilog-wishbone/rtl/wb_mux.py | $(GENERATE_DIR)
	$< -p $(N_PORTS_IO) -n wb_mux_io -o $@

# Common boot binary
$(BUILD_DIR)/boot.hex: $(GATEWARE_DIR)/boot.asm $(TOOLSDIR)/simpleasm.py
	$(TOOLSDIR)/simpleasm.py $< $@ --pack 2048