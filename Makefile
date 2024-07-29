# Dispatch makefile for all builds
# Mostly exists to call other makefiles

.DEFAULT_GOAL = build
include Common.mk

.PHONY: build lint sim sim-build synth synth-gui dfu

build: synth sim-build

# Simulation-related targets
sim:
	$(MAKE) -f Simulate.mk run
sim-build:
	$(MAKE) -f Simulate.mk build

# Synthesis-related targets
synth:
	$(MAKE) -f Synthesis.mk all
synth-gui:
	$(MAKE) -f Synthesis.mk nextpnrgui
dfu:
	$(MAKE) -f Synthesis.mk dfu
lint:
	$(MAKE) -f Synthesis.mk lint
