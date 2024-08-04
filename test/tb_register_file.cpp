#include "Vregister_file.h"
#include "test_tools.h"
#include "verilator_test_util.h"

Vregister_file dut;

void stepclk() {
    static size_t elapsed = 0;
    dut.clk = 1;
    dut.eval();
    dut.clk = 0;
    dut.eval();
}

int main(int argc, char** argv) {
    // Due to some strangeness with Verilator's initialization order, this seems
    // to have to be non-global
    // vtu::trace trace(VCD_PATH, &dut);
    { // Zero register reads 0
        dut.fwd_addr = 0;
        dut.write_addr = 0;
        test::testcase tc("zero");
        dut.a_addr = 0;
        dut.eval();
        tc.assertEqual(dut.a_data, (IData) 0, "Zero reigster did not read 0");

        dut.write_data = 1234;
        stepclk();
        tc.assertEqual(dut.a_data, (IData) 0, "Zero reigster was overwritten");
    }
    { // Zero register ignores forwarding
        test::testcase tc("zero_fwd");
        dut.fwd_addr = 0;
        dut.fwd_data = 1234;
        dut.a_addr = 0;
        dut.eval();
        tc.assertEqual(dut.a_data, (IData) 0, "Zero register erroneously forwarded from forward port");

        dut.fwd_addr = 1;
        dut.write_addr = 0;
        dut.write_data = 1234;
        dut.a_addr = 0;
        dut.eval();
        tc.assertEqual(dut.a_data, (IData) 0, "Zero register erroneously forwarded from writeback port");
    }
    { // Writes work
        test::testcase tc("write");
        dut.write_addr = 3;
        dut.write_data = 1234;
        stepclk();
        dut.a_addr = 3;
        dut.eval();
        tc.assertEqual(dut.a_data, (IData) 1234, "Write did not succeed");

        dut.write_data = 5678;
        dut.write_addr = 5;
        stepclk();
        dut.a_addr = 3;
        dut.eval();
        tc.assertEqual(dut.a_data, (IData) 1234, "Write clobbered by different register");
    }
    { // Forwarding
        test::testcase tc("forwarding");
        dut.write_addr = 4;
        dut.write_data = 5678;
        stepclk();

        dut.write_addr = 4;
        dut.write_data = 1234;
        dut.a_addr = 4;
        dut.eval();
        tc.assertEqual(dut.a_data, (IData) 1234, "Writeback stage did not forward");
        
        dut.fwd_addr = 4;
        dut.fwd_data = 7890;
        dut.eval();
        tc.assertEqual(dut.a_data, (IData) 7890, "Forwarding stage did not forward");
    }
}