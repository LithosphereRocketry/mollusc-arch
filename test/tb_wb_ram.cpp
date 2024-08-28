#include "Vwb_ram.h"
#include "test_tools.h"
#include "verilator_test_util.h"

// Make the linter behave
#ifndef VCD_PATH
    #define VCD_PATH "out.vcd"
#endif

// Default parameters: 32-bit word, 8-bit granularity, 8-bit address
Vwb_ram dut;

void stepclk() {
    static size_t elapsed = 0;
    dut.clk_i = 1;
    dut.eval();
    dut.clk_i = 0;
    dut.eval();
}

int main(int argc, char** argv) {
    try {
        vtu::trace trace(VCD_PATH, &dut);
        trace.advance();
        {
            test::testcase tc("Simple write -> read");
            dut.adr_i = 0x12;
            dut.dat_i = 0x3456;
            dut.we_i = 1;
            dut.sel_i = 0b1111;
            dut.stb_i = 1;

            int cyc_count = 0;
            while(!dut.ack_o) {
                stepclk();
                trace.advance();
                cyc_count++;
                tc.assertLess(cyc_count, 100, "Write acknowledge timed out");
            }

            dut.stb_i = 0;
            while(dut.ack_o) {
                stepclk();
                trace.advance();
                cyc_count++;
                tc.assertLess(cyc_count, 100, "Write stuck in acknowledge");
            }

            dut.we_i = 0;
            dut.stb_i = 1;
            while(!dut.ack_o) {
                stepclk();
                trace.advance();
                cyc_count++;
                tc.assertLess(cyc_count, 100, "Read acknowledge timed out");
            }

            tc.assertEqual(dut.dat_o, 0x3456, "Incorrect data read back");
            trace.advance();
        }
    } catch(test::test_failed e) {
        std::cout << e.what() << "\n";
        exit(-1);
    }
}
