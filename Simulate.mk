.DEFAULT_GOAL = run
include Common.mk

LINKS = Vcore verilated SDL2 SDL2main SDL2_image

CXXFLAGS = -O2 -L./$(SIM_GEN_DIR)/ $(foreach l,$(LINKS),-l$(l)) -I$(SIM_GEN_DIR) -I$(SRCDIR) -I/opt/oss-cad-suite/share/verilator/include

LIBCORE = $(SIM_GEN_DIR)/libVcore.a

SRCDIR = src-simulate

TOPLEVEL = sim
SRCS = $(wildcard $(SRCDIR)*.cpp)

.PHONY: run build
build: $(OUT_DIR)/$(TOPLEVEL)

# Static library generated from Verilog source
$(LIBCORE): $(GATEWARE) | $(SIM_GEN_DIR)
	verilator -O3 --cc --Mdir $(SIM_GEN_DIR) --build $(GATEWARE) -I./src --top-module core -Wno-fatal

$(OUT_DIR)/$(TOPLEVEL): $(SRCDIR)/$(TOPLEVEL).cpp $(SRCDIR)/scancodesets.c $(SRCDIR)/scancodesets.h $(LIBCORE)
	$(CXX) $< $(SRCDIR)/scancodesets.c $(CXXFLAGS) -o $@

run: build
	$(OUT_DIR)/$(TOPLEVEL)