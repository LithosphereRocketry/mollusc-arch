#include "Vcachetest.h"
#include "test_tools.h"
#include "verilator_test_util.h"

Vcachetest dut;

void stepclk(vtu::trace<Vcachetest>* trace) {
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

void reset(vtu::trace<Vcachetest>* trace) {
    dut.rst = 1;
    stepclk(trace);
    dut.rst = 0;
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

        {
            test::testcase tc("Simple write-readback");
            reset(&trace);

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
            reset(&trace);

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
            tc.assertEqual(dut.dataout_b, 0x2345, "Incorrect data returned after caching");
        }

        {
            test::testcase tc("Block cache performance");
            reset(&trace);

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

        {
            test::testcase tc("Simultaneous uncached read requests");
            reset(&trace);

            dut.valid_b = 1;
            dut.addr_b = 0x0014;
            dut.wr_b = 1;
            dut.datain_b = 0x5678;
            stepclk(&trace);
            dut.valid_b = 0;
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to write");
            }

            dut.valid_b = 1;
            dut.addr_b = 0x0024;
            dut.wr_b = 1;
            dut.datain_b = 0x6789;
            stepclk(&trace);
            dut.valid_b = 0;
            dut.wr_b = 0;
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to write");
            }

            dut.valid_a = 1;
            dut.addr_a = 0x0024;
            dut.valid_b = 1;
            dut.addr_b = 0x0014;
            stepclk(&trace);
            dut.valid_a = 0;
            dut.valid_b = 0;
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to read");
            }
            tc.assertEqual(dut.dataout_b, 0x5678, "Incorrect data on B");
            tc.assertEqual(dut.ready_a, 0, "B port should be fetched first");

            for(size_t count = 0; !dut.ready_a; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to read");
            }
            tc.assertEqual(dut.dataout_a, 0x6789, "Incorrect data on A");
        }

        {
            // TODO: This test triggers a bit of extra latency, but it's not a
            // common use case so I'm OK with that
            // The issue is that the instant a read operation goes in, if the
            // requested address isn't cached, the controller commits to making
            // a read request on the bus. However, if that read request gets
            // queued behind another, and that other one pulls the data into
            // cache, we don't re-check and realize we don't have to make a bus
            // request anymore. Fixing this would be a pain, so I'm just going
            // to leave it.
            test::testcase tc("Simultaneous shared-line read requests");
            reset(&trace);

            dut.valid_b = 1;
            dut.addr_b = 0x0034;
            dut.wr_b = 1;
            dut.datain_b = 0x5678;
            stepclk(&trace);
            dut.valid_b = 0;
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to write");
            }

            dut.valid_b = 1;
            dut.addr_b = 0x0038;
            dut.wr_b = 1;
            dut.datain_b = 0x6789;
            stepclk(&trace);
            dut.valid_b = 0;
            dut.wr_b = 0;
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to write");
            }

            dut.valid_a = 1;
            dut.addr_a = 0x0038;
            dut.valid_b = 1;
            dut.addr_b = 0x0034;
            stepclk(&trace);
            dut.valid_a = 0;
            dut.valid_b = 0;
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to read");
            }
            tc.assertEqual(dut.dataout_b, 0x5678, "Incorrect data on B");
            tc.assertEqual(dut.ready_a, 0, "B port should be fetched first");

            for(size_t count = 0; !dut.ready_a; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to read");
            }
            tc.assertEqual(dut.dataout_a, 0x6789, "Incorrect data on A");
        }

        {
            test::testcase tc("Simultaneous prefetched shared-line read requests");
            reset(&trace);

            dut.valid_b = 1;
            dut.addr_b = 0x0044;
            dut.wr_b = 1;
            dut.datain_b = 0x5678;
            stepclk(&trace);
            dut.valid_b = 0;
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to write");
            }

            dut.valid_b = 1;
            dut.addr_b = 0x0048;
            dut.wr_b = 1;
            dut.datain_b = 0x6789;
            stepclk(&trace);
            dut.valid_b = 0;
            dut.wr_b = 0;
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to write");
            }

            // Prefetch
            dut.valid_b = 1;
            dut.addr_b = 0x0048;
            stepclk(&trace);
            dut.valid_b = 0;
            // Wait for memory to report ready
            for(size_t count = 0; !dut.ready_b; count++) {
                stepclk(&trace);
                tc.assertLess(count, 10, "Took too long to prefetch");
            }

            dut.valid_a = 1;
            dut.addr_a = 0x0048;
            dut.valid_b = 1;
            dut.addr_b = 0x0044;
            stepclk(&trace);
            dut.valid_a = 0;
            dut.valid_b = 0;

            tc.assertEqual(dut.ready_a, 1, "A not available immediately");
            tc.assertEqual(dut.dataout_a, 0x6789, "Incorrect data on A");
            tc.assertEqual(dut.ready_b, 1, "B not available immediately");
            tc.assertEqual(dut.dataout_b, 0x5678, "Incorrect data on B");
        }

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
