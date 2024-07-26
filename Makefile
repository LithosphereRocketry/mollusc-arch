# Based on makefiles from OrangeCrab Examples repository
# https://github.com/orangecrab-fpga/orangecrab-examples

TOPLEVEL = orangecrab_core

PCF = orangecrab-hbb.pcf
DENSITY = 25F

ifneq (,$(findstring 85,$(DENSITY)))
	NEXTPNR_DENSITY:=--85k
else
	NEXTPNR_DENSITY:=--25k
endif

# TODO: this is copy-pasted from the TinyFPGA source, it should be better
# USB_SRCS = \
# 	edge_detect.v \
# 	serial.v \
# 	usb_fs_in_arb.v \
# 	usb_fs_in_pe.v \
# 	usb_fs_out_arb.v \
# 	usb_fs_out_pe.v \
# 	usb_fs_pe.v \
# 	usb_fs_rx.v \
# 	usb_fs_tx_mux.v \
# 	usb_fs_tx.v \
# 	usb_reset_det.v \
# 	usb_serial_ctrl_ep.v \
# 	usb_uart_bridge_ep.v \
# 	usb_uart_core.v

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


# USB_SRCS = $(wildcard external/usb_cdc/usb_cdc/*.v)
# USB_SRCS = $(wildcard external/tinyfpga_bx_usbserial/usb/*.v)

ASSETDIR = assets
SRCDIR = src
GENERATEDIR = generated
OUTDIR = out
BUILDDIR = build
TOOLSDIR = tools

DIRS = $(GENERATEDIR) $(OUTDIR) $(BUILDDIR)

GENERATED = $(GENERATEDIR)/pll_108.v $(GENERATEDIR)/lite_ddr3l.v
SOURCES = $(wildcard $(SRCDIR)/*.v)  $(USB_SRCS) $(GENERATED)

.PHONY: clean all dfu nextpnrgui

all: $(OUTDIR)/$(TOPLEVEL).dfu $(OUTDIR)/png2hex

dfu: $(OUTDIR)/$(TOPLEVEL).dfu
	dfu-util --alt 0 -D $<

${GENERATEDIR}/pll_108.v: | $(GENERATEDIR)
	ecppll -n pll_108 -i 48 -o 108 -f $@
${GENERATEDIR}/lite_ddr3l.v: orangecrab-dram.yml | $(GENERATEDIR)
	python -m litedram.gen orangecrab-dram.yml --name lite_ddr3l --no-compile --gateware-dir generated/

$(OUTDIR)/png2hex: $(TOOLSDIR)/png2hex.c | $(OUTDIR)
	gcc -o $@ $^ -lpng

# this rule is kinda cursed but it makes me happy
$(BUILDDIR)/charset.hex: $(OUTDIR)/png2hex $(ASSETDIR)/charset.png | $(BUILDDIR)
	$^ $@

$(BUILDDIR)/myst.hex: $(TOOLSDIR)/maketext.py
	$^

src/%.v: ;

.SECONDARY:

$(BUILDDIR)/%.ys: $(SOURCES) $(BUILDDIR)/charset.hex $(BUILDDIR)/myst.hex | $(BUILDDIR)
	$(file >$@)
	$(foreach V,$(SOURCES),$(file >>$@,read_verilog $V))
	$(file >>$@,synth_ecp5 -top $(TOPLEVEL)) \
	$(file >>$@,write_json "$(basename $@).json") \

$(BUILDDIR)/%.json: $(BUILDDIR)/%.ys | $(BUILDDIR)
	yosys -s "$<"

$(BUILDDIR)/%_out.config: $(BUILDDIR)/%.json $(PCF) | $(BUILDDIR)
	nextpnr-ecp5 --json $< --textcfg $@ $(NEXTPNR_DENSITY) --package CSFBGA285 --lpf $(PCF)

nextpnrgui: $(BUILDDIR)/$(TOPLEVEL).pnr.json
	nextpnr-ecp5 --json $< $(NEXTPNR_DENSITY) --package CSFBGA285 --lpf $(PCF) --gui &


$(BUILDDIR)/%.bit: $(BUILDDIR)/%_out.config | $(BUILDDIR)
	ecppack --compress --freq 38.8 --input $< --bit $@

$(OUTDIR)/%.dfu : $(BUILDDIR)/%.bit | $(OUTDIR)
	cp $< $@
	dfu-suffix -v 1209 -p 5af0 -a $@

$(DIRS): %:
	mkdir -p $@

clean:
	rm -rf $(DIRS)
