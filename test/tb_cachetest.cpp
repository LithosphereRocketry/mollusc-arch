#include "Vcachetest.h"
#include "test_tools.h"
#include "verilator_test_util.h"

Vcachetest dut;

void stepclk(vtu::trace<Vcachetest>* trace) {
    dut.clk = 1;
    dut.eval();
    trace->advance();
    dut.clk = 0;
    dut.eval();
    trace->advance();
}

#ifndef VCD_PATH
    #define VCD_PATH "out.vcd"
#endif

int main(int argc, char** argv) {
    vtu::trace trace(VCD_PATH, &dut);
    dut.eval();
    stepclk(&trace);
    try {

        {
            test::testcase tc("Simple write-readback");

            // Write data to memory
            dut.valid_b = 1;
            dut.wr_b = 1;
            dut.addr_b = 0x0004;
            dut.datain_b = 0x1234;
            stepclk(&trace);
            dut.valid_b = 0;
            dut.wr_b = 0;
            dut.addr_b = 0xEEEE;
            dut.datain_b = 0xEEEE;
            dut.eval();
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to write");
            }

            // Read data back from memory
            dut.valid_b = 1;
            dut.addr_b = 0x0004;
            stepclk(&trace);
            dut.valid_b = 0;
            dut.addr_b = 0xEEEE;
            dut.eval();
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to read");
            }

            tc.assertEqual(dut.dataout_b, 0x1234, "Incorrect data returned");
        }

        {
            test::testcase tc("Cached performance");

            // Write data to memory
            dut.valid_b = 1;
            dut.wr_b = 1;
            dut.addr_b = 0x0014;
            dut.datain_b = 0x2345;
            stepclk(&trace);
            dut.valid_b = 0;
            dut.wr_b = 0;
            dut.addr_b = 0xEEEE;
            dut.datain_b = 0xEEEE;
            dut.eval();
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to write");
            }

            // Read data back from memory
            dut.valid_b = 1;
            dut.addr_b = 0x0014;
            stepclk(&trace);
            dut.valid_b = 0;
            dut.addr_b = 0xEEEE;
            dut.eval();
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to read");
            }

            tc.assertEqual(dut.dataout_b, 0x2345, "Incorrect data returned");
            dut.valid_b = 1;
            dut.addr_b = 0x0014;
            stepclk(&trace);
            tc.assertEqual(dut.ready_b, 1, "Cached access should not stall");
            tc.assertEqual(dut.dataout_b, 0x2345, "Incorrect data returned");
        }

        {
            test::testcase tc("Block cache performance");

            // Write data to memory
            dut.valid_b = 1;
            dut.wr_b = 1;
            dut.addr_b = 0x0024;
            dut.datain_b = 0x3456;
            stepclk(&trace);
            dut.valid_b = 0;
            dut.wr_b = 0;
            dut.addr_b = 0xEEEE;
            dut.datain_b = 0xEEEE;
            dut.eval();
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to write");
            }
            // Write more data to memory, adjacent to existing item
            dut.valid_b = 1;
            dut.wr_b = 1;
            dut.addr_b = 0x0028;
            dut.datain_b = 0x4567;
            stepclk(&trace);
            dut.valid_b = 0;
            dut.wr_b = 0;
            dut.addr_b = 0xEEEE;
            dut.datain_b = 0xEEEE;
            dut.eval();
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to write");
            }

            // Read data back from memory
            dut.valid_b = 1;
            dut.addr_b = 0x0024;
            stepclk(&trace);
            dut.valid_b = 0;
            dut.addr_b = 0xEEEE;
            dut.eval();
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to read");
            }

            tc.assertEqual(dut.dataout_b, 0x3456, "Incorrect data returned");
            dut.valid_b = 1;
            dut.addr_b = 0x0028;
            stepclk(&trace);
            tc.assertEqual(dut.ready_b, 1, "Block-cached access should not stall");
            tc.assertEqual(dut.dataout_b, 0x4567, "Incorrect data returned");
        }

        // Make the graph a little more readable
        stepclk(&trace);
        stepclk(&trace);
    } catch(test::test_failed& f) {
        // Make the graph a little more readable
        stepclk(&trace);
        stepclk(&trace);
        std::cerr << f.what();
        return -1;
    }
    // dut.valid_a = 1;
    // dut.addr_a = 0x0014;
    // trace.advance();
    // stepclk();
    // dut.valid_a = 0;
    // dut.addr_a = 0xEEEE;

    // for(size_t i = 0; i < 10; i++) {
    //     trace.advance();
    //     stepclk();
    // }

    // dut.valid_a = 1;
    // dut.addr_a = 0x0018;
    // trace.advance();
    // stepclk();
    // dut.valid_a = 0;
    // dut.addr_a = 0xEEEE;

    // // dut.valid_b = 1;
    // // dut.addr_b = 0x0010;
    // // trace.advance();
    // // stepclk();
    // // dut.valid_b = 0;
    // // dut.addr_b = 0xEEEE;

    // for(size_t i = 0; i < 10; i++) {
    //     trace.advance();
    //     stepclk();
    // }

    // dut.valid_b = 1;
    // dut.addr_b = 0x001C;
    // dut.datain_b = 0x9876;
    // dut.wr_b = 1;
    // trace.advance();
    // stepclk();
    // dut.valid_b = 0;
    // dut.addr_b = 0xEEEE;
    // dut.wr_b = 0;

    // for(size_t i = 0; i < 10; i++) {
    //     trace.advance();
    //     stepclk();
    // }

}
