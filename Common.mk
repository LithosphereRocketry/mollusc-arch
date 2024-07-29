# Common variable definitions and rules required for both simulation and synthesis.

# Non-code, but user-created, assets; fonts, etc.
ASSET_DIR = assets
# Human-written, non-hardware-specific Verilog.
GATEWARE_DIR = src
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
# Directories we might have to create on a fresh build
DIRS = $(GENERATE_DIR) $(OUT_DIR) $(BUILD_DIR) $(SIM_GEN_DIR)

GATEWARE = $(wildcard $(GATEWARE_DIR)/*.v)

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