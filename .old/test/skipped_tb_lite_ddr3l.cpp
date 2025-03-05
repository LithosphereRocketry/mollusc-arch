#include "Vlite_ddr3l.h"
#include "test_tools.h"
#include "verilator_test_util.h"

// Turns out LiteDRAM requires a CPU to do memory training and other
// initialization tasks, so this test won't work until the CPU is fully spun up


// Make the linter behave
#ifndef VCD_PATH
    #define VCD_PATH "out.vcd"
#endif

Vlite_ddr3l dut;

template <class T>
void stepclk(T* trace) {
    trace->advance();
    static size_t elapsed = 0;
    dut.clk = 1;
    dut.eval();
    dut.clk = 0;
    dut.eval();
}

int main(int argc, char** argv) {
    try {
        vtu::trace trace(VCD_PATH, &dut);
        test::testcase t("RAM");
        dut.eval();

        size_t initcount = 0;
        while(!dut.init_done) {
            stepclk(&trace);
            t.assertLess(++initcount, 1000000UL, "RAM failed to initialize");
        }
        t.assertEqual(dut.init_error, (CData) 0, "RAM init yielded error");
        
        stepclk(&trace);
        dut.user_port_wishbone_0_adr = 0x5678;
        dut.user_port_wishbone_0_dat_w = {0x1234};
        dut.user_port_wishbone_0_we = 1;
        dut.user_port_wishbone_0_sel = 0xFFFF;
        dut.user_port_wishbone_0_cyc = 1;
        dut.user_port_wishbone_0_stb = 1;

        while(!dut.user_port_wishbone_0_ack) {
            stepclk(&trace);
        }

        dut.user_port_wishbone_0_cyc = 0;
        dut.user_port_wishbone_0_stb = 0;

        stepclk(&trace);
        stepclk(&trace);
        stepclk(&trace);
    } catch(test::test_failed e) {
        std::cout << e.what() << "\n";
        exit(-1);
    }

}