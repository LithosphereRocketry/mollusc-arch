#include "Vcputest.h"
#include "test_tools.h"
#include "verilator_test_util.h"

// Make the linter behave
#ifndef VCD_PATH
    #define VCD_PATH "out.vcd"
#endif

Vcputest dut;

void stepclk() {
    static size_t elapsed = 0;
    dut.clk = 1;
    dut.eval();
    dut.clk = 0;
    dut.eval();
}

int main(int argc, char** argv) {
    try {
        vtu::trace trace(VCD_PATH, &dut);
        dut.rst = 1;
        dut.eval();
        trace.advance();
        stepclk();
        dut.rst = 0;
        for(size_t i = 0; i < 256; i++) {
            trace.advance();
            stepclk();
        }
        dut.rst = 1;
        dut.eval();
        trace.advance();
        stepclk();
        dut.rst = 0;
        for(size_t i = 0; i < 256; i++) {
            trace.advance();
            stepclk();
        }
        
    } catch(test::test_failed e) {
        std::cout << e.what() << "\n";
        exit(-1);
    }
}
