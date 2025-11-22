# Update with your installation location
YOSYS_GATEWARE_LOC = /opt/oss-cad-suite/share/yosys

# Update with your part
NEXTPNR_DEVICE = 25k
NEXTPNR_PACKAGE = CSFBGA285
NEXTPNR_SPEEDGRADE = 8

# Nothing I've done in the pnr settings seems to do much, but it's there
PLACER_OPTS = --placer heap
ROUTER_OPTS = --router router1

PNR_OPTS = --$(NEXTPNR_DEVICE) --package $(NEXTPNR_PACKAGE) --speed $(NEXTPNR_SPEEDGRADE) $(PLACER_OPTS) $(ROUTER_OPTS)

RTL_DIR = rtl
RTL_COMMON_DIR = $(RTL_DIR)/common
RTL_SIM_DIR = $(RTL_DIR)/sim
RTL_SYNTH_DIR = $(RTL_DIR)/hardware
RTL_INC_DIR = $(RTL_DIR)/include

FPGA_DIR = fpga
TOOLS_DIR = tools

VVP_DIR = vvp
ROM_DIR = rom
WAVE_DIR = waveforms
BUILD_DIR = build
OUT_DIR = out
GENERATE_DIR = $(RTL_DIR)/generated
SYNTH_GEN_DIR = $(RTL_DIR)/generated-hw

LINT_OPTS = -Wno-initialdly -Wno-timescalemod --language 1800-2009 -I$(RTL_INC_DIR) --lint-only --timing
SIM_OPTS = -g2009 -I$(RTL_INC_DIR)
SYNTH_OPTS = -I$(RTL_INC_DIR)

DIRS = $(VVP_DIR) $(ROM_DIR) $(WAVE_DIR) $(GENERATE_DIR) $(SYNTH_GEN_DIR) $(BUILD_DIR) $(OUT_DIR)

EXT_DIR = external
EXT_WISHBONE_DIR = $(EXT_DIR)/verilog-wishbone/rtl

# Which files we actually need from TinyFPGA's USB library. Effectively, everything
# except the hardware interface layer.
RTL_USB_DIR = $(EXT_DIR)/tinyfpga_bx_usbserial/usb
USB_SRCS = $(RTL_USB_DIR)/edge_detect.v \
	$(RTL_USB_DIR)/serial.v \
	$(RTL_USB_DIR)/usb_fs_in_arb.v \
	$(RTL_USB_DIR)/usb_fs_in_pe.v \
	$(RTL_USB_DIR)/usb_fs_out_arb.v \
	$(RTL_USB_DIR)/usb_fs_out_pe.v \
	$(RTL_USB_DIR)/usb_fs_pe.v \
	$(RTL_USB_DIR)/usb_fs_rx.v \
	$(RTL_USB_DIR)/usb_fs_tx_mux.v \
	$(RTL_USB_DIR)/usb_fs_tx.v \
	$(RTL_USB_DIR)/usb_reset_det.v \
	$(RTL_USB_DIR)/usb_serial_ctrl_ep.v \
	$(RTL_USB_DIR)/usb_uart_bridge_ep.v \
	$(RTL_USB_DIR)/usb_uart_core.v

SKIPPED_PLATFORMS = 

MUX_SIZES = 4
MUX_PREREQS = $(MUX_SIZES:%=$(GENERATE_DIR)/wb_mux_%.v)

CPU_SPEED = 30
SYNTH_GEN = $(SYNTH_GEN_DIR)/pll_cpu.v

RTL_GENERATED = $(MUX_PREREQS)
RTL_COMMON = $(wildcard $(RTL_COMMON_DIR)/*.v) $(wildcard $(EXT_WISHBONE_DIR)/*.v) $(RTL_GENERATED)
RTL_SIM = $(wildcard $(RTL_SIM_DIR)/*.v) $(RTL_COMMON)
RTL_SYNTH = $(wildcard $(RTL_SYNTH_DIR)/*.v) $(USB_SRCS) $(RTL_COMMON) $(SYNTH_GEN)

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

PCF = $(FPGA_DIR)/orangecrab-hbb.pcf
DENSITY = 25F

TOPLEVEL = fpga_root

.PHONY: clean test test-vl test-asm $(VL_TEST_TGTS) $(ASM_TEST_TGTS) synth dfu nextpnrgui
.DEFAULT_GOAL: test

test: test-vl test-asm

test-vl: $(VL_TEST_TGTS)

test-asm: $(ASM_TEST_TGTS)

synth: $(OUT_DIR)/$(TOPLEVEL).dfu
dfu: $(OUT_DIR)/$(TOPLEVEL).dfu
	dfu-util --alt 0 -D $<

# Note here, Yosys doesn't like synthesizing dualport RAM unless no-rw-check is given
.SECONDARY:
$(BUILD_DIR)/%.ys: $(RTL_SYNTH) $(ROM_DIR)/boot.hex | $(BUILD_DIR)
	# verilator $(LINT_OPTS) -DROMPATH=\"$(ROM_DIR)/boot.hex\" -I$(YOSYS_GATEWARE_LOC)/lattice $(RTL_SYNTH) $(YOSYS_GATEWARE_LOC)/lattice/cells_sim_ecp5.v --top-module $(TOPLEVEL)
	$(file >$@)
	$(foreach V,$(RTL_SYNTH),$(file >>$@,read_verilog $(SYNTH_OPTS) -DROMPATH="$(ROM_DIR)/boot.hex" $V))
	$(file >>$@,synth_ecp5 -no-rw-check -top $(TOPLEVEL)) \
	$(file >>$@,write_json "$(basename $@).json") \

$(BUILD_DIR)/%.json: $(BUILD_DIR)/%.ys | $(BUILD_DIR)
	yosys -s "$<" > yosys-log.txt

$(BUILD_DIR)/%_out.config $(BUILD_DIR)/%.pnr.json: $(BUILD_DIR)/%.json $(PCF) | $(BUILD_DIR)
	nextpnr-ecp5 --json $< --textcfg $(BUILD_DIR)/$*_out.config $(PNR_OPTS) --lpf $(PCF) --write $(BUILD_DIR)/$*.pnr.json 2> nextpnr-log.txt

nextpnrgui: $(BUILD_DIR)/$(TOPLEVEL).pnr.json
	nextpnr-ecp5 --json $< $(NEXTPNR_DEVICE) --package CSFBGA285 --lpf $(PCF) --gui &

$(BUILD_DIR)/%.bit: $(BUILD_DIR)/%_out.config | $(BUILD_DIR)
	ecppack --compress --freq 38.8 --input $< --bit $@

$(OUT_DIR)/%.dfu : $(BUILD_DIR)/%.bit | $(OUT_DIR)
	cp $< $@
	dfu-suffix -v 1209 -p 5af0 -a $@

$(SYNTH_GEN_DIR)/pll_cpu.v: | $(SYNTH_GEN_DIR)
	ecppll -n pll_cpu -i 48 -o $(CPU_SPEED) -f $@

# Local macros defined as variables here bc reasons
PLT = $$(word 1,$$(subst +, ,$$*))
PROG = $$(word 2,$$(subst +, ,$$*))
# These only work in secondary expansion prereqs because reasons
.SECONDEXPANSION:
$(VVP_DIR)/tb_asm_%.vvp: $(ROM_DIR)/tb_$$*.hex $(ROM_DIR)/verify_$(PROG).hex $(PLATFORM_DIR)/$(PLT)/platform.v $(RTL_SIM) | $(VVP_DIR)
	verilator $(LINT_OPTS) -DSIM -DVERIFYPATH=\"$(word 2,$^)\" -DROMPATH=\"$<\" -DPLATFORM=\"$(word 3,$^)\" -DWAVEPATH=\"$(WAVE_DIR)/tb_asm_$*.fst\" $(filter-out $< $(word 2,$^),$^) --top-module toplevel_test
	iverilog $(SIM_OPTS) -DSIM -DVERIFYPATH=\"$(word 2,$^)\" -DROMPATH=\"$<\" -DPLATFORM=\"$(word 3,$^)\" -DWAVEPATH=\"$(WAVE_DIR)/tb_asm_$*.fst\" -o $@ $(filter-out $< $(word 2,$^),$^) -s toplevel_test
	
$(VVP_DIR)/tb_vl_%.vvp: $(VL_TEST_DIR)/tb_%.v $(RTL_SIM) | $(VVP_DIR)
	verilator $(LINT_OPTS) -DSIM -DVERIFYPATH=\"\" -DROMPATH=\"\" -DPLATFORM=\"\" -DWAVEPATH=\"$(WAVE_DIR)/tb_vl_$*.fst\" $^ --top-module tb_$*
	iverilog $(SIM_OPTS) -DSIM -DVERIFYPATH=\"\" -DROMPATH=\"\" -DPLATFORM=\"\" -DWAVEPATH=\"$(WAVE_DIR)/tb_vl_$*.fst\" -o $@ $^ -s tb_$*
	
$(VL_TEST_TGTS): test-vl-%: $(VVP_DIR)/tb_vl_%.vvp | $(WAVE_DIR)
	vvp $< -fst
$(ASM_TEST_TGTS): tb_asm_%: $(VVP_DIR)/tb_asm_%.vvp | $(WAVE_DIR)
	vvp $< -fst

# TODO write an assembler/linker that doesn't suck
.PRECIOUS: $(ROM_DIR)/tb_%.hex
$(ROM_DIR)/tb_%.hex: $(BUILD_DIR)/tb_%.asm $(ASSEMBLER) | $(ROM_DIR)
	$(ASSEMBLER) $< $@ --pack 32768 --base 32768

$(ROM_DIR)/boot.hex: $(FPGA_DIR)/boot.asm $(ASSEMBLER) | $(ROM_DIR)
	$(ASSEMBLER) $< $@ --pack 2048 --base 32768

.PRECIOUS: $(ROM_DIR)/verify_%.hex
$(ROM_DIR)/verify_%.hex: $(ASM_TEST_DIR)/%.py
	python3 $< | xxd -p -g 1 -c 1 > $@

# Local macros defined as variables here bc reasons
PLT = $$(word 1,$$(subst +, ,$$*))
PROG = $$(word 2,$$(subst +, ,$$*))
# These only work in secondary expansion prereqs because reasons
.SECONDEXPANSION:
.PRECIOUS: $(BUILD_DIR)/tb_%.asm
$(BUILD_DIR)/tb_%.asm: $(ASM_TEST_DIR)/$(PROG).asm $(PLATFORM_DIR)/$(PLT)/platform.asm | $(BUILD_DIR)
	cat $^ > $@

.PRECIOUS: $(GENERATE_DIR)/wb_mux_%.v
$(GENERATE_DIR)/wb_mux_%.v: $(EXT_WISHBONE_DIR)/wb_mux.py | $(GENERATE_DIR)
	$< -p $* -n wb_mux_$* -o $@

$(DIRS): %:
	mkdir -p $@

clean:
	rm -rf $(DIRS) *-log.txt

