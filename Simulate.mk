.DEFAULT_GOAL = run
include Common.mk

LINKS = verilated SDL2 SDL2main SDL2_image

CXXFLAGS = -O2 -L./$(SIM_GEN_DIR)/ $(foreach l,$(LINKS),-l$(l)) -I$(SIM_GEN_DIR) -I$(SRCDIR) -I/opt/oss-cad-suite/share/verilator/include
VERFLAGS = -O3 --trace --cc --Mdir $(SIM_GEN_DIR) --build -I./src -Wno-fatal

LIBCORE = $(SIM_GEN_DIR)/libVcore.a

SRCDIR = src-simulate
TESTROMDIR = $(TEST_DIR)/rom

TOPLEVEL = sim
SRCS = $(wildcard $(SRCDIR)*.cpp)
TESTSRCS = $(wildcard $(TEST_DIR)/tb_*.cpp)
TESTTGTS = $(patsubst $(TEST_DIR)/tb_%.cpp,$(LOG_DIR)/tb_%.txt,$(TESTSRCS))

.PHONY: run build test
build: $(OUT_DIR)/$(TOPLEVEL)

# Static library generated from Verilog source
.PRECIOUS: $(SIM_GEN_DIR)/libV%.a
$(SIM_GEN_DIR)/libV%.a: $(GATEWARE) $(TESTROMDIR)/tb_%.hex | $(SIM_GEN_DIR)
	verilator $(VERFLAGS) -DROMPATH=\"$(TESTROMDIR)/tb_$*.hex\" $(GATEWARE) --top-module $*

$(OUT_DIR)/$(TOPLEVEL): $(SRCDIR)/$(TOPLEVEL).cpp $(SRCDIR)/scancodesets.c $(SRCDIR)/scancodesets.h $(LIBCORE) | $(OUT_DIR)
	$(CXX) $< -lVcore $(SRCDIR)/scancodesets.c $(CXXFLAGS) -o $@

# TODO: why does this need to depend on the hex file?
.PRECIOUS: $(OUT_DIR)/tb_%
$(OUT_DIR)/tb_%: $(TEST_DIR)/tb_%.cpp $(SIM_GEN_DIR)/libV%.a $(TEST_DIR)/test_tools.h $(TEST_DIR)/verilator_test_util.h $(TESTROMDIR)/tb_%.hex | $(OUT_DIR)
	$(CXX) $< -lV$* $(CXXFLAGS) -DVCD_PATH=\"$(WAVE_DIR)/tb_$*.vcd\" -o $@

run: build
	$(OUT_DIR)/$(TOPLEVEL)

# This is a little trick borrowed from one of my other projects, the logfile
# doesn't get created unless the test passes, and otherwise it gets printed to
# the console for debugging
$(LOG_DIR)/tb_%.txt: $(OUT_DIR)/tb_% | $(LOG_DIR) $(FAIL_DIR) $(WAVE_DIR)
	$< > $(FAIL_DIR)/tb_$*.txt || { cat $(FAIL_DIR)/tb_$*.txt; exit 1; } 
	mv $(FAIL_DIR)/tb_$*.txt $@

test: $(TESTTGTS)