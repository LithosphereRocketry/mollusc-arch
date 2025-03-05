RTL_DIR = rtl
RTL_COMMON_DIR = $(RTL_DIR)/common
RTL_SIM_DIR = $(RTL_DIR)/sim
RTL_SYNTH_DIR = $(RTL_DIR)/hardware
RTL_INC_DIR = $(RTL_DIR)/include

TOOLS_DIR = tools

VVP_DIR = vvp
ROM_DIR = rom
WAVE_DIR = waveforms
BUILD_DIR = build
GENERATE_DIR = $(RTL_DIR)/generated

LINT_OPTS = -Wno-initialdly -Wno-timescalemod --language 1800-2009 -I$(RTL_INC_DIR) --lint-only --timing
SIM_OPTS = -g2009 -I$(RTL_INC_DIR)

DIRS = $(VVP_DIR) $(ROM_DIR) $(WAVE_DIR) $(GENERATE_DIR) $(BUILD_DIR)

EXT_DIR = external
EXT_WISHBONE_DIR = $(EXT_DIR)/verilog-wishbone/rtl

SKIPPED_PLATFORMS = wishbone

MUX_SIZES = 4
MUX_PREREQS = $(MUX_SIZES:%=$(GENERATE_DIR)/wb_mux_%.v)

RTL_GENERATED = $(MUX_PREREQS)
RTL_COMMON = $(wildcard $(RTL_COMMON_DIR)/*.v) $(wildcard $(EXT_WISHBONE_DIR)/*.v) $(RTL_GENERATED)
RTL_SIM = $(wildcard $(RTL_SIM_DIR)/*.v) $(RTL_COMMON)
RTL_SYNTH = $(wildcard $(RTL_SYNTH_DIR)/*.v) $(RTL_COMMON)

TEST_DIR = tests
VL_TEST_DIR = $(TEST_DIR)/verilog
PLATFORM_DIR = $(TEST_DIR)/platforms
ASM_TEST_DIR = $(TEST_DIR)/asm

VL_TEST_SRCS = $(wildcard $(VL_TEST_DIR)/tb_*.v)
VL_TEST_TGTS = $(VL_TEST_SRCS:$(VL_TEST_DIR)/tb_%.v=test-vl-%)

PLATFORM_SRCS = $(wildcard $(PLATFORM_DIR)/*)
PLATFORMS = $(filter-out $(SKIPPED_PLATFORMS),$(PLATFORM_SRCS:$(PLATFORM_DIR)/%=%))

ASM_SRCS = $(wildcard $(ASM_TEST_DIR)/*.asm)
ASM_PROGS = $(ASM_SRCS:$(ASM_TEST_DIR)/%.asm=%)
ASM_TEST_TGTS = $(foreach p,$(PLATFORMS),$(ASM_PROGS:%=tb_asm_$(p)+%))

ASSEMBLER = $(TOOLS_DIR)/simpleasm.py

.PHONY: clean test test-vl test-asm $(VL_TEST_TGTS) $(ASM_TEST_TGTS)

test: test-vl test-asm

test-vl: $(VL_TEST_TGTS)

test-asm: $(ASM_TEST_TGTS)


# Local macros defined as variables here bc reasons
PLT = $$(word 1,$$(subst +, ,$$*))
PROG = $$(word 2,$$(subst +, ,$$*))
# These only work in secondary expansion prereqs because reasons
.SECONDEXPANSION:
$(VVP_DIR)/tb_asm_%.vvp: $(ROM_DIR)/tb_$$*.hex $(ROM_DIR)/verify_$(PROG).hex $(PLATFORM_DIR)/$(PLT)/platform.v $(RTL_SIM) | $(VVP_DIR)
	verilator $(LINT_OPTS) -DVERIFYPATH=\"$(word 2,$^)\" -DROMPATH=\"$<\" -DPLATFORM=\"$(word 3,$^)\" -DWAVEPATH=\"$(WAVE_DIR)/tb_asm_$*.fst\" $(filter-out $< $(word 2,$^),$^) --top-module toplevel_test
	iverilog $(SIM_OPTS) -DVERIFYPATH=\"$(word 2,$^)\" -DROMPATH=\"$<\" -DPLATFORM=\"$(word 3,$^)\" -DWAVEPATH=\"$(WAVE_DIR)/tb_asm_$*.fst\" -o $@ $(filter-out $< $(word 2,$^),$^) -s toplevel_test
	
$(VVP_DIR)/tb_vl_%.vvp: $(VL_TEST_DIR)/tb_%.v $(RTL_SIM) | $(VVP_DIR)
	verilator $(LINT_OPTS) -DVERIFYPATH=\"\" -DROMPATH=\"\" -DPLATFORM=\"\" -DWAVEPATH=\"$(WAVE_DIR)/tb_vl_$*.fst\" $^ --top-module tb_$*
	iverilog $(SIM_OPTS) -DVERIFYPATH=\"\" -DROMPATH=\"\" -DPLATFORM=\"\" -DWAVEPATH=\"$(WAVE_DIR)/tb_vl_$*.fst\" -o $@ $^ -s tb_$*
	
$(VL_TEST_TGTS): test-vl-%: $(VVP_DIR)/tb_vl_%.vvp | $(WAVE_DIR)
	vvp $< -fst
$(ASM_TEST_TGTS): tb_asm_%: $(VVP_DIR)/tb_asm_%.vvp | $(WAVE_DIR)
	vvp $< -fst

# TODO write an assembler/linker that doesn't suck
.PRECIOUS: $(ROM_DIR)/tb_%.hex
$(ROM_DIR)/tb_%.hex: $(BUILD_DIR)/tb_%.asm $(ASSEMBLER) | $(ROM_DIR)
	$(ASSEMBLER) $< $@ --pack 32768 --base 32768

.PRECIOUS: $(ROM_DIR)/verify_%.hex
$(ROM_DIR)/verify_%.hex: $(ASM_TEST_DIR)/%.py
	python3 $< | xxd -p -g 1 -c 1 > $@

# Local macros defined as variables here bc reasons
PLT = $$(word 1,$$(subst +, ,$$*))
PROG = $$(word 2,$$(subst +, ,$$*))
# These only work in secondary expansion prereqs because reasons
.SECONDEXPANSION:
$(BUILD_DIR)/tb_%.asm: $(ASM_TEST_DIR)/$(PROG).asm $(PLATFORM_DIR)/$(PLT)/platform.asm | $(BUILD_DIR)
	cat $^ > $@

.PRECIOUS: $(GENERATE_DIR)/wb_mux_%.v
$(GENERATE_DIR)/wb_mux_%.v: $(EXT_WISHBONE_DIR)/wb_mux.py | $(GENERATE_DIR)
	$< -p $* -n wb_mux_$* -o $@

$(DIRS): %:
	mkdir -p $@

clean:
	rm -rf $(DIRS)

