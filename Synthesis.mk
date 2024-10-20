# Based on makefiles from OrangeCrab Examples repository
# https://github.com/orangecrab-fpga/orangecrab-examples

.DEFAULT_GOAL = all
include Common.mk

YOSYS_GATEWARE_LOC = /opt/oss-cad-suite/share/yosys

# Top-level module. Inputs and outputs for this will be matched against PCF file.
TOPLEVEL = fpga_root

# PCF file. Contains descriptions of location, voltage, etc of all external signals.
# If you want to build on a different ECP5 platform, just remap the ball coordinates
# in this file to the correct ones for your board.
PCF = orangecrab-hbb.pcf
DENSITY = 25F

# Model of ECP5 core to build for. 25k or 85k for Orangecrab.
NEXTPNR_DENSITY:=--25k

# Which files we actually need from TinyFPGA's USB library. Effectively, everything
# except the hardware interface layer.
RTL_USB_DIR = external/tinyfpga_bx_usbserial/usb
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

# Synthesis-specific gateware e.g. hardware interfaces
GATEWARE_DIR_FPGA = src-hardware

# Collect all required Verilog to synthesize
GENERATED = $(GENERATE_DIR)/pll_108.v $(GENERATE_DIR)/lite_ddr3l.v
FPGA_GATEWARE = $(GATEWARE) $(wildcard $(GATEWARE_DIR_FPGA)/*.v) $(USB_SRCS) $(GENERATED)

# Rules specific to synthesis
.PHONY: all dfu nextpnrgui

all: $(OUT_DIR)/$(TOPLEVEL).dfu

dfu: $(OUT_DIR)/$(TOPLEVEL).dfu
	dfu-util --alt 0 -D $<

${GENERATE_DIR}/pll_108.v: | $(GENERATE_DIR)
	ecppll -n pll_108 -i 48 -o 108 -f $@
${GENERATE_DIR}/lite_ddr3l.v: orangecrab-dram.yml | $(GENERATE_DIR)
	python -m litedram.gen orangecrab-dram.yml --name lite_ddr3l --no-compile --gateware-dir ${GENERATE_DIR}/ --doc

.SECONDARY:
$(BUILD_DIR)/%.ys: $(FPGA_GATEWARE) $(BUILD_DIR)/boot.hex $(BUILD_DIR)/charset.hex $(BUILD_DIR)/myst.hex | $(BUILD_DIR)
	$(file >$@)
	$(foreach V,$(FPGA_GATEWARE),$(file >>$@,read_verilog -DROMPATH="$(BUILD_DIR)/boot.hex" $V))
	$(file >>$@,synth_ecp5 -top $(TOPLEVEL)) \
	$(file >>$@,write_json "$(basename $@).json") \

$(BUILD_DIR)/%.json: $(BUILD_DIR)/%.ys | $(BUILD_DIR)
	yosys -s "$<" > yosys-log.txt

$(BUILD_DIR)/%_out.config $(BUILD_DIR)/%.pnr.json: $(BUILD_DIR)/%.json $(PCF) | $(BUILD_DIR)
	nextpnr-ecp5 --json $< --textcfg $(BUILD_DIR)/$*_out.config $(NEXTPNR_DENSITY) --package CSFBGA285 --lpf $(PCF) --write $(BUILD_DIR)/$*.pnr.json

nextpnrgui: $(BUILD_DIR)/$(TOPLEVEL).pnr.json
	nextpnr-ecp5 --json $< $(NEXTPNR_DENSITY) --package CSFBGA285 --lpf $(PCF) --gui &

$(BUILD_DIR)/%.bit: $(BUILD_DIR)/%_out.config | $(BUILD_DIR)
	ecppack --compress --freq 38.8 --input $< --bit $@

$(OUT_DIR)/%.dfu : $(BUILD_DIR)/%.bit | $(OUT_DIR)
	cp $< $@
	dfu-suffix -v 1209 -p 5af0 -a $@

lint:
	verilator --lint-only $(FPGA_GATEWARE) $(YOSYS_GATEWARE_LOC)/lattice/cells_sim_ecp5.v -I./src -I$(YOSYS_GATEWARE_LOC)/lattice