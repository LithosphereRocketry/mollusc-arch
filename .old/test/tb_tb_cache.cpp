#include "Vtb_cache.h"
#include "test_tools.h"
#include "verilator_test_util.h"

Vtb_cache dut;

void stepclk(vtu::trace<Vtb_cache>* trace) {
    dut.eval();
    trace->advance();
    dut.clk = 1;
    dut.eval();
    trace->advance();
    dut.eval();
    trace->advance();
    dut.clk = 0;
    dut.eval();
    trace->advance();
}

void reset(vtu::trace<Vtb_cache>* trace, test::testcase* tc) {
    dut.rst = 1;
    stepclk(trace);
    dut.rst = 0;

    for(size_t count = 0; !dut.addr_ready; count++) {
        stepclk(trace);
        tc->assertLess(count, 100, "Took too long to complete reset");
    }
}

#ifndef VCD_PATH
    #define VCD_PATH "out.vcd"
#endif

int main(int argc, char** argv) {
    std::cerr << std::hex;
    vtu::trace trace(VCD_PATH, &dut);
    dut.eval();
    stepclk(&trace);
    try {

        

        // Make the graph a little more readable
        stepclk(&trace);
        stepclk(&trace);
    } catch(test::test_failed& f) {
        // Make the graph a little more readable
        trace.advance();
        std::cerr << f.what();
        return -1;
    }
}
