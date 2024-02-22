# Based on makefiles from OrangeCrab Examples repository
# https://github.com/orangecrab-fpga/orangecrab-examples

TOPLEVEL = vgadisplay

PCF = orangecrab_r0.2.1.pcf
DENSITY = 25F

ifneq (,$(findstring 85,$(DENSITY)))
	NEXTPNR_DENSITY:=--85k
else
	NEXTPNR_DENSITY:=--25k
endif

SRCDIR = src
GENERATEDIR = generated
OUTDIR = out
BUILDDIR = build

DIRS = $(SRCDIR) $(GENERATEDIR) $(OUTDIR) $(BUILDDIR)

SOURCES = $(wildcard $(SRCDIR)/*.v) $(GENERATEDIR)/pll_108.v

.PHONY: clean all dfu

all: $(OUTDIR)/$(TOPLEVEL).dfu

dfu: $(OUTDIR)/$(TOPLEVEL).dfu
	dfu-util --alt 0 -D $<

${GENERATEDIR}/pll_108.v: | $(GENERATEDIR)
	ecppll -n pll_108 -i 48 -o 108 -f $@

.SECONDARY:

$(BUILDDIR)/%.ys: $(SOURCES) | $(BUILDDIR)
	$(file >$@)
	$(foreach V,$(SOURCES),$(file >>$@,read_verilog $V))
	$(file >>$@,synth_ecp5 -top $(TOPLEVEL)) \
	$(file >>$@,write_json "$(basename $@).json") \

$(BUILDDIR)/%.json: $(BUILDDIR)/%.ys | $(BUILDDIR)
	yosys -s "$<"

$(BUILDDIR)/%_out.config: $(BUILDDIR)/%.json | $(BUILDDIR)
	nextpnr-ecp5 --json $< --textcfg $@ $(NEXTPNR_DENSITY) --package CSFBGA285 --lpf $(PCF)

$(BUILDDIR)/%.bit: $(BUILDDIR)/%_out.config | $(BUILDDIR)
	ecppack --compress --freq 38.8 --input $< --bit $@

$(OUTDIR)/%.dfu : $(BUILDDIR)/%.bit | $(OUTDIR)
	cp $< $@
	dfu-suffix -v 1209 -p 5af0 -a $@

$(DIRS): %:
	mkdir $@

clean:
	rm -rf $(GENERATEDIR) $(BUILDDIR) $(OUTDIR)