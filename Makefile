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
TFPGA_SRCS = \
	edge_detect.v \
	serial.v \
	usb_fs_in_arb.v \
	usb_fs_in_pe.v \
	usb_fs_out_arb.v \
	usb_fs_out_pe.v \
	usb_fs_pe.v \
	usb_fs_rx.v \
	usb_fs_tx_mux.v \
	usb_fs_tx.v \
	usb_reset_det.v \
	usb_serial_ctrl_ep.v \
	usb_uart_bridge_ep.v \
	usb_uart_core.v

ASSETDIR = assets
SRCDIR = src
GENERATEDIR = generated
OUTDIR = out
BUILDDIR = build
TOOLSDIR = tools

DIRS = $(GENERATEDIR) $(OUTDIR) $(BUILDDIR)

USBGEN = $(foreach f,$(TFPGA_SRCS),$(GENERATEDIR)/$(f)) 

GENERATED = $(GENERATEDIR)/pll_108.v $(GENERATEDIR)/lite_ddr3l.v $(USBGEN)
SOURCES = $(wildcard $(SRCDIR)/*.v) $(GENERATED)

$(info $(SOURCES))

.PHONY: clean all dfu

all: $(OUTDIR)/$(TOPLEVEL).dfu $(OUTDIR)/png2hex

dfu: $(OUTDIR)/$(TOPLEVEL).dfu
	dfu-util --alt 0 -D $<

${GENERATEDIR}/pll_108.v: | $(GENERATEDIR)
	ecppll -n pll_108 -i 48 -o 108 -f $@
${GENERATEDIR}/lite_ddr3l.v: orangecrab-dram.yml | $(GENERATEDIR)
	python -m litedram.gen orangecrab-dram.yml --name lite_ddr3l --no-compile --gateware-dir generated/
${USBGEN}: ${GENERATEDIR}/%: external/tinyfpga_bx_usbserial/usb/% | $(GENERATEDIR)
	cp $< $@

$(OUTDIR)/png2hex: $(TOOLSDIR)/png2hex.c | $(OUTDIR)
	gcc -o $@ $^ -lpng

# this rule is kinda cursed but it makes me happy
$(BUILDDIR)/charset.hex: $(OUTDIR)/png2hex $(ASSETDIR)/charset.png | $(BUILDDIR)
	$^ $@

.SECONDARY:

$(BUILDDIR)/%.ys: $(SOURCES) $(BUILDDIR)/charset.hex | $(BUILDDIR)
	$(file >$@)
	$(foreach V,$(SOURCES),$(file >>$@,read_verilog $V))
	$(file >>$@,synth_ecp5 -top $(TOPLEVEL)) \
	$(file >>$@,write_json "$(basename $@).json") \

$(BUILDDIR)/%.json: $(BUILDDIR)/%.ys | $(BUILDDIR)
	yosys -s "$<"

$(BUILDDIR)/%_out.config: $(BUILDDIR)/%.json $(PCF) | $(BUILDDIR)
	nextpnr-ecp5 --json $< --textcfg $@ $(NEXTPNR_DENSITY) --package CSFBGA285 --lpf $(PCF)

$(BUILDDIR)/%.bit: $(BUILDDIR)/%_out.config | $(BUILDDIR)
	ecppack --compress --freq 38.8 --input $< --bit $@

$(OUTDIR)/%.dfu : $(BUILDDIR)/%.bit | $(OUTDIR)
	cp $< $@
	dfu-suffix -v 1209 -p 5af0 -a $@

$(DIRS): %:
	mkdir -p $@

clean:
	rm -rf $(DIRS)